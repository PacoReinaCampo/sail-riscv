// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_RvU) = hartSupports(Ext_RvU) & currentlyEnabled(Ext_U) & currentlyEnabled(Ext_S)
function clause currentlyEnabled(Ext_RvUsctr) = hartSupports(Ext_RvUsctr) & currentlyEnabled(Ext_RvU)
function clause currentlyEnabled(Ext_RvUvinval) = hartSupports(Ext_RvUvinval) & currentlyEnabled(Ext_RvU)

struct rv_u_context = {
  generation : int,
  asid : asidbits,
  translation : bool,
  ctr : bool,
}

register rv_u_grant : option(rv_u_context) = None()
register rv_u_return_frame : option((xlenbits, bool)) = None()
register rv_u_notification_enabled : bool = false
register rv_u_ctr_entries : list((xlenbits, xlenbits)) = [||]
register rv_u_ctr_cycle_count : xlenbits = zeros()
register rv_u_ctr_cycle_valid : bool = false

function reset_rv_u() -> unit = {
  rv_u_grant = None();
  rv_u_return_frame = None();
  rv_u_notification_enabled = false;
  rv_u_ctr_entries = [||];
  rv_u_ctr_cycle_count = zeros();
  rv_u_ctr_cycle_valid = false;
}

// Trusted supervisor/platform interface. A native user trap or a SATP write
// revokes the old grant, including when software reuses the same ASID.
function rv_u_bind_context(translation : bool, ctr : bool) -> unit = {
  if cur_privilege == Supervisor & currentlyEnabled(Ext_RvU) then {
    reset_rv_u();
    rv_u_grant = Some(struct rv_u_context {
      generation = native_user_context_generation,
      asid = get_asid(S_Stage),
      translation = translation,
      ctr = ctr,
    });
  }
}

function rv_u_install_return_frame(target : xlenbits, saved_enable : bool) -> unit = {
  if cur_privilege == Supervisor then {
    match rv_u_grant {
      Some(grant) if grant.generation == native_user_context_generation => {
        rv_u_return_frame = Some(((target >> 1) << 1, saved_enable));
        rv_u_notification_enabled = false;
      },
      _ => (),
    }
  }
}

private function rv_u_current_grant() -> option(rv_u_context) = {
  if cur_privilege != User then return None();
  match rv_u_grant {
    Some(grant) if grant.generation == native_user_context_generation & grant.asid == get_asid(S_Stage) => Some(grant),
    _ => None(),
  }
}

private function rv_u_flush(rs1 : regidx, rs2 : regidx) -> ExecutionResult = {
  match rv_u_current_grant() {
    Some(grant) if grant.translation => {
      let addr = if rs1 == zreg then None() else Some(X(rs1));
      let selected_asid : asidbits = if asidlen == 0 then zeros() else zero_extend(X(rs2)[asidlen - 1 .. 0]);
      if rs2 != zreg & selected_asid != grant.asid then return Illegal_Instruction();
      // Even X0 selects only this grant's ASID; global TLB entries are excluded.
      flush_TLB(Some(grant.asid), None(), addr, S_Stage);
      RETIRE_SUCCESS
    },
    _ => Illegal_Instruction(),
  }
}

// The sequential model makes stores and invalidations visible immediately.
private function rv_u_barrier() -> ExecutionResult =
  match rv_u_current_grant() {
    Some(grant) if grant.translation => RETIRE_SUCCESS,
    _ => Illegal_Instruction(),
  }

union clause instruction = UTRAPRET : unit

mapping clause encdec = UTRAPRET()
  <-> 0x8c000073
  when currentlyEnabled(Ext_RvU)

mapping clause assembly = UTRAPRET() <-> "utrapret"

function clause execute UTRAPRET() = {
  match (rv_u_current_grant(), rv_u_return_frame) {
    (Some(_), Some((target, saved_enable))) => {
      rv_u_return_frame = None();
      rv_u_notification_enabled = saved_enable;
      set_next_pc(if currentlyEnabled(Ext_Zca) then target else (target >> 2) << 2);
      RETIRE_SUCCESS
    },
    _ => Illegal_Instruction(),
  }
}

union clause instruction = UCTRCLR : unit

mapping clause encdec = UCTRCLR()
  <-> 0x8c0000f3
  when currentlyEnabled(Ext_RvUsctr)

mapping clause assembly = UCTRCLR() <-> "uctrclr"

function clause execute UCTRCLR() = {
  match rv_u_current_grant() {
    Some(grant) if grant.ctr => {
      rv_u_ctr_entries = [||];
      rv_u_ctr_cycle_count = zeros();
      rv_u_ctr_cycle_valid = false;
      RETIRE_SUCCESS
    },
    _ => Illegal_Instruction(),
  }
}

union clause instruction = UFENCE_VMA : (regidx, regidx)

mapping clause encdec = UFENCE_VMA(rs1, rs2)
  <-> 0b1000110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000000101110011
  when currentlyEnabled(Ext_RvU)

mapping clause assembly = UFENCE_VMA(rs1, rs2) <-> "ufence.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute UFENCE_VMA(rs1, rs2) = rv_u_flush(rs1, rs2)

union clause instruction = UINVAL_VMA : (regidx, regidx)

mapping clause encdec = UINVAL_VMA(rs1, rs2)
  <-> 0b1000110 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000000111110011
  when currentlyEnabled(Ext_RvUvinval)

mapping clause assembly = UINVAL_VMA(rs1, rs2) <-> "uinval.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute UINVAL_VMA(rs1, rs2) = rv_u_flush(rs1, rs2)

union clause instruction = UFENCE_INVAL_IR : unit

mapping clause encdec = UFENCE_INVAL_IR()
  <-> 0x8c000273
  when currentlyEnabled(Ext_RvUvinval)

mapping clause assembly = UFENCE_INVAL_IR() <-> "ufence.inval.ir"

function clause execute UFENCE_INVAL_IR() = rv_u_barrier()

union clause instruction = UFENCE_W_INVAL : unit

mapping clause encdec = UFENCE_W_INVAL()
  <-> 0x8c0002f3
  when currentlyEnabled(Ext_RvUvinval)

mapping clause assembly = UFENCE_W_INVAL() <-> "ufence.w.inval"

function clause execute UFENCE_W_INVAL() = rv_u_barrier()
