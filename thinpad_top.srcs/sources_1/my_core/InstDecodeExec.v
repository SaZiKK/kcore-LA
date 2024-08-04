module IDEX(
    input  wire         clk,
    input  wire         rst,
    input  wire         stall_current_stage,
    input  wire         stall_next_stage,

    input  wire [31: 0] pc_in,
    input  wire [31: 0] alu_src1_in,
    input  wire [31: 0] alu_src2_in,
    input  wire [12: 0] alu_op_in,
    input  wire [ 4: 0] rf_waddr_in,
    input  wire         rf_we_in,

    input  wire [31: 0] data_ram_wdata_in,
    input  wire [ 3: 0] data_ram_be_in,
    input  wire         data_ram_ce_in,
    input  wire         data_ram_oe_in,
    input  wire         data_ram_we_in,

    output wire [31: 0] pc_out,
    output wire [31: 0] alu_src1_out,
    output wire [31: 0] alu_src2_out,
    output wire [12: 0] alu_op_out,
    output wire [ 4: 0] rf_waddr_out,
    output wire         rf_we_out,

    output wire [31: 0] data_ram_wdata_out,
    output wire [ 3: 0] data_ram_be_out,
    output wire         data_ram_ce_out,
    output wire         data_ram_oe_out,
    output wire         data_ram_we_out
);

    PipelineCtrl #(32) pc_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        pc_in, pc_out
    );

    PipelineCtrl #(32) operand1_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        alu_src1_in, alu_src1_out
    );

    PipelineCtrl #(32) operand2_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        alu_src2_in, alu_src2_out
    );

    PipelineCtrl #(13) alu_op_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        alu_op_in, alu_op_out
    );

    PipelineCtrl #(5) reg_waddr_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        rf_waddr_in, rf_waddr_out
    );

    PipelineCtrl #(1) reg_we_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        rf_we_in, rf_we_out
    );

    PipelineCtrl #(32) data_ram_wdata_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_wdata_in, data_ram_wdata_out
    );

        PipelineCtrl #(4) data_ram_be_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_be_in, data_ram_be_out
    );

        PipelineCtrl #(1) data_ram_ce_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_ce_in, data_ram_ce_out
    );

        PipelineCtrl #(1) data_ram_oe_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_oe_in, data_ram_oe_out
    );

        PipelineCtrl #(1) data_ram_we_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_we_in, data_ram_we_out
    );


endmodule