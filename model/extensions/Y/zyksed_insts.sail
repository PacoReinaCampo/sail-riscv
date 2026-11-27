union clause instruction = XYK_YSM4K_YI : (yregidx, bits(5), yregidx)

mapping clause encdec48 = XYK_YSM4K_YI(ys2, uimm, yd)
  <-> 0x0000 @ 0b100001 @ 0b1 @ y_encdec_yreg(ys2) @ uimm @ 0b010 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk) & y_get_sew() == 32 & zyk_check_encdec(128, 4)

function clause execute XYK_YSM4K_YI(ys2, uimm, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ys2_val = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);

  let ck_index : bits(5) = uimm[2..0] @ 0b00;

  let group_count = (unsigned(yl) / 4);
  let first_group = (unsigned(ystart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let rk_in = y_get_yelem_quad_vec(ys2_val, group_index);

    var rk_out : vector(4, bits(32)) = vector_init(zeros());

    var B = rk_in[1] ^ rk_in[2] ^ rk_in[3] ^ zyk_sm4_ck(ck_index);
    var S = zyk_sm4_subword(B);
    rk_out[0] = zyk_round_key(rk_in[0], S);

    B = rk_in[2]  ^ rk_in[3]  ^ rk_out[0] ^ zyk_sm4_ck(ck_index + to_bits(5, 1));
    S = zyk_sm4_subword(B);
    rk_out[1] = zyk_round_key(rk_in[1], S);

    B = rk_in[3]  ^ rk_out[0] ^ rk_out[1] ^ zyk_sm4_ck(ck_index + to_bits(5, 2));
    S = zyk_sm4_subword(B);
    rk_out[2] = zyk_round_key(rk_in[2], S);

    B = rk_out[0] ^ rk_out[1] ^ rk_out[2] ^ zyk_sm4_ck(ck_index + to_bits(5, 3));
    S = zyk_sm4_subword(B);
    rk_out[3] = zyk_round_key(rk_in[3], S);

    y_write_yelem_quad_vec(yd, SEW, rk_out, group_index);
  };

  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

mapping clause assembly = XYK_YSM4K_YI(ys2, uimm, yd)
  <-> "ysm4k.yi" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ hex_bits_5(uimm)

union clause instruction = XYK_ZYKSM4RTYPE : (zyk_ysm4r_funct6, yregidx, yregidx)

mapping clause encdec48 = XYK_ZYKSM4RTYPE(XYK_ZYK_YSM4R_YY, ys2, yd)
  <-> 0x0000 @ 0b101000 @ 0b1 @ y_encdec_yreg(ys2) @ 0b10000 @ 0b010 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk) & y_get_sew() == 32 & zyk_check_encdec(128, 4)

mapping clause encdec48 = XYK_ZYKSM4RTYPE(XYK_ZYK_YSM4R_YS, ys2, yd)
  <-> 0x0000 @ 0b101001 @ 0b1 @ y_encdec_yreg(ys2) @ 0b10000 @ 0b010 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk) & y_get_sew() == 32 & zyk_check_encdec(128, 4) & zyk_valid_reg_overlap(ys2, yd, y_get_lmul_pow())

function clause execute XYK_ZYKSM4RTYPE(funct6, ys2, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  assert(SEW == 32);

  let ys2_val = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let group_count = (unsigned(yl) / 4);
  let first_group = (unsigned(ystart) / 4);

  foreach (group_index from first_group to (group_count - 1)) {
    assert(group_index * 4 + 3 < num_elem);

    let rk_in = if funct6 == XYK_ZYK_YSM4R_YY
                then y_get_yelem_quad_vec(ys2_val, group_index)
                else y_get_yelem_quad_vec(ys2_val, 0);

    let x_in  = y_get_yelem_quad_vec(yd_val, group_index);

    var x_out : vector(4, bits(32)) = vector_init(zeros());

    var B = x_in[1] ^ x_in[2] ^ x_in[3] ^ rk_in[0];
    var S = zyk_sm4_subword(B);
    x_out[0] = zyk_sm4_round(x_in[0], S);

    B = x_in[2]  ^ x_in[3]  ^ x_out[0] ^ rk_in[1];
    S = zyk_sm4_subword(B);
    x_out[1] = zyk_sm4_round(x_in[1], S);

    B = x_in[3]  ^ x_out[0] ^ x_out[1] ^ rk_in[2];
    S = zyk_sm4_subword(B);
    x_out[2] = zyk_sm4_round(x_in[2], S);

    B = x_out[0] ^ x_out[1] ^ x_out[2] ^ rk_in[3];
    S = zyk_sm4_subword(B);
    x_out[3] = zyk_sm4_round(x_in[3], S);

    y_write_yelem_quad_vec(yd, SEW, x_out, group_index);
  };

  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

mapping yk_sm4r_mnemonic : zyk_ysm4r_funct6 <-> string = {
   XYK_ZYK_YSM4R_YY <-> "ysm4r.yy",
   XYK_ZYK_YSM4R_YS <-> "ysm4r.ys",
}

mapping clause assembly = XYK_ZYKSM4RTYPE(funct6, ys2, yd)
  <-> yk_sm4r_mnemonic(funct6) ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2)
