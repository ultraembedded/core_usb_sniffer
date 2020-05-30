#ifndef CAPTURE_BIN_H
#define CAPTURE_BIN_H

#include <stdint.h>
#include <stdlib.h>

//-----------------------------------------------------------------
// Defines:
//-----------------------------------------------------------------
// Tokens
#define PID_OUT                    0xE1
#define PID_IN                     0x69
#define PID_SOF                    0xA5
#define PID_SETUP                  0x2D
#define PID_PING                   0xB4

// Data
#define PID_DATA0                  0xC3
#define PID_DATA1                  0x4B
#define PID_DATA2                  0x87
#define PID_MDATA                  0x0F

// Handshake
#define PID_ACK                    0xD2
#define PID_NAK                    0x5A
#define PID_STALL                  0x1E
#define PID_NYET                   0x96

// Special
#define PID_PRE                    0x3C
#define PID_ERR                    0x3C
#define PID_SPLIT                  0x78

// Rounded up...
#define MAX_PACKET_SIZE            2048

//--------------------------------------------------------------------
// Enums
//--------------------------------------------------------------------
typedef enum
{
    USB_SPEED_HS,
    USB_SPEED_FS,
    USB_SPEED_LS,
    USB_SPEED_MANUAL,
} tUsbSpeed;

//---------------------------------------------------------------------
// capture_bin: Functions for processing binary capture format
//---------------------------------------------------------------------
class capture_bin
{
public:
    capture_bin()
    {
    }

    bool open(const char *filename, bool high_speed=true);

    virtual bool on_sof(uint16_t frame_num)                      { return true; }
    virtual bool on_rst(bool in_rst)                             { return true; }
    virtual bool on_token(uint8_t pid, uint8_t dev, uint8_t ep)  { return true; }
    virtual bool on_split(uint8_t hub_addr, bool complete)       { return true; }
    virtual bool on_handshake(uint8_t pid)                       { return true; }
    virtual bool on_data(uint8_t pid, uint8_t *data, int length) { return true; }

    // Functions to get more details about the current entry
    bool     is_high_speed(void) { return m_high_speed; }
    uint32_t get_raw_entry(void) { return m_raw; }
    uint64_t get_timestamp(void) { return m_timestamp + (uint32_t)(m_frame_time * 16.667); }

    // Class functions for decoding fields within capture binary format
    static uint8_t  get_pid(uint32_t value);
    static uint16_t get_cycle_delta(uint32_t value);
    static int      get_rst_state(uint32_t value);
    static uint8_t  get_token_device(uint32_t value);
    static uint8_t  get_token_endpoint(uint32_t value);
    static uint8_t  get_token_crc5(uint32_t value);
    static uint16_t get_data_length(uint32_t value);
    static uint16_t get_sof_frame(uint32_t value);
    static uint8_t  get_sof_crc5(uint32_t value);
    static uint8_t  get_split_hub_addr(uint32_t value);
    static uint8_t  get_split_complete(uint32_t value);

    // Misc
    static uint16_t calc_crc16(uint8_t *buffer, int len);
    static char*    get_pid_str(uint8_t pid);

protected:
    bool     m_high_speed;
    uint32_t m_raw;
    uint64_t m_timestamp;
    uint32_t m_frame_time;
};

#endif