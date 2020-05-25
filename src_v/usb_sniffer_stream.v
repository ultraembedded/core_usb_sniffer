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
`include "usb_sniffer_stream_defs.v"

//-----------------------------------------------------------------
// Module:  USB Sniffer Peripheral
//-----------------------------------------------------------------
module usb_sniffer_stream
(
    // Inputs
     input          clk_i
    ,input          rst_i
    ,input          cfg_awvalid_i
    ,input  [31:0]  cfg_awaddr_i
    ,input          cfg_wvalid_i
    ,input  [31:0]  cfg_wdata_i
    ,input  [3:0]   cfg_wstrb_i
    ,input          cfg_bready_i
    ,input          cfg_arvalid_i
    ,input  [31:0]  cfg_araddr_i
    ,input          cfg_rready_i
    ,input  [7:0]   utmi_data_out_i
    ,input  [7:0]   utmi_data_in_i
    ,input          utmi_txvalid_i
    ,input          utmi_txready_i
    ,input          utmi_rxvalid_i
    ,input          utmi_rxactive_i
    ,input          utmi_rxerror_i
    ,input  [1:0]   utmi_linestate_i
    ,input          outport_tready_i
    ,input  [31:0]  buffer_current_i
    ,input          buffer_wrapped_i

    // Outputs
    ,output         cfg_awready_o
    ,output         cfg_wready_o
    ,output         cfg_bvalid_o
    ,output [1:0]   cfg_bresp_o
    ,output         cfg_arready_o
    ,output         cfg_rvalid_o
    ,output [31:0]  cfg_rdata_o
    ,output [1:0]   cfg_rresp_o
    ,output [1:0]   utmi_op_mode_o
    ,output [1:0]   utmi_xcvrselect_o
    ,output         utmi_termselect_o
    ,output         utmi_dppulldown_o
    ,output         utmi_dmpulldown_o
    ,output         outport_tvalid_o
    ,output [31:0]  outport_tdata_o
    ,output [3:0]   outport_tstrb_o
    ,output [3:0]   outport_tdest_o
    ,output         outport_tlast_o
    ,output [31:0]  buffer_base_o
    ,output [31:0]  buffer_end_o
    ,output         buffer_reset_o
    ,output         buffer_cont_o
);

//-----------------------------------------------------------------
// Write address / data split
//-----------------------------------------------------------------
// Address but no data ready
reg awvalid_q;

// Data but no data ready
reg wvalid_q;

wire wr_cmd_accepted_w  = (cfg_awvalid_i && cfg_awready_o) || awvalid_q;
wire wr_data_accepted_w = (cfg_wvalid_i  && cfg_wready_o)  || wvalid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    awvalid_q <= 1'b0;
else if (cfg_awvalid_i && cfg_awready_o && !wr_data_accepted_w)
    awvalid_q <= 1'b1;
else if (wr_data_accepted_w)
    awvalid_q <= 1'b0;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wvalid_q <= 1'b0;
else if (cfg_wvalid_i && cfg_wready_o && !wr_cmd_accepted_w)
    wvalid_q <= 1'b1;
else if (wr_cmd_accepted_w)
    wvalid_q <= 1'b0;

//-----------------------------------------------------------------
// Capture address (for delayed data)
//-----------------------------------------------------------------
reg [7:0] wr_addr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wr_addr_q <= 8'b0;
else if (cfg_awvalid_i && cfg_awready_o)
    wr_addr_q <= cfg_awaddr_i[7:0];

wire [7:0] wr_addr_w = awvalid_q ? wr_addr_q : cfg_awaddr_i[7:0];

//-----------------------------------------------------------------
// Retime write data
//-----------------------------------------------------------------
reg [31:0] wr_data_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wr_data_q <= 32'b0;
else if (cfg_wvalid_i && cfg_wready_o)
    wr_data_q <= cfg_wdata_i;

//-----------------------------------------------------------------
// Request Logic
//-----------------------------------------------------------------
wire read_en_w  = cfg_arvalid_i & cfg_arready_o;
wire write_en_w = wr_cmd_accepted_w && wr_data_accepted_w;

//-----------------------------------------------------------------
// Accept Logic
//-----------------------------------------------------------------
assign cfg_arready_o = ~cfg_rvalid_o;
assign cfg_awready_o = ~cfg_bvalid_o && ~cfg_arvalid_i && ~awvalid_q;
assign cfg_wready_o  = ~cfg_bvalid_o && ~cfg_arvalid_i && ~wvalid_q;


//-----------------------------------------------------------------
// Register usb_buffer_cfg
//-----------------------------------------------------------------
reg usb_buffer_cfg_wr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_wr_q <= 1'b1;
else
    usb_buffer_cfg_wr_q <= 1'b0;

// usb_buffer_cfg_cont [internal]
reg        usb_buffer_cfg_cont_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_cont_q <= 1'd`USB_BUFFER_CFG_CONT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_cont_q <= cfg_wdata_i[`USB_BUFFER_CFG_CONT_R];

wire        usb_buffer_cfg_cont_out_w = usb_buffer_cfg_cont_q;


// usb_buffer_cfg_dev [internal]
reg [6:0]  usb_buffer_cfg_dev_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_dev_q <= 7'd`USB_BUFFER_CFG_DEV_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_dev_q <= cfg_wdata_i[`USB_BUFFER_CFG_DEV_R];

wire [6:0]  usb_buffer_cfg_dev_out_w = usb_buffer_cfg_dev_q;


// usb_buffer_cfg_ep [internal]
reg [3:0]  usb_buffer_cfg_ep_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_ep_q <= 4'd`USB_BUFFER_CFG_EP_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_ep_q <= cfg_wdata_i[`USB_BUFFER_CFG_EP_R];

wire [3:0]  usb_buffer_cfg_ep_out_w = usb_buffer_cfg_ep_q;


// usb_buffer_cfg_phy_dmpulldown [internal]
reg        usb_buffer_cfg_phy_dmpulldown_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_phy_dmpulldown_q <= 1'd`USB_BUFFER_CFG_PHY_DMPULLDOWN_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_phy_dmpulldown_q <= cfg_wdata_i[`USB_BUFFER_CFG_PHY_DMPULLDOWN_R];

wire        usb_buffer_cfg_phy_dmpulldown_out_w = usb_buffer_cfg_phy_dmpulldown_q;


// usb_buffer_cfg_phy_dppulldown [internal]
reg        usb_buffer_cfg_phy_dppulldown_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_phy_dppulldown_q <= 1'd`USB_BUFFER_CFG_PHY_DPPULLDOWN_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_phy_dppulldown_q <= cfg_wdata_i[`USB_BUFFER_CFG_PHY_DPPULLDOWN_R];

wire        usb_buffer_cfg_phy_dppulldown_out_w = usb_buffer_cfg_phy_dppulldown_q;


// usb_buffer_cfg_phy_termselect [internal]
reg        usb_buffer_cfg_phy_termselect_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_phy_termselect_q <= 1'd`USB_BUFFER_CFG_PHY_TERMSELECT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_phy_termselect_q <= cfg_wdata_i[`USB_BUFFER_CFG_PHY_TERMSELECT_R];

wire        usb_buffer_cfg_phy_termselect_out_w = usb_buffer_cfg_phy_termselect_q;


// usb_buffer_cfg_phy_xcvrselect [internal]
reg [1:0]  usb_buffer_cfg_phy_xcvrselect_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_phy_xcvrselect_q <= 2'd`USB_BUFFER_CFG_PHY_XCVRSELECT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_phy_xcvrselect_q <= cfg_wdata_i[`USB_BUFFER_CFG_PHY_XCVRSELECT_R];

wire [1:0]  usb_buffer_cfg_phy_xcvrselect_out_w = usb_buffer_cfg_phy_xcvrselect_q;


// usb_buffer_cfg_phy_opmode [internal]
reg [1:0]  usb_buffer_cfg_phy_opmode_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_phy_opmode_q <= 2'd`USB_BUFFER_CFG_PHY_OPMODE_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_phy_opmode_q <= cfg_wdata_i[`USB_BUFFER_CFG_PHY_OPMODE_R];

wire [1:0]  usb_buffer_cfg_phy_opmode_out_w = usb_buffer_cfg_phy_opmode_q;


// usb_buffer_cfg_speed [internal]
reg [1:0]  usb_buffer_cfg_speed_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_speed_q <= 2'd`USB_BUFFER_CFG_SPEED_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_speed_q <= cfg_wdata_i[`USB_BUFFER_CFG_SPEED_R];

wire [1:0]  usb_buffer_cfg_speed_out_w = usb_buffer_cfg_speed_q;


// usb_buffer_cfg_exclude_ep [internal]
reg        usb_buffer_cfg_exclude_ep_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_exclude_ep_q <= 1'd`USB_BUFFER_CFG_EXCLUDE_EP_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_exclude_ep_q <= cfg_wdata_i[`USB_BUFFER_CFG_EXCLUDE_EP_R];

wire        usb_buffer_cfg_exclude_ep_out_w = usb_buffer_cfg_exclude_ep_q;


// usb_buffer_cfg_match_ep [internal]
reg        usb_buffer_cfg_match_ep_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_match_ep_q <= 1'd`USB_BUFFER_CFG_MATCH_EP_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_match_ep_q <= cfg_wdata_i[`USB_BUFFER_CFG_MATCH_EP_R];

wire        usb_buffer_cfg_match_ep_out_w = usb_buffer_cfg_match_ep_q;


// usb_buffer_cfg_exclude_dev [internal]
reg        usb_buffer_cfg_exclude_dev_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_exclude_dev_q <= 1'd`USB_BUFFER_CFG_EXCLUDE_DEV_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_exclude_dev_q <= cfg_wdata_i[`USB_BUFFER_CFG_EXCLUDE_DEV_R];

wire        usb_buffer_cfg_exclude_dev_out_w = usb_buffer_cfg_exclude_dev_q;


// usb_buffer_cfg_match_dev [internal]
reg        usb_buffer_cfg_match_dev_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_match_dev_q <= 1'd`USB_BUFFER_CFG_MATCH_DEV_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_match_dev_q <= cfg_wdata_i[`USB_BUFFER_CFG_MATCH_DEV_R];

wire        usb_buffer_cfg_match_dev_out_w = usb_buffer_cfg_match_dev_q;


// usb_buffer_cfg_ignore_sof [internal]
reg        usb_buffer_cfg_ignore_sof_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_ignore_sof_q <= 1'd`USB_BUFFER_CFG_IGNORE_SOF_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_ignore_sof_q <= cfg_wdata_i[`USB_BUFFER_CFG_IGNORE_SOF_R];

wire        usb_buffer_cfg_ignore_sof_out_w = usb_buffer_cfg_ignore_sof_q;


// usb_buffer_cfg_ignore_in_nak [internal]
reg        usb_buffer_cfg_ignore_in_nak_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_ignore_in_nak_q <= 1'd`USB_BUFFER_CFG_IGNORE_IN_NAK_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_ignore_in_nak_q <= cfg_wdata_i[`USB_BUFFER_CFG_IGNORE_IN_NAK_R];

wire        usb_buffer_cfg_ignore_in_nak_out_w = usb_buffer_cfg_ignore_in_nak_q;


// usb_buffer_cfg_enabled [internal]
reg        usb_buffer_cfg_enabled_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_cfg_enabled_q <= 1'd`USB_BUFFER_CFG_ENABLED_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CFG))
    usb_buffer_cfg_enabled_q <= cfg_wdata_i[`USB_BUFFER_CFG_ENABLED_R];

wire        usb_buffer_cfg_enabled_out_w = usb_buffer_cfg_enabled_q;


//-----------------------------------------------------------------
// Register usb_buffer_sts
//-----------------------------------------------------------------
reg usb_buffer_sts_wr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_sts_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_STS))
    usb_buffer_sts_wr_q <= 1'b1;
else
    usb_buffer_sts_wr_q <= 1'b0;




//-----------------------------------------------------------------
// Register usb_buffer_base
//-----------------------------------------------------------------
reg usb_buffer_base_wr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_base_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_BASE))
    usb_buffer_base_wr_q <= 1'b1;
else
    usb_buffer_base_wr_q <= 1'b0;

// usb_buffer_base_addr [internal]
reg [31:0]  usb_buffer_base_addr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_base_addr_q <= 32'd`USB_BUFFER_BASE_ADDR_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_BASE))
    usb_buffer_base_addr_q <= cfg_wdata_i[`USB_BUFFER_BASE_ADDR_R];

wire [31:0]  usb_buffer_base_addr_out_w = usb_buffer_base_addr_q;


//-----------------------------------------------------------------
// Register usb_buffer_end
//-----------------------------------------------------------------
reg usb_buffer_end_wr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_end_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_END))
    usb_buffer_end_wr_q <= 1'b1;
else
    usb_buffer_end_wr_q <= 1'b0;

// usb_buffer_end_addr [internal]
reg [31:0]  usb_buffer_end_addr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_end_addr_q <= 32'd`USB_BUFFER_END_ADDR_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_END))
    usb_buffer_end_addr_q <= cfg_wdata_i[`USB_BUFFER_END_ADDR_R];

wire [31:0]  usb_buffer_end_addr_out_w = usb_buffer_end_addr_q;


//-----------------------------------------------------------------
// Register usb_buffer_current
//-----------------------------------------------------------------
reg usb_buffer_current_wr_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    usb_buffer_current_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `USB_BUFFER_CURRENT))
    usb_buffer_current_wr_q <= 1'b1;
else
    usb_buffer_current_wr_q <= 1'b0;


wire        usb_buffer_sts_data_loss_in_w;
wire        usb_buffer_sts_wrapped_in_w;
wire        usb_buffer_sts_trig_in_w;
wire [31:0]  usb_buffer_current_addr_in_w;


//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
reg [31:0] data_r;

always @ *
begin
    data_r = 32'b0;

    case (cfg_araddr_i[7:0])

    `USB_BUFFER_CFG:
    begin
        data_r[`USB_BUFFER_CFG_CONT_R] = usb_buffer_cfg_cont_q;
        data_r[`USB_BUFFER_CFG_DEV_R] = usb_buffer_cfg_dev_q;
        data_r[`USB_BUFFER_CFG_EP_R] = usb_buffer_cfg_ep_q;
        data_r[`USB_BUFFER_CFG_PHY_DMPULLDOWN_R] = usb_buffer_cfg_phy_dmpulldown_q;
        data_r[`USB_BUFFER_CFG_PHY_DPPULLDOWN_R] = usb_buffer_cfg_phy_dppulldown_q;
        data_r[`USB_BUFFER_CFG_PHY_TERMSELECT_R] = usb_buffer_cfg_phy_termselect_q;
        data_r[`USB_BUFFER_CFG_PHY_XCVRSELECT_R] = usb_buffer_cfg_phy_xcvrselect_q;
        data_r[`USB_BUFFER_CFG_PHY_OPMODE_R] = usb_buffer_cfg_phy_opmode_q;
        data_r[`USB_BUFFER_CFG_SPEED_R] = usb_buffer_cfg_speed_q;
        data_r[`USB_BUFFER_CFG_EXCLUDE_EP_R] = usb_buffer_cfg_exclude_ep_q;
        data_r[`USB_BUFFER_CFG_MATCH_EP_R] = usb_buffer_cfg_match_ep_q;
        data_r[`USB_BUFFER_CFG_EXCLUDE_DEV_R] = usb_buffer_cfg_exclude_dev_q;
        data_r[`USB_BUFFER_CFG_MATCH_DEV_R] = usb_buffer_cfg_match_dev_q;
        data_r[`USB_BUFFER_CFG_IGNORE_SOF_R] = usb_buffer_cfg_ignore_sof_q;
        data_r[`USB_BUFFER_CFG_IGNORE_IN_NAK_R] = usb_buffer_cfg_ignore_in_nak_q;
        data_r[`USB_BUFFER_CFG_ENABLED_R] = usb_buffer_cfg_enabled_q;
    end
    `USB_BUFFER_STS:
    begin
        data_r[`USB_BUFFER_STS_DATA_LOSS_R] = usb_buffer_sts_data_loss_in_w;
        data_r[`USB_BUFFER_STS_WRAPPED_R] = usb_buffer_sts_wrapped_in_w;
        data_r[`USB_BUFFER_STS_TRIG_R] = usb_buffer_sts_trig_in_w;
    end
    `USB_BUFFER_BASE:
    begin
        data_r[`USB_BUFFER_BASE_ADDR_R] = usb_buffer_base_addr_q;
    end
    `USB_BUFFER_END:
    begin
        data_r[`USB_BUFFER_END_ADDR_R] = usb_buffer_end_addr_q;
    end
    `USB_BUFFER_CURRENT:
    begin
        data_r[`USB_BUFFER_CURRENT_ADDR_R] = usb_buffer_current_addr_in_w;
    end
    default :
        data_r = 32'b0;
    endcase
end

//-----------------------------------------------------------------
// RVALID
//-----------------------------------------------------------------
reg rvalid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    rvalid_q <= 1'b0;
else if (read_en_w)
    rvalid_q <= 1'b1;
else if (cfg_rready_i)
    rvalid_q <= 1'b0;

assign cfg_rvalid_o = rvalid_q;

//-----------------------------------------------------------------
// Retime read response
//-----------------------------------------------------------------
reg [31:0] rd_data_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    rd_data_q <= 32'b0;
else if (!cfg_rvalid_o || cfg_rready_i)
    rd_data_q <= data_r;

assign cfg_rdata_o = rd_data_q;
assign cfg_rresp_o = 2'b0;

//-----------------------------------------------------------------
// BVALID
//-----------------------------------------------------------------
reg bvalid_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    bvalid_q <= 1'b0;
else if (write_en_w)
    bvalid_q <= 1'b1;
else if (cfg_bready_i)
    bvalid_q <= 1'b0;

assign cfg_bvalid_o = bvalid_q;
assign cfg_bresp_o  = 2'b0;



//-----------------------------------------------------------------
// Log word format
//-----------------------------------------------------------------
// TYPE = LOG_CTRL_TYPE_SOF/RST
`define LOG_SOF_FRAME_W         11
`define LOG_SOF_FRAME_L         0
`define LOG_SOF_FRAME_H         (`LOG_SOF_FRAME_L + `LOG_SOF_FRAME_W - 1)
`define LOG_RST_STATE_W         1
`define LOG_RST_STATE_L         (`LOG_SOF_FRAME_H + 1)
`define LOG_RST_STATE_H         (`LOG_RST_STATE_L + `LOG_RST_STATE_W - 1)

// TYPE = LOG_CTRL_TYPE_TOKEN | LOG_CTRL_TYPE_HSHAKE | LOG_CTRL_TYPE_DATA | LOG_CTRL_TYPE_SPLIT
`define LOG_TOKEN_PID_W         4
`define LOG_TOKEN_PID_L         0
`define LOG_TOKEN_PID_H         (`LOG_TOKEN_PID_L + `LOG_TOKEN_PID_W - 1)

// TYPE = LOG_CTRL_TYPE_TOKEN
`define LOG_TOKEN_DATA_W        16
`define LOG_TOKEN_DATA_L        (`LOG_TOKEN_PID_H + 1)
`define LOG_TOKEN_DATA_H        (`LOG_TOKEN_DATA_L + `LOG_TOKEN_DATA_W - 1)

// TYPE = LOG_CTRL_TYPE_DATA
`define LOG_DATA_LEN_W          16
`define LOG_DATA_LEN_L          (`LOG_TOKEN_PID_H + 1)
`define LOG_DATA_LEN_H          (`LOG_DATA_LEN_L + `LOG_DATA_LEN_W - 1)

// TYPE = LOG_CTRL_TYPE_TOKEN | LOG_CTRL_TYPE_HSHAKE | LOG_CTRL_TYPE_DATA | LOG_CTRL_TYPE_SOF
`define LOG_CTRL_CYCLE_W        8
`define LOG_CTRL_CYCLE_L        20
`define LOG_CTRL_CYCLE_H        (`LOG_CTRL_CYCLE_L + `LOG_CTRL_CYCLE_W - 1)

// TYPE = LOG_CTRL_TYPE_SPLIT
`define LOG_SPLIT_DATA_W        24
`define LOG_SPLIT_DATA_L        (`LOG_TOKEN_PID_H + 1)
`define LOG_SPLIT_DATA_H        (`LOG_SPLIT_DATA_L + `LOG_SPLIT_DATA_W - 1)

`define LOG_CTRL_TYPE_W          4
`define LOG_CTRL_TYPE_L          28
`define LOG_CTRL_TYPE_H          31
`define LOG_CTRL_TYPE_SOF        4'd1
`define LOG_CTRL_TYPE_RST        4'd2
`define LOG_CTRL_TYPE_TOKEN      4'd3
`define LOG_CTRL_TYPE_HSHAKE     4'd4
`define LOG_CTRL_TYPE_DATA       4'd5
`define LOG_CTRL_TYPE_SPLIT      4'd6

//-----------------------------------------------------------------
// USB PID tokens
//-----------------------------------------------------------------
// Tokens
`define PID_OUT                  8'hE1
`define PID_IN                   8'h69
`define PID_SOF                  8'hA5
`define PID_SETUP                8'h2D

// Data
`define PID_DATA0                8'hC3
`define PID_DATA1                8'h4B
`define PID_DATA2                8'h87
`define PID_MDATA                8'h0F

// Handshake
`define PID_ACK                  8'hD2
`define PID_NAK                  8'h5A
`define PID_STALL                8'h1E
`define PID_NYET                 8'h96

// Special
`define PID_PRE                  8'h3C
`define PID_ERR                  8'h3C
`define PID_SPLIT                8'h78
`define PID_PING                 8'hB4

//-----------------------------------------------------------------
// Registers / Writes
//-----------------------------------------------------------------
wire        cfg_ignore_sof_w  = usb_buffer_cfg_ignore_sof_out_w;
wire        cfg_ignore_in_nak_w = usb_buffer_cfg_ignore_in_nak_out_w;
wire        cfg_enabled_w     = usb_buffer_cfg_enabled_out_w;
wire        cfg_match_dev_w   = usb_buffer_cfg_match_dev_out_w;
wire        cfg_match_ep_w    = usb_buffer_cfg_match_ep_out_w;
wire        cfg_exclude_dev_w = usb_buffer_cfg_exclude_dev_out_w;
wire        cfg_exclude_ep_w  = usb_buffer_cfg_exclude_ep_out_w;
wire [6:0]  cfg_dev_w         = usb_buffer_cfg_dev_out_w;
wire [3:0]  cfg_ep_w          = usb_buffer_cfg_ep_out_w;
wire [1:0]  cfg_speed_w       = usb_buffer_cfg_speed_out_w;

wire        rst_change_w;
wire        usb_rst_w;

wire [6:0]  current_dev_w;
wire [3:0]  current_ep_w;

//-----------------------------------------------------------------
// USB Speed Select
//-----------------------------------------------------------------
`define USB_SPEED_HS       2'b00
`define USB_SPEED_FS       2'b01
`define USB_SPEED_LS       2'b10
`define USB_SPEED_MANUAL   2'b11

reg [1:0] xcvrselect_r;
reg       termselect_r;
reg [1:0] op_mode_r;
reg       dppulldown_r;
reg       dmpulldown_r;

always @ *
begin
    xcvrselect_r = 2'b00;
    termselect_r = 1'b0;
    op_mode_r    = 2'b01;
    dppulldown_r = 1'b1;
    dmpulldown_r = 1'b1;

    case (cfg_speed_w)
    `USB_SPEED_HS:
    begin
        xcvrselect_r = 2'b00;
        termselect_r = 1'b0;
        op_mode_r    = 2'b01;
        dppulldown_r = 1'b1;
        dmpulldown_r = 1'b1;
    end
    `USB_SPEED_FS:
    begin
        xcvrselect_r = 2'b01;
        termselect_r = 1'b0;
        op_mode_r    = 2'b01;
        dppulldown_r = 1'b1;
        dmpulldown_r = 1'b1;
    end
    `USB_SPEED_LS:
    begin
        xcvrselect_r = 2'b10;
        termselect_r = 1'b0;
        op_mode_r    = 2'b01;
        dppulldown_r = 1'b1;
        dmpulldown_r = 1'b1;
    end
    `USB_SPEED_MANUAL:
    begin
        xcvrselect_r = usb_buffer_cfg_phy_xcvrselect_out_w;
        termselect_r = usb_buffer_cfg_phy_termselect_out_w;
        op_mode_r    = usb_buffer_cfg_phy_opmode_out_w;
        dppulldown_r = usb_buffer_cfg_phy_dppulldown_out_w;
        dmpulldown_r = usb_buffer_cfg_phy_dmpulldown_out_w;
    end  
    default :
        ;
    endcase
end

assign utmi_op_mode_o    = op_mode_r;
assign utmi_xcvrselect_o = xcvrselect_r;
assign utmi_termselect_o = termselect_r;
assign utmi_dppulldown_o = dppulldown_r;
assign utmi_dmpulldown_o = dmpulldown_r;

//-----------------------------------------------------------------
// Device / Endpoint filtering
//-----------------------------------------------------------------
reg dev_match_r;
reg ep_match_r;

always @ *
begin
    if (cfg_match_dev_w)
        dev_match_r = (current_dev_w == cfg_dev_w) || (current_dev_w == 7'd0);
    else if (cfg_exclude_dev_w)
        dev_match_r = (current_dev_w != cfg_dev_w);
    else
        dev_match_r = 1'b1;

    if (cfg_match_ep_w)
        ep_match_r = (current_ep_w == cfg_ep_w);
    else if (cfg_exclude_ep_w)
        ep_match_r = (current_ep_w != cfg_ep_w);
    else
        ep_match_r = 1'b1;
end

wire dev_match_w = dev_match_r;
wire ep_match_w  = ep_match_r;

//-----------------------------------------------------------------
// Start / End of packet detection
//-----------------------------------------------------------------
reg rx_active_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    rx_active_q <= 1'b0;
// IDLE
else if (!rx_active_q)
begin 
    // Rx data
    if (utmi_rxvalid_i && utmi_rxactive_i)
        rx_active_q <= 1'b1;
end
// ACTIVE
else
begin
    // End of packet
    if (!utmi_rxactive_i)
        rx_active_q <= 1'b0;
end

reg tx_active_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    tx_active_q <= 1'b0;
// IDLE
else if (!tx_active_q)
begin 
    // Tx data
    if (utmi_txvalid_i && utmi_txready_i)
        tx_active_q <= 1'b1;
end
// ACTIVE
else
begin
    // End of packet
    if (!utmi_txvalid_i)
        tx_active_q <= 1'b0;
end

wire int_sample_byte_w  = (utmi_rxvalid_i && utmi_rxactive_i) || (utmi_txvalid_i && utmi_txready_i);
wire int_start_packet_w = !rx_active_q && !tx_active_q && int_sample_byte_w;
wire int_end_packet_w   = (rx_active_q  && !utmi_rxactive_i) || (tx_active_q && !utmi_txvalid_i);

wire [7:0] int_sample_data_w = utmi_txvalid_i ? utmi_data_out_i : utmi_data_in_i;

//-----------------------------------------------------------------
// Retimed data
//-----------------------------------------------------------------
reg       sample_byte_q;
reg       start_packet_q;
reg       end_packet_q;
reg [7:0] sample_data_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
begin
    sample_byte_q  <= 1'b0;
    start_packet_q <= 1'b0;
    end_packet_q   <= 1'b0;
    sample_data_q  <= 8'b0;
end
else
begin
    sample_byte_q  <= int_sample_byte_w;
    start_packet_q <= int_start_packet_w;
    end_packet_q   <= int_end_packet_w;
    sample_data_q  <= int_sample_data_w;
end

wire sample_byte_w       = sample_byte_q;
wire start_packet_w      = start_packet_q;
wire end_packet_w        = end_packet_q;
wire [7:0] sample_data_w = sample_data_q;

//-----------------------------------------------------------------
// State machine
//-----------------------------------------------------------------
`define STATE_W  4

// Current state
localparam STATE_RX_IDLE                 = 4'd0;
localparam STATE_RX_TOKEN2               = 4'd1;
localparam STATE_RX_TOKEN3               = 4'd2;
localparam STATE_RX_TOKEN4               = 4'd3;
localparam STATE_RX_TOKEN_COMPLETE       = 4'd4;
localparam STATE_RX_SOF2                 = 4'd5;
localparam STATE_RX_SOF3                 = 4'd6;
localparam STATE_RX_SOF_COMPLETE         = 4'd7;
localparam STATE_RX_DATA                 = 4'd8;
localparam STATE_RX_DATA_COMPLETE        = 4'd9;
localparam STATE_RX_HSHAKE_COMPLETE      = 4'd10;
localparam STATE_RX_DATA_IGNORE          = 4'd11;
localparam STATE_UPDATE_RST              = 4'd12;

reg [`STATE_W-1:0] state_q;
reg [`STATE_W-1:0] next_state_r;
reg [7:0]          pid_q;

always @ *
begin
    next_state_r = state_q;

    //-----------------------------------------
    // State Machine
    //-----------------------------------------
    case (state_q)

    //-----------------------------------------
    // IDLE
    //-----------------------------------------
    STATE_RX_IDLE :
    begin
        // Disabled - ignore frame
        if (!cfg_enabled_w && start_packet_w)
            next_state_r  = STATE_RX_DATA_IGNORE;
        // Enable
        else if (start_packet_w)
        begin
            // Decode PID
            case (sample_data_w)

            // Token
            `PID_OUT, `PID_IN, `PID_SETUP, `PID_PING:
                next_state_r  = STATE_RX_TOKEN2;

            // Token: SOF
            `PID_SOF:
                next_state_r  = STATE_RX_SOF2;

            // Data
            `PID_DATA0, `PID_DATA1, `PID_DATA2, `PID_MDATA:
            begin
                if (dev_match_w && ep_match_w)
                    next_state_r  = STATE_RX_DATA;
                else
                    next_state_r  = STATE_RX_DATA_IGNORE;
            end

            // Handshake
            `PID_ACK, `PID_NAK, `PID_STALL, `PID_NYET, `PID_PRE:
            begin
                if (dev_match_w && ep_match_w)
                    next_state_r  = STATE_RX_HSHAKE_COMPLETE;
                else            
                    next_state_r  = STATE_RX_DATA_IGNORE;
            end

            // Split
            `PID_SPLIT:
            begin
                next_state_r  = STATE_RX_TOKEN2;
            end

            default :
                ;
            endcase
        end
        // Reset state change, record status
        else if (rst_change_w && cfg_enabled_w)
            next_state_r  = STATE_UPDATE_RST;
    end

    //-----------------------------------------
    // SOF (BYTE 2)
    //-----------------------------------------
    STATE_RX_SOF2 :
    begin
        if (sample_byte_w)
            next_state_r = STATE_RX_SOF3;
        else if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // SOF (BYTE 3)
    //-----------------------------------------
    STATE_RX_SOF3 :
    begin
        if (sample_byte_w)
            next_state_r = STATE_RX_SOF_COMPLETE;
        else if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // TOKEN (BYTE 2)
    //-----------------------------------------
    STATE_RX_TOKEN2 :
    begin
        if (sample_byte_w)
            next_state_r = STATE_RX_TOKEN3;
        else if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // TOKEN (BYTE 3)
    //-----------------------------------------
    STATE_RX_TOKEN3 :
    begin
        if (sample_byte_w && pid_q == `PID_SPLIT)
            next_state_r = STATE_RX_TOKEN4;
        else if (sample_byte_w)
            next_state_r = STATE_RX_TOKEN_COMPLETE;
        else if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // TOKEN (BYTE 4) - SPLIT only
    //-----------------------------------------
    STATE_RX_TOKEN4 :
    begin
        if (sample_byte_w)
            next_state_r = STATE_RX_TOKEN_COMPLETE;
        else if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // RX_DATA
    //-----------------------------------------
    STATE_RX_DATA :
    begin
        // Receive complete
        if (end_packet_w)
            next_state_r = STATE_RX_DATA_COMPLETE;
    end

    //-----------------------------------------
    // *_COMPLETE
    //-----------------------------------------
    STATE_RX_DATA_COMPLETE,
    STATE_RX_TOKEN_COMPLETE,
    STATE_RX_HSHAKE_COMPLETE,
    STATE_RX_SOF_COMPLETE :
    begin
        next_state_r  = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // RX_DATA_IGNORE
    //-----------------------------------------
    STATE_RX_DATA_IGNORE :
    begin
        // Receive complete
        if (end_packet_w)
            next_state_r = STATE_RX_IDLE;
    end

    //-----------------------------------------
    // UPDATE_RST
    //-----------------------------------------
    STATE_UPDATE_RST :
    begin
        next_state_r = STATE_RX_IDLE;
    end

    default :
       ;

    endcase
end

// Update state
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    state_q <= STATE_RX_IDLE;
else
    state_q <= next_state_r;

//-----------------------------------------------------------------
// USB Reset Condition
//-----------------------------------------------------------------
reg [14:0] se0_cnt_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    se0_cnt_q <= 15'b0;
else if (utmi_linestate_i == 2'b0)
begin
    if (!se0_cnt_q[14])
        se0_cnt_q <= se0_cnt_q + 15'd1;
end    
else
    se0_cnt_q <= 15'b0;

assign usb_rst_w = se0_cnt_q[14];

reg usb_rst_q;
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    usb_rst_q <= 1'b0;
else if (state_q == STATE_RX_IDLE && !start_packet_w)
    usb_rst_q <= usb_rst_w;

assign rst_change_w = usb_rst_q ^ usb_rst_w;

//-----------------------------------------------------------------
// Capture PID
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    pid_q <= 8'b0;
else if (state_q == STATE_RX_IDLE && sample_byte_w)
    pid_q <= sample_data_w;

//-----------------------------------------------------------------
// SOF Frame Number
//-----------------------------------------------------------------
reg [10:0] frame_number_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    frame_number_q          <= 11'b0;
else if (state_q == STATE_RX_SOF2 && sample_byte_w)
    frame_number_q[7:0]     <= sample_data_w;
else if (state_q == STATE_RX_SOF3 && sample_byte_w)
    frame_number_q[10:8]    <= sample_data_w[2:0];

//-----------------------------------------------------------------
// Token data
//-----------------------------------------------------------------
reg [23:0] token_data_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    token_data_q        <= 24'b0;
else if (state_q == STATE_RX_TOKEN2 && sample_byte_w)
    token_data_q[7:0]   <= sample_data_w;
else if (state_q == STATE_RX_TOKEN3 && sample_byte_w)
    token_data_q[15:8]  <= sample_data_w;
else if (state_q == STATE_RX_TOKEN4 && sample_byte_w)
    token_data_q[23:16]  <= sample_data_w;

assign current_dev_w = token_data_q[6:0];
assign current_ep_w  = token_data_q[10:7];

//-----------------------------------------------------------------
// Data Counter
//-----------------------------------------------------------------
reg [15:0] data_count_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    data_count_q <= 16'b0;
else if (state_q == STATE_RX_IDLE)
    data_count_q <= 16'b0;
else if (state_q == STATE_RX_DATA && sample_byte_w)
    data_count_q <= data_count_q + 16'd1;

//-----------------------------------------------------------------
// Skipped token (ignore NAK'd INs)
//-----------------------------------------------------------------
reg token_skipped_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    token_skipped_q <= 1'b0;
else if (state_q == STATE_RX_TOKEN_COMPLETE)
    token_skipped_q <= cfg_ignore_in_nak_w && (pid_q == `PID_IN);
else if (token_skipped_q && state_q == STATE_RX_IDLE && next_state_r == STATE_RX_DATA)
    token_skipped_q <= 1'b0;
else if (state_q == STATE_RX_HSHAKE_COMPLETE)
    token_skipped_q <= 1'b0;

//-----------------------------------------------------------------
// Buffer write word
//-----------------------------------------------------------------
reg [31:0] cmd_buffer_r;
reg        cmd_buffer_wr_r;
reg [15:0] cycle_q;

always @ *
begin
    cmd_buffer_r    = 32'b0;
    cmd_buffer_wr_r = 1'b0;

    // Logging SOFs?
    if (state_q == STATE_RX_SOF_COMPLETE && !cfg_ignore_sof_w)
    begin
        cmd_buffer_r[`LOG_SOF_FRAME_H:`LOG_SOF_FRAME_L]   = frame_number_q;
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_SOF;
        cmd_buffer_wr_r = 1'b1;
    end
    // Token (SPLIT)
    else if (state_q == STATE_RX_TOKEN_COMPLETE && pid_q == `PID_SPLIT)
    begin
        cmd_buffer_r[`LOG_TOKEN_PID_H:`LOG_TOKEN_PID_L]   = pid_q[3:0];
        cmd_buffer_r[`LOG_SPLIT_DATA_H:`LOG_SPLIT_DATA_L] = token_data_q[23:0];
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_SPLIT;
        cmd_buffer_wr_r = 1'b1;
    end
    // Token
    else if (state_q == STATE_RX_TOKEN_COMPLETE)
    begin
        cmd_buffer_r[`LOG_TOKEN_PID_H:`LOG_TOKEN_PID_L]   = pid_q[3:0];
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_TOKEN_DATA_H:`LOG_TOKEN_DATA_L] = token_data_q[15:0];
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_TOKEN;
        cmd_buffer_wr_r = dev_match_w && ep_match_w && (!cfg_ignore_in_nak_w || pid_q != `PID_IN);
    end
    // Handshake
    else if (state_q == STATE_RX_HSHAKE_COMPLETE)
    begin
        cmd_buffer_r[`LOG_TOKEN_PID_H:`LOG_TOKEN_PID_L]   = pid_q[3:0];
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_HSHAKE;
        cmd_buffer_wr_r = !token_skipped_q;
    end
    // Reset event
    else if (state_q == STATE_UPDATE_RST)
    begin
        cmd_buffer_r[`LOG_SOF_FRAME_H:`LOG_SOF_FRAME_L] = frame_number_q;
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_RST_STATE_H:`LOG_RST_STATE_L] = usb_rst_q;
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L] = `LOG_CTRL_TYPE_RST;
        cmd_buffer_wr_r = 1'b1;
    end
    // Only logging IN tokens if DATA returned
    else if (token_skipped_q && state_q == STATE_RX_IDLE && next_state_r == STATE_RX_DATA)
    begin
        cmd_buffer_r[`LOG_TOKEN_PID_H:`LOG_TOKEN_PID_L]   = pid_q[3:0];
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_TOKEN_DATA_H:`LOG_TOKEN_DATA_L] = token_data_q[15:0];
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_TOKEN;
        cmd_buffer_wr_r = dev_match_w && ep_match_w;
    end
    // End of data transfer
    else if (state_q == STATE_RX_DATA_COMPLETE)
    begin
        cmd_buffer_r[`LOG_TOKEN_PID_H:`LOG_TOKEN_PID_L]   = pid_q[3:0];
        cmd_buffer_r[`LOG_CTRL_CYCLE_H:`LOG_CTRL_CYCLE_L] = cycle_q[15:8];
        cmd_buffer_r[`LOG_DATA_LEN_H:`LOG_DATA_LEN_L]     = data_count_q;
        cmd_buffer_r[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L]   = `LOG_CTRL_TYPE_DATA;
        cmd_buffer_wr_r = 1'b1;
    end
end

reg [31:0] buffer_q;
reg        buffer_wr_q;

reg [31:0] buffer_r;
reg        buffer_wr_r;

always @ *
begin
    buffer_r    = 32'b0;
    buffer_wr_r = 1'b0;

    // Receiving data
    if (state_q == STATE_RX_DATA)
    begin
        // Capture new data, building up a word
        if (sample_byte_w)
        begin
            case (data_count_q[1:0])
                2'd0: buffer_r = {24'b0, sample_data_w};
                2'd1: buffer_r = {16'b0, sample_data_w, buffer_q[7:0]};
                2'd2: buffer_r = {8'b0, sample_data_w, buffer_q[15:0]};
                2'd3: buffer_r = {sample_data_w, buffer_q[23:0]};
            endcase
        end
        // Hold current
        else
            buffer_r = buffer_q;

        // Every 4 bytes, or the last byte
        buffer_wr_r = (sample_byte_w && (data_count_q[1:0] == 2'd3)) || 
                      (end_packet_w && data_count_q[1:0] != 2'd0);
    end
end

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    buffer_q <= 32'b0;
else
    buffer_q <= buffer_r;

//-----------------------------------------------------------------
// FIFO: Data messages
//-----------------------------------------------------------------
wire        data_valid_w;
wire [31:0] data_data_w;
wire        data_pop_w;
wire        data_accept_w;

usb_sniffer_fifo
u_fifo_data
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.data_in_i(buffer_r)
    ,.push_i(buffer_wr_r)
    ,.accept_o(data_accept_w)

    ,.valid_o(data_valid_w)
    ,.data_out_o(data_data_w)
    ,.pop_i(data_pop_w)
);

//-----------------------------------------------------------------
// FIFO: Control messages
//-----------------------------------------------------------------
wire        ctrl_valid_w;
wire [31:0] ctrl_data_w;
wire        ctrl_pop_w;
wire        ctrl_accept_w;

usb_sniffer_fifo
u_fifo_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.data_in_i(cmd_buffer_r)
    ,.push_i(cmd_buffer_wr_r)
    ,.accept_o(ctrl_accept_w)

    ,.valid_o(ctrl_valid_w)
    ,.data_out_o(ctrl_data_w)
    ,.pop_i(ctrl_pop_w)
);

//-----------------------------------------------------------------
// Cycle Counter: Delta ticks since last log entry
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    cycle_q <= 16'b0;
// Don't count during data frame - maintain count at start of response
else if (state_q == STATE_RX_DATA)
    ;
// Reset cycle counter on header write
else if (cmd_buffer_wr_r)
    cycle_q <= 16'b0;
else if (cycle_q != 16'hFFFF)
    cycle_q <= cycle_q + 16'd1;

//-----------------------------------------------------------------
// Enable Reset
//-----------------------------------------------------------------
reg cfg_enabled_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    cfg_enabled_q <= 1'b0;
else
    cfg_enabled_q <= cfg_enabled_w;

wire cfg_enable_reset_w = !cfg_enabled_q & cfg_enabled_w;

//-----------------------------------------------------------------
// Write detection
//-----------------------------------------------------------------
reg write_detect_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    write_detect_q <= 1'b0;
else if (cfg_enable_reset_w)
    write_detect_q <= 1'b0;
else if (cmd_buffer_wr_r)
    write_detect_q <= 1'b1;

assign usb_buffer_sts_trig_in_w = write_detect_q;

//-----------------------------------------------------------------
// Memory stall detect
//-----------------------------------------------------------------
reg data_lost_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i) 
    data_lost_q <= 1'b0;
else if (cfg_enable_reset_w)
    data_lost_q <= 1'b0;
else if (buffer_wr_r && !data_accept_w)
    data_lost_q <= 1'b1;
else if (cmd_buffer_wr_r && !ctrl_accept_w)
    data_lost_q <= 1'b1;

assign usb_buffer_sts_data_loss_in_w = data_lost_q;

//-------------------------------------------------------------------
// Output
//-------------------------------------------------------------------
reg        output_valid_q;
reg [31:0] output_data_q;
reg        output_valid_r;
reg [31:0] output_data_r;
reg [15:0] output_count_q;
reg [15:0] output_count_r;

always @ *
begin
    output_valid_r = 1'b0;
    output_data_r  = 32'b0;
    output_count_r = output_count_q;

    if (output_count_r == 16'b0)
    begin
        output_valid_r = ctrl_valid_w;
        output_data_r  = ctrl_data_w;

        // Data payload
        if (ctrl_valid_w && ctrl_data_w[`LOG_CTRL_TYPE_H:`LOG_CTRL_TYPE_L] == `LOG_CTRL_TYPE_DATA)
            output_count_r = ctrl_data_w[`LOG_DATA_LEN_H:`LOG_DATA_LEN_L];
    end
    else
    begin
        output_valid_r = data_valid_w;
        output_data_r  = data_data_w;

        if (data_valid_w)
        begin
            if (output_count_r > 16'd4)
                output_count_r = output_count_r - 16'd4;
            else
                output_count_r = 16'd0;
        end
    end
end

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
begin
    output_valid_q <= 1'b0;
    output_data_q  <= 32'b0;
    output_count_q <= 16'b0;
end
else if (!output_valid_q || outport_tready_i)
begin
    output_valid_q <= output_valid_r;
    output_data_q  <= output_data_r;
    output_count_q <= output_count_r;
end


assign ctrl_pop_w = (output_count_q == 16'd0) ? outport_tready_i : 1'b0;
assign data_pop_w = (output_count_q != 16'd0) ? outport_tready_i : 1'b0;

assign outport_tvalid_o = output_valid_q;
assign outport_tdata_o  = output_data_q;
assign outport_tstrb_o  = 4'hF;
assign outport_tdest_o  = 4'b0;
assign outport_tlast_o  = 1'b0;

assign usb_buffer_current_addr_in_w = buffer_current_i;
assign buffer_base_o                = {usb_buffer_base_addr_out_w[31:2], 2'b0};
assign buffer_end_o                 = {usb_buffer_end_addr_out_w[31:2], 2'b0};
assign buffer_reset_o               = !cfg_enabled_w;
assign usb_buffer_sts_wrapped_in_w  = buffer_wrapped_i;
assign buffer_cont_o                = usb_buffer_cfg_cont_out_w;


//-------------------------------------------------------------------
// Debug
//-------------------------------------------------------------------
`ifdef verilator
/* verilator lint_off WIDTH */
reg [79:0] dbg_pid;
reg [7:0]  dbg_pid_r;
always @ *
begin
    dbg_pid = "-";

    if (state_q == STATE_RX_IDLE && start_packet_w)
        dbg_pid_r = sample_data_w;
    else
        dbg_pid_r = 8'b0;

    case (dbg_pid_r)
    // Token
    `PID_OUT:
        dbg_pid = "OUT";
    `PID_IN:
        dbg_pid = "IN";
    `PID_SOF:
        dbg_pid = "SOF";
    `PID_SETUP:
        dbg_pid = "SETUP";
    `PID_PING:
        dbg_pid = "PING";
    // Data
    `PID_DATA0:
        dbg_pid = "DATA0";
    `PID_DATA1:
        dbg_pid = "DATA1";
    `PID_DATA2:
        dbg_pid = "DATA2";
    `PID_MDATA:
        dbg_pid = "MDATA";
    // Handshake
    `PID_ACK:
        dbg_pid = "ACK";
    `PID_NAK:
        dbg_pid = "NAK";
    `PID_STALL:
        dbg_pid = "STALL";
    `PID_NYET:
        dbg_pid = "NYET";
    // Special
    `PID_PRE:
        dbg_pid = "PRE/ERR";
    `PID_SPLIT:
        dbg_pid = "SPLIT";
    default:
        ;
    endcase
end
/* verilator lint_on WIDTH */
`endif

endmodule


module usb_sniffer_fifo
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  data_in_i
    ,input           push_i
    ,input           pop_i

    // Outputs
    ,output [ 31:0]  data_out_o
    ,output          accept_o
    ,output          valid_o
);



//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [8:0]   rd_ptr_q;
reg [8:0]   wr_ptr_q;

//-----------------------------------------------------------------
// Write Side
//-----------------------------------------------------------------
wire [8:0] write_next_w = wr_ptr_q + 9'd1;

wire full_w = (write_next_w == rd_ptr_q);

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wr_ptr_q <= 9'b0;
// Push
else if (push_i & !full_w)
    wr_ptr_q <= write_next_w;

//-----------------------------------------------------------------
// Read Side
//-----------------------------------------------------------------
wire read_ok_w = (wr_ptr_q != rd_ptr_q);
reg  rd_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    rd_q <= 1'b0;
else
    rd_q <= read_ok_w;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    rd_ptr_q     <= 9'b0;
// Read address increment
else if (read_ok_w && ((!valid_o) || (valid_o && pop_i)))
    rd_ptr_q <= rd_ptr_q + 9'd1;

//-------------------------------------------------------------------
// Read Skid Buffer
//-------------------------------------------------------------------
reg                rd_skid_q;
reg [31:0] rd_skid_data_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    rd_skid_q <= 1'b0;
    rd_skid_data_q <= 32'b0;
end
else if (valid_o && !pop_i)
begin
    rd_skid_q      <= 1'b1;
    rd_skid_data_q <= data_out_o;
end
else
begin
    rd_skid_q      <= 1'b0;
    rd_skid_data_q <= 32'b0;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
assign valid_o       = rd_skid_q | rd_q;
assign accept_o      = !full_w;

//-------------------------------------------------------------------
// Dual port RAM
//-------------------------------------------------------------------
wire [31:0] data_out_w;

usb_sniffer_fifo_dp_512_9
u_ram
(
    // Inputs
    .clk0_i(clk_i),
    .rst0_i(rst_i),
    .clk1_i(clk_i),
    .rst1_i(rst_i),

    // Write side
    .addr0_i(wr_ptr_q),
    .wr0_i(push_i & accept_o),
    .data0_i(data_in_i),
    .data0_o(),

    // Read side
    .addr1_i(rd_ptr_q),
    .data1_i(32'b0),
    .wr1_i(1'b0),
    .data1_o(data_out_w)
);

assign data_out_o = rd_skid_q ? rd_skid_data_q : data_out_w;

endmodule

//-------------------------------------------------------------------
// Dual port RAM
//-------------------------------------------------------------------
module usb_sniffer_fifo_dp_512_9
(
    // Inputs
     input           clk0_i
    ,input           rst0_i
    ,input  [ 8:0]  addr0_i
    ,input  [ 31:0]  data0_i
    ,input           wr0_i
    ,input           clk1_i
    ,input           rst1_i
    ,input  [ 8:0]  addr1_i
    ,input  [ 31:0]  data1_i
    ,input           wr1_i

    // Outputs
    ,output [ 31:0]  data0_o
    ,output [ 31:0]  data1_o
);

/* verilator lint_off MULTIDRIVEN */
reg [31:0]   ram [511:0] /*verilator public*/;
/* verilator lint_on MULTIDRIVEN */

reg [31:0] ram_read0_q;
reg [31:0] ram_read1_q;

// Synchronous write
always @ (posedge clk0_i)
begin
    if (wr0_i)
        ram[addr0_i] <= data0_i;

    ram_read0_q <= ram[addr0_i];
end

always @ (posedge clk1_i)
begin
    if (wr1_i)
        ram[addr1_i] <= data1_i;

    ram_read1_q <= ram[addr1_i];
end

assign data0_o = ram_read0_q;
assign data1_o = ram_read1_q;



endmodule
