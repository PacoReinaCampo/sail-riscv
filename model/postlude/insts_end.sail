// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Put the illegal instructions last to use their wildcard match.

// *****************************************************************

mapping clause encdec = ILLEGAL(s) <-> s

function clause execute ILLEGAL(_s) = Illegal_Instruction()

mapping clause assembly = ILLEGAL(s) <-> "illegal" ^ spc() ^ hex_bits_32(s)

// *****************************************************************

mapping clause encdec_compressed = C_ILLEGAL(s) <-> s

function clause execute C_ILLEGAL(_s) = Illegal_Instruction()

mapping clause assembly = C_ILLEGAL(s) <-> "c.illegal" ^ spc() ^ hex_bits_16(s)

// *****************************************************************

mapping clause encdec48 = ILLEGAL48(s) <-> s
mapping clause encdec64 = ILLEGAL64(s) <-> s

function clause execute ILLEGAL48(_) = Illegal_Instruction()
function clause execute ILLEGAL64(_) = Illegal_Instruction()

mapping clause assembly = forwards ILLEGAL48(s) => "illegal.48 " ^ bits_str(s)
mapping clause assembly = forwards ILLEGAL64(s) => "illegal.64 " ^ bits_str(s)

// End definitions
end extension
end extensionName
end hartSupports
end currentlyEnabled
end instruction
end execute
end assembly
end encdec
end encdec_compressed
end encdec48
end encdec64

// Some legal instructions do not have any corresponding assembly, e.g. reserved fences.
private function instruction_to_str_base(insn : instruction) -> string =
  if assembly_forwards_matches(insn) then assembly(insn) else (".insn " ^ bits_str(encdec(insn)))

function instruction_to_str(insn : instruction) -> string =
  match insn {
    O_INSN(body, opcode) => "o." ^ instruction_to_str_base(encdec(body @ opcode)),
    _ => instruction_to_str_base(insn),
  }

overload to_str = {instruction_to_str}
