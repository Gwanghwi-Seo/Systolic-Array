`ifndef __SYSTOLIC_VH__
`define __SYSTOLIC_VH__

// ISA v1

`define LOG2(x) (\
        (x <= 1)      ? 0 : \
        (x <= 2)      ? 1 : \
        (x <= 4)      ? 2 : \
        (x <= 8)      ? 3 : \
        (x <= 16)     ? 4 : \
        (x <= 32)     ? 5 : \
        (x <= 64)     ? 6 : \
        (x <= 128)    ? 7 : \
        (x <= 256)    ? 8 : \
        (x <= 512)    ? 9 : \
        (x <= 1024)   ? 10 : \
        (x <= 2048)   ? 11 : \
        (x <= 4096)   ? 12 : \
        (x <= 8192)   ? 13 : \
        (x <= 16384)  ? 14 : \
        (x <= 32768)  ? 15 : \
        (x <= 65536)  ? 16 : 0);

// PE_ROW, PE_COL are must be the power of 2 for effecient logic synthesis.
`define PE_ROW                  (8)
`define PE_COL                  (8)

`define ROW_ID_WIDTH            `LOG2(`PE_ROW)

`define OPC_NOP                 ('h0)
`define OPC_SET_PARAM           ('h1)
`define OPC_ST_SRAM             ('h2)
`define OPC_MATMUL              ('h3)
`define OPC_WB_PARAM            ('h4)
`define OPC_WB_PSRAM            ('h5)

`define OPC_WIDTH               (3)
`define REQ_WIDTH               (32)

`define PARAM_WIDTH             (16)
`define PARAM_TRG_WIDTH         (3)
`define RSVD_SET_PARAM_WIDTH    (32 - `PARAM_WIDTH - `PARAM_TRG_WIDTH) // reserved for future use

`define DATA_WIDTH              (8)
`define ADDR_WIDTH              (14)
`define BANK_NUM_WIDTH          (8) // max 256 banks (== 256 PE rows)
`define SRAM_TRG_WIDTH          (2)

`define PSUM_WIDTH              (24)

`define PARAM_OFFSET            (0)
`define PARAM_TRG_OFFSET        (`PARAM_WIDTH + `RSVD_SET_PARAM_WIDTH) // 14 is reserved for future use

`define PARAM_OFFSET            (0)
`define DATA_OFFSET             (0)
`define ADDR_OFFSET             (`DATA_WIDTH)
`define BANK_NUM_OFFSET         (`DATA_WIDTH + `ADDR_WIDTH + `PARAM_WIDTH)
`define SRAM_TRG_OFFSET         (`DATA_WIDTH + `ADDR_WIDTH + `PARAM_WIDTH + `BANK_NUM_WIDTH)

`define PARAM_S                 ('h0)
`define PARAM_IC                ('h1)
`define PARAM_OC                ('h2)
`define PARAM_ISRAM_BASE_ADDR   ('h3)
`define PARAM_WSRAM_BASE_ADDR   ('h4)
`define PARAM_PSRAM_BASE_ADDR   ('h5)

// PARAM
`define TRG_ISRAM               ('h0)
`define TRG_WSRAM               ('h1)
`define TRG_PSRAM               ('h2)

`endif // __SYSTOLIC_VH__