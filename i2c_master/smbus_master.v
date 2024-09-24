// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "i2c_master_defines.v"

module smbus_master(
    input               clk                 ,
    input               rst_n               ,

    input       [7:0]   slave_addr          ,   //从设备地址 
    input       [15:0]  prescale            ,   //时钟分频系数 prescale = clk / ( 5 * desire scl ) - 1

    input               trans_en            ,   //帧传输使能, 边沿触发
    input               trans_abort         ,   //帧传输中止, 边沿触发
    output  reg         trans_done          ,   //帧传输结束, 边沿触发

    input       [15:0]  write_number        ,   //发送或接收的字节数量, 不包含器件地址
    output  reg [15:0]  write_count         ,   //传输字节的数量, 不包含器件地址
    input       [7:0]   data_w              ,   //master 发送的数据
    output  reg         byte_w_done         ,   //字节发送完成

    input       [15:0]  read_number         ,   //发送或接收的字节数量, 不包含器件地址
    output  reg [15:0]  read_count          ,   //传输字节的数量, 不包含器件地址
    output      [7:0]   data_r              ,   //master 接收的数据
    output  reg         byte_r_done         ,   //字节接收完成

    output              bus_busy            ,   //总线忙
    output              aribitration_lose   ,   //多主机仲裁丢失
    output  reg         slave_no_response   ,   //设备应答

    input               scl_pad_i           ,   //SCL-line input 
    output              scl_padoen_o        ,   //SCL-line output enable (active low)
    input               sda_pad_i           ,   //SDA-line input
    output              sda_padoen_o            //SDA-line output enable (active low)
);

reg             byte_ctrl_en;
reg             byte_ctrl_start;
reg             byte_ctrl_stop; 
reg             byte_ctrl_read; 
reg             byte_ctrl_write;
reg             byte_ctrl_ack_in;
reg     [7:0]   byte_ctrl_din;
wire            byte_ctrl_core_ack;
wire            byte_ctrl_cmd_ack;
wire            slave_ack_n;

reg             trans_en_d2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        trans_en_d2 <= #1 1'b0;
    else
        trans_en_d2 <= #1 trans_en;
end

reg             byte_ctrl_cmd_ack_d2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        byte_ctrl_cmd_ack_d2 <= #1 1'b0;
    else
        byte_ctrl_cmd_ack_d2 <= #1 byte_ctrl_cmd_ack;
end

wire            posedge_trans_en;
assign          posedge_trans_en = (~trans_en_d2) & trans_en;

reg             trans_abort_d2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        trans_abort_d2 <= #1 1'b0;
    else
        trans_abort_d2 <= #1 trans_abort;
end

