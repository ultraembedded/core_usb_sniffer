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
`define USB_BUFFER_CFG    8'h0

    `define USB_BUFFER_CFG_CONT      31
    `define USB_BUFFER_CFG_CONT_DEFAULT    0
    `define USB_BUFFER_CFG_CONT_B          31
    `define USB_BUFFER_CFG_CONT_T          31
    `define USB_BUFFER_CFG_CONT_W          1
    `define USB_BUFFER_CFG_CONT_R          31:31

    `define USB_BUFFER_CFG_DEV_DEFAULT    0
    `define USB_BUFFER_CFG_DEV_B          24
    `define USB_BUFFER_CFG_DEV_T          30
    `define USB_BUFFER_CFG_DEV_W          7
    `define USB_BUFFER_CFG_DEV_R          30:24

    `define USB_BUFFER_CFG_EP_DEFAULT    0
    `define USB_BUFFER_CFG_EP_B          16
    `define USB_BUFFER_CFG_EP_T          19
    `define USB_BUFFER_CFG_EP_W          4
    `define USB_BUFFER_CFG_EP_R          19:16

    `define USB_BUFFER_CFG_PHY_DMPULLDOWN      15
    `define USB_BUFFER_CFG_PHY_DMPULLDOWN_DEFAULT    0
    `define USB_BUFFER_CFG_PHY_DMPULLDOWN_B          15
    `define USB_BUFFER_CFG_PHY_DMPULLDOWN_T          15
    `define USB_BUFFER_CFG_PHY_DMPULLDOWN_W          1
    `define USB_BUFFER_CFG_PHY_DMPULLDOWN_R          15:15

    `define USB_BUFFER_CFG_PHY_DPPULLDOWN      14
    `define USB_BUFFER_CFG_PHY_DPPULLDOWN_DEFAULT    0
    `define USB_BUFFER_CFG_PHY_DPPULLDOWN_B          14
    `define USB_BUFFER_CFG_PHY_DPPULLDOWN_T          14
    `define USB_BUFFER_CFG_PHY_DPPULLDOWN_W          1
    `define USB_BUFFER_CFG_PHY_DPPULLDOWN_R          14:14

    `define USB_BUFFER_CFG_PHY_TERMSELECT      13
    `define USB_BUFFER_CFG_PHY_TERMSELECT_DEFAULT    0
    `define USB_BUFFER_CFG_PHY_TERMSELECT_B          13
    `define USB_BUFFER_CFG_PHY_TERMSELECT_T          13
    `define USB_BUFFER_CFG_PHY_TERMSELECT_W          1
    `define USB_BUFFER_CFG_PHY_TERMSELECT_R          13:13

    `define USB_BUFFER_CFG_PHY_XCVRSELECT_DEFAULT    0
    `define USB_BUFFER_CFG_PHY_XCVRSELECT_B          11
    `define USB_BUFFER_CFG_PHY_XCVRSELECT_T          12
    `define USB_BUFFER_CFG_PHY_XCVRSELECT_W          2
    `define USB_BUFFER_CFG_PHY_XCVRSELECT_R          12:11

    `define USB_BUFFER_CFG_PHY_OPMODE_DEFAULT    0
    `define USB_BUFFER_CFG_PHY_OPMODE_B          9
    `define USB_BUFFER_CFG_PHY_OPMODE_T          10
    `define USB_BUFFER_CFG_PHY_OPMODE_W          2
    `define USB_BUFFER_CFG_PHY_OPMODE_R          10:9

    `define USB_BUFFER_CFG_SPEED_DEFAULT    0
    `define USB_BUFFER_CFG_SPEED_B          7
    `define USB_BUFFER_CFG_SPEED_T          8
    `define USB_BUFFER_CFG_SPEED_W          2
    `define USB_BUFFER_CFG_SPEED_R          8:7

    `define USB_BUFFER_CFG_EXCLUDE_EP      6
    `define USB_BUFFER_CFG_EXCLUDE_EP_DEFAULT    0
    `define USB_BUFFER_CFG_EXCLUDE_EP_B          6
    `define USB_BUFFER_CFG_EXCLUDE_EP_T          6
    `define USB_BUFFER_CFG_EXCLUDE_EP_W          1
    `define USB_BUFFER_CFG_EXCLUDE_EP_R          6:6

    `define USB_BUFFER_CFG_MATCH_EP      5
    `define USB_BUFFER_CFG_MATCH_EP_DEFAULT    0
    `define USB_BUFFER_CFG_MATCH_EP_B          5
    `define USB_BUFFER_CFG_MATCH_EP_T          5
    `define USB_BUFFER_CFG_MATCH_EP_W          1
    `define USB_BUFFER_CFG_MATCH_EP_R          5:5

    `define USB_BUFFER_CFG_EXCLUDE_DEV      4
    `define USB_BUFFER_CFG_EXCLUDE_DEV_DEFAULT    0
    `define USB_BUFFER_CFG_EXCLUDE_DEV_B          4
    `define USB_BUFFER_CFG_EXCLUDE_DEV_T          4
    `define USB_BUFFER_CFG_EXCLUDE_DEV_W          1
    `define USB_BUFFER_CFG_EXCLUDE_DEV_R          4:4

    `define USB_BUFFER_CFG_MATCH_DEV      3
    `define USB_BUFFER_CFG_MATCH_DEV_DEFAULT    0
    `define USB_BUFFER_CFG_MATCH_DEV_B          3
    `define USB_BUFFER_CFG_MATCH_DEV_T          3
    `define USB_BUFFER_CFG_MATCH_DEV_W          1
    `define USB_BUFFER_CFG_MATCH_DEV_R          3:3

    `define USB_BUFFER_CFG_IGNORE_SOF      2
    `define USB_BUFFER_CFG_IGNORE_SOF_DEFAULT    0
    `define USB_BUFFER_CFG_IGNORE_SOF_B          2
    `define USB_BUFFER_CFG_IGNORE_SOF_T          2
    `define USB_BUFFER_CFG_IGNORE_SOF_W          1
    `define USB_BUFFER_CFG_IGNORE_SOF_R          2:2

    `define USB_BUFFER_CFG_IGNORE_IN_NAK      1
    `define USB_BUFFER_CFG_IGNORE_IN_NAK_DEFAULT    0
    `define USB_BUFFER_CFG_IGNORE_IN_NAK_B          1
    `define USB_BUFFER_CFG_IGNORE_IN_NAK_T          1
    `define USB_BUFFER_CFG_IGNORE_IN_NAK_W          1
    `define USB_BUFFER_CFG_IGNORE_IN_NAK_R          1:1

    `define USB_BUFFER_CFG_ENABLED      0
    `define USB_BUFFER_CFG_ENABLED_DEFAULT    0
    `define USB_BUFFER_CFG_ENABLED_B          0
    `define USB_BUFFER_CFG_ENABLED_T          0
    `define USB_BUFFER_CFG_ENABLED_W          1
    `define USB_BUFFER_CFG_ENABLED_R          0:0

