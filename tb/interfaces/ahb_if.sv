`timescale 1ns / 1ps
interface ahb_if #(
    parameter int ADDR_WIDTH = 10,
    DATA_WIDTH = 32
) (
    input logic HCLK
);
  logic HRESETn, HSEL, HWRITE, HREADY, HREADYOUT, HRESP;
  logic [ADDR_WIDTH-1:0] HADDR;
  logic [1:0] HTRANS;
  logic [2:0] HSIZE, HBURST;
  logic [DATA_WIDTH-1:0] HWDATA, HRDATA;
  clocking drv_cb @(negedge HCLK);
    output HSEL, HADDR, HTRANS, HWRITE, HSIZE, HBURST, HWDATA;
    input HREADY, HREADYOUT, HRESP, HRDATA;
  endclocking
endinterface
