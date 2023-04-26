// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>

/// Bare bus error unit without register port
module bus_err_unit_bare #(
  parameter int unsigned AddrWidth       = 48,
  parameter int unsigned MetaDataWidth   = 1,
  parameter int unsigned ErrBits         = 3,
  parameter int unsigned NumOutstanding  = 4,
  parameter int unsigned NumStoredErrors = 4,
  parameter int unsigned NumChannels     = 1, // Channels are one-hot!
  parameter bit          DropOldest      = 1'b0
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     testmode_i,
  
  input  logic [  NumChannels-1:0] req_hs_valid_i,
  input  logic [    AddrWidth-1:0] req_addr_i,
  input  logic [MetaDataWidth-1:0] req_meta_i,
  input  logic [  NumChannels-1:0] rsp_hs_valid_i,
  input  logic [  NumChannels-1:0] rsp_burst_last_i,
  input  logic [      ErrBits-1:0] rsp_err_i,

  output logic                     err_irq_o,

  input  logic                     err_fifo_pop_i,
  output logic [      ErrBits-1:0] err_code_o,
  output logic [    AddrWidth-1:0] err_addr_o,
  output logic [MetaDataWidth-1:0] err_meta_o
);
  assert final ($onehot0(req_hs_valid_i)) else $fatal(1, "Bus Error unit requires one-hot!");
  assert final ($onehot0(rsp_hs_valid_i)) else $fatal(1, "Bus Error unit requires one-hot!");

  typedef struct packed {
    logic [      ErrBits-1:0] err;
    logic [    AddrWidth-1:0] addr;
    logic [MetaDataWidth-1:0] meta;
  } err_addr_t;

  logic [NumChannels-1:0][    AddrWidth-1:0] err_addr;
  logic [NumChannels-1:0][MetaDataWidth-1:0] err_meta;
  err_addr_t read_err_addr;
  logic bus_unit_full;
  logic err_fifo_empty;

  assign err_irq_o = ~err_fifo_empty;

  for (genvar i = 0; i < NumChannels; i++) begin
    fifo_v3 #(
      .FALL_THROUGH ( 1'b0                    ),
      .DATA_WIDTH   ( AddrWidth+MetaDataWidth ),
      .DEPTH        ( NumOutstanding          )
    ) i_addr_fifo (
      .clk_i,
      .rst_ni,
      .flush_i   (1'b0),
      .testmode_i(testmode_i),
      .full_o    (),
      .empty_o   (),
      .usage_o   (),
      .data_i    ({req_addr_i, req_meta_i}),
      .push_i    (req_hs_valid_i[i]),
      .data_o    ({err_addr[i], err_meta[i]}),
      .pop_i     (rsp_burst_last_i[i])
    );
  end

  logic [cf_math_pkg::idx_width(NumChannels)-1:0] chan_select;

  onehot_to_bin #(
    .ONEHOT_WIDTH(NumChannels)
  ) i_rsp_chan_select (
    .onehot(rsp_hs_valid_i),
    .bin   (chan_select)
  );

  logic push_err_fifo, pop_err_fifo;
  err_addr_t fifo_data;

  assign push_err_fifo = (|rsp_hs_valid_i) & (DropOldest | ~bus_unit_full) & (|rsp_err_i);
  assign pop_err_fifo  = (err_fifo_pop_i & ~err_fifo_empty) | (DropOldest & bus_unit_full);

  assign fifo_data = '{err: rsp_err_i, addr: err_addr[chan_select], meta: err_meta[chan_select]};

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0            ),
    .dtype        ( err_addr_t      ),
    .DEPTH        ( NumStoredErrors )
  ) i_err_fifo (
    .clk_i,
    .rst_ni,
    .flush_i   ( 1'b0           ),
    .testmode_i( testmode_i     ),
    .full_o    ( bus_unit_full  ),
    .empty_o   ( err_fifo_empty ),
    .usage_o   (),
    .data_i    ( fifo_data      ),
    .push_i    ( push_err_fifo  ),
    .data_o    ( read_err_addr  ),
    .pop_i     ( pop_err_fifo   )
  );


endmodule
