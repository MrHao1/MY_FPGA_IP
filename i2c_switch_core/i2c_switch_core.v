`include "timescale.v"

module i2c_switch_core #(
    parameter           CLK_FREQ = 100          ,
    parameter           SCL_RISE_TIME = 100     ,
    parameter           SDA_RISE_TIME = 100     
) (
    input               clk                     ,
    input               rst_n                   ,

    input               m_scl_pad_i             ,    
    output  reg         m_scl_padoen_o          ,   
    input               m_sda_pad_i             ,   
    output  reg         m_sda_padoen_o          ,

    input               s_scl_pad_i             ,    
    output  reg         s_scl_padoen_o          ,   
    input               s_sda_pad_i             ,   
    output  reg         s_sda_padoen_o        
);

/************************************************************
******系统时钟与I2C CLK频率的关系
            100K    400K
            5000    1250    ns
    100M    500     125     clk cycle
    50M     250     63      clk cycle
    25M     125     32      clk cycle
******I2C Tr Max规范
            100K    400K
            1000    300     ns
    100M    100     30      clk cycle
    50M     50      15      clk cycle
    25M     25      7       clk cycle
************************************************************/

/************************************************************
******全局定义
************************************************************/
`define BUF_I2C_LEN     (8*CLK_FREQ)/100
`define SCL_DET_LEN     (8*CLK_FREQ)/100
`define SDA_DET_LEN     (8*CLK_FREQ)/100

/************************************************************
******信号预处理
************************************************************/
reg     [`BUF_I2C_LEN-1:0]  m_sdaPipe;
reg     [`BUF_I2C_LEN-1:0]  m_sclPipe;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_sdaPipe <= #1 {`BUF_I2C_LEN{1'b1}};
        m_sclPipe <= #1 {`BUF_I2C_LEN{1'b1}};
    end
    else begin
        m_sdaPipe <= #1 {m_sdaPipe[`BUF_I2C_LEN-2:0], m_sda_pad_i};
        m_sclPipe <= #1 {m_sclPipe[`BUF_I2C_LEN-2:0], m_scl_pad_i};
    end
end

