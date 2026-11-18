#!/usr/bin/env python3
"""Run W/Y regressions with the simulator, using only Python and local sources.

No assembler is needed: the small ELF programs use the supplied opcode tables.
The Sail unit tests additionally check all 627 base encodings per extension.
"""

import argparse
import copy
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile


class Program:
    def __init__(self, xlen=64):
        self.xlen = xlen
        self.words = []
        self.labels = {}
        self.branches = []
        self.checks = 0

    def emit(self, word):
        self.words.append(word & 0xffffffff)

    def li(self, rd, value):
        negative = value < 0
        value &= 0xffffffff
        high = (value + 0x800) >> 12
        low = value - (high << 12)
        self.emit((high << 12) | (rd << 7) | 0x37)
        self.emit(((low & 0xfff) << 20) | (rd << 15) | (rd << 7) | 0x13)
        if self.xlen == 64 and not negative and value >= 0x80000000:
            self.emit((32 << 20) | (rd << 15) | (1 << 12) | (rd << 7) | 0x13)
            self.emit((32 << 20) | (rd << 15) | (5 << 12) | (rd << 7) | 0x13)

    def check(self, actual, expected):
        self.checks += 1
        self.li(10, self.checks)
        self.li(28, expected)
        self.branches.append((len(self.words), actual, 28, 'finish'))
        self.emit(0)

    def finish(self):
        self.li(10, 0)
        self.labels['finish'] = len(self.words)
        # HTIF exit command: (exit_code << 1) | 1.
        self.emit((1 << 20) | (10 << 15) | (1 << 12) | (10 << 7) | 0x13)
        self.emit((1 << 20) | (10 << 15) | (6 << 12) | (10 << 7) | 0x13)
        self.li(5, 0x80010020)
        if self.xlen == 64:
            self.emit((10 << 20) | (5 << 15) | (3 << 12) | 0x23)  # sd a0, 0(t0)
        else:
            self.emit((10 << 20) | (5 << 15) | (2 << 12) | 0x23)  # sw a0, 0(t0)
            self.emit((5 << 15) | (2 << 12) | (4 << 7) | 0x23)  # sw zero, 4(t0)
        self.emit(0x0000006f)
        for location, rs1, rs2, target in self.branches:
            offset = (self.labels[target] - location) * 4
            assert -4096 <= offset < 4096
            self.words[location] = (((offset >> 12) & 1) << 31 |
                                    ((offset >> 5) & 63) << 25 |
                                    rs2 << 20 | rs1 << 15 | 1 << 12 |
                                    ((offset >> 1) & 15) << 8 |
                                    ((offset >> 11) & 1) << 7 | 0x63)
        return b''.join(struct.pack('<I', w) for w in self.words)


