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
module usb_sniffer_axi
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
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
    ,input  [  3:0]  inport_wr_i
    ,input           inport_rd_i
    ,input  [  7:0]  inport_len_i
    ,input  [ 31:0]  inport_addr_i
    ,input  [ 31:0]  inport_write_data_i

    // Outputs
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
    ,output          inport_accept_o
    ,output          inport_ack_o
    ,output          inport_error_o
    ,output [ 31:0]  inport_read_data_o
);





//-------------------------------------------------------------
// Request FIFO
//-------------------------------------------------------------

// Accepts from both FIFOs
wire          res_accept_w;
wire          req_accept_w;

// Output accept
wire          write_complete_w;
wire          read_complete_w;

wire          req_pop_w   = read_complete_w | write_complete_w;
wire          req_valid_w;
wire [69-1:0] req_w;

// Push on transaction and other FIFO not full
wire          req_push_w   = (inport_rd_i || inport_wr_i != 4'b0) && res_accept_w;

usb_sniffer_axi_fifo
#( 
    .ADDR_W(3),
    .DEPTH(8),
    .WIDTH(32+32+4+1)
)
u_req
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Input side
    .data_in_i({inport_rd_i, inport_wr_i, inport_write_data_i, inport_addr_i}),
    .push_i(req_push_w),
    .accept_o(req_accept_w),

    // Outputs
    .valid_o(req_valid_w),
    .data_out_o(req_w),
    .pop_i(req_pop_w)
);

assign inport_accept_o = req_accept_w & res_accept_w;

//-------------------------------------------------------------
// Response Tracking FIFO
//-------------------------------------------------------------
// Push on transaction and other FIFO not full
wire res_push_w = (inport_rd_i || inport_wr_i != 4'b0) && req_accept_w;

usb_sniffer_axi_fifo
#( 
    .ADDR_W(4),
    .DEPTH(16),
    .WIDTH(1)
)
u_resp
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Input side
    .data_in_i(1'b0),
    .push_i(res_push_w),
    .accept_o(res_accept_w),

    // Outputs
    .valid_o(), // UNUSED
    .data_out_o(), // UNUSED
    .pop_i(inport_ack_o)
);

assign inport_ack_o   = outport_bvalid_i || outport_rvalid_i;
assign inport_error_o = outport_bvalid_i ? (outport_bresp_i != 2'b0) : (outport_rresp_i != 2'b0);

//-------------------------------------------------------------
// Write Request
//-------------------------------------------------------------
wire req_is_read_w  = (req_valid_w ? req_w[68] : 1'b0);
wire req_is_write_w = (req_valid_w ? ~req_w[68] : 1'b0);

reg awvalid_inhibit_q;
reg wvalid_inhibit_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    awvalid_inhibit_q <= 1'b0;
else if (outport_awvalid_o && outport_awready_i && outport_wvalid_o && !outport_wready_i)
    awvalid_inhibit_q <= 1'b1;
else if (outport_wvalid_o && outport_wready_i)
    awvalid_inhibit_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wvalid_inhibit_q <= 1'b0;
else if (outport_wvalid_o && outport_wready_i && outport_awvalid_o && !outport_awready_i)
    wvalid_inhibit_q <= 1'b1;
else if (outport_awvalid_o && outport_awready_i)
    wvalid_inhibit_q <= 1'b0;

assign outport_awvalid_o = req_is_write_w && !awvalid_inhibit_q;
assign outport_awaddr_o  = {req_w[31:2], 2'b0};
assign outport_wvalid_o  = req_is_write_w && !wvalid_inhibit_q;
assign outport_wdata_o   = req_w[63:32];
assign outport_wstrb_o   = req_w[67:64];

assign outport_awid_o    = AXI_ID;
assign outport_awlen_o   = 8'b0;
assign outport_awburst_o = 2'b01;
assign outport_wlast_o   = 1'b1;

assign outport_bready_o  = 1'b1;

assign write_complete_w = (awvalid_inhibit_q || outport_awready_i) &&
                          (wvalid_inhibit_q || outport_wready_i) && req_is_write_w;

//-------------------------------------------------------------
// Read Request
//-------------------------------------------------------------
assign outport_arvalid_o  = req_is_read_w;
assign outport_araddr_o   = {req_w[31:2], 2'b0};
assign outport_arid_o     = AXI_ID;
assign outport_arlen_o    = 8'b0;
assign outport_arburst_o  = 2'b01;

assign outport_rready_o   = 1'b1;

assign inport_read_data_o = outport_rdata_i;

assign read_complete_w    = outport_arvalid_o && outport_arready_i;

endmodule


module usb_sniffer_axi_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];



endmodule
