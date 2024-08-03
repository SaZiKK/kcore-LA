module EX (
    input  wire         clk,
    input  wire         rst,
    output  wire         stall_current_stage,
    input  wire         stall_next_stage,

    input  wire [31: 0] alu_src1,
    input  wire [31: 0] alu_src2,
    input  wire [11: 0] alu_op,

    output wire [31: 0] alu_result_out,

    input  wire [31: 0] data_ram_wdata,
    input  wire [ 3: 0] data_ram_be,
    input  wire         data_ram_ce,
    input  wire         data_ram_oe,
    input  wire         data_ram_we,

    input  wire [ 4: 0] reg_waddr,
    input  wire         reg_we,

    output wire [31: 0] data_ram_vaddr_out,
    output wire [31: 0] data_ram_wdata_out,
    output wire [ 3: 0] data_ram_be_out,
    output wire         data_ram_ce_out,
    output wire         data_ram_oe_out,
    output wire         data_ram_we_out,

    output wire [ 4: 0] reg_waddr_out,
    output wire         reg_we_out,

    output wire [31: 0] alu_result

);

    assign stall_current_stage = 1'b0; // EX不停

    alu alu(
        .alu_op     ( alu_op         ),
        .alu_src1   ( alu_src1       ),
        .alu_src2   ( alu_src2       ),
        .alu_result ( alu_result )
    );

    assign data_ram_vaddr = alu_result;

    EXMEM EXMEM(
        .clk                 ( clk                 ),
        .rst                 ( rst                 ),
        .stall_current_stage ( stall_current_stage ),
        .stall_next_stage    ( stall_next_stage    ),

        .alu_result_in       ( alu_result          ),
        .data_ram_vaddr_in   ( data_ram_vaddr      ),
        .data_ram_wdata_in   ( data_ram_wdata      ),
        .data_ram_be_in      ( data_ram_be         ),
        .data_ram_ce_in      ( data_ram_ce         ),
        .data_ram_oe_in      ( data_ram_oe         ),
        .data_ram_we_in      ( data_ram_we         ),
        .reg_waddr_in        ( reg_waddr           ),
        .reg_we_in           ( reg_we              ),

        .alu_result_out      ( alu_result_out      ),
        .data_ram_vaddr_out  ( data_ram_vaddr_out  ),
        .data_ram_wdata_out  ( data_ram_wdata_out  ),
        .data_ram_be_out     ( data_ram_be_out     ),
        .data_ram_ce_out     ( data_ram_ce_out     ),
        .data_ram_oe_out     ( data_ram_oe_out     ),
        .data_ram_we_out     ( data_ram_we_out     ),
        .reg_waddr_out       ( reg_waddr_out       ),
        .reg_we_out          ( reg_we_out          )
    );
endmodule