reg                         m_sdaDeb;
reg                         m_sclDeb;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_sdaDeb <= #1 1'b1;
        m_sclDeb <= #1 1'b1;
    end
    else begin
        if (&m_sclPipe[`BUF_I2C_LEN-1:1] == 1'b1)
            m_sclDeb <= #1 1'b1;
        else if (|m_sclPipe[`BUF_I2C_LEN-1:1] == 1'b0)
            m_sclDeb <= #1 1'b0;
        if (&m_sdaPipe[`BUF_I2C_LEN-1:1] == 1'b1)
            m_sdaDeb <= #1 1'b1;
        else if (|m_sdaPipe[`BUF_I2C_LEN-1:1] == 1'b0)
            m_sdaDeb <= #1 1'b0;
    end
end

reg     [`SCL_DET_LEN-1:0]  m_sclDelayed;
reg     [`SDA_DET_LEN-1:0]  m_sdaDelayed;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
    m_sclDelayed <= #1 {`SCL_DET_LEN{1'b1}};
    m_sdaDelayed <= #1 {`SDA_DET_LEN{1'b1}};
  end
  else begin
    m_sclDelayed <= #1 {m_sclDelayed[`SCL_DET_LEN-2:0], m_sclDeb};
    m_sdaDelayed <= #1 {m_sdaDelayed[`SDA_DET_LEN-2:0], m_sdaDeb};
  end
end

reg     [`BUF_I2C_LEN-1:0]  s_sdaPipe;
reg     [`BUF_I2C_LEN-1:0]  s_sclPipe;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_sdaPipe <= #1 {`BUF_I2C_LEN{1'b1}};
        s_sclPipe <= #1 {`BUF_I2C_LEN{1'b1}};
    end
    else begin
        s_sdaPipe <= #1 {s_sdaPipe[`BUF_I2C_LEN-2:0], s_sda_pad_i};
        s_sclPipe <= #1 {s_sclPipe[`BUF_I2C_LEN-2:0], s_scl_pad_i};
    end
end

reg                         s_sdaDeb;
reg                         s_sclDeb;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_sdaDeb <= #1 1'b1;
        s_sclDeb <= #1 1'b1;
    end
    else begin
        if (&s_sclPipe[`BUF_I2C_LEN-1:1] == 1'b1)
            s_sclDeb <= #1 1'b1;
        else if (|s_sclPipe[`BUF_I2C_LEN-1:1] == 1'b0)
            s_sclDeb <= #1 1'b0;
        if (&s_sdaPipe[`BUF_I2C_LEN-1:1] == 1'b1)
            s_sdaDeb <= #1 1'b1;
        else if (|s_sdaPipe[`BUF_I2C_LEN-1:1] == 1'b0)
            s_sdaDeb <= #1 1'b0;
    end
end

reg     [`SCL_DET_LEN-1:0]  s_sclDelayed;
reg     [`SDA_DET_LEN-1:0]  s_sdaDelayed;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
    s_sclDelayed <= #1 {`SCL_DET_LEN{1'b1}};
    s_sdaDelayed <= #1 {`SDA_DET_LEN{1'b1}};
  end
  else begin
    s_sclDelayed <= #1 {s_sclDelayed[`SCL_DET_LEN-2:0], s_sclDeb};
    s_sdaDelayed <= #1 {s_sdaDelayed[`SDA_DET_LEN-2:0], s_sdaDeb};
  end
end

wire    posedge_m_sclDelayed    ;
assign  posedge_m_sclDelayed    =   (~m_sclDelayed[2]) & m_sclDelayed[1];

wire    negedge_m_sclDelayed    ;
assign  negedge_m_sclDelayed    =   m_sclDelayed[2] & (~m_sclDelayed[1]);

wire    posedge_m_sdaDelayed    ;
assign  posedge_m_sdaDelayed    =   (~m_sdaDelayed[2]) & m_sdaDelayed[1];

wire    negedge_m_sdaDelayed    ;
assign  negedge_m_sdaDelayed    =   m_sdaDelayed[2] & (~m_sdaDelayed[1]);

wire    start_det               ;
assign  start_det               =   negedge_m_sdaDelayed & m_sclDelayed[1];

wire    stop_det                ;
assign  stop_det                =   posedge_m_sdaDelayed & m_sclDelayed[1];

/************************************************************
******数据端口状态机
************************************************************/
reg             counter_d_en;
reg     [7:0]   counter_d;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        counter_d[7:0] <= #1 8'h0;
    else if(counter_d_en == 1'b0)
        counter_d[7:0] <= #1 8'h0;
    else if(counter_d[7:0] < SDA_RISE_TIME[7:0])
        counter_d[7:0] <= #1 counter_d[7:0] + 1'b1;
end

wire            counter_d_tu;
assign          counter_d_tu    = (counter_d[7:0] == SDA_RISE_TIME[7:0]) ? 1'b1 : 1'b0;


localparam [4:0] ST_D_IDLE  = 5'b0_0000;
localparam [4:0] ST_D_MTOS  = 5'b0_0001;
localparam [4:0] ST_D_STOM  = 5'b0_0010;
localparam [4:0] ST_D_HOLD  = 5'b0_0100;

//状态跳转, 时序电路
reg     [4:0]   state_d_c;
reg     [4:0]   state_d_n;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_d_c[4:0] <= #1 ST_D_IDLE;
    else
        state_d_c[4:0] <= #1 state_d_n[4:0];
end

//状态转移判断, 组合电路, 判断条件需要打拍, 避免出现毛刺
always@(*) begin
    case(state_d_c[4:0]) 
    ST_D_IDLE : begin
                    if(m_sdaDelayed[1] == 1'b0)
                        state_d_n[4:0] = ST_D_MTOS;
                    else if(s_sdaDelayed[1] == 1'b0)
                        state_d_n[4:0] = ST_D_STOM;
                    else
                        state_d_n[4:0] = ST_D_IDLE;
                end
    ST_D_MTOS : begin
                    if(m_sdaDelayed[1] == 1'b1)
                        state_d_n[4:0] = ST_D_HOLD;
                    else
                        state_d_n[4:0] = ST_D_MTOS;
                end
    ST_D_STOM : begin
                    if(s_sdaDelayed[1] == 1'b1)
                        state_d_n[4:0] = ST_D_HOLD;
                    else
                        state_d_n[4:0] = ST_D_STOM;
                end
    ST_D_HOLD : begin
                    if(counter_d_tu == 1'b1)
                        state_d_n[4:0] = ST_D_IDLE;
                    else
                        state_d_n[4:0] = ST_D_HOLD;
                end
    default :           state_d_n[4:0] = ST_D_IDLE;
    endcase
end

//输出, 时序电路
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        m_sda_padoen_o <= #1 1'b1; 
        s_sda_padoen_o <= #1 1'b1; 
        counter_d_en <= #1 1'b0;
    end
    else begin
        case(state_d_n[4:0])
        ST_D_IDLE : begin
                        m_sda_padoen_o <= #1 1'b1; 
                        s_sda_padoen_o <= #1 1'b1; 
                        counter_d_en <= #1 1'b0;
                    end
        ST_D_MTOS : begin
                        m_sda_padoen_o <= #1 1'b1; 
                        s_sda_padoen_o <= #1 1'b0; 
                        counter_d_en <= #1 1'b0;
                    end
        ST_D_STOM : begin
                        m_sda_padoen_o <= #1 1'b0; 
                        s_sda_padoen_o <= #1 1'b1; 
                        counter_d_en <= #1 1'b0;
                    end
        ST_D_HOLD : begin
                        m_sda_padoen_o <= #1 1'b1; 
                        s_sda_padoen_o <= #1 1'b1; 
                        counter_d_en <= #1 1'b1;
                    end            
        default :   begin
                        m_sda_padoen_o <= #1 1'b1; 
                        s_sda_padoen_o <= #1 1'b1; 
                        counter_d_en <= #1 1'b0;
                    end
        endcase
    end
end

/************************************************************
******时钟端口状态机
************************************************************/

//时钟边沿计数
reg     [3:0]   scl_negedge_count;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        scl_negedge_count[3:0] <= #1 4'd0;
    else if((start_det == 1'b1) || (stop_det == 1'b1))
        scl_negedge_count[3:0] <= #1 4'd0;
    else if(scl_negedge_count[3:0] > 4'd9)
        scl_negedge_count[3:0] <= #1 4'd1;
    else if(negedge_m_sclDelayed == 1'b1)
        scl_negedge_count[3:0] <= #1 scl_negedge_count[3:0] + 1'b1;
end

//检测第5个时钟边沿的低电平时间
reg     [9:0]   scl_low_time;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        scl_low_time[9:0] <= #1 10'h0;
    else if(scl_negedge_count[3:0] == 4'd4)
        scl_low_time[9:0] <= #1 10'h0;     //第四个周期清零计数器
    else if((scl_negedge_count[3:0] == 4'd5) && (m_sclDelayed[1] == 1'b0))
        scl_low_time[9:0] <= #1 scl_low_time[9:0] + 1'b1;
end

reg     [9:0] scl_low_time_latch;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        scl_low_time_latch[9:0] <= #1 10'h0;
    else if((scl_negedge_count[3:0] == 4'd5) && (posedge_m_sclDelayed == 1'b1))
        scl_low_time_latch[9:0] <= #1 scl_low_time[9:0];
end

//时钟延展检测等待时间, 约等于低电平时间的6/5
wire    [9:0]   streth_wait_time;
assign          streth_wait_time[9:0] = scl_low_time_latch[9:0] + scl_low_time_latch[9:3] + scl_low_time_latch[9:4];

reg             counter_wait_en;
reg     [9:0]   counter_wait;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        counter_wait[9:0] <= #1 10'h0;
    else if(counter_wait_en == 1'b0)
        counter_wait[9:0] <= #1 10'h0;
    else if(counter_wait[9:0] < streth_wait_time[9:0])
        counter_wait[9:0] <= #1 counter_wait[9:0] + 1'b1;
end

wire            counter_wait_tu;
assign          counter_wait_tu = (counter_wait[9:0] == streth_wait_time[9:0]) ? 1'b1 : 1'b0;

//根据实际信号的上升时间调整
reg             counter_ddet_en;
reg     [7:0]   counter_ddet;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        counter_ddet[7:0] <= #1 8'h0;
    else if(counter_ddet_en == 1'b0)
        counter_ddet[7:0] <= #1 8'h0;
    else if(counter_ddet[7:0] < SCL_RISE_TIME[7:0])    
        counter_ddet[7:0] <= #1 counter_ddet[7:0] + 1'b1;
end

wire            counter_ddet_tu;
assign          counter_ddet_tu = (counter_ddet[7:0] == SCL_RISE_TIME[7:0]) ? 1'b1 : 1'b0;

//根据实际信号的上升时间调整
reg             counter_c_en;
reg     [7:0]   counter_c;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        counter_c[7:0] <= #1 8'h0;
    else if(counter_c_en == 1'b0)
        counter_c[7:0] <= #1 8'h0;
    else if(counter_c[7:0] < SCL_RISE_TIME[7:0])       
        counter_c[7:0] <= #1 counter_c[7:0] + 1'b1;
end

wire            counter_c_tu;
assign          counter_c_tu = (counter_c[7:0] == SCL_RISE_TIME[7:0]) ? 1'b1 : 1'b0;


localparam [4:0] ST_C_IDLE  = 5'b0_0000;
localparam [4:0] ST_C_MTOS  = 5'b0_0001;
localparam [4:0] ST_C_WAIT  = 5'b0_0010;
localparam [4:0] ST_C_DDET  = 5'b0_0100;
localparam [4:0] ST_C_STOM  = 5'b0_1000;
localparam [4:0] ST_C_HOLD  = 5'b1_0000;

//状态跳转, 时序电路
reg     [4:0]   state_c_c;
reg     [4:0]   state_c_n;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_c_c[4:0] <= #1 ST_C_IDLE;
    else
        state_c_c[4:0] <= #1 state_c_n[4:0];
end

//状态转移判断, 组合电路, 判断条件需要打拍, 避免出现毛刺
always@(*) begin
    case(state_c_c[4:0]) 
    ST_C_IDLE : begin
                    if(m_sclDelayed[1] == 1'b0)
                        state_c_n[4:0] = ST_C_MTOS;
                    else
                        state_c_n[4:0] = ST_C_IDLE;
                end
    ST_C_MTOS : begin
                    if(scl_negedge_count[3:0] == 4'd9) 
                        state_c_n[4:0] = ST_C_WAIT;
                    else if(stop_det == 1'b1)   
                        state_c_n[4:0] = ST_C_IDLE;
                    else
                        state_c_n[4:0] = ST_C_MTOS;
                end
    ST_C_WAIT : begin
                    if(counter_wait_tu == 1'b1)
                        state_c_n[4:0] = ST_C_DDET;
                    else
                        state_c_n[4:0] = ST_C_WAIT;
                end
    ST_C_DDET : begin
                    if((counter_ddet_tu == 1'b1) && (s_sclDelayed[1] == 1'b0))
                        state_c_n[4:0] = ST_C_STOM;
                    else if((counter_ddet_tu == 1'b1) && (s_sclDelayed[1] == 1'b1))
                        state_c_n[4:0] = ST_C_HOLD;
                    else
                        state_c_n[4:0] = ST_C_DDET;
                end
    ST_C_STOM : begin
                    if(s_sclDelayed[1] == 1'b1)
                        state_c_n[4:0] = ST_C_HOLD;
                    else
                        state_c_n[4:0] = ST_C_STOM;
                end
    ST_C_HOLD : begin
                    if(counter_c_tu == 1'b1)
                        state_c_n[4:0] = ST_C_IDLE;
                    else
                        state_c_n[4:0] = ST_C_HOLD;
                end
    default :           state_c_n[4:0] = ST_C_IDLE;
    endcase
end

//输出, 时序电路
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        m_scl_padoen_o  <= #1 1'b1;
        s_scl_padoen_o  <= #1 1'b1;
        counter_wait_en <= #1 1'b0;
        counter_ddet_en <= #1 1'b0;
        counter_c_en    <= #1 1'b0;
    end
    else begin
        case(state_c_n[4:0])
        ST_C_IDLE : begin
                        m_scl_padoen_o  <= #1 1'b1;
                        s_scl_padoen_o  <= #1 1'b1;
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b0;
                    end
        ST_C_MTOS : begin
                        m_scl_padoen_o  <= #1 1'b1;
                        s_scl_padoen_o  <= #1 m_sclDelayed[1];
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b0;
                    end
        ST_C_WAIT : begin
                        m_scl_padoen_o  <= #1 1'b0;
                        s_scl_padoen_o  <= #1 1'b0;
                        counter_wait_en <= #1 1'b1;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b0;
                    end
        ST_C_DDET : begin
                        m_scl_padoen_o  <= #1 1'b0;
                        s_scl_padoen_o  <= #1 1'b1;
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b1;
                        counter_c_en    <= #1 1'b0;
                    end
        ST_C_STOM : begin
                        m_scl_padoen_o  <= #1 s_sclDelayed[1];
                        s_scl_padoen_o  <= #1 1'b1;
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b0;
                    end
        ST_C_HOLD : begin
                        m_scl_padoen_o  <= #1 1'b1;
                        s_scl_padoen_o  <= #1 1'b1;
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b1;
                    end
        default :   begin
                        m_scl_padoen_o  <= #1 1'b1;
                        s_scl_padoen_o  <= #1 1'b1;
                        counter_wait_en <= #1 1'b0;
                        counter_ddet_en <= #1 1'b0;
                        counter_c_en    <= #1 1'b0;
                    end
        endcase
    end
end
endmodule
