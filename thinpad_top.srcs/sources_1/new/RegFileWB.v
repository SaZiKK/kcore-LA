module WB(
    input  wire [ 4: 0] reg_waddr      ,
    input  wire         reg_we         ,
    input  wire [31: 0] result         ,
    input  wire [31: 0] mem_result     ,
    input  wire         mem_oe         ,
    input  wire         mem_ce         ,

    output wire [ 4: 0] reg_waddr_out  ,
    output wire [31: 0] reg_wdata_out  ,
    output wire         reg_we_out     
);

    assign reg_we_out = reg_we;
    assign reg_waddr_out = reg_waddr;
    assign reg_wdata_out = mem_oe & mem_ce ? mem_result : result;


endmodule