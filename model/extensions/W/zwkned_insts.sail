union clause instruction = XWK_WAESDF : (zwk_waesdf_funct6, wregidx, wregidx)

mapping wk_encdec_vaesdf : zwk_waesdf_funct6 <-> bits(6) = {
  XWK_ZWK_WAESDF_WW <-> 0b101000,
  XWK_ZWK_WAESDF_WS <-> 0b101001,
}

mapping clause encdec48 = XWK_WAESDF(funct6, ws2, wd)
  <-> 0x0000 @ wk_encdec_vaesdf(funct6) @ 0b1 @ w_encdec_wreg(ws2) @ 0b00001 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4) & (funct6 == XWK_ZWK_WAESDF_WW |
  zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow()))

function clause execute XWK_WAESDF(funct6, ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let state = w_get_welem_quad(wd_val, group_index);
    let rkey : bits(128) = match funct6 {
      XWK_ZWK_WAESDF_WW => w_get_welem_quad(ws2_val, group_index),
      XWK_ZWK_WAESDF_WS => w_get_welem_quad(ws2_val, 0),
    };
    let sr  = aes_shift_rows_inv(state);
    let sb  = aes_subbytes_inv(sr);
    let ark = sb ^ rkey;

    w_write_welem_quad(wd, SEW, ark, group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping wk_aesdf_mnemonic : zwk_waesdf_funct6 <-> string = {
  XWK_ZWK_WAESDF_WW <-> "waesdf.ww",
  XWK_ZWK_WAESDF_WS <-> "waesdf.ws",
}

mapping clause assembly = XWK_WAESDF(funct6, ws2, wd)
  <-> wk_aesdf_mnemonic(funct6) ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2)

union clause instruction = XWK_WAESDM : (zwk_waesdm_funct6, wregidx, wregidx)

mapping wk_encdec_vaesdm : zwk_waesdm_funct6 <-> bits(6) = {
  XWK_ZWK_WAESDM_WW <-> 0b101000,
  XWK_ZWK_WAESDM_WS <-> 0b101001,
}

mapping clause encdec48 = XWK_WAESDM(funct6, ws2, wd)
  <-> 0x0000 @ wk_encdec_vaesdm(funct6) @ 0b1 @ w_encdec_wreg(ws2) @ 0b00000 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4) & (funct6 == XWK_ZWK_WAESDM_WW |
  zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow()))

function clause execute XWK_WAESDM(funct6, ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let state = w_get_welem_quad(wd_val, group_index);
    let rkey : bits(128) = match funct6 {
      XWK_ZWK_WAESDM_WW => w_get_welem_quad(ws2_val, group_index),
      XWK_ZWK_WAESDM_WS => w_get_welem_quad(ws2_val, 0),
    };
    let sr    = aes_shift_rows_inv(state);
    let sb    = aes_subbytes_inv(sr);
    let ark   = sb ^ rkey;
    let mix   = aes_mixcolumns_inv(ark);

    w_write_welem_quad(wd, SEW, mix, group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping wk_aesdm_mnemonic : zwk_waesdm_funct6 <-> string = {
  XWK_ZWK_WAESDM_WW <-> "waesdm.ww",
  XWK_ZWK_WAESDM_WS <-> "waesdm.ws",
}

mapping clause assembly = XWK_WAESDM(funct6, ws2, wd)
  <-> wk_aesdm_mnemonic(funct6) ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2)

union clause instruction = XWK_WAESEF : (zwk_waesef_funct6, wregidx, wregidx)

mapping wk_encdec_vaesef : zwk_waesef_funct6 <-> bits(6) = {
  XWK_ZWK_WAESEF_WW <-> 0b101000,
  XWK_ZWK_WAESEF_WS <-> 0b101001,
}

mapping clause encdec48 = XWK_WAESEF(funct6, ws2, wd)
  <-> 0x0000 @ wk_encdec_vaesef(funct6) @ 0b1 @ w_encdec_wreg(ws2) @ 0b00011 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4) & (funct6 == XWK_ZWK_WAESEF_WW |
  zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow()))

function clause execute XWK_WAESEF(funct6, ws2, wd) = {
  let SEW = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let state = w_get_welem_quad(wd_val, group_index);
    let rkey : bits(128) = match funct6 {
      XWK_ZWK_WAESEF_WW => w_get_welem_quad(ws2_val, group_index),
      XWK_ZWK_WAESEF_WS => w_get_welem_quad(ws2_val, 0),
    };
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let ark   = sr ^ rkey;

    w_write_welem_quad(wd, SEW, ark, group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping wk_aesef_mnemonic : zwk_waesef_funct6 <-> string = {
  XWK_ZWK_WAESEF_WW <-> "waesef.ww",
  XWK_ZWK_WAESEF_WS <-> "waesef.ws",
}

mapping clause assembly = XWK_WAESEF(funct6, ws2, wd)
  <-> wk_aesef_mnemonic(funct6) ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2)

union clause instruction = XWK_WAESEM : (zwk_waesem_funct6, wregidx, wregidx)

mapping wk_encdec_vaesem : zwk_waesem_funct6 <-> bits(6) = {
  XWK_ZWK_WAESEM_WW <-> 0b101000,
  XWK_ZWK_WAESEM_WS <-> 0b101001,
}

mapping clause encdec48 = XWK_WAESEM(funct6, ws2, wd)
  <-> 0x0000 @ wk_encdec_vaesem(funct6) @ 0b1 @ w_encdec_wreg(ws2) @ 0b00010 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4) & (funct6 == XWK_ZWK_WAESEM_WW |
  zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow()))

