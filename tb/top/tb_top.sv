`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import ahb_uvm_pkg::*;
  logic HCLK = 0;
  always #5ns HCLK = ~HCLK;
  ahb_if #(ADDR_WIDTH, DATA_WIDTH) vif (HCLK);
  assign vif.HREADY = vif.HREADYOUT;
  ahb_lite_memory_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH),
      .WAIT_STATES(WAIT_STATES)
  ) dut (
      .HCLK,
      .HRESETn(vif.HRESETn),
      .HSEL(vif.HSEL),
      .HADDR(vif.HADDR),
      .HTRANS(vif.HTRANS),
      .HWRITE(vif.HWRITE),
      .HSIZE(vif.HSIZE),
      .HBURST(vif.HBURST),
      .HWDATA(vif.HWDATA),
      .HREADY(vif.HREADY),
      .HRDATA(vif.HRDATA),
      .HREADYOUT(vif.HREADYOUT),
      .HRESP(vif.HRESP)
  );
  ahb_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .HCLK,
      .HRESETn(vif.HRESETn),
      .HSEL(vif.HSEL),
      .HWRITE(vif.HWRITE),
      .HREADY(vif.HREADY),
      .HRESP(vif.HRESP),
      .HADDR(vif.HADDR),
      .HTRANS(vif.HTRANS),
      .HSIZE(vif.HSIZE),
      .HWDATA(vif.HWDATA)
  );
  initial begin
    vif.HRESETn = 0;
    vif.HSEL = 0;
    vif.HADDR = 0;
    vif.HTRANS = 0;
    vif.HWRITE = 0;
    vif.HSIZE = 2;
    vif.HBURST = 0;
    vif.HWDATA = 0;
    repeat (4) @(posedge HCLK);
    vif.HRESETn = 1;
  end
  initial begin
    uvm_config_db#(virtual ahb_if #(ADDR_WIDTH, DATA_WIDTH))::set(null, "uvm_test_top.env.agent.*",
                                                                  "vif", vif);
    run_test("ahb_test");
  end
endmodule
