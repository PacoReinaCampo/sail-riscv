union clause instruction = XWK_WANDN_WW : (bits(1), wregidx, wregidx, wregidx)

mapping clause encdec48 = XWK_WANDN_WW(wm, ws1, ws2, wd)
  <-> 0x0000 @ 0b000001 @ wm @ w_encdec_wreg(ws2) @ w_encdec_wreg(ws1) @ 0b000 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WANDN_WW(wm, ws1, ws2, wd)
  <-> "wk.wandn.ww" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ w_wreg_name(ws1) ^ w_maybe_wmask(wm)

function clause execute XWK_WANDN_WW(wm, ws1, ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws1, LMUL_pow)) |
     not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let ws1_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws1);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ~(ws1_val[i]) & ws2_val[i];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WANDN_WX : (bits(1), wregidx, regidx, wregidx)

mapping clause encdec48 = XWK_WANDN_WX(wm, ws2, rs1, wd)
  <-> 0x0000 @ 0b000001 @ wm @ w_encdec_wreg(ws2) @ encdec_reg(rs1) @ 0b100 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WANDN_WX(wm, ws2, rs1, wd)
  <-> "wk.wandn.wx" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ reg_name(rs1) ^ w_maybe_wmask(wm)

function clause execute XWK_WANDN_WX(wm, ws2, rs1, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let rs1_val : bits('m) = w_get_scalar(rs1, SEW);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem- 1)) {
    if mask[i] == 0b1 then
      result[i] = ~(rs1_val) & ws2_val[i];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WBREW8_W : (bits(1), wregidx, wregidx)

mapping clause encdec48 = XWK_WBREW8_W(wm, ws2, wd)
  <-> 0x0000 @ 0b010010 @ wm @ w_encdec_wreg(ws2) @ 0b01000 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WBREW8_W(wm, ws2, wd)
  <-> "wk.wbrev8.w" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ w_maybe_wmask(wm)

function clause execute XWK_WBREW8_W(wm, ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = brev8(ws2_val[i]);
    };
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WREW8_W : (bits(1), wregidx, wregidx)

mapping clause encdec48 = XWK_WREW8_W(wm, ws2, wd)
  <-> 0x0000 @ 0b010010 @ wm @ w_encdec_wreg(ws2) @ 0b01001 @ 0b010 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WREW8_W(wm, ws2, wd)
  <-> "wk.wrev8.w" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ w_maybe_wmask(wm)

function clause execute XWK_WREW8_W(wm, ws2, wd) = {
  let SEW      = w_get_sew();
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = rev8(ws2_val[i]);
    };
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WROL_WW : (bits(1), wregidx, wregidx, wregidx)

mapping clause encdec48 = XWK_WROL_WW(wm, ws1, ws2, wd)
  <-> 0x0000 @ 0b010101 @ wm @ w_encdec_wreg(ws2) @ w_encdec_wreg(ws1) @ 0b000 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WROL_WW(wm, ws1, ws2, wd)
 <-> "wk.wrol.ww" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ w_wreg_name(ws1) ^ w_maybe_wmask(wm)

function clause execute XWK_WROL_WW(wm, ws1, ws2, wd) = {
  let SEW_pow  = w_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws1, LMUL_pow)) |
     not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let ws1_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws1);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ws2_val[i] <<< ws1_val[i][SEW_pow - 1 .. 0];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WROL_WX : (bits(1), wregidx, regidx, wregidx)

mapping clause encdec48 = XWK_WROL_WX(wm, ws2, rs1, wd)
  <-> 0x0000 @ 0b010101 @ wm @ w_encdec_wreg(ws2) @ encdec_reg(rs1) @ 0b100 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WROL_WX(wm, ws2, rs1, wd)
 <-> "wk.wrol.wx" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ reg_name(rs1) ^ w_maybe_wmask(wm)

function clause execute XWK_WROL_WX(wm, ws2, rs1, wd) = {
  let SEW_pow  = w_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let rs1_val : bits('m) = w_get_scalar(rs1, SEW);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ws2_val[i] <<< rs1_val[SEW_pow - 1 .. 0];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WROR_WW : (bits(1), wregidx, wregidx, wregidx)

mapping clause encdec48 = XWK_WROR_WW(wm, ws1, ws2, wd)
  <-> 0x0000 @ 0b010100 @ wm @ w_encdec_wreg(ws2) @ w_encdec_wreg(ws1) @ 0b000 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WROR_WW(wm, ws1, ws2, wd)
 <-> "wk.wror.ww" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ w_wreg_name(ws1) ^ w_maybe_wmask(wm)

function clause execute XWK_WROR_WW(wm, ws1, ws2, wd) = {
  let SEW_pow  = w_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws1, LMUL_pow)) |
     not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let ws1_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws1);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ws2_val[i] >>> ws1_val[i][SEW_pow - 1 .. 0];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WROR_WX : (bits(1), wregidx, regidx, wregidx)

mapping clause encdec48 = XWK_WROR_WX(wm, ws2, rs1, wd)
  <-> 0x0000 @ 0b010100 @ wm @ w_encdec_wreg(ws2) @ encdec_reg(rs1) @ 0b100 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WROR_WX(wm, ws2, rs1, wd)
 <-> "wk.wror.wx" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ reg_name(rs1)^ w_maybe_wmask(wm)

function clause execute XWK_WROR_WX(wm, ws2, rs1, wd) = {
  let SEW_pow  = w_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val  : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let rs1_val : bits('m) = w_get_scalar(rs1, SEW);
  let ws2_val : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ws2_val[i] >>> rs1_val[SEW_pow - 1 .. 0];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = XWK_WROR_WI : (bits(1), wregidx, bits(6), wregidx)

mapping clause encdec48 = XWK_WROR_WI(wm, ws2, uimm, wd)
  <-> 0x0000 @ 0b01010 @ uimm[5] @ wm @ w_encdec_wreg(ws2) @ uimm[4..0] @ 0b011 @ w_encdec_wreg(wd) @ 0b0011111
  when w_valid_wtype() & currentlyEnabled(Ext_Xwk)

mapping clause assembly = XWK_WROR_WI(wm, ws2, uimm, wd)
 <-> "wk.wror.wi" ^ spc() ^ w_wreg_name(wd) ^ sep() ^ w_wreg_name(ws2) ^ sep() ^ hex_bits_6(uimm) ^ w_maybe_wmask(wm)

function clause execute XWK_WROR_WI(wm, ws2, uimm, wd) = {
  let SEW_pow  = w_get_sew_pow();
  let SEW      = 2 ^ SEW_pow;
  let LMUL_pow = w_get_lmul_pow();
  let num_elem = w_get_num_elem(LMUL_pow, SEW);

  if not(w_valid_reg_group(ws2, LMUL_pow)) |
     not(w_valid_reg_group(wd, LMUL_pow))
  then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;

  let wm_val   : bits('n) = w_read_wmask(num_elem, wm, w_zwreg);
  let uimm_val : bits('m) = zero_extend(uimm);
  let ws2_val  : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, ws2);
  let wd_val   : vector('n, bits('m)) = w_read_wreg(num_elem, SEW, LMUL_pow, wd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = w_init_masked_result(num_elem, SEW, LMUL_pow, wd_val, wm_val);
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then
      result[i] = ws2_val[i] >>> uimm_val[SEW_pow - 1 .. 0];
  };
  w_write_wreg(num_elem, SEW, LMUL_pow, wd, result);
  w_set_wstart(zeros());
  RETIRE_SUCCESS
}