function clause execute XWK_WAESEM(funct6, ws2, wd) = {
  let SEW = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let state = w_get_welem_quad(wd_val, group_index);
    let rkey : bits(128) = match funct6 {
      XWK_ZWK_WAESEM_WW => w_get_welem_quad(ws2_val, group_index),
      XWK_ZWK_WAESEM_WS => w_get_welem_quad(ws2_val, 0),
    };
    let sb    = aes_subbytes_fwd(state);
    let sr    = aes_shift_rows_fwd(sb);
    let mix   = aes_mixcolumns_fwd(sr);
    let ark   = mix ^ rkey;

    w_write_welem_quad(wd, SEW, ark, group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping wk_aesem_mnemonic : zwk_waesem_funct6 <-> string = {
  XWK_ZWK_WAESEM_WW <-> "waesem.ww",
  XWK_ZWK_WAESEM_WS <-> "waesem.ws",
}

mapping clause assembly = XWK_WAESEM(funct6, ws2, wd)
  <-> wk_aesem_mnemonic(funct6) ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2)

union clause instruction = XWK_WAESKF1_WI : (wregidx, bits(5), wregidx)

mapping clause encdec48 = XWK_WAESKF1_WI(ws2, rnd, wd)
  <-> 0x0000 @ 0b1000101 @ w_encdec_wreg(ws2) @ rnd @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4)

function clause execute XWK_WAESKF1_WI(ws2, rnd, wd) = {
  let SEW = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  var rnd_val : bits(5) = rnd;

  if (unsigned(rnd_val[3..0]) > 10) | (unsigned(rnd_val[3..0]) == 0)
  then rnd_val[3] = not_bit(rnd_val[3]);

  let r : bits(4) = rnd_val[3..0] - 1;

  var w : vector(4, bits(32)) = vector_init(zeros());

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let current_round_key = w_get_welem_quad_vec(ws2_val, group_index);

    w[0] = aes_subword_fwd(current_round_key[3] >>> 8) ^
           aes_decode_rcon(r) ^ current_round_key[0];
    w[1] = w[0] ^ current_round_key[1];
    w[2] = w[1] ^ current_round_key[2];
    w[3] = w[2] ^ current_round_key[3];

    w_write_welem_quad_vec(wd, SEW, w, group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XWK_WAESKF1_WI(ws2, rnd, wd)
  <-> "waeskf1.wi" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ hex_bits_5(rnd)

union clause instruction = XWK_WAESKF2_WI : (wregidx, bits(5), wregidx)

mapping clause encdec48 = XWK_WAESKF2_WI(ws2, rnd, wd)
  <-> 0x0000 @ 0b101010 @ 0b1 @ w_encdec_wreg(ws2) @ rnd @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4)

function clause execute XWK_WAESKF2_WI(ws2, rnd, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  var rnd_val : bits(4) = rnd[3..0];

  if (unsigned(rnd_val) < 2) | (unsigned(rnd_val) > 14)
  then rnd_val[3] = not_bit(rnd_val[3]);

  var w : vector(4, bits(32)) = vector_init(zeros());

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let current_round_key = w_get_welem_quad_vec(ws2_val, group_index);
    let round_key_b       = w_get_welem_quad_vec(wd_val, group_index);

    w[0] = if (rnd_val[0] == 0b1)
           then aes_subword_fwd(current_round_key[3]) ^ round_key_b[0]
           else aes_subword_fwd(current_round_key[3] >>> 8) ^
                aes_decode_rcon((rnd_val >> 1) - 1) ^ round_key_b[0];
    w[1] = w[0] ^ round_key_b[1];
    w[2] = w[1] ^ round_key_b[2];
    w[3] = w[2] ^ round_key_b[3];

    w_write_welem_quad_vec(wd, SEW, w, group_index)
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XWK_WAESKF2_WI(ws2, rnd, wd)
  <-> "waeskf2.wi" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ hex_bits_5(rnd)

union clause instruction = XWK_WAESZ_WS : (wregidx, wregidx)

mapping clause encdec48 = XWK_WAESZ_WS(ws2, wd)
  <-> 0x0000 @ 0b101001 @ 0b1 @ w_encdec_wreg(ws2) @ 0b00111 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(128, 4) & zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow())

function clause execute XWK_WAESZ_WS(ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let group_count = (unsigned(wl) / 4);
  let first_group = (unsigned(wstart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let state = w_get_welem_quad(wd_val, group_index);
    let rkey  = w_get_welem_quad(ws2_val, 0);
    let ark   = state ^ rkey;

    w_write_welem_quad(wd, SEW, ark, group_index)
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XWK_WAESZ_WS(ws2, wd)
  <-> "waesz.ws" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2)
