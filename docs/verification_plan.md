# Verification Plan

## Strategy

The UVM master generates address phases and supplies write data in the following data phase. The monitor snapshots control only on an accepted address and waits through the matching data phase, preventing the common error of pairing `HWDATA` with the wrong address. A memory-model scoreboard checks every observed beat.

| Goal | Stimulus | Check |
|---|---|---|
| Basic storage | Eight directed writes followed by eight reads | Word-for-word memory scoreboard |
| Wait-state handling | All transfers through configured stalls | Monitor wait count and stable-control SVA |
| Misalignment | Directed address `0x002` plus random traffic | Two-cycle ERROR, no model update |
| Invalid size | Directed non-word `HSIZE` | Two-cycle ERROR |
| Decode error | First address beyond memory | Two-cycle ERROR |
| Pipeline semantics | Back-to-back sequence items | Address/data phase reconstruction |

## Constraints and coverage

Address and size distributions favor legal traffic while deliberately retaining invalid ranges and sizes. Payload and direction remain unconstrained. Coverage classifies direction, transfer size, response, and zero/nonzero waits, then crosses direction with response.

## Assertions and closure

SVA requires address/control stability while global `HREADY` is low, checks the first and second cycles of the ERROR response, and rejects unknown READY/RESP values. Read, write, and error cover properties provide protocol-event evidence. Closure requires zero UVM errors/fatals, passing assertions, required coverage bins, and the executable smoke PASS token.
