// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_RvX) = hartSupports(Ext_RvX)
function clause currentlyEnabled(Ext_RvXsctr) = hartSupports(Ext_RvXsctr)
function clause currentlyEnabled(Ext_RvXvinval) = hartSupports(Ext_RvXvinval)
function clause currentlyEnabled(Ext_RvXh) = hartSupports(Ext_RvXh) & currentlyEnabled(Ext_H)
function clause currentlyEnabled(Ext_RvXvinvalH) = hartSupports(Ext_RvXvinvalH) & currentlyEnabled(Ext_H)
function clause currentlyEnabled(Ext_RvXrnmi) = hartSupports(Ext_RvXrnmi)

register rv_x_ctr_entries : list((xlenbits, xlenbits)) = [||]
register rv_x_ctr_cycle_count : xlenbits = zeros()
register rv_x_ctr_cycle_valid : bool = false
register rv_x_ctr_recording : bool = false

// RNMI entry is supplied by the platform. Expose the return state so the
// machine handler can inspect or modify its continuation.
bitfield RvXMnstatus : xlenbits = {
  NMIE : 3,
  MNPV : 7,
  MNPELP : 9,
  MNPP : 12 .. 11,
}

register rv_x_mnepc : xlenbits = zeros()
register rv_x_mnstatus : RvXMnstatus = Mk_RvXMnstatus(zero_extend(0x1808))

mapping clause csr_name_map = 0x741 <-> "mnepc"
mapping clause csr_name_map = 0x744 <-> "mnstatus"

function clause is_CSR_accessible(0x741, priv, _) = currentlyEnabled(Ext_RvXrnmi) & priv == Machine
function clause is_CSR_accessible(0x744, priv, _) = currentlyEnabled(Ext_RvXrnmi) & priv == Machine
function clause read_CSR(0x741) = if currentlyEnabled(Ext_Zca) then rv_x_mnepc else (rv_x_mnepc >> 2) << 2
function clause read_CSR(0x744) = rv_x_mnstatus.bits

function clause write_CSR(0x741, value) = {
  rv_x_mnepc = (value >> 1) << 1;
  Ok(read_CSR(0x741))
}

function clause write_CSR(0x744, value) = {
  let requested = Mk_RvXMnstatus(value);
  let previous = rv_x_mnstatus;
  rv_x_mnstatus = [Mk_RvXMnstatus(zeros()) with
    NMIE = previous[NMIE] | requested[NMIE],
    MNPV = if currentlyEnabled(Ext_H) then requested[MNPV] else 0b0,
    MNPELP = if hartSupports(Ext_Zicfilp) then requested[MNPELP] else 0b0,
    MNPP = legalize_nominal_privLevel(requested[MNPP], previous[MNPP]),
  ];
  Ok(rv_x_mnstatus.bits)
}

function rv_x_save_rnmi_frame(target : xlenbits, previous : Privilege, saved_elp : bool) -> unit = {
  if currentlyEnabled(Ext_RvXrnmi) & rv_x_mnstatus[NMIE] == 0b1 then {
    rv_x_mnepc = (target >> 1) << 1;
    rv_x_mnstatus = [rv_x_mnstatus with
      NMIE = 0b0,
      MNPV = bool_to_bit(privLevel_is_virtual(previous)),
      MNPELP = bool_to_bit(saved_elp),
      MNPP = privLevel_to_bits(previous),
    ];
  }
}

function reset_rv_x() -> unit = {
  rv_x_ctr_entries = [||];
  rv_x_ctr_cycle_count = zeros();
  rv_x_ctr_cycle_valid = false;
  rv_x_ctr_recording = false;
  rv_x_mnepc = zeros();
  rv_x_mnstatus = Mk_RvXMnstatus(zero_extend(0x1808));
}

union clause instruction = MTRAPRET : unit

mapping clause encdec = MTRAPRET()
  <-> 0xbc000073
  when currentlyEnabled(Ext_RvX)

mapping clause assembly = MTRAPRET() <-> "mtrapret"

function clause execute MTRAPRET() = execute_mret(true)

union clause instruction = MCTRCLR : unit

mapping clause encdec = MCTRCLR()
  <-> 0xbc0000f3
  when currentlyEnabled(Ext_RvXsctr)

mapping clause assembly = MCTRCLR() <-> "mctrclr"

function clause execute MCTRCLR() = {
  if cur_privilege != Machine then return Illegal_Instruction();
  rv_x_ctr_entries = [||];
  rv_x_ctr_cycle_count = zeros();
  rv_x_ctr_cycle_valid = false;
  RETIRE_SUCCESS
}

union clause instruction = MFENCE_VMA : (regidx, regidx)

mapping clause encdec = MFENCE_VMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000000101110011
  when currentlyEnabled(Ext_RvX)

