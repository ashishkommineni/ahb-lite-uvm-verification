# AHB-Lite Memory Slave Specification

The DUT implements a 32-bit AHB-Lite memory slave. It accepts NONSEQ or SEQ beats, supports pipelined address/data phases, inserts configurable wait states, and returns a protocol-style two-cycle ERROR response for misaligned, out-of-range, or non-word accesses.

Write data is sampled in the data phase, one cycle after address/control. A read returns the word selected during the preceding address phase. Each burst beat is handled independently; address sequencing and burst-boundary rules remain master responsibilities.
