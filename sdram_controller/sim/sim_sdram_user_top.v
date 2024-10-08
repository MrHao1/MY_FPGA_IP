`include "timescale.v"
`include "sdram_para.v"

module sim_sdram_user_top(); 

reg     rst_n;
reg     clk_100m;
reg     clk_100m_d;
reg     ch1_w_clk;
reg     ch1_r_clk;

initial begin
        clk_100m    = 1'b0;
        clk_100m_d  = 1'b0;
        ch1_w_clk   = 1'b0;
        ch1_r_clk   = 1'b0;
        rst_n       = 1'b0;
    #50 rst_n       = 1'b1;
end

always begin
    #1  clk_100m = 1'b0;
    #1  clk_100m = 1'b0;
    #1  clk_100m = 1'b0;
    #1  clk_100m = 1'b0;
    #1  clk_100m = 1'b0;
    #1  clk_100m = 1'b1;
    #1  clk_100m = 1'b1;
    #1  clk_100m = 1'b1;
    #1  clk_100m = 1'b1;
    #1  clk_100m = 1'b1;
end

always begin
    #1  clk_100m_d = 1'b0;
    #1  clk_100m_d = 1'b0;
    #1  clk_100m_d = 1'b0;
    #1  clk_100m_d = 1'b0;
    #1  clk_100m_d = 1'b1;
    #1  clk_100m_d = 1'b1;
    #1  clk_100m_d = 1'b1;
    #1  clk_100m_d = 1'b1;
    #1  clk_100m_d = 1'b1;
    #1  clk_100m_d = 1'b0;
end

always begin
    #4  ch1_w_clk = ~ch1_w_clk;
end

always begin
    #6  ch1_r_clk = ~ch1_r_clk;
end



wire            sdram_busy;
wire            sdram_init_done;
reg     [31:0]  ch1_w_data;
reg             ch1_w_fi_en;
reg             ch1_w_dr_en;

