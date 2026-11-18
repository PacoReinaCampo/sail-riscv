# Experimental V/W/Y coexistence profile v1

The machine-readable contract is ALGEBRA_PROFILE.json. W/Y use custom CSR
addresses, differing from GreenCard register tables; they are not normative
RISC-V allocations. Memory bank selection is fixed at simulator startup.

W/Y context dirty flags and snapshot/restore functions are emulator internals,
not new instructions, CSRs or mstatus fields. Host software owns contexts;
automatic guest isolation is not provided. Scalar F state remains shared.

Zwbc/Zybc are optional, disabled by default, and require their bank and ELEN64.
algebra.trace_writes enables bank/register/value traces. algebra.agnostic_ones
chooses ones in the explicitly agnostic result-helper branches; false preserves
the previous behavior. These flags do not change determined active elements.

Validated sources and binary hashes, full configuration records, test tools
and implementation details are delivered in the companion riscv-model catalog,
validation/vwy and IMPLEMENTACION_MEJORAS_V_W_Y.md. Previous build artifacts
are not evidence for these modified sources.
