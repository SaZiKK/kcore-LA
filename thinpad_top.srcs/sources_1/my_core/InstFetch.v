module IF(
    input  wire         clk,
    input  wire         rst,
    input  wire         branch_flag,
    input  wire [31: 0] branch_addr,
    input  wire         stall_next_stage,
    output reg  [31: 0] pc,
    output wire [31: 0] inst_addr,
    input  wire [31: 0] inst,
    output reg  [31: 0] inst_out
);
    reg  [31: 0] nextpc;

    assign inst_addr = pc;

    always @(*)begin
        if(branch_flag & ~stall_next_stage)
            nextpc = branch_addr;
        else if(~stall_next_stage)         // 下一级流水线不需要暂停，PC+4
            nextpc = pc + 'd4;
        else 
            nextpc = pc;                   // 下一级流水线需要暂停，PC不变
    end

    // 复位时，PC初始化为0x8000_0000
    // 非复位时，PC更新为nextpc

    always @(posedge clk ) begin
        if(rst)
            pc <= 32'h8000_0000;
        else 
            pc <= nextpc;
    end

    // 复位时，inst_out初始化为0
    // 非复位时，inst_out更新为inst

    always @(posedge clk ) begin
        if(rst)
            inst_out <= 0;
        else if (branch_flag | stall_next_stage)
            inst_out <= 32'h00000000; // nop
        else
            inst_out <= inst;
    end



endmodule