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
        else if(~stall_next_stage)
            nextpc = pc + 'd4;
        else 
            nextpc = pc;
    end

    always @(posedge clk ) begin
        if(rst)
            pc <= 32'h8000_0000;
        else 
            pc <= nextpc;
    end

    always @(posedge clk ) begin
        if(rst)
            inst_out <= 0;
        else
            inst_out <= inst;
    end

endmodule