`define USB_BUFFER_STS    8'h4

    `define USB_BUFFER_STS_DATA_LOSS      2
    `define USB_BUFFER_STS_DATA_LOSS_DEFAULT    0
    `define USB_BUFFER_STS_DATA_LOSS_B          2
    `define USB_BUFFER_STS_DATA_LOSS_T          2
    `define USB_BUFFER_STS_DATA_LOSS_W          1
    `define USB_BUFFER_STS_DATA_LOSS_R          2:2

    `define USB_BUFFER_STS_WRAPPED      1
    `define USB_BUFFER_STS_WRAPPED_DEFAULT    0
    `define USB_BUFFER_STS_WRAPPED_B          1
    `define USB_BUFFER_STS_WRAPPED_T          1
    `define USB_BUFFER_STS_WRAPPED_W          1
    `define USB_BUFFER_STS_WRAPPED_R          1:1

    `define USB_BUFFER_STS_TRIG      0
    `define USB_BUFFER_STS_TRIG_DEFAULT    0
    `define USB_BUFFER_STS_TRIG_B          0
    `define USB_BUFFER_STS_TRIG_T          0
    `define USB_BUFFER_STS_TRIG_W          1
    `define USB_BUFFER_STS_TRIG_R          0:0

`define USB_BUFFER_BASE    8'h8

    `define USB_BUFFER_BASE_ADDR_DEFAULT    0
    `define USB_BUFFER_BASE_ADDR_B          0
    `define USB_BUFFER_BASE_ADDR_T          31
    `define USB_BUFFER_BASE_ADDR_W          32
    `define USB_BUFFER_BASE_ADDR_R          31:0

`define USB_BUFFER_END    8'hc

    `define USB_BUFFER_END_ADDR_DEFAULT    0
    `define USB_BUFFER_END_ADDR_B          0
    `define USB_BUFFER_END_ADDR_T          31
    `define USB_BUFFER_END_ADDR_W          32
    `define USB_BUFFER_END_ADDR_R          31:0

`define USB_BUFFER_CURRENT    8'h10

    `define USB_BUFFER_CURRENT_ADDR_DEFAULT    0
    `define USB_BUFFER_CURRENT_ADDR_B          0
    `define USB_BUFFER_CURRENT_ADDR_T          31
    `define USB_BUFFER_CURRENT_ADDR_W          32
    `define USB_BUFFER_CURRENT_ADDR_R          31:0

