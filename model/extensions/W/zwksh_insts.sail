union clause instruction = XWK_WSM3ME_WW : (wregidx, wregidx, wregidx)

mapping clause encdec48 = XWK_WSM3ME_WW(ws2, ws1, wd)
  <-> 0x0000 @ 0b100000 @ 0b1 @ w_encdec_wreg(ws2) @ w_encdec_wreg(ws1) @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
   when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(256, 8) & zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow())

function clause execute XWK_WSM3ME_WW(ws2, ws1, wd) = {
  let 'SEW     = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws1, LMUL_pow)) |
     not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let ws1_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws1);

  var w : vector(24, bits(32)) = vector_init(zeros());

  let group_count = (unsigned(wl) / 8);
  let first_group = (unsigned(wstart) / 8);

  foreach (group_index from first_group to (group_count - 1)) {
    let position = group_index * 8;
    assert(position + 7 < num_elem);

    foreach (j from 0 to 7) {
      w[j]     = rev8(ws1_val[position + j]);
      w[j + 8] = rev8(ws2_val[position + j]);
    };

    foreach (j from 16 to 23)
      w[j] = zwk_sh_w(w[j - 16], w[j - 9], w[j - 3], w[j - 13], w[j - 6]);

    w_write_welem_oct_vec(wd, SEW,
      w_wrev8([w[23], w[22], w[21], w[20], w[19], w[18], w[17], w[16]]), group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XWK_WSM3ME_WW(ws2, ws1, wd)
  <-> "wsm3me.ww" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ w_wreg_name(ws1)

union clause instruction = XWK_WSM3C_WI : (wregidx, bits(5), wregidx)

mapping clause encdec48 = XWK_WSM3C_WI(ws2, uimm, wd)
  <-> 0x0000 @ 0b1010111 @ w_encdec_wreg(ws2) @ uimm @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk) & w_get_sew() == 32 & zwk_check_encdec(256, 8) & zwk_valid_reg_overlap(ws2, wd, w_get_lmul_pow())

function clause execute XWK_WSM3C_WI(ws2, uimm, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ws2_val = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let rnds = unsigned(uimm);

  let group_count = (unsigned(wl) / 8);
  let first_group = (unsigned(wstart) / 8);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 8 + 7 < num_elem);

    let A_H : vector(8, bits(32)) = w_wrev8(w_get_welem_oct_vec(wd_val,  group_index));
    let w   : vector(8, bits(32)) = w_wrev8(w_get_welem_oct_vec(ws2_val, group_index));

    let x_0 = w[0] ^ w[4];
    let x_1 = w[1] ^ w[5];

    let A1_H1 = zwk_sm3_round(  A_H, w[0], x_0, 2 * rnds);
    let A2_H2 = zwk_sm3_round(A1_H1, w[1], x_1, 2 * rnds + 1);

    w_write_welem_oct_vec(wd, SEW,
      w_wrev8([A1_H1[6], A2_H2[6], A1_H1[4], A2_H2[4], A1_H1[2], A2_H2[2], A1_H1[0], A2_H2[0]]), group_index);
  };

  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XWK_WSM3C_WI(ws2, uimm, wd)
  <-> "wsm3c.wi" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ hex_bits_5(uimm)
