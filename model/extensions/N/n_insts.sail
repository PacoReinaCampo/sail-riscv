// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_N) = hartSupports(Ext_N) & currentlyEnabled(Ext_U)

register n_uepc : xlenbits = zeros()
register n_uie : bits(1) = 0b0
register n_upie : bits(1) = 0b0

function reset_rv_n() -> unit = {
  n_uepc = zeros();
  n_uie = 0b0;
  n_upie = 0b0;
}

mapping clause csr_name_map = 0x000 <-> "ustatus"
mapping clause csr_name_map = 0x041 <-> "uepc"

function clause is_CSR_accessible(0x000, priv, _) = currentlyEnabled(Ext_N) & not(privLevel_is_virtual(priv))
function clause is_CSR_accessible(0x041, priv, _) = currentlyEnabled(Ext_N) & not(privLevel_is_virtual(priv))
function clause read_CSR(0x000) = zero_extend(n_upie @ 0b000 @ n_uie)
function clause read_CSR(0x041) = if currentlyEnabled(Ext_Zca) then n_uepc else (n_uepc >> 2) << 2

function clause write_CSR(0x000, value) = {
  n_uie = value[0];
  n_upie = value[4];
  Ok(read_CSR(0x000))
}

function clause write_CSR(0x041, value) = {
  n_uepc = (value >> 1) << 1;
  Ok(read_CSR(0x041))
}

union clause instruction = URET : unit

mapping clause encdec = URET() <-> 0x00200073
  when currentlyEnabled(Ext_N)

mapping clause assembly = URET() <-> "uret"

function clause execute URET() = {
  if inVirtualPrivilege() then return Illegal_Instruction();
  n_uie = n_upie;
  n_upie = 0b1;
  cur_privilege = User;
  set_next_pc(read_CSR(0x041));
  RETIRE_SUCCESS
}
