`include "timescale.v"

module  sdram_user_ctrl(
    //系统信号
    input                       clk                     ,//控制器时钟, 与sdram频率一致
    input                       rst_n                   ,//全局复位

    //phy接口
    output  reg                 sdram_wr_req            ,//写请求, 边沿触发, 优先级高于读
    input                       sdram_wr_ack            ,//写响应,作为wrFIFO的输出有效信号
    output          [20:0]      sdram_wr_addr           ,//写地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    output          [8:0]       sdram_wr_byte           ,//突发写字节数（1-256个）
    output  reg     [31:0]      sdram_wr_data           ,//写数据

    output  reg                 sdram_rd_req            ,//读请求, 边沿触发
    input                       sdram_rd_ack            ,//读响应
    output          [20:0]      sdram_rd_addr           ,//读地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    output          [8:0]       sdram_rd_byte           ,//突发读字节数（1-256个）
    input           [31:0]      sdram_rd_data           ,//读数据

    input                       sdram_init_done         ,//初始化完成

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

/************************************************************
******严格优先级轮询仲裁器
************************************************************/
reg           trans_done;
reg     [5:0] arbiter_value;

reg     [5:0] request;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        request[5:0] <= #1 6'b00_0000;
    else if(state_ar_n[2:0] == ST_AR_DECD)  //对通信请求信号进行时钟同步并锁定状态
        request[5:0] <= #1 {ch3_r_dr_en, ch3_w_dr_en, ch2_r_dr_en, ch2_w_dr_en, ch1_r_dr_en, ch1_w_dr_en};
end

localparam [2:0] ST_AR_IDLE  = 4'd0;
localparam [2:0] ST_AR_DECD  = 4'd1;
localparam [2:0] ST_AR_DOIT  = 4'd2;

reg     [2:0]   state_ar_c;
reg     [2:0]   state_ar_n;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_ar_c[2:0] <= #1 ST_AR_IDLE;
    else
        state_ar_c[2:0] <= #1 state_ar_n[2:0];
end

always@(*) begin
    case(state_ar_c[2:0])
    ST_AR_IDLE : begin
                    if(sdram_init_done == 1'b1)
                        state_ar_n[2:0] = ST_AR_DECD;
                    else
                        state_ar_n[2:0] = ST_AR_IDLE;
                 end
    ST_AR_DECD : begin //申请
                    if(request[5:0] != 6'b00_0000)
                        state_ar_n[2:0] = ST_AR_DOIT;
                    else
                        state_ar_n[2:0] = ST_AR_DECD;
                 end
    ST_AR_DOIT : begin //传输完成, 由读写状态机反馈
                    if( trans_done == 1'b1 )
                        state_ar_n[2:0] = ST_AR_DECD;
                    else
                        state_ar_n[2:0] = ST_AR_DOIT;
                 end
    default :           state_ar_n[2:0] = ST_AR_IDLE;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        arbiter_value[5:0] <= #1 6'b00_0000;
    end
    else begin
        case(state_ar_n[2:0])
        ST_AR_IDLE :    arbiter_value[5:0] <= #1 6'b00_0000;
        ST_AR_DECD :    arbiter_value[5:0] <= #1 6'b00_0000;
        ST_AR_DOIT : begin
                        if(request[0] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b00_0001;
                        else if(request[1] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b00_0010;
                        else if(request[2] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b00_0100;
                        else if(request[3] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b00_1000;
                        else if(request[4] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b01_0000;
                        else if(request[5] == 1'b1)
                            arbiter_value[5:0] <= #1 6'b10_0000;
                     end
        default :       arbiter_value[5:0] <= #1 6'b00_0000;
        endcase
    end
end

/************************************************************
******读写状态机
************************************************************/
//地址  0   1    ...   255
//数量  256 255  ...   1
//地址+数量<=256不需要操作2次, >256需要操作2次
//        地址a,  数量n; 
//第一次, 地址a,   数量256-a
//第二次, 地址a+1, 数量n+a-256

//锁存写地址
reg     [20:0]  ch_w_addr_latch;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_w_addr_latch[20:0] <= #1 21'd0;
    else begin
        case(arbiter_value[5:0])
            6'b00_0001 :    ch_w_addr_latch[20:0] <= #1 ch1_w_addr[20:0];
            6'b00_0100 :    ch_w_addr_latch[20:0] <= #1 ch2_w_addr[20:0];
            6'b01_0000 :    ch_w_addr_latch[20:0] <= #1 ch3_w_addr[20:0];
            default    :    ch_w_addr_latch[20:0] <= #1 21'd0;
        endcase
    end
end

//第一次写地址
wire    [20:0]  ch_w_addr_1;
assign          ch_w_addr_1[20:0] = ch_w_addr_latch[20:0];

//第二次写地址
wire    [12:0]  w_addr_temp;
assign          w_addr_temp[12:0] = ch_w_addr_latch[20:8] + 13'd1;

reg     [20:0]  ch_w_addr_2;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_w_addr_2[20:0] <= #1 21'd0;
    else
        ch_w_addr_2[20:0] <= #1 {w_addr_temp[12:0], 8'h0};
end

//锁存写数量
reg     [8:0]   ch_w_number_latch;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_w_number_latch[8:0] <= #1 9'd0;
    else begin
        case(arbiter_value[5:0])
            6'b00_0001 :    ch_w_number_latch[8:0] <= #1 ch1_w_number[8:0];
            6'b00_0100 :    ch_w_number_latch[8:0] <= #1 ch2_w_number[8:0];
            6'b01_0000 :    ch_w_number_latch[8:0] <= #1 ch3_w_number[8:0];
            default    :    ch_w_number_latch[8:0] <= #1 9'd0;
        endcase
    end
end

//第一次写数量
reg     [8:0]   ch_w_number_1;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_w_number_1[8:0] <= #1 9'd0;
    else
        ch_w_number_1[8:0] <= #1 9'd256 - ch_w_addr_latch[7:0];
end

//第二次写数量
reg     [8:0]   ch_w_number_2;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_w_number_2[8:0] <= #1 9'd0;
    else
        ch_w_number_2[8:0] <= #1 ch_w_number_latch[8:0] + {1'h0, ch_w_addr_latch[7:0]} - 9'd256;
end

//锁存读地址
reg     [20:0]  ch_r_addr_latch;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_r_addr_latch[20:0] <= #1 21'd0;
    else begin
        case(arbiter_value[5:0])
            6'b00_0010 :    ch_r_addr_latch[20:0] <= #1 ch1_r_addr[20:0];
            6'b00_1000 :    ch_r_addr_latch[20:0] <= #1 ch2_r_addr[20:0];
            6'b10_0000 :    ch_r_addr_latch[20:0] <= #1 ch3_r_addr[20:0];
            default    :    ch_r_addr_latch[20:0] <= #1 21'd0;
        endcase
    end
end

//第一次读地址
wire    [20:0]  ch_r_addr_1;
assign          ch_r_addr_1[20:0] = ch_r_addr_latch[20:0];

//第二次读地址
wire    [12:0]  r_addr_temp;
assign          r_addr_temp[12:0] = ch_r_addr_latch[20:8] + 13'd1;

reg     [20:0]  ch_r_addr_2;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_r_addr_2[20:0] <= #1 21'd0;
    else
        ch_r_addr_2[20:0] <= #1 {r_addr_temp[12:0], 8'h0};
end

//锁存读数量
reg     [8:0]   ch_r_number_latch;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_r_number_latch[8:0] <= #1 9'd0;
    else begin
        case(arbiter_value[5:0])
            6'b00_0010 :    ch_r_number_latch[8:0] <= #1 ch1_r_number[8:0];
            6'b00_1000 :    ch_r_number_latch[8:0] <= #1 ch2_r_number[8:0];
            6'b10_0000 :    ch_r_number_latch[8:0] <= #1 ch3_r_number[8:0];
            default    :    ch_r_number_latch[8:0] <= #1 9'd0;
        endcase
    end
end

//第一次读数量
reg     [8:0]   ch_r_number_1;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_r_number_1[8:0] <= #1 9'd0;
    else
        ch_r_number_1[8:0] <= #1 9'd256 - ch_r_addr_latch[7:0];
end

//第二次读数量
reg     [8:0]   ch_r_number_2;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ch_r_number_2[8:0] <= #1 9'd0;
    else
        ch_r_number_2[8:0] <= #1 ch_r_number_latch[8:0] + {1'h0, ch_r_addr_latch[7:0]} - 9'd256;
end

//写次数检测
wire    [8:0]   w_detect;
assign          w_detect[8:0] = ch_w_number_latch[8:0] + ch_w_addr_latch[7:0];

wire            w_trans_twice;
assign          w_trans_twice = (w_detect[8:0] > 9'd256) ? 1'b1 : 1'b0;

//读次数检测
wire    [8:0]   r_detect;
assign          r_detect[8:0] = ch_r_number_latch[8:0] + ch_r_addr_latch[7:0];

wire            r_trans_twice;
assign          r_trans_twice = (r_detect[8:0] > 9'd256) ? 1'b1 : 1'b0;

//写通道配置
reg     [1:0]   ch_w_sel;

reg     [20:0]  w_addr;
always@(*) begin
    case(ch_w_sel[1:0])
        2'd1    : w_addr[20:0] = ch_w_addr_latch[20:0];
        2'd2    : w_addr[20:0] = ch_w_addr_1[20:0];
        2'd3    : w_addr[20:0] = ch_w_addr_2[20:0];
        default : w_addr[20:0] = 21'h0;
    endcase
end
assign          sdram_wr_addr[20:0] = w_addr[20:0];

reg     [8:0]   w_number;
always@(*) begin
    case(ch_w_sel[1:0])
        2'd1    : w_number[8:0] = ch_w_number_latch[8:0];
        2'd2    : w_number[8:0] = ch_w_number_1[8:0];
        2'd3    : w_number[8:0] = ch_w_number_2[8:0];
        default : w_number[8:0] = 9'h0;
    endcase
end
assign          sdram_wr_byte[8:0]  = w_number[8:0];

wire    [31:0]  ch1_w_fifo_data;
wire    [31:0]  ch2_w_fifo_data;
wire    [31:0]  ch3_w_fifo_data;
always@(*) begin
    case(arbiter_value[5:0])
        6'b00_0001 : sdram_wr_data[31:0] = ch1_w_fifo_data[31:0];
        6'b00_0100 : sdram_wr_data[31:0] = ch2_w_fifo_data[31:0];
        6'b01_0000 : sdram_wr_data[31:0] = ch3_w_fifo_data[31:0];
        default    : sdram_wr_data[31:0] = 32'h0;
    endcase
end

reg             ch1_w_fifo_en;
reg             ch2_w_fifo_en;
reg             ch3_w_fifo_en;
always@(*) begin
    case(arbiter_value[5:0])
        6'b00_0001 : begin
                        ch1_w_fifo_en = sdram_wr_ack;
                        ch2_w_fifo_en = 1'b0;
                        ch3_w_fifo_en = 1'b0;
                     end
        6'b00_0100 : begin
                        ch1_w_fifo_en = 1'b0;
                        ch2_w_fifo_en = sdram_wr_ack;
                        ch3_w_fifo_en = 1'b0;
                     end
        6'b01_0000 : begin
                        ch1_w_fifo_en = 1'b0;
                        ch2_w_fifo_en = 1'b0;
                        ch3_w_fifo_en = sdram_wr_ack;
                     end
        default    : begin
                        ch1_w_fifo_en = 1'b0;
                        ch2_w_fifo_en = 1'b0;
                        ch3_w_fifo_en = 1'b0;
                     end
    endcase
end


//读通道配置
reg     [1:0]   ch_r_sel;

reg     [20:0]  r_addr;
always@(*) begin
    case(ch_r_sel[1:0])
        2'd1    : r_addr[20:0] = ch_r_addr_latch[20:0];
        2'd2    : r_addr[20:0] = ch_r_addr_1[20:0];
        2'd3    : r_addr[20:0] = ch_r_addr_2[20:0];
        default : r_addr[20:0] = 21'h0;
    endcase
end
assign          sdram_rd_addr[20:0] = r_addr[20:0];

reg     [8:0]   r_number;
always@(*) begin
    case(ch_r_sel[1:0])
        2'd1    : r_number[8:0] = ch_r_number_latch[8:0];
        2'd2    : r_number[8:0] = ch_r_number_1[8:0];
        2'd3    : r_number[8:0] = ch_r_number_2[8:0];
        default : r_number[8:0] = 9'h0;
    endcase
end
assign          sdram_rd_byte[8:0]  = r_number[8:0];

reg     [31:0]  ch1_r_fifo_data;
reg     [31:0]  ch2_r_fifo_data;
reg     [31:0]  ch3_r_fifo_data;
always@(*) begin
    case(arbiter_value[5:0])
        6'b00_0010 : begin
                        ch1_r_fifo_data[31:0] = sdram_rd_data[31:0];
                        ch2_r_fifo_data[31:0] = 32'h0;
                        ch3_r_fifo_data[31:0] = 32'h0;
                     end
        6'b00_1000 : begin
                        ch1_r_fifo_data[31:0] = 32'h0;
                        ch2_r_fifo_data[31:0] = sdram_rd_data[31:0];
                        ch3_r_fifo_data[31:0] = 32'h0;
                     end
        6'b10_0000 : begin
                        ch1_r_fifo_data[31:0] = 32'h0;
                        ch2_r_fifo_data[31:0] = 32'h0;
                        ch3_r_fifo_data[31:0] = sdram_rd_data[31:0];
                     end
        default :    begin
                        ch1_r_fifo_data[31:0] = 32'h0;
                        ch2_r_fifo_data[31:0] = 32'h0;
                        ch3_r_fifo_data[31:0] = 32'h0;
                     end
    endcase
end

reg             ch1_r_fifo_en;
reg             ch2_r_fifo_en;
reg             ch3_r_fifo_en;
always@(*) begin
    case(arbiter_value[5:0])
        6'b00_0010 : begin
                        ch1_r_fifo_en = sdram_rd_ack;
                        ch2_r_fifo_en = 1'b0;
                        ch3_r_fifo_en = 1'b0;
                     end
        6'b00_1000 : begin
                        ch1_r_fifo_en = 1'b0;
                        ch2_r_fifo_en = sdram_rd_ack;
                        ch3_r_fifo_en = 1'b0;
                     end
        6'b10_0000 : begin
                        ch1_r_fifo_en = 1'b0;
                        ch2_r_fifo_en = 1'b0;
                        ch3_r_fifo_en = sdram_rd_ack;
                     end
        default    : begin
                        ch1_r_fifo_en = 1'b0;
                        ch2_r_fifo_en = 1'b0;
                        ch3_r_fifo_en = 1'b0;
                     end
    endcase
end

//读写状态标识
wire            write_req;
assign          write_req = arbiter_value[4] | arbiter_value[2] | arbiter_value[0];

wire            read_req;
assign          read_req  = arbiter_value[5] | arbiter_value[3] | arbiter_value[1];

//通信标识      
reg             phy_w_en;   //11 clk cycle min
reg             phy_r_en;   //13 clk cycle min

localparam [4:0] ST_IDLE  = 5'h0;
localparam [4:0] ST_SYNC  = 5'h1;
localparam [4:0] ST_W_SET = 5'h2;
localparam [4:0] ST_W_ADD = 5'h3;
localparam [4:0] ST_W_ENA = 5'h4;
localparam [4:0] ST_W_AK1 = 5'h5;
localparam [4:0] ST_W_DET = 5'h6;
localparam [4:0] ST_W_END = 5'h7;
localparam [4:0] ST_R_SET = 5'h8;
localparam [4:0] ST_R_ADD = 5'h9;
localparam [4:0] ST_R_ENA = 5'hA;
localparam [4:0] ST_R_AK1 = 5'hB;
localparam [4:0] ST_R_DET = 5'hC;
localparam [4:0] ST_R_END = 5'hD;

reg     [4:0]   state_rw_c;
reg     [4:0]   state_rw_n;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_rw_c[4:0] <= #1 ST_IDLE;
    else
        state_rw_c[4:0] <= #1 state_rw_n[4:0];
end

always@(*) begin
    case(state_rw_c[4:0])
        ST_IDLE  :  begin
                        if( (write_req == 1'b1) || (read_req == 1'b1) )
                            state_rw_n[4:0] = ST_SYNC;
                        else
                            state_rw_n[4:0] = ST_IDLE;
                    end
        ST_SYNC  :  begin
                        if( write_req == 1'b1 )
                            state_rw_n[4:0] = ST_W_SET;
                        else 
                            state_rw_n[4:0] = ST_R_SET;
                    end
        ST_W_SET :          state_rw_n[4:0] = ST_W_ADD;
        ST_W_ADD :          state_rw_n[4:0] = ST_W_ENA;
        ST_W_ENA :  begin
                        if( sdram_wr_ack == 1'b1 )
                            state_rw_n[4:0] = ST_W_AK1; //写使能
                        else
                            state_rw_n[4:0] = ST_W_ENA;
                    end
        ST_W_AK1 :  begin
                        if( sdram_wr_ack == 1'b0 )
                            state_rw_n[4:0] = ST_W_DET; //等待控制器应答
                        else
                            state_rw_n[4:0] = ST_W_AK1;
                    end
        ST_W_DET :  begin
                        if( w_trans_twice == 1'b0 )
                            state_rw_n[4:0] = ST_W_END; //等待传输完成结束
                        else if( ch_w_sel[1:0] == 2'd3 )
                            state_rw_n[4:0] = ST_W_END;
                        else
                            state_rw_n[4:0] = ST_W_ADD;
                    end
        ST_W_END :          state_rw_n[4:0] = ST_IDLE;
        ST_R_SET :          state_rw_n[4:0] = ST_R_ADD;
        ST_R_ADD :          state_rw_n[4:0] = ST_R_ENA;
        ST_R_ENA :  begin
                        if( sdram_rd_ack == 1'b1 )
                            state_rw_n[4:0] = ST_R_AK1; //读使能
                        else
                            state_rw_n[4:0] = ST_R_ENA;
                    end        
        ST_R_AK1 :  begin
                        if( sdram_rd_ack == 1'b0 )
                            state_rw_n[4:0] = ST_R_DET; //等待控制器应答
                        else
                            state_rw_n[4:0] = ST_R_AK1;
                    end
        ST_R_DET :  begin
                        if( r_trans_twice == 1'b0 )
                            state_rw_n[4:0] = ST_R_END; //等待传输完成结束
                        else if( ch_r_sel[1:0] == 2'd3 )
                            state_rw_n[4:0] = ST_R_END;
                        else
                            state_rw_n[4:0] = ST_R_ADD;
                    end
        ST_R_END :          state_rw_n[4:0] = ST_IDLE;
        default  :          state_rw_n[4:0] = ST_IDLE;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ch_w_sel[1:0] <= #1 2'd0;
        sdram_wr_req  <= #1 1'b0;
        phy_w_en      <= #1 1'b0;
        ch_r_sel[1:0] <= #1 2'd0;
        sdram_rd_req  <= #1 1'b0;
        phy_r_en      <= #1 1'b0;
        trans_done    <= #1 1'b0;
    end
    else begin
        case(state_rw_n[4:0])
        ST_W_SET :  begin
                        if( w_trans_twice == 1'b1 )
                            ch_w_sel[1:0] <= #1 2'd1;
                        else
                            ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b1;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;
                        phy_r_en      <= #1 1'b0;
                        trans_done    <= #1 1'b0;
                    end
        ST_W_ADD :  begin
                        ch_w_sel[1:0] <= #1 ch_w_sel[1:0] + 2'd1;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b1;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;   
                        phy_r_en      <= #1 1'b0;
                        trans_done    <= #1 1'b0;                 
                    end
        ST_W_ENA :  begin
                        ch_w_sel[1:0] <= #1 ch_w_sel[1:0];
                        sdram_wr_req  <= #1 1'b1;
                        phy_w_en      <= #1 1'b1;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;
                        phy_r_en      <= #1 1'b0;
                        trans_done    <= #1 1'b0;
                    end
        ST_W_AK1 , 
        ST_W_DET :  begin
                        ch_w_sel[1:0] <= #1 ch_w_sel[1:0];
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b1;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;   
                        phy_r_en      <= #1 1'b0; 
                        trans_done    <= #1 1'b0;                
                    end
        ST_W_END :  begin
                        ch_w_sel[1:0] <= #1 ch_w_sel[1:0];
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;   
                        phy_r_en      <= #1 1'b0; 
                        trans_done    <= #1 1'b1;                
                    end
        ST_R_SET :  begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        if( r_trans_twice == 1'b1 )
                            ch_r_sel[1:0] <= #1 2'd1;
                        else
                            ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;
                        phy_r_en      <= #1 1'b1;
                        trans_done    <= #1 1'b0;
                    end
        ST_R_ADD :  begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 ch_r_sel[1:0] + 2'd1;
                        sdram_rd_req  <= #1 1'b0;
                        phy_r_en      <= #1 1'b1;
                        trans_done    <= #1 1'b0;
                    end
        ST_R_ENA :  begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 ch_r_sel[1:0];
                        sdram_rd_req  <= #1 1'b1;   
                        phy_r_en      <= #1 1'b1;  
                        trans_done    <= #1 1'b0;               
                    end
        ST_R_AK1 ,  
        ST_R_DET :  begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 ch_r_sel[1:0];
                        sdram_rd_req  <= #1 1'b0;     
                        phy_r_en      <= #1 1'b1;  
                        trans_done    <= #1 1'b0;                                 
                    end
        ST_R_END :  begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 ch_r_sel[1:0];
                        sdram_rd_req  <= #1 1'b0;     
                        phy_r_en      <= #1 1'b0;  
                        trans_done    <= #1 1'b1;                                 
                    end
        default :   begin
                        ch_w_sel[1:0] <= #1 2'd0;
                        sdram_wr_req  <= #1 1'b0;
                        phy_w_en      <= #1 1'b0;
                        ch_r_sel[1:0] <= #1 2'd0;
                        sdram_rd_req  <= #1 1'b0;
                        phy_r_en      <= #1 1'b0;
                        trans_done    <= #1 1'b0;
                    end
        endcase
    end
end

/************************************************************
******fifo例化
************************************************************/
reg     [1:0]   ch1_w_en_d2;
always@(posedge ch1_w_clk or negedge rst_n) begin
    if(!rst_n)
        ch1_w_en_d2[1:0] <= #1 2'b00;
    else
        ch1_w_en_d2[1:0] <= #1 {ch1_w_en_d2[0], phy_w_en & arbiter_value[0]};
end
assign          ch1_w_ack  = ~ch1_w_en_d2[1] & ch1_w_en_d2[0];
assign          ch1_w_done = ch1_w_en_d2[1] & ~ch1_w_en_d2[0];

reg     [1:0]   ch2_w_en_d2;
always@(posedge ch2_w_clk or negedge rst_n) begin
    if(!rst_n)
        ch2_w_en_d2[1:0] <= #1 2'b00;
    else
        ch2_w_en_d2[1:0] <= #1 {ch2_w_en_d2[0], phy_w_en & arbiter_value[2]};
end
assign          ch2_w_ack  = ~ch2_w_en_d2[1] & ch2_w_en_d2[0];
assign          ch2_w_done = ch2_w_en_d2[1] & ~ch2_w_en_d2[0];

reg     [1:0]   ch3_w_en_d2;
always@(posedge ch3_w_clk or negedge rst_n) begin
    if(!rst_n)
        ch3_w_en_d2[1:0] <= #1 2'b00;
    else
        ch3_w_en_d2[1:0] <= #1 {ch3_w_en_d2[0], phy_w_en & arbiter_value[4]};
end
assign          ch3_w_ack  = ~ch3_w_en_d2[1] & ch3_w_en_d2[0];
assign          ch3_w_done = ch3_w_en_d2[1] & ~ch3_w_en_d2[0];

reg     [1:0]   ch1_r_en_d2;
always@(posedge ch1_r_clk or negedge rst_n) begin
    if(!rst_n)
        ch1_r_en_d2[1:0] <= #1 2'b00;
    else
        ch1_r_en_d2[1:0] <= #1 {ch1_r_en_d2[0], phy_r_en & arbiter_value[1]};
end
assign          ch1_r_ack  = ~ch1_r_en_d2[1] & ch1_r_en_d2[0];
assign          ch1_r_done = ch1_r_en_d2[1] & ~ch1_r_en_d2[0];

reg     [1:0]   ch2_r_en_d2;
always@(posedge ch2_r_clk or negedge rst_n) begin
    if(!rst_n)
        ch2_r_en_d2[1:0] <= #1 2'b00;
    else
        ch2_r_en_d2[1:0] <= #1 {ch2_r_en_d2[0], phy_r_en & arbiter_value[3]};
end
assign          ch2_r_ack  = ~ch2_r_en_d2[1] & ch2_r_en_d2[0];
assign          ch2_r_done = ch2_r_en_d2[1] & ~ch2_r_en_d2[0];

reg     [1:0]   ch3_r_en_d2;
always@(posedge ch3_r_clk or negedge rst_n) begin
    if(!rst_n)
        ch3_r_en_d2[1:0] <= #1 2'b00;
    else
        ch3_r_en_d2[1:0] <= #1 {ch3_r_en_d2[0], phy_r_en & arbiter_value[5]};
end
assign          ch3_r_ack  = ~ch3_r_en_d2[1] & ch3_r_en_d2[0];
assign          ch3_r_done = ch3_r_en_d2[1] & ~ch3_r_en_d2[0];

my_fifo ch1_w_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (ch1_w_clk              ),//i 写时钟
    .wr_en              (ch1_w_fi_en            ),//i 写使能
    .wr_data            (ch1_w_data[31:0]       ),//i 写数据
    .wr_almost_full     (),//o 
    .wr_full            (),//o 

    .rd_clk             (clk                    ),//i 时钟
    .rd_en              (ch1_w_fifo_en          ),//i 读使能
    .rd_data            (ch1_w_fifo_data[31:0]  ),//o 读数据
    .rd_almost_empty    (),//o 
    .rd_empty           () //o 
);

my_fifo ch2_w_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (ch2_w_clk              ),//写时钟
    .wr_en              (ch2_w_fi_en            ),//写使能
    .wr_data            (ch2_w_data[31:0]       ),//写数据
    .wr_almost_full     (),//
    .wr_full            (),//

    .rd_clk             (clk                    ),//i 时钟
    .rd_en              (ch2_w_fifo_en          ),//读使能
    .rd_data            (ch2_w_fifo_data[31:0]  ),//o 读数据
    .rd_almost_empty    (),//
    .rd_empty           () //
);

my_fifo ch3_w_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (ch3_w_clk              ),//写时钟
    .wr_en              (ch3_w_fi_en            ),//写使能
    .wr_data            (ch3_w_data[31:0]       ),//写数据
    .wr_almost_full     (),//
    .wr_full            (),//

    .rd_clk             (clk                    ),//i 时钟
    .rd_en              (ch3_w_fifo_en          ),//读使能
    .rd_data            (ch3_w_fifo_data[31:0]  ),//o 读数据
    .rd_almost_empty    (),//
    .rd_empty           () //
);

my_fifo ch1_r_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (clk                    ),//i 时钟
    .wr_en              (ch1_r_fifo_en          ),//写使能
    .wr_data            (ch1_r_fifo_data[31:0]  ),//写数据
    .wr_almost_full     (),//
    .wr_full            (),//

    .rd_clk             (ch1_r_clk              ),//读时钟
    .rd_en              (ch1_r_fo_en            ),//读使能
    .rd_data            (ch1_r_data[31:0]       ),//读数据
    .rd_almost_empty    (),//
    .rd_empty           () //
);

my_fifo ch2_r_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (clk                    ),//i 时钟
    .wr_en              (ch2_r_fifo_en          ),//写使能
    .wr_data            (ch2_r_fifo_data[31:0]  ),//写数据
    .wr_almost_full     (),//
    .wr_full            (),//

    .rd_clk             (ch2_r_clk              ),//读时钟
    .rd_en              (ch2_r_fo_en            ),//读使能
    .rd_data            (ch2_r_data[31:0]       ),//读数据
    .rd_almost_empty    (),//
    .rd_empty           () //
);

my_fifo ch3_r_fifo(
    .rst_n              (rst_n                  ),//i 复位，低电平有效

    .wr_clk             (clk                    ),//i 时钟
    .wr_en              (ch3_r_fifo_en          ),//写使能
    .wr_data            (ch3_r_fifo_data[31:0]  ),//写数据
    .wr_almost_full     (),//
    .wr_full            (),//

    .rd_clk             (ch3_r_clk              ),//读时钟
    .rd_en              (ch3_r_fo_en            ),//读使能
    .rd_data            (ch3_r_data[31:0]       ),//读数据
    .rd_almost_empty    (),//
    .rd_empty           () //
);

endmodule