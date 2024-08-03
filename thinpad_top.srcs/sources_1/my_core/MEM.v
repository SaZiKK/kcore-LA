module MEM(
    input  wire         clk,
    input  wire         rst,
    output wire         stall_current_stage,
    input  wire         stall_next_stage,

    input  wire [31: 0] data_ram_vaddr,
    input  wire [31: 0] data_ram_wdata,
    input  wire [ 3: 0] data_ram_be,
    input  wire         data_ram_ce,
    input  wire         data_ram_oe,
    input  wire         data_ram_we,

    input  wire [ 4: 0] reg_waddr,
    input  wire         reg_we,
    input  wire [31: 0] alu_result,

    output wire [31: 0] data_ram_vaddr_out,
    output wire [31: 0] data_ram_wdata_out,
    output wire [ 3: 0] data_ram_be_out,
    output wire         data_ram_ce_out,
    output wire         data_ram_oe_out,
    output wire         data_ram_we_out,

    output wire [31: 0] data_ram_vaddr_v,
    output wire [31: 0] data_ram_wdata_v,
    output wire [ 3: 0] data_ram_be_v,
    output wire         data_ram_ce_v,
    output wire         data_ram_oe_v,
    output wire         data_ram_we_v,

    input  wire [31: 0] data_ram_rdata,
    output wire [31: 0] data_ram_rdata_out,

    output wire [ 4: 0] reg_waddr_out,
    output wire         reg_we_out,
    output wire [31: 0] alu_result_out
);

    assign stall_current_stage = 1'b0; // 访存流水不停

    // 不做处理
    assign data_ram_vaddr_v  = data_ram_vaddr;
    assign data_ram_wdata_v  = data_ram_wdata;
    assign data_ram_be_v     = data_ram_be;
    assign data_ram_ce_v     = data_ram_ce;
    assign data_ram_oe_v     = data_ram_oe;
    assign data_ram_we_v     = data_ram_we;

    MEMWB MEMWB(
        .clk                 ( clk                 ),
        .rst                 ( rst                 ),
        .stall_current_stage ( stall_current_stage ),
        .stall_next_stage    ( stall_next_stage    ),

        .reg_waddr_in        ( reg_waddr           ),
        .reg_we_in           ( reg_we              ),
        .result_in           ( alu_result          ),

        .data_ram_vaddr_in   ( data_ram_vaddr_v    ),
        .data_ram_wdata_in   ( data_ram_wdata_v    ),
        .data_ram_be_in      ( data_ram_be_v       ),
        .data_ram_ce_in      ( data_ram_ce_v       ),
        .data_ram_oe_in      ( data_ram_oe_v       ),
        .data_ram_we_in      ( data_ram_we_v       ),

        .data_ram_vaddr_out  ( data_ram_vaddr_out  ),
        .data_ram_wdata_out  ( data_ram_wdata_out  ),
        .data_ram_be_out     ( data_ram_be_out     ),
        .data_ram_ce_out     ( data_ram_ce_out     ),
        .data_ram_oe_out     ( data_ram_oe_out     ),
        .data_ram_we_out     ( data_ram_we_out     ),

        .reg_waddr_out       ( reg_waddr_out       ),
        .reg_we_out          ( reg_we_out          ),
        .result_out          ( alu_result_out      ),
        
        .data_ram_rdata_in   ( data_ram_rdata      ),
        .data_ram_rdata_out  ( data_ram_rdata_out  )
    );

    
endmodule