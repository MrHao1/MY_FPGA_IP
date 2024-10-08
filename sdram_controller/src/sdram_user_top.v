`include "timescale.v"

module  sdram_user_top(
    //系统信号
    input                       clk                     ,//系统时钟
    input                       rst_n                   ,//复位信号，低电平有效

    //SDRAM硬件接口
//  output                      sdram_clk               ,//SDRAM时钟信号
    output                      sdram_cke               ,//SDRAM时钟有效信号
    output                      sdram_cs_n              ,//SDRAM片选信号
    output                      sdram_ras_n             ,//SDRAM行地址选通脉冲
    output                      sdram_cas_n             ,//SDRAM列地址选通脉冲
    output                      sdram_we_n              ,//SDRAM写允许位
    output          [10:0]      sdram_addr              ,//SDRAM地址总线
    output          [1:0]       sdram_ba                ,//SDRAM的L-Bank地址线
    inout           [31:0]      sdram_data              ,//SDRAM数据总线
    output          [3:0]       sdram_dqm               ,//SDRAM低字节屏蔽

    //SDRAM状态信号
    output                      sdram_init_done         ,//SDRAM初始化完毕信号
    output                      sdram_busy              ,//SDRAM 忙标志

    //用户接口, 优先级ch1_w > ch1_r > ch2_w > ch2_r > ch3_w > ch3_r
    input                       ch1_w_clk               ,//写时钟
    input                       ch1_w_fi_en             ,//写fifo使能, 电平有效
    input           [31:0]      ch1_w_data              ,//写入的数据
    input                       ch1_w_dr_en             ,//写dram使能, 电平有效, 应答后可拉低
    input           [20:0]      ch1_w_addr              ,//写地址
    input           [8:0]       ch1_w_number            ,//写入的数量
    output                      ch1_w_ack               ,//命令接收应答 边沿有效
    output                      ch1_w_done              ,//写完成 边沿有效

    input                       ch1_r_clk               ,//读时钟
    input                       ch1_r_fo_en             ,//读fifo使能
    output          [31:0]      ch1_r_data              ,//读出的数据
    input                       ch1_r_dr_en             ,//读dram使能
    input           [20:0]      ch1_r_addr              ,//读地址
    input           [8:0]       ch1_r_number            ,//读出的数量
    output                      ch1_r_ack               ,//命令接收应答 边沿有效
    output                      ch1_r_done              ,//读完成 边沿有效

    input                       ch2_w_clk               ,//写时钟
    input                       ch2_w_fi_en             ,//写fifo使能
    input           [31:0]      ch2_w_data              ,//写入的数据
    input                       ch2_w_dr_en             ,//写dram使能
    input           [20:0]      ch2_w_addr              ,//写地址
    input           [8:0]       ch2_w_number            ,//写入的数量
    output                      ch2_w_ack               ,//命令接收应答 边沿有效
    output                      ch2_w_done              ,//写完成 边沿有效

    input                       ch2_r_clk               ,//读时钟
    input                       ch2_r_fo_en             ,//读fifo使能
    output          [31:0]      ch2_r_data              ,//读出的数据
    input                       ch2_r_dr_en             ,//读dram使能
    input           [20:0]      ch2_r_addr              ,//读地址
    input           [8:0]       ch2_r_number            ,//读出的数量
    output                      ch2_r_ack               ,//命令接收应答 边沿有效
    output                      ch2_r_done              ,//读完成 边沿有效

    input                       ch3_w_clk               ,//写时钟
    input                       ch3_w_fi_en             ,//写fifo使能
    input           [31:0]      ch3_w_data              ,//写入的数据
    input                       ch3_w_dr_en             ,//写dram使能
    input           [20:0]      ch3_w_addr              ,//写地址
    input           [8:0]       ch3_w_number            ,//写入的数量
    output                      ch3_w_ack               ,//命令接收应答 边沿有效
    output                      ch3_w_done              ,//写完成 边沿有效

    input                       ch3_r_clk               ,//读时钟
    input                       ch3_r_fo_en             ,//读fifo使能
    output          [31:0]      ch3_r_data              ,//读出的数据
    input                       ch3_r_dr_en             ,//读dram使能
    input           [20:0]      ch3_r_addr              ,//读地址
    input           [8:0]       ch3_r_number            ,//读出的数量
    output                      ch3_r_ack               ,//命令接收应答 边沿有效
    output                      ch3_r_done               //读完成 边沿有效
);

wire                sdram_wr_req ;
wire                sdram_wr_ack ;
wire    [20:0]      sdram_wr_addr;
wire    [8:0]       sdram_wr_byte;
wire    [31:0]      sdram_wr_data;

wire                sdram_rd_req ;
wire                sdram_rd_ack ;
wire    [20:0]      sdram_rd_addr;
wire    [8:0]       sdram_rd_byte;
wire    [31:0]      sdram_rd_data;

sdram_phy u_sdram_phy(
    .clk                (clk                    ),//i 时钟
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .sdram_wr_req       (sdram_wr_req           ),//i 写请求, 边沿触发, 优先级高于读
    .sdram_wr_ack       (sdram_wr_ack           ),//o 写响应,作为wrFIFO的输出有效信号
    .sys_wraddr         (sdram_wr_addr[20:0]    ),//i 写地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    .sdwr_byte          (sdram_wr_byte[8:0]     ),//i 突发写字节数（1-256个）
    .sys_data_in        (sdram_wr_data[31:0]    ),//i 写数据

    .sdram_rd_req       (sdram_rd_req           ),//i 读请求, 边沿触发
    .sdram_rd_ack       (sdram_rd_ack           ),//o 读响应
    .sys_rdaddr         (sdram_rd_addr[20:0]    ),//i 读地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    .sdrd_byte          (sdram_rd_byte[8:0]     ),//i 突发读字节数（1-256个）
    .sys_data_out       (sdram_rd_data[31:0]    ),//o 读数据

    .sdram_busy         (sdram_busy             ),//o SDRAM忙标志
    .sdram_init_done    (sdram_init_done        ),//o SDRAM初始化完毕信号

    .sdram_cke          (sdram_cke              ),//o SDRAM时钟有效信号
    .sdram_cs_n         (sdram_cs_n             ),//o SDRAM片选信号
    .sdram_ras_n        (sdram_ras_n            ),//o SDRAM行地址选通脉冲
    .sdram_cas_n        (sdram_cas_n            ),//o SDRAM列地址选通脉冲
    .sdram_we_n         (sdram_we_n             ),//o SDRAM写允许位
    .sdram_addr         (sdram_addr[10:0]       ),//o SDRAM地址总线
    .sdram_ba           (sdram_ba[1:0]          ),//o SDRAM的L-Bank地址线
    .sdram_data         (sdram_data[31:0]       ),//i SDRAM数据总线
    .sdram_dqm          (sdram_dqm[3:0]         ) //o SDRAM低字节屏蔽
);

sdram_user_ctrl u_sdram_user_ctrl(
    .clk                (clk                    ),//i 时钟
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .sdram_wr_req       (sdram_wr_req           ),//o 写请求, 边沿触发, 优先级高于读
    .sdram_wr_ack       (sdram_wr_ack           ),//i 写响应,作为wrFIFO的输出有效信号
    .sdram_wr_addr      (sdram_wr_addr[20:0]    ),//o 写地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    .sdram_wr_byte      (sdram_wr_byte[8:0]     ),//o 突发写字节数（1-256个）
    .sdram_wr_data      (sdram_wr_data[31:0]    ),//o 写数据

    .sdram_rd_req       (sdram_rd_req           ),//o 读请求, 边沿触发
    .sdram_rd_ack       (sdram_rd_ack           ),//i 读响应
    .sdram_rd_addr      (sdram_rd_addr[20:0]    ),//o 读地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    .sdram_rd_byte      (sdram_rd_byte[8:0]     ),//o 突发读字节数（1-256个）
    .sdram_rd_data      (sdram_rd_data[31:0]    ),//i 读数据

    .sdram_init_done    (sdram_init_done        ),//o SDRAM初始化完毕信号

    .ch1_w_clk          (ch1_w_clk              ),//i 写时钟
    .ch1_w_addr         (ch1_w_addr[20:0]       ),//i 写地址
    .ch1_w_number       (ch1_w_number[8:0]      ),//i 写入的数量
    .ch1_w_data         (ch1_w_data[31:0]       ),//i 写入的数据
    .ch1_w_fi_en        (ch1_w_fi_en            ),//i 写fifo使能
    .ch1_w_dr_en        (ch1_w_dr_en            ),//i 写dram使能
    .ch1_w_ack          (ch1_w_ack              ),//o 开始写应答
    .ch1_w_done         (ch1_w_done             ),//o 写完成

    .ch1_r_clk          (ch1_r_clk              ),//i 读时钟
    .ch1_r_addr         (ch1_r_addr[20:0]       ),//i 读地址
    .ch1_r_number       (ch1_r_number[8:0]      ),//i 读出的数量
    .ch1_r_data         (ch1_r_data[31:0]       ),//o 读出的数据
    .ch1_r_fo_en        (ch1_r_fo_en            ),//i 读fifo使能
    .ch1_r_dr_en        (ch1_r_dr_en            ),//i 读dram使能
    .ch1_r_ack          (ch1_r_ack              ),//o 读应答, 表示已开始传输数据
    .ch1_r_done         (ch1_r_done             ),//o 读完成

    .ch2_w_clk          (ch2_w_clk              ),//i 写时钟
    .ch2_w_addr         (ch2_w_addr  [20:0]     ),//i 写地址
    .ch2_w_number       (ch2_w_number[8:0]      ),//i 写入的数量
    .ch2_w_data         (ch2_w_data  [31:0]     ),//i 写入的数据
    .ch2_w_fi_en        (ch2_w_fi_en            ),//i 写fifo使能
    .ch2_w_dr_en        (ch2_w_dr_en            ),//i 写dram使能
    .ch2_w_ack          (ch2_w_ack              ),//o 开始写应答
    .ch2_w_done         (ch2_w_done             ),//o 写完成

    .ch2_r_clk          (ch2_r_clk              ),//i 读时钟
    .ch2_r_addr         (ch2_r_addr[20:0]       ),//i 读地址
    .ch2_r_number       (ch2_r_number[8:0]      ),//i 读出的数量
    .ch2_r_data         (ch2_r_data[31:0]       ),//o 读出的数据
    .ch2_r_fo_en        (ch2_r_fo_en            ),//i 读fifo使能
    .ch2_r_dr_en        (ch2_r_dr_en            ),//i 读dram使能
    .ch2_r_ack          (ch2_r_ack              ),//o 读应答, 表示已开始传输数据
    .ch2_r_done         (ch2_r_done             ),//o 读完成

    .ch3_w_clk          (ch3_w_clk              ),//i 写时钟
    .ch3_w_addr         (ch3_w_addr  [20:0]     ),//i 写地址
    .ch3_w_number       (ch3_w_number[8:0]      ),//i 写入的数量
    .ch3_w_data         (ch3_w_data  [31:0]     ),//i 写入的数据
    .ch3_w_fi_en        (ch3_w_fi_en            ),//i 写fifo使能
    .ch3_w_dr_en        (ch3_w_dr_en            ),//i 写dram使能
    .ch3_w_ack          (ch3_w_ack              ),//o 开始写应答
    .ch3_w_done         (ch3_w_done             ),//o 写完成

    .ch3_r_clk          (ch3_r_clk              ),//i 读时钟
    .ch3_r_addr         (ch3_r_addr[20:0]       ),//i 读地址
    .ch3_r_number       (ch3_r_number[8:0]      ),//i 读出的数量
    .ch3_r_data         (ch3_r_data[31:0]       ),//o 读出的数据
    .ch3_r_fo_en        (ch3_r_fo_en            ),//i 读fifo使能
    .ch3_r_dr_en        (ch3_r_dr_en            ),//i 读dram使能
    .ch3_r_ack          (ch3_r_ack              ),//o 读应答, 表示已开始传输数据
    .ch3_r_done         (ch3_r_done             ) //o 读完成
);

endmodule