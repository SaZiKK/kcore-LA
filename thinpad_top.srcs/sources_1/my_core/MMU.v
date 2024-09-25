module MMU(
    // from cpu
    input  wire [31: 0] inst_ram_vaddr, 
    output wire [31: 0] inst_ram_rdata,

    input  wire [31: 0] data_ram_vaddr, 
    output wire [31: 0] data_ram_rdata,
    input  wire [31: 0] data_ram_wdata,
    input  wire [ 3: 0] data_ram_be,
    input  wire         data_ram_ce,
    input  wire         data_ram_oe,
    input  wire         data_ram_we,

    // direct interface to top module
    inout  wire [31: 0] base_ram_data, // only input
    output wire [19: 0] base_ram_addr,
    output wire [ 3: 0] base_ram_be_n,
    output wire         base_ram_ce_n,
    output wire         base_ram_oe_n,
    output wire         base_ram_we_n,

    inout  wire [31: 0] ext_ram_data, // input and output
    output wire [19: 0] ext_ram_addr,
    output wire [ 3: 0] ext_ram_be_n,
    output wire         ext_ram_ce_n,
    output wire         ext_ram_oe_n,
    output wire         ext_ram_we_n
);

    wire [19: 0] inst_ram_paddr;
    wire [19: 0] data_ram_paddr;

    // 按字长寻址，字长32位，2^2*8 = 32，忽略低两位地址
    // 直接映射，va = pa
    assign inst_ram_paddr = inst_ram_vaddr[21: 2];
    assign data_ram_paddr = data_ram_vaddr[21: 2];

    assign base_ram_addr  = inst_ram_paddr;
    assign ext_ram_addr   = data_ram_paddr;

    // inst
    assign inst_ram_rdata = base_ram_data; // 暂时认为base只读

    assign base_ram_data = 32'bz;

    // data
    assign data_ram_rdata = ext_ram_data;

    assign ext_ram_data = data_ram_ce & data_ram_we ? data_ram_wdata : 32'bz;

    // control enable
    assign base_ram_be_n = 4'b0; 
    assign base_ram_ce_n = 1'b0;
    assign base_ram_oe_n = 1'b0;
    assign base_ram_we_n = 1'b1;

    assign ext_ram_be_n = ~data_ram_be;
    assign ext_ram_ce_n = ~data_ram_ce;
    assign ext_ram_oe_n = ~data_ram_oe;
    assign ext_ram_we_n = ~data_ram_we;

endmodule