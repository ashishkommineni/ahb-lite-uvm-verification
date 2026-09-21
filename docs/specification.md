# AHB-Lite Memory Slave Specification

## Scope

The DUT is a 32-bit AHB-Lite memory slave containing `DEPTH` words. It accepts `NONSEQ` and `SEQ` transfers, inserts `WAIT_STATES` programmable wait cycles, and implements the pipelined address/data relationship required by AHB-Lite. SPLIT, RETRY, locked-transfer policy, and burst-address generation are outside this slave model.

## Transfer behavior

An address phase is accepted when `HSEL && HREADY && HTRANS[1]` is true. The slave stores address, direction, and size. For a write, `HWDATA` is consumed later when that stored transfer's data phase completes; it is not sampled with the address. For a read, `HRDATA` is driven from the stored word index during the data phase.

| Access | Completion |
|---|---|
| Aligned 32-bit access within memory | `HRESP=0`, data phase completes after configured waits |
| Misaligned address | Two-cycle ERROR response |
| `HSIZE` other than word (`3'b010`) | Two-cycle ERROR response |
| Address outside memory | Two-cycle ERROR response |

The first ERROR cycle drives `HRESP=1, HREADYOUT=0`; the second drives `HRESP=1, HREADYOUT=1`. Invalid writes never modify memory.

## Pipelining rule

On the edge that completes one data phase, the slave may accept the next address phase. This overlap is why the implementation keeps registered control for the active transfer. Each accepted burst beat is treated independently; the master remains responsible for legal burst sequencing and boundary rules.

Reset is asynchronous and active low. It clears transaction state and initializes the demonstration memory to zero.
