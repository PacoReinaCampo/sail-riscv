// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_T) = hartSupports(Ext_T)

register rv_t_checkpoint : vector(2 ^ regidx_bit_width, xlenbits) = vector_init(zeros())
register rv_t_abort_pc : xlenbits = zeros()
register rv_t_status_reg : regidx = zreg

// GreenCard leaves the numeric values of the status flags open.
let rv_t_explicit : xlenbits = to_bits(1)
let rv_t_nested : xlenbits = to_bits(2)
let rv_t_unavailable : xlenbits = to_bits(4)
let rv_t_interrupted : xlenbits = to_bits(8)
let rv_t_conflict : xlenbits = to_bits(16)

function rv_t_abort(status : xlenbits) -> unit = {
  rv_t_discard();
  foreach (i from 1 to (length(rv_t_checkpoint) - 1)) {
    X(Regno(i)) = rv_t_checkpoint[i];
  };
  X(rv_t_status_reg) = status;
  set_next_pc(rv_t_abort_pc);
}

union clause instruction = TBEGIN : regidx
union clause instruction = TCOMMIT : unit
union clause instruction = TABORT : bits(12)
union clause instruction = TTEST : regidx

mapping clause encdec = TBEGIN(rd)
  <-> 0b00000000000000000000 @ encdec_reg(rd) @ 0b1101011
  when currentlyEnabled(Ext_T)

mapping clause encdec = TCOMMIT() <-> 0x0000106b
  when currentlyEnabled(Ext_T)

mapping clause encdec = TABORT(code)
  <-> code @ 0b00000010000001101011
  when currentlyEnabled(Ext_T)

mapping clause encdec = TTEST(rd)
  <-> 0b00000000000000000011 @ encdec_reg(rd) @ 0b1101011
  when currentlyEnabled(Ext_T)

mapping clause assembly = TBEGIN(rd) <-> "tbegin" ^ spc() ^ reg_name(rd)
mapping clause assembly = TCOMMIT() <-> "tcommit"
mapping clause assembly = TABORT(code) <-> "tabort" ^ spc() ^ hex_bits_12(code)
mapping clause assembly = TTEST(rd) <-> "ttest" ^ spc() ^ reg_name(rd)

function clause execute TBEGIN(rd) = {
  if rd == zreg then return Illegal_Instruction();
  if rv_t_active then {
    rv_t_abort(rv_t_nested);
  } else {
    sail_barrier(Barrier_RISCV_rw_rw);
    cancel_reservation();
    // The supported transaction profile uses native M-mode with physical
    // addressing. This avoids speculative page-table walks and A/D updates.
    if cur_privilege != Machine | mstatus[MPRV] == 0b1 | is_landing_pad_expected() then {
      X(rd) = rv_t_unavailable;
    } else {
      foreach (i from 1 to (length(rv_t_checkpoint) - 1)) {
        rv_t_checkpoint[i] = X(Regno(i));
      };
      rv_t_abort_pc = get_next_pc();
      rv_t_status_reg = rd;
      rv_t_active = true;
      X(rd) = zeros();
    }
  };
  RETIRE_SUCCESS
}

function clause execute TCOMMIT() = {
  if not(rv_t_active) then return Illegal_Instruction();
  if rv_t_commit_ram() then {
    rv_t_discard();
    sail_barrier(Barrier_RISCV_rw_rw);
  } else {
    rv_t_abort(rv_t_conflict);
  };
  RETIRE_SUCCESS
}

function clause execute TABORT(code) = {
  if not(rv_t_active) then return Illegal_Instruction();
  let status : xlenbits = zero_extend(code);
  rv_t_abort((status << 16) | rv_t_explicit);
  RETIRE_SUCCESS
}

function clause execute TTEST(rd) = {
  X(rd) = if rv_t_active then to_bits(1) else zeros();
  RETIRE_SUCCESS
}

// Abort before instructions that can change state outside the journal and
// integer register checkpoint, including CSR, device, and atomic operations.
function rv_t_execute(instr : instruction) -> ExecutionResult = {
  if not(rv_t_active) then return execute(instr);
  match instr {
    TBEGIN(_)     => execute(instr),
    TCOMMIT()     => execute(instr),
    TABORT(_)     => execute(instr),
    TTEST(_)      => execute(instr),
    UTYPE(_)      => execute(instr),
    ITYPE(_)      => execute(instr),
    RTYPE(_)      => execute(instr),
    SHIFTIOP(_)   => execute(instr),
    ADDIW(_)      => execute(instr),
    RTYPEW(_)     => execute(instr),
    SHIFTIWOP(_)  => execute(instr),
    BTYPE(_)      => execute(instr),
    JAL(_)        => execute(instr),
    LOAD(_)       => execute(instr),
    STORE(_)      => execute(instr),
    _ => {
      rv_t_abort(rv_t_unavailable);
      RETIRE_SUCCESS
    },
  }
}
