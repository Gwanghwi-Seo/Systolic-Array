
`ifndef __SYSTOLIC_VH__
`define __SYSTOLIC_VH__

`define SIM // for simulation, comment out for synthesis (FPGA)
// `define VCS // fsdbDumpvars

// PE_ROW, PE_COL are must be the power of 2 for effecient logic synthesis.
`define PE_ROW                  8 // if set to 1, it causes a violation(`LOG2(`PE_ROW))
`define PE_COL                  8

`define PE_ROW_ID_WIDTH         $clog2(`PE_ROW)

`define OPC_NOP                 ('h0)
`define OPC_SET_PARAM           ('h1)
`define OPC_GET_PARAM           ('h2)
`define OPC_ST_SRAM             ('h3)
`define OPC_LD_SRAM             ('h4)
`define OPC_MATMUL              ('h5)

`define OPC_WIDTH               3
`define REQ_WIDTH               32

`define PARAM_WIDTH             16
`define PARAM_TRG_WIDTH         2
`define RSVD_SET_PARAM_WIDTH    (32 - `PARAM_WIDTH - `PARAM_TRG_WIDTH) // reserved for future use

`define DATA_WIDTH              8
`define ADDR_WIDTH              14
`define BANK_NUM_WIDTH          8 // max 256 banks (== 256 PE rows)
`define SRAM_TRG_WIDTH          2

`define PSUM_WIDTH              24

`define PARAM_OFFSET            (0)
`define PARAM_TRG_OFFSET        (`PARAM_WIDTH + `RSVD_SET_PARAM_WIDTH) // 14 is reserved for future use

`define PARAM_OFFSET            (0)
`define DATA_OFFSET             (0)
`define ADDR_OFFSET             (`DATA_WIDTH)
`define BANK_NUM_OFFSET         (`DATA_WIDTH + `ADDR_WIDTH)
`define SRAM_TRG_OFFSET         (`DATA_WIDTH + `ADDR_WIDTH + `BANK_NUM_WIDTH)

`define PARAM_M                 ('h0)
`define PARAM_N                 ('h1)
`define PARAM_K                 ('h2)

// Target SRAM
`define TRG_ISRAM               ('h0)
`define TRG_WSRAM               ('h1)
`define TRG_PSRAM               ('h2)

`endif // __SYSTOLIC_VH__