module ID(
    input wire clk,
    input wire rst,
    output wire         stall_current_stage,
    input  wire         stall_next_stage,

    input wire [31: 0] pc,
    input wire [31: 0] inst,

    output wire         branch_flag,
    output wire [31: 0] branch_addr,

    output wire [31: 0] alu_src1_out,
    output wire [31: 0] alu_src2_out,
    output wire [ 5: 0] alu_op_out,

    output wire [ 4: 0] reg_raddr1,
    input wire  [31: 0] reg_rdata1,

    output wire [ 4: 0] reg_raddr2,
    input wire  [31: 0] reg_rdata2,

    output wire [ 4: 0] reg_waddr_out,
    output wire         reg_we_out,

    output wire [31: 0] pc_out,

    output wire [31: 0] data_ram_wdata_out,
    output wire [ 3: 0] data_ram_be_out,
    output wire         data_ram_ce_out,
    output wire         data_ram_oe_out,
    output wire         data_ram_we_out
);

// Loong Arch Instruction Set
//              31                                                        10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// |  2R-type   |                   opcode                                  |   rj(5)   |   rd(5)   |
// +------------+-----------------------------------------------------------------------------------+
//              31                                            15 14       10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// |  3R-type   |                   opcode                      |    rk(5)  |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                                20 19       15 14       10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// |  4R-type   |         opcode                    |    ra(5)  |    rk(5)  |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                                    18 17               10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// | 2RI8-type  |         opcode                        |        I8         |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                         22 21                          10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// | 2RI12-type |        opcode              |              I12             |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                     24 23                              10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// | 2RI14-type |      opcode            |                I14               |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                 26 25                                  10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// | 2RI16-type |      opcode        |                 I16                  |   rj(5)   |   rd(5)   |
// +------------------------------------------------------------------------------------------------+
//              31                 26 25                                  10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// | 1RI21-type |  opcode            |            I21[15:0]                 |   rj(5)   | I21[20:16]|
// +------------------------------------------------------------------------------------------------+
//              31                 26 25                                  10 9         5 4          0
// +------------+-----------------------------------------------------------------------------------+
// |  I26-type  |  opcode            |            I26[15:0]                 |      I26[25:16]       |
// +------------------------------------------------------------------------------------------------+




/* =========== Define signals =========== */

    wire [ 5: 0] opcode;
    wire [ 5: 0] op_31_26;
    wire [ 3: 0] op_25_22;
    wire [ 1: 0] op_21_20;
    wire [ 4: 0] op_19_15;

    // one hot code of instructions
    wire [63: 0] op_31_26_d;
    wire [15: 0] op_25_22_d;
    wire [ 3: 0] op_21_20_d;
    wire [31: 0] op_19_15_d;


    // all instructions
    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_sltu;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_or;
    wire        inst_xor;
    wire        inst_slli_w;
    wire        inst_srli_w;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_w;
    wire        inst_st_w;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_lu12i_w;


    // register file signals
    wire [ 4: 0] rd;
    wire [ 4: 0] rj;
    wire [ 4: 0] rk;

    // immediate nums 
    wire [31: 0] imm; // 32-bit immediate num, directly for alu
    wire [11: 0] i12;
    wire [19: 0] i20;
    wire [15: 0] i16;
    wire [25: 0] i26;

    // immediate num flags
    wire         need_ui5;
    wire         need_si12;
    wire         need_si16;
    wire         need_si20;
    wire         need_si26;
    wire         src2_is_4;

    // alu control signals
    wire [ 5: 0] alu_op;

    // alu 
    wire [31: 0] alu_src1   ;
    wire [31: 0] alu_src2   ;

    // reg file write
    wire [ 4: 0] rf_raddr1;
    wire [31: 0] rf_rdata1;
    wire [ 4: 0] rf_raddr2;
    wire [31: 0] rf_rdata2;
    wire         rf_we   ;
    wire [ 4: 0] rf_waddr;
    wire [31: 0] rf_wdata;

    // other flags
    wire         src1_is_pc;
    wire         src2_is_imm;
    wire         src_reg_is_rd;
    wire         dst_is_r1;
    wire         gr_we;           // general register write enable
    wire         mem_we;          // memory write enable
    wire         mem_re;          // memory read enable
    wire         res_from_mem;

    //offsets
    wire [31: 0] br_offs;
    wire [31: 0] jirl_offs;

    wire [4: 0] dest;
    wire [31:0] rj_value;
    wire [31:0] rkd_value;


