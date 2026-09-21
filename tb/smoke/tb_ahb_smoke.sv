`timescale 1ns / 1ps
module tb_ahb_smoke;
  localparam int ADDR_WIDTH = 10, DATA_WIDTH = 32, DEPTH = 64, WAIT_STATES = 1;
  logic HCLK, HRESETn, HSEL, HWRITE, HREADY, HREADYOUT, HRESP;
  logic [9:0] HADDR;
  logic [1:0] HTRANS;
  logic [2:0] HSIZE, HBURST;
  logic [31:0] HWDATA, HRDATA;
  int checks = 0;
  initial HCLK = 0;
  always #5 HCLK = ~HCLK;
  assign HREADY = HREADYOUT;
  ahb_lite_memory_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH),
      .WAIT_STATES(WAIT_STATES)
  ) dut (
      .*
  );
  ahb_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .HCLK,
      .HRESETn,
      .HSEL,
      .HWRITE,
      .HREADY,
      .HRESP,
      .HADDR,
      .HTRANS,
      .HSIZE,
      .HWDATA
  );
  task automatic beat(input bit wr, input logic [9:0] addr, input logic [2:0] size,
                      input logic [31:0] wdata, output logic [31:0] rdata, output bit resp);
    while (!HREADY) @(negedge HCLK);
    @(negedge HCLK);
    HSEL   = 1;
    HTRANS = 2'b10;
    HADDR  = addr;
    HWRITE = wr;
    HSIZE  = size;
    HBURST = 0;
    @(negedge HCLK);
    HSEL   = 0;
    HTRANS = 0;
    HWDATA = wdata;
    while (!HREADYOUT) @(negedge HCLK);
    rdata = HRDATA;
    resp  = HRESP;
    checks++;
  endtask
  initial begin
    logic [31:0] r;
    bit e;
    HRESETn = 0;
    HSEL = 0;
    HADDR = 0;
    HTRANS = 0;
    HWRITE = 0;
    HSIZE = 2;
    HBURST = 0;
    HWDATA = 0;
    repeat (4) @(posedge HCLK);
    HRESETn = 1;
    for (int i = 0; i < 8; i++) beat(1, 10'(i * 4), 2, 32'h5A000000 + i, r, e);
    for (int i = 0; i < 8; i++) begin
      beat(0, 10'(i * 4), 2, 0, r, e);
      if (e || r !== 32'h5A000000 + i) $fatal(1, "AHB read mismatch i=%0d r=%08h e=%0b", i, r, e);
    end
    beat(0, 10'h002, 2, 0, r, e);
    if (!e) $fatal(1, "misaligned access did not error");
    beat(0, 10'h000, 1, 0, r, e);
    if (!e) $fatal(1, "wrong HSIZE did not error");
    beat(0, 10'h200, 2, 0, r, e);
    if (!e) $fatal(1, "out-of-range address did not error");
    $display("AHB_LITE_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