mapping clause assembly = MFENCE_VMA(rs1, rs2) <-> "mfence.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MFENCE_VMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(SFENCE_VMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MINVAL_VMA : (regidx, regidx)

mapping clause encdec = MINVAL_VMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000000111110011
  when currentlyEnabled(Ext_RvXvinval)

mapping clause assembly = MINVAL_VMA(rs1, rs2) <-> "minval.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MINVAL_VMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(SFENCE_VMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MFENCE_INVAL_IR : unit

mapping clause encdec = MFENCE_INVAL_IR()
  <-> 0xbc000273
  when currentlyEnabled(Ext_RvXvinval)

mapping clause assembly = MFENCE_INVAL_IR() <-> "mfence.inval.ir"

function clause execute MFENCE_INVAL_IR() = if cur_privilege == Machine then RETIRE_SUCCESS else Illegal_Instruction()

union clause instruction = MFENCE_W_INVAL : unit

mapping clause encdec = MFENCE_W_INVAL()
  <-> 0xbc0002f3
  when currentlyEnabled(Ext_RvXvinval)

mapping clause assembly = MFENCE_W_INVAL() <-> "mfence.w.inval"

function clause execute MFENCE_W_INVAL() = if cur_privilege == Machine then RETIRE_SUCCESS else Illegal_Instruction()

union clause instruction = MNTRAPRET : unit

mapping clause encdec = MNTRAPRET()
  <-> 0xbc000373
  when currentlyEnabled(Ext_RvXrnmi)

mapping clause assembly = MNTRAPRET() <-> "mntrapret"

function clause execute MNTRAPRET() = {
  if cur_privilege != Machine then return Illegal_Instruction();
  let previous = rv_x_mnstatus[MNPP];
  let virt = if previous == 0b11 | not(currentlyEnabled(Ext_H)) then 0b0 else rv_x_mnstatus[MNPV];
  let next = privLevel_bits((previous, virt));
  rv_x_mnstatus[NMIE] = 0b1;
  cur_privilege = next;
  if next != Machine then {
    mstatus[MPRV] = 0b0;
    xret_clear_dbltrp(Machine, next);
  };
  rv_x_restore_rnmi_elp(next, rv_x_mnstatus[MNPELP] == 0b1);
  set_next_pc(read_CSR(0x741));
  xret_callback(true);
  RETIRE_SUCCESS
}

union clause instruction = MWAIT : unit

mapping clause encdec = MWAIT()
  <-> 0xbc0003f3
  when currentlyEnabled(Ext_RvX)

mapping clause assembly = MWAIT() <-> "mwait"

function clause execute MWAIT() = if cur_privilege == Machine then Enter_Wait(WAIT_WFI) else Illegal_Instruction()

union clause instruction = MFENCE_GVMA : (regidx, regidx)

mapping clause encdec = MFENCE_GVMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000010001110011
  when currentlyEnabled(Ext_RvXh)

mapping clause assembly = MFENCE_GVMA(rs1, rs2) <-> "mfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MFENCE_GVMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(HFENCE_GVMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MFENCE_VVMA : (regidx, regidx)

mapping clause encdec = MFENCE_VVMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000010011110011
  when currentlyEnabled(Ext_RvXh)

mapping clause assembly = MFENCE_VVMA(rs1, rs2) <-> "mfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MFENCE_VVMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(HFENCE_VVMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MINVAL_GVMA : (regidx, regidx)

mapping clause encdec = MINVAL_GVMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000010101110011
  when currentlyEnabled(Ext_RvXvinvalH)

mapping clause assembly = MINVAL_GVMA(rs1, rs2) <-> "minval.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MINVAL_GVMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(HFENCE_GVMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MINVAL_VVMA : (regidx, regidx)

mapping clause encdec = MINVAL_VVMA(rs1, rs2)
  <-> 0b1011110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000010111110011
  when currentlyEnabled(Ext_RvXvinvalH)

mapping clause assembly = MINVAL_VVMA(rs1, rs2) <-> "minval.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute MINVAL_VVMA(rs1, rs2) = if cur_privilege == Machine then ExecuteAs(HFENCE_VVMA(rs1, rs2)) else Illegal_Instruction()

union clause instruction = MCTRCTL : regidx

mapping clause encdec = MCTRCTL(rs1)
  <-> 0b1011110 @ 0b00000 @ encdec_reg(rs1) @ 0b000011001110011
  when currentlyEnabled(Ext_RvXsctr)

mapping clause assembly = MCTRCTL(rs1) <-> "mctrctl" ^ spc() ^ reg_name(rs1)

function clause execute MCTRCTL(rs1) = {
  if cur_privilege != Machine then return Illegal_Instruction();
  rv_x_ctr_recording = X(rs1)[0] == 0b1;
  RETIRE_SUCCESS
}
