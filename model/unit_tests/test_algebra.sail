// SPDX-License-Identifier: BSD-2-Clause
// Regression properties of the common rule and native bank views.
$[test]
function test_algebra_rounding_reference() -> unit = {
  let cases : vector(12, bits(8)) = [0x00, 0x01, 0x02, 0x03, 0x7f, 0x80, 0x81, 0xfe, 0xff, 0x55, 0xaa, 0x40];
  foreach (index from 0 to 11) {
    let value = unsigned(cases[index]);
    foreach (shift from 0 to 7) {
      let input : bits(8) = to_bits(value);
      foreach (mode from 0 to 3) {
        let divisor = 2 ^ shift;
        let quotient = value / divisor;
        let remainder = value % divisor;
        let expected = if shift == 0 then false else match mode {
          0 => 2 * remainder >= divisor,
          1 => 2 * remainder > divisor | (2 * remainder == divisor & quotient % 2 == 1),
          2 => false,
          _ => quotient % 2 == 0 & remainder != 0,
        };
        assert(algebra_rounding_incr(input, shift, to_bits(2, mode)) == bool_to_bit(expected))
      }
    }
  }
}
$[test]
function test_algebra_shape_roundtrip() -> unit = {
  var data : vector(17, bits(8)) = vector_init(zeros());
  foreach (p from 0 to 16) { data[p] = to_bits(8, p * 7) };
  assert(w_unshape_vector(17, w_shape_vector(data, w_columns), w_columns) == data);
  assert(y_unshape_vector(17, y_shape_vector(data, y_columns, y_depth), y_columns, y_depth) == data);
  let mask : bits(17) = 0b10100110011001011;
  assert(w_unshape_bits(17, w_shape_bits(mask, w_columns), w_columns) == mask);
  assert(y_unshape_bits(17, y_shape_bits(mask, y_columns, y_depth), y_columns, y_depth) == mask)
}
$[test]
function test_algebra_context_bookkeeping() -> unit = {
  w_reset(); y_reset();
  assert(not(w_context_dirty) & not(y_context_dirty));
  w_dirty_w_context();
  assert(w_context_dirty & not(y_context_dirty));
  y_dirty_y_context();
  w_clear_context_dirty();
  assert(not(w_context_dirty) & y_context_dirty);
  y_clear_context_dirty();
  assert(not(y_context_dirty));
  w_reset(); y_reset()
}

$[test]
function test_algebra_context_save_restore() -> unit = {
  w_init_wregs(); y_init_yregs(); w_reset(); y_reset();
  wr3 = to_bits_unsafe(wlen, 17); yr3 = to_bits_unsafe(ylen, 29);
  let w_saved = w_save_context(); let y_saved = y_save_context();
  wr3 = ones(); yr3 = zeros(); w_dirty_w_context(); y_dirty_y_context();
  w_restore_context(w_saved); y_restore_context(y_saved);
  assert(wr3 == to_bits_unsafe(wlen, 17) & yr3 == to_bits_unsafe(ylen, 29));
  assert(w_save_context() == w_saved & y_save_context() == y_saved)
}
