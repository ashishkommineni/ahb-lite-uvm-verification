XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=ahb_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 11 29 53 79 131;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/ahb_lite_memory_slave.sv
smoke:
	rm -rf build/obj_ahb;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET --top-module tb_ahb_smoke --Mdir build/obj_ahb rtl/ahb_lite_memory_slave.sv tb/assertions/ahb_sva.sv tb/smoke/tb_ahb_smoke.sv
	bash -o pipefail -c './build/obj_ahb/Vtb_ahb_smoke | tee results_smoke.log'
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
