`default_nettype none

module thinpad_top(
    input  wire           clk_50M,           //50MHz 时钟输入
    input  wire           clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）
        
    input  wire           clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input  wire           reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire [ 3: 0]  touch_btn,         //BTN1~BTN4，按钮开关，按下时为1
    input  wire [31: 0]  dip_sw,            //32位拨码开关，拨到“ON”时为1
    output wire [15: 0]  leds,              //16位LED，输出时1点亮
    output wire [ 7: 0]  dpy0,              //数码管低位信号，包括小数点，输出1点亮
    output wire [ 7: 0]  dpy1,              //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout  wire [31: 0]  base_ram_data,     //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire [19: 0]  base_ram_addr,     //BaseRAM地址
    output wire [ 3: 0]  base_ram_be_n,     //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire          base_ram_ce_n,     //BaseRAM片选，低有效
    output wire          base_ram_oe_n,     //BaseRAM读使能，低有效
    output wire          base_ram_we_n,     //BaseRAM写使能，低有效

    //ExtRAM信号
    inout  wire [31: 0]  ext_ram_data,      //ExtRAM数据
    output wire [19: 0]  ext_ram_addr,      //ExtRAM地址
    output wire [ 3: 0]  ext_ram_be_n,      //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire          ext_ram_ce_n,      //ExtRAM片选，低有效
    output wire          ext_ram_oe_n,      //ExtRAM读使能，低有效
    output wire          ext_ram_we_n,      //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22: 0]  flash_a,           //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15: 0]  flash_d,           //Flash数据
    output wire          flash_rp_n,        //Flash复位信号，低有效
    output wire          flash_vpen,        //Flash写保护信号，低电平时不能擦除、烧写
    output wire          flash_ce_n,        //Flash片选信号，低有效
    output wire          flash_oe_n,        //Flash读使能信号，低有效
    output wire          flash_we_n,        //Flash写使能信号，低有效
    output wire          flash_byte_n,      //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire [ 2: 0] video_red,          //红色像素，3位
    output wire [ 2: 0] video_green,        //绿色像素，3位
    output wire [ 1: 0] video_blue,         //蓝色像素，2位
    output wire         video_hsync,        //行同步（水平同步）信号
    output wire         video_vsync,        //场同步（垂直同步）信号
    output wire         video_clk,          //像素时钟输出
    output wire         video_de            //行数据有效信号，用于区分消隐区
);

/* =========== Define signals =========== */

    wire         clk;

    // 虚拟cpu接口
    wire [31: 0] inst_ram_vaddr;
    wire [31: 0] inst_ram_rdata;
    wire [31: 0] data_ram_vaddr;
    wire [31: 0] data_ram_rdata;
    wire [31: 0] data_ram_wdata;
    wire [ 3: 0] data_ram_be;
    wire         data_ram_ce;
    wire         data_ram_oe;
    wire         data_ram_we;

    wire [31: 0] pc;
    wire [31: 0] reg_rdata1, reg_rdata2;
    wire [ 4: 0] reg_raddr1, reg_raddr2;

    wire         reg_we_wb;
    wire [ 4: 0] reg_waddr_wb;
    wire [31: 0] reg_wdata_wb;

    wire [ 4: 0] reg_waddr_id;
    wire         reg_we_id;

    wire [ 4: 0] reg_waddr_ex;
    wire         reg_we_ex;

    wire [ 4: 0] reg_waddr_mem;
    wire         reg_we_mem;

    wire [31: 0] alu_src1_id;
    wire [31: 0] alu_src2_id;
    wire [12: 0] alu_op_id;
    
    wire         branch_flag;
    wire [31: 0] branch_addr;

    wire [31: 0] result_ex;
    wire [31: 0] pc_id;

    // 译码流水
    wire [31: 0] data_ram_wdata_id;
    wire [ 3: 0] data_ram_be_id;
    wire         data_ram_ce_id;
    wire         data_ram_oe_id;
    wire         data_ram_we_id;

    // 执行流水
    wire [31: 0] data_ram_vaddr_ex;
    wire [31: 0] data_ram_wdata_ex;
    wire [ 3: 0] data_ram_be_ex;
    wire         data_ram_ce_ex;
    wire         data_ram_oe_ex;
    wire         data_ram_we_ex;

    // 访存流水
    wire [31: 0] data_ram_vaddr_mem;
    wire [31: 0] data_ram_wdata_mem;
    wire [ 3: 0] data_ram_be_mem;
    wire         data_ram_ce_mem;
    wire         data_ram_oe_mem;
    wire         data_ram_we_mem;

    // 流水控制线
    wire         stall_id;
    wire         stall_ex;
    wire         stall_mem;
    wire         stall_wb;

    wire [31: 0] result;
    wire [31: 0] result_mem;
    wire [31: 0] inst;
    wire [31: 0] data_ram_rdata_mem;

/* =========== connect signals =========== */

    assign clk = clk_11M0592;
    
    MMU mmu  (
        // virtual interface marked with "!" 
        .inst_ram_vaddr      ( inst_ram_vaddr     ),  // !input
        .inst_ram_rdata      ( inst_ram_rdata     ),  // !outpu

        .data_ram_vaddr      ( data_ram_vaddr     ),  // !input
        .data_ram_rdata      ( data_ram_rdata     ),  // !output
        .data_ram_wdata      ( data_ram_wdata     ),  // !input
        .data_ram_be         ( data_ram_be        ),  // !input
        .data_ram_ce         ( data_ram_ce        ),  // !input
        .data_ram_oe         ( data_ram_oe        ),  // !input
        .data_ram_we         ( data_ram_we        ),  // !input


        .base_ram_data       ( base_ram_data      ),  // inout  
        .base_ram_addr       ( base_ram_addr      ),  // output
        .base_ram_be_n       ( base_ram_be_n      ),  // output
        .base_ram_ce_n       ( base_ram_ce_n      ),  // output
        .base_ram_oe_n       ( base_ram_oe_n      ),  // output
        .base_ram_we_n       ( base_ram_we_n      ),  // output

        .ext_ram_data        ( ext_ram_data       ),  // inout
        .ext_ram_addr        ( ext_ram_addr       ),  // output
        .ext_ram_be_n        ( ext_ram_be_n       ),  // output
        .ext_ram_ce_n        ( ext_ram_ce_n       ),  // output
        .ext_ram_oe_n        ( ext_ram_oe_n       ),  // output
        .ext_ram_we_n        ( ext_ram_we_n       )   // output
    );   
    
    // 取址
    IF IF (   
        .clk                 ( clk                ),  // input
        .rst                 ( reset_btn          ),  // input
        .branch_flag         ( branch_flag        ),  // input 
        .branch_addr         ( branch_addr        ),  // input
        .stall_next_stage    ( stall_id           ),  // input
        .pc                  ( pc                 ),  // output
        .inst_addr           ( inst_ram_vaddr     ),  // output
        .inst                ( inst_ram_rdata     ),  // input
        .inst_out            ( inst               )   // output
    );   
   
   // 译码
    ID ID (   
        .clk                 ( clk                ),  // input
        .rst                 ( reset_btn          ),  // input
    
        .stall_current_stage ( stall_id           ),  // output
        .stall_next_stage    ( stall_mem          ),  // input
            
        .pc                  ( pc                 ),  // input
        .pc_out              ( pc_id              ),  // output
        .inst                ( inst               ),  // input
       
        .branch_flag         ( branch_flag        ),  // output
        .branch_addr         ( branch_addr        ),  // output
    
        .rf_rdata1           ( reg_rdata1         ),  // input
        .rf_rdata2           ( reg_rdata2         ),  // input
      
        .rf_raddr1           ( reg_raddr1         ),  // output
        .rf_raddr2           ( reg_raddr2         ),  // output
    
        .alu_src1_out        ( alu_src1_id        ),  // output
        .alu_src2_out        ( alu_src2_id        ),  // output
        .alu_op_out          ( alu_op_id          ),  // output

        .rf_wdata_ex         ( result            ),

        .rf_waddr_mem        ( reg_waddr_ex      ),
        .rf_we_mem           ( reg_we_ex         ),
        .rf_wdata_mem        ( result_ex         ),

        .rf_waddr_wb         ( reg_waddr_wb      ),
        .rf_we_wb            ( reg_we_wb         ),
        .rf_wdata_wb         ( reg_wdata_wb      ),

        .mem_load_ex         ( data_ram_oe_id    ),  // input
        .mem_load_mem        ( data_ram_oe_ex    ),  // input
    
        .rf_waddr_out        ( reg_waddr_id       ),  // output
        .rf_we_out           ( reg_we_id          ),  // output
 
        .data_ram_wdata_out  ( data_ram_wdata_id  ),  // output
        .data_ram_be_out     ( data_ram_be_id     ),  // output
        .data_ram_ce_out     ( data_ram_ce_id     ),  // output
        .data_ram_oe_out     ( data_ram_oe_id     ),  // output
        .data_ram_we_out     ( data_ram_we_id     )   // output
    );

    // 执行
    EX EX (   
        .clk                 ( clk                ),  // input
        .rst                 ( reset_btn          ),  // input
        .stall_current_stage ( stall_ex           ),  // output
        .stall_next_stage    ( stall_mem          ),  // input
    
        .alu_src1            ( alu_src1_id        ),  // input
        .alu_src2            ( alu_src2_id        ),  // input
        .alu_op              ( alu_op_id          ),  // input
        .alu_result          ( result             ),  // output
        .alu_result_out      ( result_ex          ),  // output
 
        .data_ram_wdata      ( data_ram_wdata_id  ),  // input
        .data_ram_be         ( data_ram_be_id     ),  // input
        .data_ram_ce         ( data_ram_ce_id     ),  // input
        .data_ram_oe         ( data_ram_oe_id     ),  // input
        .data_ram_we         ( data_ram_we_id     ),  // input
 
        .data_ram_vaddr_out  ( data_ram_vaddr_ex  ),  // output
        .data_ram_wdata_out  ( data_ram_wdata_ex  ),  // output
        .data_ram_be_out     ( data_ram_be_ex     ),  // output
        .data_ram_ce_out     ( data_ram_ce_ex     ),  // output
        .data_ram_oe_out     ( data_ram_oe_ex     ),  // output
        .data_ram_we_out     ( data_ram_we_ex     ),  // output
 
        .reg_waddr           ( reg_waddr_id       ),  // input
        .reg_we              ( reg_we_id          ),  // input
    
        .reg_waddr_out       ( reg_waddr_ex       ),  // output
        .reg_we_out          ( reg_we_ex          )  // output
   
    );

    // 访存
    MEM MEM (   
        .clk                 ( clk                ),  // input
        .rst                 ( reset_btn          ),  // input
        .stall_current_stage ( stall_mem          ),  // output
        .stall_next_stage    ( stall_wb           ),  // input

        .reg_waddr           ( reg_waddr_ex       ),  // input
        .reg_we              ( reg_we_ex          ),  // input
        .reg_waddr_out       ( reg_waddr_mem      ),  // output
        .reg_we_out          ( reg_we_mem         ),  // output

        .alu_result          ( result_ex          ),  // input
        .alu_result_out      ( result_mem         ),  // output

        .data_ram_vaddr      ( data_ram_vaddr_ex  ),  // input
        .data_ram_wdata      ( data_ram_wdata_ex  ),  // input
        .data_ram_be         ( data_ram_be_ex     ),  // input
        .data_ram_ce         ( data_ram_ce_ex     ),  // input
        .data_ram_oe         ( data_ram_oe_ex     ),  // input
        .data_ram_we         ( data_ram_we_ex     ),  // input
        
        .data_ram_vaddr_v    ( data_ram_vaddr     ),  // output
        .data_ram_wdata_v    ( data_ram_wdata     ),  // output
        .data_ram_be_v       ( data_ram_be        ),  // output
        .data_ram_ce_v       ( data_ram_ce        ),  // output
        .data_ram_oe_v       ( data_ram_oe        ),  // output
        .data_ram_we_v       ( data_ram_we        ),  // output
   
        .data_ram_rdata      ( data_ram_rdata     ),  // input
        .data_ram_rdata_out  ( data_ram_rdata_mem ),  // output
        .data_ram_vaddr_out  ( data_ram_vaddr_mem ),  // output
        .data_ram_wdata_out  ( data_ram_wdata_mem ),  // output
        .data_ram_be_out     ( data_ram_be_mem    ),  // output
        .data_ram_ce_out     ( data_ram_ce_mem    ),  // output
        .data_ram_oe_out     ( data_ram_oe_mem    ),  // output
        .data_ram_we_out     ( data_ram_we_mem    )   // output
    );

    // 写回
    RegFileWB WB (   

        .stall_current_stage ( stall_wb           ),  // output

        .alu_result          ( result_mem         ),  // input
        .mem_result          ( data_ram_rdata_mem ),  // input

        .mem_oe              ( data_ram_oe_mem    ),  // input
        .mem_ce              ( data_ram_ce_mem    ),  // input

        .reg_waddr           ( reg_waddr_mem      ),  // input
        .reg_we              ( reg_we_mem         ),  // input

        .reg_waddr_out       ( reg_waddr_wb       ),  // output
        .reg_we_out          ( reg_we_wb          ),  // output
        .reg_wdata_out       ( reg_wdata_wb       )   // output
    );

    RegFile RF (   

        .clk                 ( clk                ),  // input

        .raddr1              ( reg_raddr1         ),  // output
        .raddr2              ( reg_raddr2         ),  // output
        .rdata1              ( reg_rdata1         ),  // output
        .rdata2              ( reg_rdata2         ),  // output

        .we                  ( reg_we_wb          ),  // input
        .waddr               ( reg_waddr_wb       ),  // input
        .wdata               ( reg_wdata_wb       )   // input
    );


/* =========== Demo code begin =========== */

// PLL分频示例
    wire locked, clk_10M, clk_20M;
    pll_example clock_gen(
        // Clock in ports
        .clk_in1  ( clk_50M    ),  // 外部时钟输入
        // Clock out ports
        .clk_out1 ( clk_10M   ),   // 时钟输出1，频率在IP配置界面中设置
        .clk_out2 ( clk_20M   ),   // 时钟输出2，频率在IP配置界面中设置
        // Status and control signals
        .reset    ( reset_btn ),   // PLL复位输入
        .locked   ( locked    )    // PLL锁定指示输出，"1"表示时钟稳定，
                                // 后级电路复位信号应当由它生成（见下）
    );

reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED为初始值
        led_bits <= 16'h1;
    end
    else begin //每次按下时钟按钮，LED循环左移
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
assign number = ext_uart_buffer;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_50M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //将缓冲区ext_uart_buffer发送出去
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_50M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