//写入1到256
always@(posedge ch1_w_clk or negedge rst_n) begin
    if(!rst_n) begin
        ch1_w_data[31:0] <= #1 32'd0;
    end
    else if(ch1_w_data[31:0] < 32'd256) begin
        ch1_w_data[31:0] <= #1 ch1_w_data[31:0] + 32'd1;
    end
end

//写fifo使能
always@(posedge ch1_w_clk or negedge rst_n) begin
    if(!rst_n) begin
        ch1_w_fi_en <= #1 1'b0;
    end
    else if(ch1_w_data[31:0] < 32'd256) begin
        ch1_w_fi_en <= #1 1'b1;
    end
    else begin
        ch1_w_fi_en <= #1 1'b0;
    end
end

//写ram使能
reg  ch1_w_flag;
always@(posedge ch1_w_clk or negedge rst_n) begin
    if(!rst_n) begin
        ch1_w_dr_en <= #1 1'b0;
        ch1_w_flag <= #1 1'b0;
    end
    else if((ch1_w_data[31:0] == 32'd256) && (sdram_init_done == 1'b1) && (ch1_w_flag == 1'b0)) begin
        ch1_w_dr_en <= #1 1'b1;
        ch1_w_flag <= #1 1'b1;
    end
    else begin
        ch1_w_dr_en <= #1 1'b0;
        ch1_w_flag <= #1 ch1_w_flag;
    end
end

wire    [31:0]  dram_Dq   ;
wire    [10:0]  dram_Addr ;
wire    [1:0]   dram_Ba   ;
wire            dram_Cke  ;
wire            dram_Cs_n ;
wire            dram_Ras_n;
wire            dram_Cas_n;
wire            dram_We_n ;
wire    [3:0]   dram_Dqm  ;

sdram_user_top u_sdram_user_top(
    .clk                 (clk_100m          ),//系统时钟
    .rst_n               (rst_n             ),//复位信号，低电平有效

    .sdram_cke           (dram_Cke          ),//SDRAM时钟有效信号
    .sdram_cs_n          (dram_Cs_n         ),//SDRAM片选信号
    .sdram_ras_n         (dram_Ras_n        ),//SDRAM行地址选通脉冲
    .sdram_cas_n         (dram_Cas_n        ),//SDRAM列地址选通脉冲
    .sdram_we_n          (dram_We_n         ),//SDRAM写允许位
    .sdram_addr          (dram_Addr         ),//SDRAM地址总线
    .sdram_ba            (dram_Ba           ),//SDRAM的L-Bank地址线
    .sdram_data          (dram_Dq           ),//SDRAM数据总线
    .sdram_dqm           (dram_Dqm          ),//SDRAM低字节屏蔽

    //SDRAM状态信号
    .sdram_init_done     (sdram_init_done   ),//o系统初始化完毕信号
    .sdram_busy          (sdram_busy        ),//oSDRAM忙标志，高表示SDRAM处于工作中

    //用户接口, 优先级ch1_w > ch1_r > ch2_w > ch2_r > ch3_w > ch3_r
    .ch1_w_clk           (ch1_w_clk         ),//i 写时钟
    .ch1_w_addr          (21'd2             ),//i [20:0]写地址
    .ch1_w_number        (9'd256            ),//i [8:0] 写入的数量
    .ch1_w_data          (ch1_w_data[31:0]  ),//i [31:0]写入的数据
    .ch1_w_fi_en         (ch1_w_fi_en       ),//i 写fifo使能
    .ch1_w_dr_en         (ch1_w_dr_en       ),//i 写dram使能
    .ch1_w_ack           (),//o 开始写应答
    .ch1_w_done          (),//o 写完成

    .ch1_r_clk           (ch1_r_clk         ),//i 读时钟
    .ch1_r_addr          (21'd2            ),//i [20:0]读地址
    .ch1_r_number        (9'd255            ),//i [8:0] 读出的数量
    .ch1_r_data          (                  ),//o [31:0]读出的数据
    .ch1_r_fo_en         (1'b0              ),//i 读fifo使能
    .ch1_r_dr_en         (1'b1              ),//i 读dram使能
    .ch1_r_ack           (),//o 读应答, 表示已开始传输数据
    .ch1_r_done          (),//o 读完成

    .ch2_w_clk           (1'b0              ),//i 写时钟
    .ch2_w_addr          (21'h0             ),//i [20:0]写地址
    .ch2_w_number        (9'h0              ),//i [8:0] 写入的数量
    .ch2_w_data          (32'h0             ),//i [31:0]写入的数据
    .ch2_w_fi_en         (1'b0              ),//i 写fifo使能
    .ch2_w_dr_en         (1'b0              ),//i 写dram使能
    .ch2_w_ack           (),//o 开始写应答
    .ch2_w_done          (),//o 写完成

    .ch2_r_clk           (1'b0              ),//i 读时钟
    .ch2_r_addr          (21'h0             ),//i [20:0]读地址
    .ch2_r_number        (9'h0              ),//i [8:0] 读出的数量
    .ch2_r_data          (),//o [31:0]读出的数据
    .ch2_r_fo_en         (1'b0              ),//i 读fifo使能
    .ch2_r_dr_en         (1'b0              ),//i 读dram使能
    .ch2_r_ack           (),//o 读应答, 表示已开始传输数据
    .ch2_r_done          (),//o 读完成

    .ch3_w_clk           (1'b0              ),//i 写时钟
    .ch3_w_addr          (21'h0             ),//i [20:0]写地址
    .ch3_w_number        (9'h0              ),//i [8:0] 写入的数量
    .ch3_w_data          (32'h0             ),//i [31:0]写入的数据
    .ch3_w_fi_en         (1'b0              ),//i 写fifo使能
    .ch3_w_dr_en         (1'b0              ),//i 写dram使能
    .ch3_w_ack           (),//o 开始写应答
    .ch3_w_done          (),//o 写完成

    .ch3_r_clk           (1'b0              ),//i 读时钟
    .ch3_r_addr          (21'h0             ),//i [20:0]读地址
    .ch3_r_number        (9'h0              ),//i [8:0] 读出的数量
    .ch3_r_data          (),//o [31:0]读出的数据
    .ch3_r_fo_en         (1'b0              ),//i 读fifo使能
    .ch3_r_dr_en         (1'b0              ),//i 读dram使能
    .ch3_r_ack           (),//o 读应答, 表示已开始传输数据
    .ch3_r_done          () //o 读完成
);

IS42s32200 u_IS42s32200(
    .Dq                  (dram_Dq           ),// 32
    .Addr                (dram_Addr         ),// 11
    .Ba                  (dram_Ba           ),// 2
    .Clk                 (clk_100m_d        ),// 
    .Cke                 (dram_Cke          ),// 
    .Cs_n                (dram_Cs_n         ),// 
    .Ras_n               (dram_Ras_n        ),// 
    .Cas_n               (dram_Cas_n        ),// 
    .We_n                (dram_We_n         ),// 
    .Dqm                 (dram_Dqm          ) // 4
);

endmodule