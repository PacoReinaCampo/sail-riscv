// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The order of vector_support is significant - each level implies all of the previous levels.
enum vector_support = {
  Disabled,
  Integer,
  Float_single,
  Float_double,
  Full,
}

let vector_support_level : vector_support = config extensions.V.support_level

function vector_support_lt(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) < num_of_vector_support(y)
function vector_support_gt(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) > num_of_vector_support(y)
function vector_support_le(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) <= num_of_vector_support(y)
function vector_support_ge(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) >= num_of_vector_support(y)

overload operator < = {vector_support_lt}
overload operator > = {vector_support_gt}
overload operator <= = {vector_support_le}
overload operator >= = {vector_support_ge}

type vlen_exp : Int = config extensions.V.vlen_exp
constraint 3 <= vlen_exp <= 16

// Note: ELEN=32 requires a different encoding of the CSR vtype.
// The current version of vtype implementation corresponds to the ELEN=64 configuration.
// TODO: the configuration of ELEN and its corresponding vtype implementations.
type elen_exp : Int = config extensions.V.elen_exp
constraint 3 <= elen_exp <= 16 & elen_exp <= vlen_exp

let vlen_exp = sizeof(vlen_exp)
let elen_exp = sizeof(elen_exp)

type vlen : Int = 2 ^ vlen_exp
type elen : Int = 2 ^ elen_exp

type velemidx = range(0, vlen - 1)

let vlen = sizeof(vlen)
let elen = sizeof(elen)

// Independent storage size and maximum scalar element width.
type wlen_exp : Int = config extensions.W.wlen_exp
constraint 3 <= wlen_exp <= 16
type welen_exp : Int = config extensions.W.elen_exp
constraint 3 <= welen_exp <= 6 & welen_exp <= wlen_exp
let wlen_exp = sizeof(wlen_exp)
let welen_exp = sizeof(welen_exp)
type wlen : Int = 2 ^ wlen_exp
type welen : Int = 2 ^ welen_exp
type welemidx = range(0, wlen - 1)
let wlen = sizeof(wlen)
let welen = sizeof(welen)

// Independent storage size and maximum scalar element width.
type ylen_exp : Int = config extensions.Y.ylen_exp
constraint 3 <= ylen_exp <= 16
type yelen_exp : Int = config extensions.Y.elen_exp
constraint 3 <= yelen_exp <= 6 & yelen_exp <= ylen_exp
let ylen_exp = sizeof(ylen_exp)
let yelen_exp = sizeof(yelen_exp)
type ylen : Int = 2 ^ ylen_exp
type yelen : Int = 2 ^ yelen_exp
type yelemidx = range(0, ylen - 1)
let ylen = sizeof(ylen)
let yelen = sizeof(yelen)