def write_elf(path, text, xlen=64):
    """Minimal RV32/RV64 ELF, with loadable data and a tohost symbol."""
    symbol_size = 24 if xlen == 64 else 16
    section_size = 64 if xlen == 64 else 40
    data = bytes(range(1, 17)) + bytes(48)
    strings = b'\x00tohost\x00'
    section_names = b'\x00.text\x00.data\x00.symtab\x00.strtab\x00.shstrtab\x00'
    image = bytearray(0x1000)
    image.extend(text)
    data_offset = (len(image) + 7) & ~7
    image.extend(bytes(data_offset - len(image)))
    image.extend(data)
    symbol_offset = len(image)
    image.extend(bytes(symbol_size))
    if xlen == 64:
        image.extend(struct.pack('<IBBHQQ', 1, 0x11, 0, 2, 0x80010020, 8))
    else:
        image.extend(struct.pack('<IIIBBH', 1, 0x80010020, 8, 0x11, 0, 2))
    string_offset = len(image)
    image.extend(strings)
    section_name_offset = len(image)
    image.extend(section_names)
    section_offset = (len(image) + 7) & ~7
    image.extend(bytes(section_offset - len(image)))
    sections = [bytes(section_size)]
    def section(name, typ, flags, addr, offset, size, link=0, info=0, align=1, entsize=0):
        fmt = '<IIQQQQIIQQ' if xlen == 64 else '<IIIIIIIIII'
        return struct.pack(fmt, section_names.index(name.encode()), typ,
                           flags, addr, offset, size, link, info, align, entsize)
    sections.append(section('.text', 1, 6, 0x80000000, 0x1000, len(text), align=4))
    sections.append(section('.data', 1, 3, 0x80010000, data_offset, len(data), align=8))
    sections.append(section('.symtab', 2, 0, 0, symbol_offset, symbol_size * 2,
                            4, 1, xlen // 8, symbol_size))
    sections.append(section('.strtab', 3, 0, 0, string_offset, len(strings)))
    sections.append(section('.shstrtab', 3, 0, 0, section_name_offset, len(section_names)))
    image.extend(b''.join(sections))
    ident = b'\x7fELF' + bytes([2 if xlen == 64 else 1, 1, 1]) + bytes(9)
    if xlen == 64:
        image[:64] = struct.pack('<16sHHIQQQIHHHHHH', ident, 2, 243, 1, 0x80000000,
                                 64, section_offset, 0, 64, 56, 2, 64, 6, 5)
        image[64:120] = struct.pack('<IIQQQQQQ', 1, 5, 0x1000, 0x80000000,
                                    0x80000000, len(text), len(text), 0x1000)
        image[120:176] = struct.pack('<IIQQQQQQ', 1, 6, data_offset, 0x80010000,
                                     0x80010000, len(data), len(data), 8)
    else:
        image[:52] = struct.pack('<16sHHIIIIIHHHHHH', ident, 2, 243, 1, 0x80000000,
                                 52, section_offset, 0, 52, 32, 2, 40, 6, 5)
        image[52:84] = struct.pack('<IIIIIIII', 1, 0x1000, 0x80000000,
                                   0x80000000, len(text), len(text), 5, 0x1000)
        image[84:116] = struct.pack('<IIIIIIII', 1, data_offset, 0x80010000,
                                    0x80010000, len(data), len(data), 6, 8)
    path.write_bytes(image)


def read_table(spec, e):
    table = {}
    for line in (spec / f'rv-{e}' / 'opcode.md').read_text().splitlines():
        if line.startswith(f'| `rv_{e}`'):
            fields = re.findall(r'`([^`]+)`', line)
            table[fields[1]] = (int(fields[4], 16), int(fields[5], 16))
    assert len(table) == 627
    return table


def make_program(table, e, memory=True, xlen=64):
    p = Program(xlen)
    E = e.upper()
    csr_base = 0x800 if e == 'w' else 0x804
    def instruction(name, dst=3, src2=1, src1=2, unmasked=1):
        match, mask = table[name]
        variables = dst << 7 | src1 << 15 | src2 << 20 | unmasked << 25
        p.emit(match | (variables & ~mask))
    def setting(sew=8, length=16):
        p.li(5, length)
        match, _ = table[e + 'set' + e + 'li']
        sew_field = {8: 0, 16: 8, 32: 16, 64: 24}[sew]
        p.emit(match | sew_field << 20 | 5 << 15 | 6 << 7)
        p.check(6, length)
    def move(dst, value):
        p.li(5, value)
        instruction(e + 'mv_' + e + '_x', dst, src1=5)
    def expect(src, value):
        instruction(e + 'mv_x_s', 7, src2=src)
        p.check(7, value)

    # Enable scalar FP while leaving VS off: W and Y must work without V state.
    p.li(5, 0x6000)
    p.emit(0x30000073 | 5 << 15 | 2 << 12)  # csrs mstatus, t0
    setting()
    move(1, 5)
    move(2, -2)
    instruction(e + 'add_' + e * 2)
    expect(3, 3)
    instruction(e + 'mul_' + e * 2)
    expect(3, -10)
    # Check each explicitly indexed mask operation before either source changes.
    for operation, expected in [('mand', 4), ('mnand', -5), ('mandn', 1),
                                ('mxor', -5), ('mor', -1), ('mnor', 0),
                                ('morn', 5), ('mxnor', 4)]:
        instruction(e + operation + '_mm')
        expect(3, expected)
    move(4, 0)
    instruction(e + 'div_' + e * 2, src1=4)
    expect(3, -1)
    instruction(e + 'saddu_' + e * 2)
    expect(3, -1)
    p.emit((csr_base + 1) << 20 | 2 << 12 | 7 << 7 | 0x73)
    p.check(7, 1)
    move(0, 0)
    move(3, 77)
    instruction(e + 'add_' + e * 2, unmasked=0)
    expect(3, 77)
    move(2, 0)
    instruction(e + 'redsum_' + e + 's', src1=2)
    expect(3, 80)

    if memory:
        p.li(5, 0x80010000)
        instruction(e + 'le8_' + e, dst=6, src1=5)
        move(2, 15)
        instruction(e + 'rgather_' + e * 2, src2=6, src1=2)
        expect(3, 16)  # row/plane boundary with columns=3, depth=5
        instruction(e + 'add_' + e + 'x', dst=6, src2=6, src1=0)
        p.li(5, 0x80010010)
        instruction(e + 'se8_' + e, dst=6, src1=5)
        for i in range(16):
            p.emit(i << 20 | 5 << 15 | 4 << 12 | 7 << 7 | 0x03)  # lbu
            p.check(7, i + 1)

    setting(32, 4)
    move(1, 0x3f800000)
    move(2, 0x40000000)
    instruction(e + 'fadd_' + e * 2)
    expect(3, 0x40400000)
    move(2, 0)
    instruction(e + 'fdiv_' + e * 2)
    expect(3, 0x7f800000)
    p.emit(0x00102073 | 7 << 7)  # csrr t2, fflags
    p.check(7, 8)
    setting(64, 4)
    move(1, 5)
    move(2, -2)
    instruction(e + 'add_' + e * 2)
    expect(3, 3)
    return p.finish(), p.checks


def load_json(path):
    # Preserve quoted strings when removing JSON-with-comments comments.
    text = re.sub(r'"(?:[^"\\]|\\.)*"|//[^\n]*|/\*.*?\*/',
                  lambda m: m.group() if m.group().startswith('"') else '',
                  path.read_text(), flags=re.S)
    return json.loads(text)


def run(command):
    result = subprocess.run([str(x) for x in command], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=120)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {command}\n{result.stdout}')
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    root = Path(__file__).resolve().parents[3]
    parser.add_argument('--build', type=Path, default=root / 'build')
    parser.add_argument('--spec', type=Path, default=root.parent / 'GreenCard/RISC-V/instructions/specific/Algebra')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    simulator = args.build / 'c_emulator/sail_riscv_sim'
    unit_tests = args.build / 'test/unit_tests/unit_tests'
    config = load_json(args.build / 'config/rv64d_v256_e64.json')
    tables = {e: read_table(args.spec, e) for e in 'vwy'}
    results = []
    with tempfile.TemporaryDirectory(prefix='sail-rvwy-') as temp:
        directory = Path(temp)
        # Full opcode audit of the three banks, including all shared memory patterns.
        for bank in 'VWY':
            cfg = copy.deepcopy(config)
            cfg['extensions']['W']['supported'] = True
            cfg['extensions']['Y']['supported'] = True
            cfg['algebra']['memory_bank'] = 'AlgebraMemory_' + bank
            path = directory / f'audit-{bank}.json'
            path.write_text(json.dumps(cfg))
            run([unit_tests, path])
            results.append({'test': f'opcode_audit_{bank}', 'status': 'PASS'})
        for xlen in [32, 64]:
            for e in 'wy':
                cfg = load_json(args.build / f'config/rv{xlen}d_v256_e64.json')
                cfg['extensions']['V']['support_level'] = 'Disabled'
                for name, settings in cfg['extensions'].items():
                    if name.startswith('Zv') and isinstance(settings, dict) and 'supported' in settings:
                        settings['supported'] = False
                for bank in 'WY':
                    cfg['extensions'][bank]['supported'] = bank == e.upper()
                cfg['algebra']['memory_bank'] = 'AlgebraMemory_' + e.upper()
                cfg['extensions'][e.upper()]['columns'] = 3
                if e == 'y':
                    cfg['extensions']['Y']['depth'] = 5
                path = directory / f'standalone-{e}-rv{xlen}.json'
                path.write_text(json.dumps(cfg))
                text, checks = make_program(tables[e], e, xlen=xlen)
                elf = directory / f'standalone-{e}-rv{xlen}.elf'
                write_elf(elf, text, xlen)
                output = run([simulator, '--config', path, '--inst-limit', '10000', elf])
                if 'SUCCESS' not in output:
                    raise RuntimeError(output)
                results.append({'test': f'RV{xlen}_{e.upper()}_without_V_or_other_bank',
                                'checks': checks, 'status': 'PASS', 'output': output.strip()})
        invalid_cases = [
            ('W_memory_disabled', ('algebra', 'memory_bank'), 'AlgebraMemory_W'),
            ('Y_memory_disabled', ('algebra', 'memory_bank'), 'AlgebraMemory_Y'),
            ('W_element_width_too_large', ('extensions', 'W', 'elen_exp'), 7),
            ('Y_element_wider_than_register', ('extensions', 'Y', 'ylen_exp'), 5),
            ('W_index_width_too_large', ('extensions', 'W', 'max_index_eew_exp'), 7),
            ('Y_zero_depth', ('extensions', 'Y', 'depth'), 0),
            ('Y_view_exceeds_capacity', ('extensions', 'Y', 'depth'), 256),
        ]
        for name, keys, value in invalid_cases:
            cfg = copy.deepcopy(config)
            field = cfg
            for key in keys[:-1]:
                field = field[key]
            field[keys[-1]] = value
            path = directory / f'invalid-{name}.json'
            path.write_text(json.dumps(cfg))
            result = subprocess.run([str(simulator), '--config', str(path), '--validate-config'],
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    timeout=30)
            if result.returncode != 1:
                raise RuntimeError(f'{name}: expected configuration rejection, got '
                                   f'{result.returncode}\n{result.stdout}')
            results.append({'test': name, 'status': 'PASS', 'expected': 'configuration_rejected'})
    report = {'results': results, 'base_specification_entries': {e.upper(): len(t) for e, t in tables.items()}}
    rendered = json.dumps(report, indent=2)
    if args.output:
        args.output.write_text(rendered + '\n')
    print(rendered)


if __name__ == '__main__':
    main()
