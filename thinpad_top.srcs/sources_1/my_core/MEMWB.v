module MEMWB(
    input  wire         clk,
    input  wire         rst,
    input  wire         stall_current_stage,
    input  wire         stall_next_stage,

    input  wire [ 4: 0] reg_waddr_in,
    input  wire         reg_we_in,
    input  wire [31: 0] result_in,

    input  wire [31: 0] data_ram_vaddr_in,
    input  wire [31: 0] data_ram_wdata_in,
    input  wire [ 3: 0] data_ram_be_in,
    input  wire         data_ram_ce_in,
    input  wire         data_ram_oe_in,
    input  wire         data_ram_we_in,

    output wire [31: 0] data_ram_vaddr_out,
    output wire [31: 0] data_ram_wdata_out,
    output wire [ 3: 0] data_ram_be_out,
    output wire         data_ram_ce_out,
    output wire         data_ram_oe_out,
    output wire         data_ram_we_out,

    output wire [ 4: 0] reg_waddr_out,
    output wire         reg_we_out,
    output wire [31: 0] result_out,

    input  wire [31: 0] data_ram_rdata_in,
    output wire [31: 0] data_ram_rdata_out
);

    PipelineCtrl #(5) reg_waddr_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        reg_waddr_in, reg_waddr_out
    );

    PipelineCtrl #(1) reg_we_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        reg_we_in, reg_we_out
    );

    PipelineCtrl #(32) result_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        result_in, result_out
    );

    PipelineCtrl #(32) data_ram_vaddr_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_vaddr_in, data_ram_vaddr_out
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

    PipelineCtrl #(32) data_ram_rdata_dff(
        clk, rst, stall_current_stage, stall_next_stage,
        data_ram_rdata_in, data_ram_rdata_out
    );

endmodule