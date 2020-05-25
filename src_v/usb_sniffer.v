//-----------------------------------------------------------------
//                       USB Sniffer Core
//                            V0.5
//                     Ultra-Embedded.com
//                     Copyright 2016-2020
//
//                 Email: admin@ultra-embedded.com
//
//                         License: LGPL
//-----------------------------------------------------------------
//
// This source file may be used and distributed without
// restriction provided that this copyright statement is not
// removed from the file and that any derivative work contains
// the original copyright notice and the associated disclaimer.
//
// This source file is free software; you can redistribute it
// and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any
// later version.
//
// This source is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU Lesser General Public License for more
// details.
//
// You should have received a copy of the GNU Lesser General
// Public License along with this source; if not, write to the
// Free Software Foundation, Inc., 59 Temple Place, Suite 330,
// Boston, MA  02111-1307  USA
//-----------------------------------------------------------------
module usb_sniffer
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           cfg_awvalid_i
    ,input  [ 31:0]  cfg_awaddr_i
    ,input           cfg_wvalid_i
    ,input  [ 31:0]  cfg_wdata_i
    ,input  [  3:0]  cfg_wstrb_i
    ,input           cfg_bready_i
    ,input           cfg_arvalid_i
    ,input  [ 31:0]  cfg_araddr_i
    ,input           cfg_rready_i
    ,input  [  7:0]  utmi_data_out_i
    ,input  [  7:0]  utmi_data_in_i
    ,input           utmi_txvalid_i
    ,input           utmi_txready_i
    ,input           utmi_rxvalid_i
    ,input           utmi_rxactive_i
    ,input           utmi_rxerror_i
    ,input  [  1:0]  utmi_linestate_i
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i

    // Outputs
    ,output          cfg_awready_o
    ,output          cfg_wready_o
    ,output          cfg_bvalid_o
    ,output [  1:0]  cfg_bresp_o
    ,output          cfg_arready_o
    ,output          cfg_rvalid_o
    ,output [ 31:0]  cfg_rdata_o
    ,output [  1:0]  cfg_rresp_o
    ,output [  1:0]  utmi_op_mode_o
    ,output [  1:0]  utmi_xcvrselect_o
    ,output          utmi_termselect_o
    ,output          utmi_dppulldown_o
    ,output          utmi_dmpulldown_o
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output          outport_wvalid_o
    ,output [ 31:0]  outport_wdata_o
    ,output [  3:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output          outport_rready_o
);



//-----------------------------------------------------------------
// Core
//-----------------------------------------------------------------
wire         fifo_tvalid_w;
wire [31:0]  fifo_tdata_w;
wire         fifo_tready_w;
    
wire [31:0]  buffer_base_w;
wire [31:0]  buffer_end_w;
wire         buffer_reset_w;
wire [31:0]  buffer_current_w;
wire         buffer_cont_w;
wire         buffer_wrapped_w;
wire         buffer_full_w;

usb_sniffer_stream
u_core
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Config
    ,.cfg_awvalid_i(cfg_awvalid_i)
    ,.cfg_awaddr_i(cfg_awaddr_i)
    ,.cfg_wvalid_i(cfg_wvalid_i)
    ,.cfg_wdata_i(cfg_wdata_i)
    ,.cfg_wstrb_i(cfg_wstrb_i)
    ,.cfg_bready_i(cfg_bready_i)
    ,.cfg_arvalid_i(cfg_arvalid_i)
    ,.cfg_araddr_i(cfg_araddr_i)
    ,.cfg_rready_i(cfg_rready_i)
    ,.cfg_awready_o(cfg_awready_o)
    ,.cfg_wready_o(cfg_wready_o)
    ,.cfg_bvalid_o(cfg_bvalid_o)
    ,.cfg_bresp_o(cfg_bresp_o)
    ,.cfg_arready_o(cfg_arready_o)
    ,.cfg_rvalid_o(cfg_rvalid_o)
    ,.cfg_rdata_o(cfg_rdata_o)
    ,.cfg_rresp_o(cfg_rresp_o)

    // UTMI
    ,.utmi_data_out_i(utmi_data_out_i)
    ,.utmi_data_in_i(utmi_data_in_i)
    ,.utmi_txvalid_i(utmi_txvalid_i)
    ,.utmi_txready_i(utmi_txready_i)
    ,.utmi_rxvalid_i(utmi_rxvalid_i)
    ,.utmi_rxactive_i(utmi_rxactive_i)
    ,.utmi_rxerror_i(utmi_rxerror_i)
    ,.utmi_linestate_i(utmi_linestate_i)
    ,.utmi_op_mode_o(utmi_op_mode_o)
    ,.utmi_xcvrselect_o(utmi_xcvrselect_o)
    ,.utmi_termselect_o(utmi_termselect_o)
    ,.utmi_dppulldown_o(utmi_dppulldown_o)
    ,.utmi_dmpulldown_o(utmi_dmpulldown_o)

    // Stream
    ,.outport_tvalid_o(fifo_tvalid_w)
    ,.outport_tdata_o(fifo_tdata_w)
    ,.outport_tstrb_o()
    ,.outport_tdest_o()
    ,.outport_tlast_o()
    ,.outport_tready_i(fifo_tready_w)

    // Buffer Config
    ,.buffer_base_o(buffer_base_w)
    ,.buffer_end_o(buffer_end_w)
    ,.buffer_reset_o(buffer_reset_w)
    ,.buffer_cont_o(buffer_cont_w)
    ,.buffer_current_i(buffer_current_w)
    ,.buffer_wrapped_i(buffer_wrapped_w)
);

