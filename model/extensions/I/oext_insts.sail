function clause currentlyEnabled(Ext_RvO) = hartSupports(Ext_RvO)

private function o_base_instruction(inst : bits(32)) -> bool = {
  let with_funct7 : bool = match inst & 0xfe00707f {
    0x00000033 => true,
    0x00007033 => true,
    0x00006033 => true,
    0x00001033 => true,
    0x00002033 => true,
    0x00003033 => true,
    0x40005033 => true,
    0x00005033 => true,
    0x40000033 => true,
    0x00004033 => true,
    _ => false,
  };
  let with_funct3 : bool = match inst & 0x0000707f {
    0x00000013 => true,
    0x00007013 => true,
    0x00000063 => true,
    0x00005063 => true,
    0x00007063 => true,
    0x00004063 => true,
    0x00006063 => true,
    0x00001063 => true,
    0x0000000f => true,
    0x00000067 => true,
    0x00000003 => true,
    0x00004003 => true,
    0x00001003 => true,
    0x00005003 => true,
    0x00002003 => true,
    0x00006013 => true,
    0x00000023 => true,
    0x00001023 => true,
    0x00002013 => true,
    0x00003013 => true,
    0x00002023 => true,
    0x00004013 => true,
    _ => false,
  };
  let with_opcode : bool = match inst & 0x0000007f {
    0x00000017 => true,
    0x0000006f => true,
    0x00000037 => true,
    _ => false,
  };
  let with_all_bits : bool = match inst & 0xffffffff {
    0x00100073 => true,
    0x00000073 => true,
    _ => false,
  };
  with_funct7 | with_funct3 | with_opcode | with_all_bits
}

private function o_rv64_instruction(inst : bits(32)) -> bool = {
  let with_funct3 : bool = match inst & 0x0000707f {
    0x0000001b => true,
    0x00003003 => true,
    0x00006003 => true,
    0x00003023 => true,
    _ => false,
  };
  let with_funct7 : bool = match inst & 0xfe00707f {
    0x0000003b => true,
    0x0000101b => true,
    0x0000103b => true,
    0x4000501b => true,
    0x4000503b => true,
    0x0000501b => true,
    0x0000503b => true,
    0x4000003b => true,
    _ => false,
  };
  let with_funct6 : bool = match inst & 0xfc00707f {
    0x00001013 => true,
    0x40005013 => true,
    0x00005013 => true,
    _ => false,
  };
  with_funct3 | with_funct7 | with_funct6
}

union clause instruction = O_INSN : (bits(25), bits(7))

mapping clause encdec64 = O_INSN(body, opcode)
  <-> 0b0000000000000000000000000 @ opcode @ body @ 0b0111111
  when currentlyEnabled(Ext_RvO) &
       (o_base_instruction(body @ opcode) | (xlen == 64 & o_rv64_instruction(body @ opcode)))

function clause execute O_INSN(body, opcode) = ExecuteAs(encdec(body @ opcode))