/* =========== connect signals =========== */    

    assign stall_current_stage = 0; //todo 流水暂时不停

    // load msg from inst
    assign op_31_26 = inst[31:26];
    assign op_25_22 = inst[25:22];
    assign op_21_20 = inst[21:20];
    assign op_19_15 = inst[19:15];

    assign opcode   = op_31_26;

    assign rd   = inst[ 4: 0];
    assign rj   = inst[ 9: 5];
    assign rk   = inst[14:10];

    assign i12  = inst[21:10];
    assign i20  = inst[24: 5];
    assign i16  = inst[25:10];
    assign i26  = {inst[ 9: 0], inst[25:10]};

    // instruction decode ( op -> one hot code )
    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    // instruction decode ( op -> specifc inst )
    assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_jirl   = op_31_26_d[6'h13];
    assign inst_b      = op_31_26_d[6'h14];
    assign inst_bl     = op_31_26_d[6'h15];
    assign inst_beq    = op_31_26_d[6'h16];
    assign inst_bne    = op_31_26_d[6'h17];
    assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst[25];

    // identify different alu operations for each instruction
    assign alu_op[ 0] = inst_add_w  |
                        inst_addi_w |
                        inst_ld_w   |
                        inst_st_w   |
                        inst_jirl   |
                        inst_bl;
    assign alu_op[ 1] = inst_sub_w;
    assign alu_op[ 2] = inst_slt;
    assign alu_op[ 3] = inst_sltu;
    assign alu_op[ 4] = inst_and;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or;
    assign alu_op[ 7] = inst_xor;
    assign alu_op[ 8] = inst_slli_w;
    assign alu_op[ 9] = inst_srli_w;
    assign alu_op[10] = inst_srai_w;
    assign alu_op[11] = inst_lu12i_w;

    // identify different immediate num needs for each instruction
    assign need_ui5   =  inst_slli_w |
                         inst_srli_w |
                         inst_srai_w;
    assign need_si12  =  inst_addi_w |
                         inst_ld_w   |
                         inst_st_w;
    assign need_si16  =  inst_jirl   |
                         inst_beq    |
                         inst_bne;
    assign need_si20  =  inst_lu12i_w;
    assign need_si26  =  inst_b      |
                         inst_bl;
    assign src2_is_4  =  inst_jirl   |
                         inst_bl;

    // immediate num assign
    assign imm = src2_is_4 ? 32'h4                      : // todo add more flags
                 need_si20 ? {i20[19:0], 12'b0}         :
/*need_ui5 || need_si12*/    {{20{i12[11]}}, i12[11:0]} ;

    // count offsets
    assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                                 {{14{i16[15]}}, i16[15:0], 2'b0} ;
    assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

    // assign flags
    assign src_reg_is_rd = inst_beq |
                           inst_bne |
                           inst_st_w;
    assign src1_is_pc    = inst_jirl |
                           inst_bl;
    assign src2_is_imm   = inst_slli_w |
                           inst_srli_w |
                           inst_srai_w |
                           inst_addi_w |
                           inst_ld_w   |
                           inst_st_w   |
                           inst_lu12i_w|
                           inst_jirl   |
                           inst_bl     ;
    assign dst_is_r1     = inst_bl;
    assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_bl;
    assign mem_we        = inst_st_w;           //需要写内存
    assign mem_re        = inst_ld_w;           //需要读内存
    assign dest          = dst_is_r1 ? 5'd1 : rd;

    // rf ctrl signals
    assign rf_raddr1 = rj;
    assign rf_raddr2 = src_reg_is_rd ? rd :rk;
    assign rf_we          = gr_we;
    assign rf_waddr       = dest;



    assign rj_value  = rf_rdata1; 
    assign rkd_value = rf_rdata2;

    assign rj_eq_rd = (rj_value == rkd_value);
    assign branch_flag = inst_beq  &&  rj_eq_rd
                      || inst_bne  && !rj_eq_rd
                      || inst_jirl
                      || inst_bl
                      || inst_b;
    assign branch_addr = (inst_beq || inst_bne || inst_bl || inst_b) ? (pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);
        
    assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
    assign alu_src2 = src2_is_imm ? imm : rkd_value;

    assign data_ram_be    = 4'b1111; // lw, st
    assign data_ram_ce    = 1'b1; //todo 暂时拉高，只选择ext_ram
    assign data_ram_oe    = mem_re;
    assign data_ram_we    = mem_we;
    assign data_ram_wdata = rkd_value;

    assign mem_result     = data_sram_rdata;

IDEX idex(
    .clk                 ( clk                 ),
    .rst                 ( rst                 ),
    .stall_current_stage ( stall_current_stage ),
    .stall_next_stage    ( stall_next_stage    ),
  
    .pc_in               ( pc                  ),
    .alu_src1_in         ( alu_src1            ),
    .alu_src2_in         ( alu_src2            ),
    .alu_op_in           ( alu_op              ),
    .rf_waddr_in         ( rf_waddr            ),
    .rf_we_in            ( rf_we               ),
  
    .data_ram_wdata_in   ( data_ram_wdata      ),
    .data_ram_be_in      ( data_ram_be         ),
    .data_ram_ce_in      ( data_ram_ce         ),
    .data_ram_oe_in      ( data_ram_oe         ),
    .data_ram_we_in      ( data_ram_we         ),
  
    .pc_out              ( pc_out              ),
    .alu_src1_out        ( alu_src1_out        ),
    .alu_src2_out        ( alu_src2_out        ),
    .alu_op_out          ( alu_op_out          ),
    .rf_waddr_out        ( rf_waddr_out        ),
    .rf_we_out           ( rf_we_out           ),
  
    .data_ram_wdata_out  ( data_ram_wdata_out  ),
    .data_ram_be_out     ( data_ram_be_out     ),
    .data_ram_ce_out     ( data_ram_ce_out     ),
    .data_ram_oe_out     ( data_ram_oe_out     ),
    .data_ram_we_out     ( data_ram_we_out     )
);

endmodule