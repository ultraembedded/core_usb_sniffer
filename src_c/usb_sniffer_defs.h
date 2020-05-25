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
#ifndef __USB_SNIFFER_STREAM_DEFS_H__
#define __USB_SNIFFER_STREAM_DEFS_H__

#define USB_BUFFER_CFG    0x0
    #define USB_BUFFER_CFG_CONT                  31
    #define USB_BUFFER_CFG_CONT_SHIFT            31
    #define USB_BUFFER_CFG_CONT_MASK             0x1

    #define USB_BUFFER_CFG_DEV_SHIFT             24
    #define USB_BUFFER_CFG_DEV_MASK              0x7f

    #define USB_BUFFER_CFG_EP_SHIFT              16
    #define USB_BUFFER_CFG_EP_MASK               0xf

    #define USB_BUFFER_CFG_PHY_DMPULLDOWN        15
    #define USB_BUFFER_CFG_PHY_DMPULLDOWN_SHIFT  15
    #define USB_BUFFER_CFG_PHY_DMPULLDOWN_MASK   0x1

    #define USB_BUFFER_CFG_PHY_DPPULLDOWN        14
    #define USB_BUFFER_CFG_PHY_DPPULLDOWN_SHIFT  14
    #define USB_BUFFER_CFG_PHY_DPPULLDOWN_MASK   0x1

    #define USB_BUFFER_CFG_PHY_TERMSELECT        13
    #define USB_BUFFER_CFG_PHY_TERMSELECT_SHIFT  13
    #define USB_BUFFER_CFG_PHY_TERMSELECT_MASK   0x1

    #define USB_BUFFER_CFG_PHY_XCVRSELECT_SHIFT  11
    #define USB_BUFFER_CFG_PHY_XCVRSELECT_MASK   0x3

    #define USB_BUFFER_CFG_PHY_OPMODE_SHIFT      9
    #define USB_BUFFER_CFG_PHY_OPMODE_MASK       0x3

    #define USB_BUFFER_CFG_SPEED_SHIFT           7
    #define USB_BUFFER_CFG_SPEED_MASK            0x3

    #define USB_BUFFER_CFG_EXCLUDE_EP            6
    #define USB_BUFFER_CFG_EXCLUDE_EP_SHIFT      6
    #define USB_BUFFER_CFG_EXCLUDE_EP_MASK       0x1

    #define USB_BUFFER_CFG_MATCH_EP              5
    #define USB_BUFFER_CFG_MATCH_EP_SHIFT        5
    #define USB_BUFFER_CFG_MATCH_EP_MASK         0x1

    #define USB_BUFFER_CFG_EXCLUDE_DEV           4
    #define USB_BUFFER_CFG_EXCLUDE_DEV_SHIFT     4
    #define USB_BUFFER_CFG_EXCLUDE_DEV_MASK      0x1

    #define USB_BUFFER_CFG_MATCH_DEV             3
    #define USB_BUFFER_CFG_MATCH_DEV_SHIFT       3
    #define USB_BUFFER_CFG_MATCH_DEV_MASK        0x1

    #define USB_BUFFER_CFG_IGNORE_SOF            2
    #define USB_BUFFER_CFG_IGNORE_SOF_SHIFT      2
    #define USB_BUFFER_CFG_IGNORE_SOF_MASK       0x1

    #define USB_BUFFER_CFG_IGNORE_IN_NAK         1
    #define USB_BUFFER_CFG_IGNORE_IN_NAK_SHIFT   1
    #define USB_BUFFER_CFG_IGNORE_IN_NAK_MASK    0x1

    #define USB_BUFFER_CFG_ENABLED               0
    #define USB_BUFFER_CFG_ENABLED_SHIFT         0
    #define USB_BUFFER_CFG_ENABLED_MASK          0x1

#define USB_BUFFER_STS    0x4
    #define USB_BUFFER_STS_DATA_LOSS             2
    #define USB_BUFFER_STS_DATA_LOSS_SHIFT       2
    #define USB_BUFFER_STS_DATA_LOSS_MASK        0x1

    #define USB_BUFFER_STS_WRAPPED               1
    #define USB_BUFFER_STS_WRAPPED_SHIFT         1
    #define USB_BUFFER_STS_WRAPPED_MASK          0x1

    #define USB_BUFFER_STS_TRIG                  0
    #define USB_BUFFER_STS_TRIG_SHIFT            0
    #define USB_BUFFER_STS_TRIG_MASK             0x1

#define USB_BUFFER_BASE   0x8
    #define USB_BUFFER_BASE_ADDR_SHIFT           0
    #define USB_BUFFER_BASE_ADDR_MASK            0xffffffff

#define USB_BUFFER_END    0xc
    #define USB_BUFFER_END_ADDR_SHIFT            0
    #define USB_BUFFER_END_ADDR_MASK             0xffffffff

#define USB_BUFFER_CURRENT  0x10
    #define USB_BUFFER_CURRENT_ADDR_SHIFT        0
    #define USB_BUFFER_CURRENT_ADDR_MASK         0xffffffff

#endif