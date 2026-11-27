union clause instruction = XYK_YANDN_YY : (bits(1), yregidx, yregidx, yregidx)

mapping clause encdec48 = XYK_YANDN_YY(ym, ys1, ys2, yd)
  <-> 0x0000 @ 0b000001 @ ym @ y_encdec_yreg(ys2) @ y_encdec_yreg(ys1) @ 0b000 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YANDN_YY(ym, ys1, ys2, yd)
  <-> "yk.yandn.yy" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ y_yreg_name(ys1) ^ y_maybe_ymask(ym)

function clause execute XYK_YANDN_YY(ym, ys1, ys2, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys1, LMUL_pow)) |
     not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let ys1_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys1);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ~(ys1_val[i]) & ys2_val[i];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YANDN_YX : (bits(1), yregidx, regidx, yregidx)

mapping clause encdec48 = XYK_YANDN_YX(ym, ys2, rs1, yd)
  <-> 0x0000 @ 0b000001 @ ym @ y_encdec_yreg(ys2) @ encdec_reg(rs1) @ 0b100 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YANDN_YX(ym, ys2, rs1, yd)
  <-> "yk.yandn.yx" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ reg_name(rs1) ^ y_maybe_ymask(ym)

function clause execute XYK_YANDN_YX(ym, ys2, rs1, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let rs1_val : bits('m) = y_get_scalar(rs1, SEW);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem- 1)) {
    if mask[i] == 0b1 then
      result[i] = ~(rs1_val) & ys2_val[i];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YBREY8_Y : (bits(1), yregidx, yregidx)

mapping clause encdec48 = XYK_YBREY8_Y(ym, ys2, yd)
  <-> 0x0000 @ 0b010010 @ ym @ y_encdec_yreg(ys2) @ 0b01000 @ 0b010 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YBREY8_Y(ym, ys2, yd)
  <-> "yk.ybrev8.y" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ y_maybe_ymask(ym)

function clause execute XYK_YBREY8_Y(ym, ys2, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = brev8(ys2_val[i]);
    };
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YREY8_Y : (bits(1), yregidx, yregidx)

mapping clause encdec48 = XYK_YREY8_Y(ym, ys2, yd)
  <-> 0x0000 @ 0b010010 @ ym @ y_encdec_yreg(ys2) @ 0b01001 @ 0b010 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YREY8_Y(ym, ys2, yd)
  <-> "yk.yrev8.y" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ y_maybe_ymask(ym)

function clause execute XYK_YREY8_Y(ym, ys2, yd) = {
  let SEW      = y_get_sew();
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = rev8(ys2_val[i]);
    };
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YROL_YY : (bits(1), yregidx, yregidx, yregidx)

mapping clause encdec48 = XYK_YROL_YY(ym, ys1, ys2, yd)
  <-> 0x0000 @ 0b010101 @ ym @ y_encdec_yreg(ys2) @ y_encdec_yreg(ys1) @ 0b000 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YROL_YY(ym, ys1, ys2, yd)
 <-> "yk.yrol.yy" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ y_yreg_name(ys1) ^ y_maybe_ymask(ym)

function clause execute XYK_YROL_YY(ym, ys1, ys2, yd) = {
  let SEW_pow  = y_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys1, LMUL_pow)) |
     not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let ys1_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys1);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ys2_val[i] <<< ys1_val[i][SEW_pow - 1 .. 0];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YROL_YX : (bits(1), yregidx, regidx, yregidx)

mapping clause encdec48 = XYK_YROL_YX(ym, ys2, rs1, yd)
  <-> 0x0000 @ 0b010101 @ ym @ y_encdec_yreg(ys2) @ encdec_reg(rs1) @ 0b100 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YROL_YX(ym, ys2, rs1, yd)
 <-> "yk.yrol.yx" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ reg_name(rs1) ^ y_maybe_ymask(ym)

function clause execute XYK_YROL_YX(ym, ys2, rs1, yd) = {
  let SEW_pow  = y_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let rs1_val : bits('m) = y_get_scalar(rs1, SEW);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ys2_val[i] <<< rs1_val[SEW_pow - 1 .. 0];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YROR_YY : (bits(1), yregidx, yregidx, yregidx)

mapping clause encdec48 = XYK_YROR_YY(ym, ys1, ys2, yd)
  <-> 0x0000 @ 0b010100 @ ym @ y_encdec_yreg(ys2) @ y_encdec_yreg(ys1) @ 0b000 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YROR_YY(ym, ys1, ys2, yd)
 <-> "yk.yror.yy" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ y_yreg_name(ys1) ^ y_maybe_ymask(ym)

function clause execute XYK_YROR_YY(ym, ys1, ys2, yd) = {
  let SEW_pow  = y_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys1, LMUL_pow)) |
     not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let ys1_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys1);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ys2_val[i] >>> ys1_val[i][SEW_pow - 1 .. 0];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YROR_YX : (bits(1), yregidx, regidx, yregidx)

mapping clause encdec48 = XYK_YROR_YX(ym, ys2, rs1, yd)
  <-> 0x0000 @ 0b010100 @ ym @ y_encdec_yreg(ys2) @ encdec_reg(rs1) @ 0b100 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YROR_YX(ym, ys2, rs1, yd)
 <-> "yk.yror.yx" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ reg_name(rs1)^ y_maybe_ymask(ym)

function clause execute XYK_YROR_YX(ym, ys2, rs1, yd) = {
  let SEW_pow  = y_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val  : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let rs1_val : bits('m) = y_get_scalar(rs1, SEW);
  let ys2_val : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ys2_val[i] >>> rs1_val[SEW_pow - 1 .. 0];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XYK_YROR_YI : (bits(1), yregidx, bits(6), yregidx)

mapping clause encdec48 = XYK_YROR_YI(ym, ys2, uimm, yd)
  <-> 0x0000 @ 0b01010 @ uimm[5] @ ym @ y_encdec_yreg(ys2) @ uimm[4..0] @ 0b011 @ y_encdec_yreg(yd) @ 0b1011111
  when y_valid_ytype() & currentlyEnabled(Ext_Xyk)

mapping clause assembly = XYK_YROR_YI(ym, ys2, uimm, yd)
 <-> "yk.yror.yi" ^ spc() ^ y_yreg_name(yd) ^ sep() ^ y_yreg_name(ys2) ^ sep() ^ hex_bits_6(uimm) ^ y_maybe_ymask(ym)

function clause execute XYK_YROR_YI(ym, ys2, uimm, yd) = {
  let SEW_pow  = y_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = y_get_lmul_pow();
  let num_elem = y_get_num_elem(LMUL_pow, SEW);

  if not(y_valid_reg_group(ys2, LMUL_pow)) |
     not(y_valid_reg_group(yd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let ym_val   : bits('n) = y_read_ymask(num_elem, ym, y_zyreg);
  let uimm_val : bits('m) = zero_extend(uimm);
  let ys2_val  : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, ys2);
  let yd_val   : vector('n, bits('m)) = y_read_yreg(num_elem, SEW, LMUL_pow, yd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = y_init_masked_result(num_elem, SEW, LMUL_pow, yd_val, ym_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ys2_val[i] >>> uimm_val[SEW_pow - 1 .. 0];
  };
  y_write_yreg(num_elem, SEW, LMUL_pow, yd, result);
  y_set_ystart(zeros());
  RETIRE_SUCCESS
}
