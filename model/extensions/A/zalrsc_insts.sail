// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zalrsc) = hartSupports(Ext_Zalrsc) | currentlyEnabled(Ext_A)
function clause currentlyEnabled(Ext_Zabhlrsc) = hartSupports(Ext_Zabhlrsc) & currentlyEnabled(Ext_Zalrsc)
function clause currentlyEnabled(Ext_Zalasr) = hartSupports(Ext_Zalasr)
function clause currentlyEnabled(Ext_Za64rs) = hartSupports(Ext_Za64rs) & currentlyEnabled(Ext_Zalrsc)
function clause currentlyEnabled(Ext_Za128rs) = hartSupports(Ext_Za128rs) & currentlyEnabled(Ext_Zalrsc)

function clause currentlyEnabled(Ext_Ziccrse) = hartSupports(Ext_Ziccrse)

function lrsc_width_valid(width : word_width) -> bool =
  width <= xlen_bytes & (width >= 4 | currentlyEnabled(Ext_Zabhlrsc))

// *****************************************************************

union clause instruction = LOADRES : (bool, bool, regidx, word_width, regidx)

mapping clause encdec = LOADRES(aq, rl, rs1, width, rd)
  <-> 0b00010 @ bool_bit(aq) @ bool_bit(rl) @ 0b00000 @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(width)

// We could set load-reservations on physical or virtual addresses.
// However most chips (especially multi-core) will use physical addresses.
// Additionally, matching on physical addresses allows as many SC's to
// succeed as the spec allows. This simplifies verification against real chips
// since you can force spurious failures from a DUT into the Sail model and
// then compare the result (a kind of one-way waiver). Using virtual addresses
// requires cancelling the reservation in some additional places, e.g. xRET, and
// that will break comparison with a DUT that doesn't require cancellation there.

function clause execute LOADRES(aq, rl, rs1, width, rd) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  match vmem_read(rs1, zeros(), width, LoadReserved(aq, rl, Data), aq, aq & rl, true) {
    Ok(data) => {
      X(rd) = sign_extend(data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = LOADRES(aq, rl, rs1, width, rd)
  <-> "lr." ^ width_mnemonic(width) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// *****************************************************************

union clause instruction = STORECON : (bool, bool, regidx, regidx, word_width, regidx)

mapping clause encdec = STORECON(aq, rl, rs2, rs1, width, rd)
  <-> 0b00011 @ bool_bit(aq) @ bool_bit(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalrsc) & lrsc_width_valid(width)

// NOTE: Currently, we only EA if address translation is successful. This may need revisiting.
function clause execute STORECON(aq, rl, rs2, rs1, width, rd) = {
  // This is checked during decoding.
  assert(width <= xlen_bytes);

  // normal non-rmem case
  // RMEM: SC is allowed to succeed (but might fail later)
  let data = X(rs2)[width * 8 - 1 .. 0];
  match vmem_write(rs1, zeros(), width, data, StoreConditional(aq, rl, Data), aq & rl, rl, true) {
    Ok(b) => {
      X(rd) = zero_extend(bool_bit(~(b)));
      cancel_reservation();
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = STORECON(aq, rl, rs2, rs1, width, rd)
  <-> "sc." ^ width_mnemonic(width) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

mapping zalasr_order : bool <-> string = {
  false <-> "",
  true <-> "rl",
}

mapping zalasr_store_order : bool <-> string = {
  false <-> ".rl",
  true <-> ".aqrl",
}

union clause instruction = LOAD_ACQUIRE : (bool, regidx, word_width, regidx)

mapping clause encdec = LOAD_ACQUIRE(rl, rs1, width, rd)
  <-> 0b001101 @ bool_bit(rl) @ 0b00000 @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when currentlyEnabled(Ext_Zalasr) & width <= xlen_bytes

function clause execute LOAD_ACQUIRE(rl, rs1, width, rd) = {
  assert(width <= xlen_bytes);
  match vmem_read(rs1, zeros(), width, Load(Data), true, rl, false) {
    Ok(data) => {
      X(rd) = sign_extend(data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = LOAD_ACQUIRE(rl, rs1, width, rd)
  <-> "l" ^ width_mnemonic(width) ^ ".aq" ^ zalasr_order(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause instruction = STORE_RELEASE : (bool, regidx, regidx, word_width)

mapping clause encdec = STORE_RELEASE(aq, rs2, rs1, width)
  <-> 0b00111 @ bool_bit(aq) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ 0b00000 @ 0b0101111
  when currentlyEnabled(Ext_Zalasr) & width <= xlen_bytes

function clause execute STORE_RELEASE(aq, rs2, rs1, width) = {
  assert(width <= xlen_bytes);
  let data = X(rs2)[width * 8 - 1 .. 0];
  match vmem_write(rs1, zeros(), width, data, Store(Data), aq, true, false) {
    Ok(_) => RETIRE_SUCCESS,
    Err(e) => e,
  }
}

mapping clause assembly = STORE_RELEASE(aq, rs2, rs1, width)
  <-> "s" ^ width_mnemonic(width) ^ zalasr_store_order(aq) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