//-----------------------------------------------------------------
// Large block RAM based buffer
//-----------------------------------------------------------------
wire         stream_tvalid_w;
wire [31:0]  stream_tdata_w;
wire         stream_tready_w;

usb_sniffer_fifo_ram
u_buffer
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(fifo_tvalid_w)
    ,.data_in_i(fifo_tdata_w)
    ,.accept_o(fifo_tready_w)

    ,.valid_o(stream_tvalid_w)
    ,.data_out_o(stream_tdata_w)
    ,.pop_i(stream_tready_w)
);

//-----------------------------------------------------------------
// AXI: Write logic
//-----------------------------------------------------------------
reg [31:0]  write_addr_q;
wire        mem_ack_w;

usb_sniffer_axi
u_axi
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .outport_awready_i(outport_awready_i),
    .outport_wready_i(outport_wready_i),
    .outport_bvalid_i(outport_bvalid_i),
    .outport_bresp_i(outport_bresp_i),
    .outport_arready_i(outport_arready_i),
    .outport_rvalid_i(outport_rvalid_i),
    .outport_rdata_i(outport_rdata_i),
    .outport_rresp_i(outport_rresp_i),
    .outport_awvalid_o(outport_awvalid_o),
    .outport_awaddr_o(outport_awaddr_o),
    .outport_wvalid_o(outport_wvalid_o),
    .outport_wdata_o(outport_wdata_o),
    .outport_wstrb_o(outport_wstrb_o),
    .outport_bready_o(outport_bready_o),
    .outport_arvalid_o(outport_arvalid_o),
    .outport_araddr_o(outport_araddr_o),
    .outport_rready_o(outport_rready_o),
    .outport_awid_o(outport_awid_o),
    .outport_awlen_o(outport_awlen_o),
    .outport_awburst_o(outport_awburst_o),
    .outport_wlast_o(outport_wlast_o),
    .outport_arid_o(outport_arid_o),
    .outport_arlen_o(outport_arlen_o),
    .outport_arburst_o(outport_arburst_o),
    .outport_bid_i(outport_bid_i),
    .outport_rid_i(outport_rid_i),
    .outport_rlast_i(outport_rlast_i),

    .inport_wr_i({4{stream_tvalid_w & ~buffer_full_w}}),
    .inport_rd_i(1'b0),
    .inport_len_i(8'b0),
    .inport_addr_i(write_addr_q),
    .inport_write_data_i(stream_tdata_w),
    .inport_accept_o(stream_tready_w),
    .inport_ack_o(mem_ack_w),
    .inport_error_o(),
    .inport_read_data_o()
);

//-----------------------------------------------------------------
// Buffer Full
//-----------------------------------------------------------------
reg buffer_full_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    buffer_full_q <= 1'b0;
else if (buffer_reset_w)
    buffer_full_q <= 1'b0;
else if (stream_tvalid_w && stream_tready_w && !buffer_cont_w && (write_addr_q == buffer_end_w))
    buffer_full_q <= 1'b1;

assign buffer_full_w = buffer_full_q;

//-----------------------------------------------------------------
// Buffer Wrapped
//-----------------------------------------------------------------
reg buffer_wrap_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    buffer_wrap_q <= 1'b0;
else if (buffer_reset_w)
    buffer_wrap_q <= 1'b0;
else if (stream_tvalid_w && stream_tready_w && buffer_cont_w && (write_addr_q == buffer_end_w))
    buffer_wrap_q <= 1'b1;

assign buffer_wrapped_w = buffer_wrap_q;

//-----------------------------------------------------------------
// Write Address
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    write_addr_q <= 32'b0;
else if (buffer_reset_w)
    write_addr_q <= buffer_base_w;
else if (stream_tvalid_w && stream_tready_w && !buffer_full_w)
begin
    if (write_addr_q == buffer_end_w)
        write_addr_q <= buffer_base_w;
    else
        write_addr_q <= write_addr_q + 32'd4;
end

//-----------------------------------------------------------------
// Read pointer (based on completed writes)
//-----------------------------------------------------------------
reg [31:0] buffer_current_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    buffer_current_q <= 32'b0;
else if (buffer_reset_w)
    buffer_current_q <= buffer_base_w;
// Control word writes actually occur in IDLE...
else if (mem_ack_w && (buffer_cont_w || buffer_current_q != buffer_end_w))
begin
    if (buffer_current_q == buffer_end_w)
        buffer_current_q <= buffer_base_w;
    else
        buffer_current_q <= buffer_current_q + 32'd4;
end

assign buffer_current_w = buffer_current_q;


endmodule
