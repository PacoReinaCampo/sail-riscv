// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// A bounded byte journal shared by the transaction and physical memory paths.
struct rv_t_byte = {
  addr : physaddrbits,
  original : bits(8),
  pending : option(bits(8)),
}

type rv_t_capacity = 256

register rv_t_active : bool = false
register rv_t_journal : vector(rv_t_capacity, option(rv_t_byte)) = vector_init(None())
register rv_t_journal_size : range(0, rv_t_capacity) = 0

function rv_t_discard() -> unit = {
  rv_t_active = false;
  rv_t_journal_size = 0;
}

private function rv_t_ram_byte(addr : physaddrbits) -> bits(8) = {
  let (value, _) = read_ram(Read_plain, Load(Data), Physaddr(addr), 1, false);
  value
}

function rv_t_touch_byte(addr : physaddrbits, pending : option(bits(8))) -> option(bits(8)) = {
  foreach (i from 0 to rv_t_journal_size - 1) {
    match rv_t_journal[i] {
      Some(entry) if entry.addr == addr => {
        if is_some(pending) then rv_t_journal[i] = Some({entry with pending = pending});
        return Some(match (pending, entry.pending) {
          (Some(value), _) => value,
          (_, Some(value)) => value,
          _ => entry.original,
        });
      },
      _ => (),
    }
  };
  let index = rv_t_journal_size;
  if index >= sizeof(rv_t_capacity) then return None();
  let original = rv_t_ram_byte(addr);
  rv_t_journal[index] = Some(struct rv_t_byte {addr = addr, original = original, pending = pending});
  rv_t_journal_size = index + 1;
  Some(match pending { Some(value) => value, None() => original })
}

// The sequential RAM backend publishes the whole journal within one step.
function rv_t_commit_ram() -> bool = {
  foreach (i from 0 to rv_t_journal_size - 1) {
    match rv_t_journal[i] {
      Some(entry) if rv_t_ram_byte(entry.addr) != entry.original => return false,
      _ => (),
    }
  };
  foreach (i from 0 to rv_t_journal_size - 1) {
    match rv_t_journal[i] {
      Some(entry) => match entry.pending {
        None() => (),
        Some(value) => {
          assert(write_ram(Write_plain, Store(Data), Physaddr(entry.addr), 1, value, default_meta),
                 "Validated transactional RAM rejected a write");
        },
      },
      None() => (),
    }
  };
  true
}
