# Verification Plan

The UVM master produces legal word reads/writes plus misaligned, invalid-size, and out-of-range accesses. The monitor reconstructs address and data phases and counts stalls. A memory-model scoreboard checks readback and response correctness. Coverage records direction, size, response, and wait behavior. SVA checks master stability whenever global `HREADY` is low.
