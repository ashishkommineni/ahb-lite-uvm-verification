`timescale 1ns / 1ps
package ahb_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int ADDR_WIDTH = 10, DATA_WIDTH = 32, DEPTH = 64, WAIT_STATES = 1;
  class ahb_item extends uvm_sequence_item;
    rand bit [ADDR_WIDTH-1:0] addr;
    rand bit write;
    rand bit [DATA_WIDTH-1:0] data;
    rand bit [2:0] size;
    bit [DATA_WIDTH-1:0] rdata;
    bit resp;
    int wait_cycles;
    constraint c_addr {
      addr dist {
        [0 : DEPTH * 4 - 1] := 8,
        [DEPTH * 4 : 2 ** ADDR_WIDTH - 1] := 2
      };
    }
    constraint c_size {
      size dist {
        2 := 9,
        [0 : 1] := 1,
        [3 : 7] := 1
      };
    }
    `uvm_object_utils_begin(ahb_item)
      `uvm_field_int(addr, UVM_HEX)
      `uvm_field_int(write, UVM_DEFAULT)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(size, UVM_DEC)
      `uvm_field_int(rdata, UVM_HEX)
      `uvm_field_int(resp, UVM_DEFAULT)
      `uvm_field_int(wait_cycles, UVM_DEC)
    `uvm_object_utils_end
    function new(string n = "ahb_item");
      super.new(n);
    endfunction
  endclass
  class ahb_sequencer extends uvm_sequencer #(ahb_item);
    `uvm_component_utils(ahb_sequencer)
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
  endclass
  class ahb_driver extends uvm_driver #(ahb_item);
    `uvm_component_utils(ahb_driver)
    virtual ahb_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual ahb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "ahb_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.drv_cb.HSEL   <= 0;
      vif.drv_cb.HTRANS <= 0;
      vif.drv_cb.HADDR  <= '0;
      vif.drv_cb.HWRITE <= 0;
      vif.drv_cb.HSIZE  <= 3'b010;
      vif.drv_cb.HBURST <= 0;
      vif.drv_cb.HWDATA <= '0;
      wait (vif.HRESETn === 1);
      forever begin
        seq_item_port.get_next_item(req);
        while (!vif.HREADY) @(vif.drv_cb);
        vif.drv_cb.HSEL   <= 1;
        vif.drv_cb.HTRANS <= 2'b10;
        vif.drv_cb.HADDR  <= req.addr;
        vif.drv_cb.HWRITE <= req.write;
        vif.drv_cb.HSIZE  <= req.size;
        vif.drv_cb.HBURST <= 0;
        @(vif.drv_cb);
        vif.drv_cb.HSEL   <= 0;
        vif.drv_cb.HTRANS <= 0;
        vif.drv_cb.HWDATA <= req.data;
        do @(vif.drv_cb); while (!vif.HREADYOUT);
        seq_item_port.item_done();
      end
    endtask
  endclass
  class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)
    virtual ahb_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    uvm_analysis_port #(ahb_item) ap;
    function new(string n, uvm_component p);
      super.new(n, p);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual ahb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "ahb_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      ahb_item tr;
      wait (vif.HRESETn === 1);
      forever begin
        @(posedge vif.HCLK iff (vif.HSEL && vif.HREADY && vif.HTRANS[1]));
        tr = ahb_item::type_id::create("tr");
        tr.addr = vif.HADDR;
        tr.write = vif.HWRITE;
        tr.size = vif.HSIZE;
        tr.wait_cycles = 0;
        do begin
          @(posedge vif.HCLK);
          if (!vif.HREADYOUT) tr.wait_cycles++;
        end while (!vif.HREADYOUT);
        #1ps;
        tr.data  = vif.HWDATA;
        tr.rdata = vif.HRDATA;
        tr.resp  = vif.HRESP;
        ap.write(tr);
      end
    endtask
  endclass
  class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)
    ahb_sequencer sqr;
    ahb_driver drv;
    ahb_monitor mon;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = ahb_sequencer::type_id::create("sqr", this);
      drv = ahb_driver::type_id::create("drv", this);
      mon = ahb_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class ahb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb_scoreboard)
    uvm_analysis_imp #(ahb_item, ahb_scoreboard) analysis_export;
    bit [31:0] model[0:DEPTH-1];
    int checked;
    function new(string n, uvm_component p);
      super.new(n, p);
      analysis_export = new("analysis_export", this);
      foreach (model[i]) model[i] = 0;
    endfunction
    function void write(ahb_item tr);
      bit valid = (tr.addr < DEPTH * 4 && tr.addr[1:0] == 0 && tr.size == 2);
      checked++;
      if (tr.resp !== !valid)
        `uvm_error("RESP", $sformatf("addr=%03h size=%0d resp=%0b", tr.addr, tr.size, tr.resp))
      if (valid) begin
        if (tr.write) model[tr.addr[$clog2(DEPTH)+1:2]] = tr.data;
        else if (tr.rdata !== model[tr.addr[$clog2(DEPTH)+1:2]])
          `uvm_error("DATA", $sformatf(
                     "expected=%08h got=%08h", model[tr.addr[$clog2(DEPTH)+1:2]], tr.rdata))
      end
    endfunction
    function void check_phase(uvm_phase phase);
      if (checked == 0) `uvm_error("NO_TRAFFIC", "No AHB-Lite beats reached the scoreboard")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("AHB_SUMMARY", $sformatf("Checked %0d beats", checked), UVM_LOW)
    endfunction
  endclass
  class ahb_coverage extends uvm_subscriber #(ahb_item);
    `uvm_component_utils(ahb_coverage)
    ahb_item tr;
    covergroup cg;
      cp_dir: coverpoint tr.write;
      cp_size: coverpoint tr.size {bins word = {2}; bins illegal = default;}
      cp_resp: coverpoint tr.resp;
      cp_wait: coverpoint tr.wait_cycles {bins zero = {0}; bins waited = {[1 : 10]};}
      cx: cross cp_dir, cp_resp;
    endgroup
    function new(string n, uvm_component p);
      super.new(n, p);
      cg = new();
    endfunction
    function void write(ahb_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class ahb_env extends uvm_env;
    `uvm_component_utils(ahb_env)
    ahb_agent agent;
    ahb_scoreboard sb;
    ahb_coverage cov;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = ahb_agent::type_id::create("agent", this);
      sb = ahb_scoreboard::type_id::create("sb", this);
      cov = ahb_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class ahb_sequence extends uvm_sequence #(ahb_item);
    `uvm_object_utils(ahb_sequence)
    function new(string n = "ahb_sequence");
      super.new(n);
    endfunction
    task body();
      for (int i = 0; i < 8; i++) begin
        req = ahb_item::type_id::create("wr");
        start_item(req);
        req.addr  = i * 4;
        req.write = 1;
        req.data  = 32'hA5000000 + i;
        req.size  = 2;
        finish_item(req);
      end
      for (int i = 0; i < 8; i++) begin
        req = ahb_item::type_id::create("rd");
        start_item(req);
        req.addr  = i * 4;
        req.write = 0;
        req.data  = 0;
        req.size  = 2;
        finish_item(req);
      end
      req = ahb_item::type_id::create("misaligned");
      start_item(req);
      req.addr  = 2;
      req.write = 0;
      req.data  = 0;
      req.size  = 2;
      finish_item(req);
      req = ahb_item::type_id::create("invalid_size");
      start_item(req);
      req.addr  = 0;
      req.write = 0;
      req.data  = 0;
      req.size  = 1;
      finish_item(req);
      req = ahb_item::type_id::create("decode_error");
      start_item(req);
      req.addr  = DEPTH * 4;
      req.write = 0;
      req.data  = 0;
      req.size  = 2;
      finish_item(req);
      repeat (100) begin
        req = ahb_item::type_id::create("rand");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class ahb_test extends uvm_test;
    `uvm_component_utils(ahb_test)
    ahb_env env;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      env = ahb_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      ahb_sequence seq;
      phase.raise_objection(this);
      seq = ahb_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      repeat (4) @(posedge env.agent.mon.vif.HCLK);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
