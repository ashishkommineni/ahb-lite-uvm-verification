`timescale 1ns / 1ps

module ahb_lite_memory_slave #(
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned DATA_WIDTH  = 32,
    parameter int unsigned DEPTH       = 64,
    parameter int unsigned WAIT_STATES = 1
) (
    input  logic                  HCLK,
    input  logic                  HRESETn,
    input  logic                  HSEL,
    input  logic [ADDR_WIDTH-1:0] HADDR,
    input  logic [           1:0] HTRANS,
    input  logic                  HWRITE,
    input  logic [           2:0] HSIZE,
    input  logic [           2:0] HBURST,
    input  logic [DATA_WIDTH-1:0] HWDATA,
    input  logic                  HREADY,
    output logic [DATA_WIDTH-1:0] HRDATA,
    output logic                  HREADYOUT,
    output logic                  HRESP
);
  localparam int WAIT_W = (WAIT_STATES == 0) ? 1 : $clog2(WAIT_STATES + 1);
  localparam int WORD_BYTES = DATA_WIDTH / 8;
  localparam int WORD_LSB = $clog2(WORD_BYTES);
  localparam int INDEX_W = $clog2(DEPTH);
  localparam int MEM_BYTES = DEPTH * WORD_BYTES;

  logic [DATA_WIDTH-1:0] mem               [0:DEPTH-1];
  logic                  active_q;
  logic                  write_q;
  logic                  error_q;
  logic                  error_second_q;
  logic [   INDEX_W-1:0] word_index_q;
  logic [    WAIT_W-1:0] wait_count_q;
  logic                  address_accept;
  logic                  transfer_complete;
  logic                  address_error;

  assign address_accept = HSEL && HREADY && HTRANS[1];
  assign address_error  = (HSIZE != 3'b010) ||
                          (HADDR[WORD_LSB-1:0] != '0) ||
                          (HADDR >= ADDR_WIDTH'(MEM_BYTES));

  always_comb begin
    HREADYOUT = 1'b1;
    HRESP     = 1'b0;
    if (active_q) begin
      if (wait_count_q < WAIT_W'(WAIT_STATES)) begin
        HREADYOUT = 1'b0;
      end else if (error_q) begin
        HRESP     = 1'b1;
        HREADYOUT = error_second_q;
      end
    end
  end

  assign transfer_complete = active_q && HREADYOUT;
  assign HRDATA = active_q && !write_q && !error_q ? mem[word_index_q] : '0;

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      active_q       <= 1'b0;
      write_q        <= 1'b0;
      error_q        <= 1'b0;
      error_second_q <= 1'b0;
      word_index_q   <= '0;
      wait_count_q   <= '0;
      for (int i = 0; i < DEPTH; i++) mem[i] <= '0;
    end else begin
      if (transfer_complete && write_q && !error_q) mem[word_index_q] <= HWDATA;

      if (transfer_complete) begin
        active_q       <= 1'b0;
        error_second_q <= 1'b0;
        wait_count_q   <= '0;
      end else if (active_q) begin
        if (wait_count_q < WAIT_W'(WAIT_STATES)) wait_count_q <= wait_count_q + 1'b1;
        else if (error_q && !error_second_q) error_second_q <= 1'b1;
      end

      // AHB address pipelining allows a new address to be accepted on the
      // same edge that completes the previous data phase.
      if (address_accept) begin
        active_q       <= 1'b1;
        write_q        <= HWRITE;
        error_q        <= address_error;
        error_second_q <= 1'b0;
        word_index_q   <= HADDR[WORD_LSB+:INDEX_W];
        wait_count_q   <= '0;
      end
    end
  end

  // HBURST is accepted for interface completeness. Each valid NONSEQ/SEQ beat
  // is handled independently; burst address generation remains a master duty.
  logic unused_hburst;
  assign unused_hburst = ^HBURST;
endmodule