reg             posedge_trans_abort;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        posedge_trans_abort <= #1 1'b0;
    else if( posedge_trans_en == 1'b1 )
        posedge_trans_abort <= #1 1'b0;
    else if( (trans_abort_d2 == 1'b0) & (trans_abort == 1'b1) )
        posedge_trans_abort <= #1 1'b1;
end

reg     [15:0]  write_number_latch;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_number_latch[15:0] <= #1 16'h0;
    else if( posedge_trans_en == 1'b1 )
        write_number_latch[15:0] <= #1 write_number[15:0];
end

reg     [15:0]  read_number_latch;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_number_latch[15:0] <= #1 16'h0;
    else if( posedge_trans_en == 1'b1 )
        read_number_latch[15:0] <= #1 read_number[15:0];
end

reg     [15:0]  write_number_count;
reg             write_number_count_en;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_number_count[15:0] <= #1 16'h0;
    else if( posedge_trans_en == 1'b1 )
        write_number_count[15:0] <= #1 16'h0;                           //出现起始位清零
    else if( (write_number_count_en == 1'b1) && (byte_ctrl_cmd_ack == 1'b1) )
        write_number_count[15:0] <= #1 write_number_count[15:0] + 1'h1;
end

always @(*) begin
    if( (write_number_count[15:0] >= 1'b1) && ( write_number_count[15:0] < write_number_latch[15:0] + 16'h1) )
        write_count[15:0] <= #1 write_number_count[15:0] - 16'h1;                          
    else if( write_number_count[15:0] >= write_number_latch[15:0] + 16'h1)
        write_count[15:0] <= #1 write_number_latch[15:0] - 16'h1;       
    else
        write_count[15:0] <= #1 16'h0;
end

reg     [15:0]  read_number_count;
reg             read_number_count_en;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_number_count[15:0] <= #1 16'h0;
    else if( posedge_trans_en == 1'b1 )
        read_number_count[15:0] <= #1 16'h0;                            //出现起始位清零
    else if( (read_number_count_en == 1'b1) && (byte_ctrl_cmd_ack == 1'b1) )
        read_number_count[15:0] <= #1 read_number_count[15:0] + 1'h1;
end

reg     [15:0]  read_number_f2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_number_f2[15:0] <= #1 16'h0;
        read_count[15:0]     <= #1 16'h0;
    end
    else begin
        read_number_f2[15:0] <= #1 read_number_count[15:0];
        read_count[15:0]     <= #1 read_number_f2[15:0];                //打拍, 与r_done信号同步
    end
end

reg             rd_wr_sel;//0写 1读
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rd_wr_sel <= #1 1'b0;
    else if( write_number_count[15:0] < write_number_latch[15:0] )
        rd_wr_sel <= #1 1'b0;
    else
        rd_wr_sel <= #1 1'b1;
end

reg             byte_w_done_en;  
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        byte_w_done_en <= #1 1'b0;
    else if( (write_number_count[15:0] > 16'h0) && (write_number_count[15:0] < write_number_latch[15:0] + 16'h1) )
        byte_w_done_en <= #1 1'b1;
    else
        byte_w_done_en <= #1 1'b0;
end

reg             write_done;    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_done <= #1 1'b0;
    else if( write_number_count[15:0] > write_number_latch[15:0] )
        write_done <= #1 1'b1;
    else
        write_done <= #1 1'b0;
end

reg             write_sa_done;  
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_sa_done <= #1 1'b0;
    else if( write_number_count[15:0] == write_number_latch[15:0] + 16'h2)
        write_sa_done <= #1 1'b1;
    else
        write_sa_done <= #1 1'b0;
end

reg             read_done;    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_done <= #1 1'b0;
    else if( read_number_count[15:0] >= read_number_latch[15:0] )
        read_done <= #1 1'b1;
    else
        read_done <= #1 1'b0;
end

reg             read_ack_n;    
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_ack_n <= #1 1'b1;
    else if( read_number_count[15:0] + 16'h1 == read_number_latch[15:0] )
        read_ack_n <= #1 1'b1;
    else
        read_ack_n <= #1 1'b0;
end

assign          bus_busy = byte_ctrl_en;

/************************************************************
******控制器状态机
************************************************************/
localparam [3:0] ST_IDLE    = 4'h0;
localparam [3:0] ST_STA     = 4'h1;
localparam [3:0] ST_W_ADR   = 4'h2;
localparam [3:0] ST_W_ADR_N = 4'h3;
localparam [3:0] ST_W_ACK   = 4'h4;
localparam [3:0] ST_W_NCK   = 4'h5;
localparam [3:0] ST_W_DAT   = 4'h6;
localparam [3:0] ST_W_DAT_N = 4'h7;
localparam [3:0] ST_R_STA   = 4'h8;
localparam [3:0] ST_R_DAT   = 4'h9;
localparam [3:0] ST_R_DAT_N = 4'hA;
localparam [3:0] ST_R_ACK   = 4'hB;
localparam [3:0] ST_STOP    = 4'hC;
localparam [3:0] ST_END     = 4'hD;

reg     [3:0]   state_c;
reg     [3:0]   state_n;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_c[3:0] <= #1 ST_IDLE;
    else
        state_c[3:0] <= #1 state_n[3:0];
end

always@(*) begin
    case(state_c[3:0]) 
    ST_IDLE   : begin
                    if( posedge_trans_en == 1'b1 )
                        state_n[3:0] = ST_STA;  //数据传输开始
                    else
                        state_n[3:0] = ST_IDLE;
                end
    ST_STA    : begin
                    if( byte_ctrl_core_ack == 1'b1 )
                        state_n[3:0] = ST_W_ADR;//起始位发送完写器件地址
                    else
                        state_n[3:0] = ST_STA;
                end
    ST_W_ADR  :         state_n[3:0] = ST_W_ADR_N;
    ST_W_ADR_N: begin
                    if( byte_ctrl_cmd_ack_d2 == 1'b1 )
                        state_n[3:0] = ST_W_ACK;//器件地址写完等待器件应答
                    else
                        state_n[3:0] = ST_W_ADR_N;
                end
    ST_W_ACK  : begin
                    if( posedge_trans_abort == 1'b1 )
                        state_n[3:0] = ST_STOP; //帧传输终止
                    else if( slave_ack_n == 1'b1 )
                        state_n[3:0] = ST_W_NCK;//从设备无应答     
                    else if( write_done == 1'b0 )
                        state_n[3:0] = ST_W_DAT;//写应答, 继续写下一字节数据
                    else if( (write_sa_done == 1'b1) && (read_done == 1'b0) )
                        state_n[3:0] = ST_R_DAT;//二次写地址完成, 准备读数据
                    else if( (write_sa_done == 1'b0) && (read_done == 1'b1) )
                        state_n[3:0] = ST_STOP; //写完成, 不读数据
                    else if( (write_sa_done == 1'b0) && (read_done == 1'b0) )
                        state_n[3:0] = ST_R_STA;//一次写地址完成, 准备发送重复起始位
                end
    ST_W_NCK  :         state_n[3:0] = ST_STOP; //器件无应答, 终止
    ST_W_DAT  :         state_n[3:0] = ST_W_DAT_N;
    ST_W_DAT_N: begin
                    if( byte_ctrl_cmd_ack_d2 == 1'b1 )
                        state_n[3:0] = ST_W_ACK;//写完成, 等待设备应答
                    else
                        state_n[3:0] = ST_W_DAT_N;
                end
    ST_R_STA  : begin
                    if( byte_ctrl_core_ack == 1'b1 )
                        state_n[3:0] = ST_W_ADR;//重复起始位发送完成, 写器件地址
                    else
                        state_n[3:0] = ST_R_STA;
                end
    ST_R_DAT  :         state_n[3:0] = ST_R_DAT_N;
    ST_R_DAT_N: begin
                    if( byte_ctrl_cmd_ack_d2 == 1'b1 )
                        state_n[3:0] = ST_R_ACK;//读数据完成, 应答从设备
                    else
                        state_n[3:0] = ST_R_DAT_N;
                end
    ST_R_ACK  : begin
                    if( read_done == 1'b1 )
                        state_n[3:0] = ST_STOP; //读完成, 发送停止位
                    else if( posedge_trans_abort == 1'b1 )
                        state_n[3:0] = ST_STOP; //帧传输终止
                    else
                        state_n[3:0] = ST_R_DAT;//读应答, 继续读下一字节数据
                end
    ST_STOP   : begin
                    if( byte_ctrl_cmd_ack == 1'b1 )
                        state_n[3:0] = ST_END;  //停止位发送完成, 准备下一次数据传输
                    else
                        state_n[3:0] = ST_STOP;
                end
    ST_END    :         state_n[3:0] = ST_IDLE;
    default   :         state_n[3:0] = ST_IDLE;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        byte_ctrl_en            <= #1 1'b0 ;
        byte_ctrl_start         <= #1 1'b0 ;
        byte_ctrl_stop          <= #1 1'b0 ;
        byte_ctrl_read          <= #1 1'b0 ;
        byte_ctrl_write         <= #1 1'b0 ;
        byte_ctrl_ack_in        <= #1 1'b1 ;
        byte_ctrl_din[7:0]      <= #1 8'hff;
        trans_done              <= #1 1'b0 ;
        byte_w_done             <= #1 1'b0 ;
        byte_r_done             <= #1 1'b0 ;
        slave_no_response       <= #1 1'b0 ;
        write_number_count_en   <= #1 1'b0 ;
        read_number_count_en    <= #1 1'b0 ;
    end
    else begin
        case(state_n[3:0])
        ST_STA    : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b1 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 {{slave_addr[7:1]}, {rd_wr_sel}};
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_ADR  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b1 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 {{slave_addr[7:1]}, {rd_wr_sel}};
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_ADR_N: begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 {{slave_addr[7:1]}, {rd_wr_sel}};
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b1 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_ACK  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 byte_w_done_en ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_NCK  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b1 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_DAT  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b1 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 data_w[7:0];
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_W_DAT_N: begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 data_w[7:0];
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b1 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_R_STA  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b1 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 {{slave_addr[7:1]}, {rd_wr_sel}};
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_R_DAT  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b1 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_R_DAT_N: begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 read_ack_n ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b1 ;
                    end
        ST_R_ACK  : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 read_ack_n ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b1 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_STOP   : begin
                        byte_ctrl_en            <= #1 1'b1 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b1 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        ST_END    : begin
                        byte_ctrl_en            <= #1 1'b0 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b1 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        default :   begin
                        byte_ctrl_en            <= #1 1'b0 ;
                        byte_ctrl_start         <= #1 1'b0 ;
                        byte_ctrl_stop          <= #1 1'b0 ;
                        byte_ctrl_read          <= #1 1'b0 ;
                        byte_ctrl_write         <= #1 1'b0 ;
                        byte_ctrl_ack_in        <= #1 1'b1 ;
                        byte_ctrl_din[7:0]      <= #1 8'hff;
                        trans_done              <= #1 1'b0 ;
                        byte_w_done             <= #1 1'b0 ;
                        byte_r_done             <= #1 1'b0 ;
                        slave_no_response       <= #1 1'b0 ;
                        write_number_count_en   <= #1 1'b0 ;
                        read_number_count_en    <= #1 1'b0 ;
                    end
        endcase
    end
end

i2c_master_byte_ctrl byte_controller (
    .clk        ( clk                   ),  
    .rst        ( 1'b0                  ),  
    .nReset     ( rst_n                 ),  
    .ena        ( byte_ctrl_en          ),  //持续置1才会发送波形
    .clk_cnt    ( prescale[15:0]        ),
    .start      ( byte_ctrl_start       ),
    .stop       ( byte_ctrl_stop        ),
    .read       ( byte_ctrl_read        ),
    .write      ( byte_ctrl_write       ),
    .ack_in     ( byte_ctrl_ack_in      ),  //主设备应答, 读应答置0, 写置1
    .din        ( byte_ctrl_din[7:0]    ),
    .cmd_ack    ( byte_ctrl_cmd_ack     ),  //字节传输完成(第9个上升沿)或出现停止位 置位
    .core_ack   ( byte_ctrl_core_ack    ),  //单bit指令应答
    .ack_out    ( slave_ack_n           ),  //器件应答状态
    .dout       ( data_r[7:0]           ),
    .i2c_busy   ( ),                        
    .i2c_al     ( aribitration_lose     ),
    .scl_i      ( scl_pad_i             ),
    .scl_o      ( ),  
    .scl_oen    ( scl_padoen_o          ),
    .sda_i      ( sda_pad_i             ),
    .sda_o      ( ),  
    .sda_oen    ( sda_padoen_o          )
);

endmodule