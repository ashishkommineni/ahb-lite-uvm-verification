# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings after full `HTRANS` decode cleanup |
| Executable RTL + SVA smoke | PASS | `AHB_LITE_SMOKE_PASS checks=19` |
| Parameter elaboration | PASS | `DEPTH=16, WAIT_STATES=0` passed strict lint |
| UVM source compile/elaboration | PASS | RTL, interface, assertions, package, and top compiled against Accellera UVM `78c0654` |

```text
AHB_LITE_SMOKE_PASS checks=19
```

The executable test performs eight writes, eight readbacks, programmed wait states, and misaligned, wrong-size, and out-of-range accesses. It observes the complete two-cycle ERROR response. Runtime SVA checks stalled control, response phasing, and known READY/RESP values.

## Second-pass findings corrected

- A tautological BUSY assertion was replaced with checks for both ERROR response cycles.
- Address acceptance now explicitly recognizes `NONSEQ` and `SEQ`, using both `HTRANS` bits.
- Zero-wait elaboration now uses a dedicated `wait_done` branch and passes strict lint without unsigned constant-comparison warnings.
- Directed UVM error beats guarantee all three negative classes.
- Scoreboard no-traffic detection and shell `pipefail` prevent false PASS results.

## Xcelium boundary

Xcelium is not installed here, so no Xcelium regression or runtime coverage percentage is claimed. Full UVM source elaboration passed; execute `make regress` on the licensed host and require zero UVM errors/fatals, passing assertions, and planned coverage closure.
