`timescale 1ns / 1ps
module ahb_sva #(
    parameter int ADDR_WIDTH = 10,
    DATA_WIDTH = 32
) (
    input logic HCLK,
    HRESETn,
    HSEL,
    HWRITE,
    HREADY,
    HRESP,
    input logic [ADDR_WIDTH-1:0] HADDR,
    input logic [1:0] HTRANS,
    input logic [2:0] HSIZE,
    input logic [DATA_WIDTH-1:0] HWDATA
);
  default clocking cb @(posedge HCLK);
  endclocking
  default disable iff (!HRESETn); ap_control_stable_when_stalled :
  assert property (!HREADY |=> $stable({HSEL, HADDR, HTRANS, HWRITE, HSIZE}));
  ap_error_first_cycle_stalls :
  assert property ($rose(HRESP) |-> !HREADY);
  ap_error_second_cycle_completes :
  assert property (HRESP && !HREADY |=> HRESP && HREADY);
  ap_response_known :
  assert property (!$isunknown({HREADY, HRESP}));
  cp_read :
  cover property (HSEL && HREADY && HTRANS[1] && !HWRITE);
  cp_write :
  cover property (HSEL && HREADY && HTRANS[1] && HWRITE);
  cp_error :
  cover property (HRESP);
  logic unused;
  assign unused = ^HWDATA;
endmodule
