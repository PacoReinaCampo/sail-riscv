// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Current fetch hooks for RISC-V extensions call extensions
// to check PC validity *before* standard fetch processing checks.

private function isRVC(h : half) -> bool = not(h[1 .. 0] == 0b11)

private union FetchBytes_Result('width : Int), 'width >= 0 = {
  FetchBytes_Ext_Error : ext_fetch_addr_error,
  FetchBytes_Exception : ExceptionContext,
  FetchBytes_Success   : bits('width * 8),
}

private function fetch_bytes forall 'n, 'n in {2, 4, 8} . (fetch_start : xlenbits, granule_start : xlenbits, width : int('n)) -> FetchBytes_Result('n) = {
  match ext_fetch_check_pc(fetch_start, granule_start) {
    Some(e) => return FetchBytes_Ext_Error(e),
    None()  => (),
  };

  let access : MemoryAccessType(mem_payload) = InstructionFetch();
  let eff_priv = effectivePrivilege(access, mstatus, cur_privilege);

  let (paddr, pbmt) : (physaddr, page_based_mem_type) = match translateAddr(Virtaddr(granule_start), access, eff_priv) {
    Err(e, _)    => return FetchBytes_Exception(e),
    Ok(paddr, pbmt, _) => (paddr, pbmt),
  };

  match mem_read(access, pbmt, eff_priv, paddr, width, false, false, false) {
    Err(exc_addr, e) => {
      // Instruction fetches are not currently split at the physical memory layer.
      assert(exc_addr == paddr);
      FetchBytes_Exception(exception_context(e, granule_start))
    },
    Ok(bytes) => FetchBytes_Success(bytes),
  }
}

private function fetch48_enabled(h : half) -> bool =
  (h[6 .. 0] == 0b0011111 & hartSupports(Ext_Xwk)) |
  (h[6 .. 0] == 0b1011111 & hartSupports(Ext_Xyk))

private function fetch64_enabled(h : half) -> bool =
  h[6 .. 0] == 0b0111111 & hartSupports(Ext_RvO)

private function fetch_last_parcel(lower : bits(48)) -> FetchResult =
  match fetch_bytes(PC, PC + 6, 2) {
    FetchBytes_Ext_Error(e) => F_Ext_Error(e),
    FetchBytes_Exception(e) => F_Error(e),
    FetchBytes_Success(p) => F_Long64(p @ lower),
  }

private function fetch_remaining(first : bits(32)) -> FetchResult = {
  let h = first[15 .. 0];
  let is48 = fetch48_enabled(h);
  let is64 = fetch64_enabled(h);
  if not(is48 | is64) then return F_Base(first);

  if is64 & currentlyEnabled(Ext_Ziccif) & is_aligned_addr(Virtaddr(PC), 4) then {
    if xlen == 64 & is_aligned_addr(Virtaddr(PC), 8) then {
      return match fetch_bytes(PC, PC, 8) {
        FetchBytes_Ext_Error(e) => F_Ext_Error(e),
        FetchBytes_Exception(e) => F_Error(e),
        FetchBytes_Success(full) => {
          let low = full[15 .. 0];
          if fetch64_enabled(low) then F_Long64(full)
          else if fetch48_enabled(low) then F_Long48(full[47 .. 0])
          else if isRVC(low) then F_RVC(low)
          else F_Base(full[31 .. 0])
        },
      }
    };
    return match fetch_bytes(PC, PC + 4, 4) {
      FetchBytes_Ext_Error(e) => F_Ext_Error(e),
      FetchBytes_Exception(e) => F_Error(e),
      FetchBytes_Success(high) => F_Long64(high @ first),
    }
  };

  match fetch_bytes(PC, PC + 4, 2) {
    FetchBytes_Ext_Error(e) => F_Ext_Error(e),
    FetchBytes_Exception(e) => F_Error(e),
    FetchBytes_Success(p) => if is48 then F_Long48(p @ first) else fetch_last_parcel(p @ first),
  }
}

private function fetch_after_first(ilo : half) -> FetchResult = {
  if isRVC(ilo) then return F_RVC(ilo);
  if currentlyEnabled(Ext_Ziccif) & (fetch48_enabled(ilo) | fetch64_enabled(ilo)) then {
    return match fetch_bytes(PC, PC + 2, 4) {
      FetchBytes_Ext_Error(e) => F_Ext_Error(e),
      FetchBytes_Exception(e) => F_Error(e),
      FetchBytes_Success(ihi) =>
        if fetch48_enabled(ilo) then F_Long48(ihi @ ilo) else fetch_last_parcel(ihi @ ilo),
    }
  };
  match fetch_bytes(PC, PC + 2, 2) {
    FetchBytes_Ext_Error(e) => F_Ext_Error(e),
    FetchBytes_Exception(e) => F_Error(e),
    FetchBytes_Success(ihi) => fetch_remaining(ihi @ ilo),
  }
}

private function fetch() -> FetchResult = {
  // TODO: Add a parameter to try_step() to allow forcing the fetch result and use that instead.

  if get_config_rvfi()
  then return rvfi_fetch();

  // Doing this check here assumes the external fetch checks are higher priority
  // than the following alignment check.
  match ext_fetch_check_pc(PC, PC) {
    Some(e) => return F_Ext_Error(e),
    None()  => (),
  };

  if   (PC[0] != 0b0 | (PC[1] != 0b0 & not(ialign16_enabled())))
  then return F_Error(exception_context(E_Fetch_Addr_Align(), PC));

  if is_aligned_addr(Virtaddr(PC), 4) & currentlyEnabled(Ext_Ziccif) then {
    match fetch_bytes(PC, PC, 4) {
      FetchBytes_Ext_Error(e)   => F_Ext_Error(e),
      // If an exception is raised for the upper two bytes but the
      // instruction is only 16 bits then the exception should be
      // ignored. In this implementation we avoid situations where
      // this can happen - the minimum PMP granularity is 4 bytes, and
      // for simplicity we restrict PMA granularity to 4096
      // bytes. This situation may still occur if MMIO devices are
      // incorrectly configured, but this is not checked currently.
      FetchBytes_Exception(e)   => F_Error(e),
      FetchBytes_Success(bytes) => if isRVC(bytes[15 .. 0]) then F_RVC(bytes[15 .. 0]) else fetch_remaining(bytes),
    }
  } else {
    // Split instruction fetch into 16-bit granules to handle RVC, as
    // well as to generate precise fault addresses in any fetch
    // exceptions.
    match fetch_bytes(PC, PC, 2) {
      FetchBytes_Ext_Error(e) => F_Ext_Error(e),
      FetchBytes_Exception(e) => F_Error(e),
      FetchBytes_Success(ilo) => fetch_after_first(ilo),
    }
  }
}
