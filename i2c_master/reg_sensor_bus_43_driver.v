`include "timescale.v"

module reg_sensor_bus_43_driver(
    input               clk                 ,
    input               rst_n               ,

    input       [15:0]  prescale            ,   //分频系数
    input               en_module           ,   //通信使能信号
    output              slave_no_response   ,   //设备无应答标志
    output              aribitration_lose   ,   //仲裁丢失标志

    output  reg  [7:0]  v_ce0_0v8_l         ,
    output  reg  [1:0]  v_ce0_0v8_h         ,
    output  reg  [7:0]  i_ce0_0v8_l         ,
    output  reg  [1:0]  i_ce0_0v8_h         ,
    output  reg  [7:0]  v_ce0_0v9_l         ,
    output  reg  [1:0]  v_ce0_0v9_h         ,
    output  reg  [7:0]  i_ce0_0v9_l         ,
    output  reg  [1:0]  i_ce0_0v9_h         ,
    output  reg  [7:0]  v_ce0_1v2_l         ,
    output  reg  [1:0]  v_ce0_1v2_h         ,
    output  reg  [7:0]  i_ce0_1v2_l         ,
    output  reg  [1:0]  i_ce0_1v2_h         ,
    output  reg  [7:0]  t_ce0_power_l       ,
    output  reg  [0:0]  t_ce0_power_h       ,

    output  reg  [7:0]  v_ce1_0v8_l         ,
    output  reg  [1:0]  v_ce1_0v8_h         ,
    output  reg  [7:0]  i_ce1_0v8_l         ,
    output  reg  [1:0]  i_ce1_0v8_h         ,
    output  reg  [7:0]  v_ce1_0v9_l         ,
    output  reg  [1:0]  v_ce1_0v9_h         ,
    output  reg  [7:0]  i_ce1_0v9_l         ,
    output  reg  [1:0]  i_ce1_0v9_h         ,
    output  reg  [7:0]  v_ce1_1v2_l         ,
    output  reg  [1:0]  v_ce1_1v2_h         ,
    output  reg  [7:0]  i_ce1_1v2_l         ,
    output  reg  [1:0]  i_ce1_1v2_h         ,
    output  reg  [7:0]  t_ce1_power_l       ,
    output  reg  [0:0]  t_ce1_power_h       ,

    output  reg  [7:0]  v_ce2_0v8_l         ,
    output  reg  [1:0]  v_ce2_0v8_h         ,
    output  reg  [7:0]  i_ce2_0v8_l         ,
    output  reg  [1:0]  i_ce2_0v8_h         ,
    output  reg  [7:0]  v_ce2_0v9_l         ,
    output  reg  [1:0]  v_ce2_0v9_h         ,
    output  reg  [7:0]  i_ce2_0v9_l         ,
    output  reg  [1:0]  i_ce2_0v9_h         ,
    output  reg  [7:0]  v_ce2_1v2_l         ,
    output  reg  [1:0]  v_ce2_1v2_h         ,
    output  reg  [7:0]  i_ce2_1v2_l         ,
    output  reg  [1:0]  i_ce2_1v2_h         ,
    output  reg  [7:0]  t_ce2_power_l       ,
    output  reg  [0:0]  t_ce2_power_h       ,

    output  reg  [7:0]  v_ce3_0v8_l         ,
    output  reg  [1:0]  v_ce3_0v8_h         ,
    output  reg  [7:0]  i_ce3_0v8_l         ,
    output  reg  [1:0]  i_ce3_0v8_h         ,
    output  reg  [7:0]  v_ce3_0v9_l         ,
    output  reg  [1:0]  v_ce3_0v9_h         ,
    output  reg  [7:0]  i_ce3_0v9_l         ,
    output  reg  [1:0]  i_ce3_0v9_h         ,
    output  reg  [7:0]  v_ce3_1v2_l         ,
    output  reg  [1:0]  v_ce3_1v2_h         ,
    output  reg  [7:0]  i_ce3_1v2_l         ,
    output  reg  [1:0]  i_ce3_1v2_h         ,
    output  reg  [7:0]  t_ce3_power_l       ,
    output  reg  [0:0]  t_ce3_power_h       ,

    output  reg  [7:0]  v_ce4_0v8_l         ,
    output  reg  [1:0]  v_ce4_0v8_h         ,
    output  reg  [7:0]  i_ce4_0v8_l         ,
    output  reg  [1:0]  i_ce4_0v8_h         ,
    output  reg  [7:0]  v_ce4_0v9_l         ,
    output  reg  [1:0]  v_ce4_0v9_h         ,
    output  reg  [7:0]  i_ce4_0v9_l         ,
    output  reg  [1:0]  i_ce4_0v9_h         ,
    output  reg  [7:0]  v_ce4_1v2_l         ,
    output  reg  [1:0]  v_ce4_1v2_h         ,
    output  reg  [7:0]  i_ce4_1v2_l         ,
    output  reg  [1:0]  i_ce4_1v2_h         ,
    output  reg  [7:0]  t_ce4_power_l       ,
    output  reg  [0:0]  t_ce4_power_h       ,

    output  reg  [7:0]  v_ce5_0v8_l         ,
    output  reg  [1:0]  v_ce5_0v8_h         ,
    output  reg  [7:0]  i_ce5_0v8_l         ,
    output  reg  [1:0]  i_ce5_0v8_h         ,
    output  reg  [7:0]  v_ce5_0v9_l         ,
    output  reg  [1:0]  v_ce5_0v9_h         ,
    output  reg  [7:0]  i_ce5_0v9_l         ,
    output  reg  [1:0]  i_ce5_0v9_h         ,
    output  reg  [7:0]  v_ce5_1v2_l         ,
    output  reg  [1:0]  v_ce5_1v2_h         ,
    output  reg  [7:0]  i_ce5_1v2_l         ,
    output  reg  [1:0]  i_ce5_1v2_h         ,
    output  reg  [7:0]  t_ce5_power_l       ,
    output  reg  [0:0]  t_ce5_power_h       ,

    output  reg  [7:0]  v_ce6_0v8_l         ,
    output  reg  [1:0]  v_ce6_0v8_h         ,
    output  reg  [7:0]  i_ce6_0v8_l         ,
    output  reg  [1:0]  i_ce6_0v8_h         ,
    output  reg  [7:0]  v_ce6_0v9_l         ,
    output  reg  [1:0]  v_ce6_0v9_h         ,
    output  reg  [7:0]  i_ce6_0v9_l         ,
    output  reg  [1:0]  i_ce6_0v9_h         ,
    output  reg  [7:0]  v_ce6_1v2_l         ,
    output  reg  [1:0]  v_ce6_1v2_h         ,
    output  reg  [7:0]  i_ce6_1v2_l         ,
    output  reg  [1:0]  i_ce6_1v2_h         ,
    output  reg  [7:0]  t_ce6_power_l       ,
    output  reg  [0:0]  t_ce6_power_h       ,

    input               scl_pad_i           ,   //SCL-line input
    output              scl_padoen_o        ,   //SCL-line output enable (active low)
    input               sda_pad_i           ,   //SDA-line input
    output              sda_padoen_o            //SDA-line output enable (active low)
);

/************************************************************
******设备地址 0写 1读
************************************************************/
localparam [7:0]    dev_number = 8'h7;
wire    [7:0]       dev_addr [dev_number-1:0];
assign              dev_addr[0] = 8'hC0;                    //0
assign              dev_addr[1] = 8'hC2;                    //1
assign              dev_addr[2] = 8'hC4;                    //2
assign              dev_addr[3] = 8'hC6;                    //3
assign              dev_addr[4] = 8'hC8;                    //4
assign              dev_addr[5] = 8'hCA;                    //5
assign              dev_addr[6] = 8'hCC;                    //6

/************************************************************
******初始化参数
************************************************************/
reg     [7:0]   PEC0;
reg     [7:0]   PEC1;
reg     [7:0]   PEC2;
reg     [7:0]   counter_dev;
reg     [7:0]   counter_fram;

localparam [7:0]    init_cmd_cnt = 8'h3;
wire    [7:0]       init_cmd [init_cmd_cnt-1:0];
assign              init_cmd[0] = 8'h00;                    //命令
assign              init_cmd[1] = 8'h00;                    //
assign              init_cmd[2] = PEC0[7:0];                //PEC  crc多项式 : X8+X2+X1+1

always@(*) begin
    case(counter_dev[7:0]) 
    8'h0    :   PEC0[7:0] = 8'h8D;
    8'h1    :   PEC0[7:0] = 8'h5B;
    8'h2    :   PEC0[7:0] = 8'h26;
    8'h3    :   PEC0[7:0] = 8'hF0;
    8'h4    :   PEC0[7:0] = 8'hDC;
    8'h5    :   PEC0[7:0] = 8'h0A;
    8'h6    :   PEC0[7:0] = 8'h77;
    default :   PEC0[7:0] = 8'hFF;
    endcase
end

always@(*) begin
    case(counter_dev[7:0]) 
    8'h0    :   PEC1[7:0] = 8'h8A;
    8'h1    :   PEC1[7:0] = 8'h5C;
    8'h2    :   PEC1[7:0] = 8'h21;
    8'h3    :   PEC1[7:0] = 8'hF7;
    8'h4    :   PEC1[7:0] = 8'hDB;
    8'h5    :   PEC1[7:0] = 8'h0D;
    8'h6    :   PEC1[7:0] = 8'h70;
    default :   PEC1[7:0] = 8'hFF;
    endcase
end

always@(*) begin
    case(counter_dev[7:0]) 
    8'h0    :   PEC2[7:0] = 8'h83;
    8'h1    :   PEC2[7:0] = 8'h55;
    8'h2    :   PEC2[7:0] = 8'h28;
    8'h3    :   PEC2[7:0] = 8'hFE;
    8'h4    :   PEC2[7:0] = 8'hD2;
    8'h5    :   PEC2[7:0] = 8'h04;
    8'h6    :   PEC2[7:0] = 8'h79;
    default :   PEC2[7:0] = 8'hFF;
    endcase
end

/************************************************************
******通信参数
************************************************************/
localparam [7:0]    comm_cmd_frame_cnt = 8'h0A;              //通信帧数量
wire    [7:0]       comm_cmd_w_cnt [comm_cmd_frame_cnt-1:0];
wire    [7:0]       comm_cmd_r_cnt [comm_cmd_frame_cnt-1:0];
wire    [7:0]       comm_cmd [comm_cmd_frame_cnt-1:0][2:0];

assign              comm_cmd_w_cnt[0] = 8'h03;
assign              comm_cmd_r_cnt[0] = 8'h00;      
assign              comm_cmd[0][0]    = 8'h00;              //page0
assign              comm_cmd[0][1]    = 8'h00;              
assign              comm_cmd[0][2]    = PEC0[7:0];          

assign              comm_cmd_w_cnt[1] = 8'h01;
assign              comm_cmd_r_cnt[1] = 8'h03;      
assign              comm_cmd[1][0]    = 8'hA8;              //V

assign              comm_cmd_w_cnt[2] = 8'h01;
assign              comm_cmd_r_cnt[2] = 8'h03;      
assign              comm_cmd[2][0]    = 8'hA9;              //I

assign              comm_cmd_w_cnt[3] = 8'h01;
assign              comm_cmd_r_cnt[3] = 8'h03;      
assign              comm_cmd[3][0]    = 8'hAA;              //T

assign              comm_cmd_w_cnt[4] = 8'h03;
assign              comm_cmd_r_cnt[4] = 8'h00;      
assign              comm_cmd[4][0]    = 8'h00;              //page1
assign              comm_cmd[4][1]    = 8'h01;              
assign              comm_cmd[4][2]    = PEC1[7:0];          

assign              comm_cmd_w_cnt[5] = 8'h01;
assign              comm_cmd_r_cnt[5] = 8'h03;      
assign              comm_cmd[5][0]    = 8'hA8;              //V

assign              comm_cmd_w_cnt[6] = 8'h01;
assign              comm_cmd_r_cnt[6] = 8'h03;      
assign              comm_cmd[6][0]    = 8'hA9;              //I

assign              comm_cmd_w_cnt[7] = 8'h03;
assign              comm_cmd_r_cnt[7] = 8'h00;      
assign              comm_cmd[7][0]    = 8'h00;              //page2
assign              comm_cmd[7][1]    = 8'h02;              
assign              comm_cmd[7][2]    = PEC2[7:0];          

assign              comm_cmd_w_cnt[8] = 8'h01;
assign              comm_cmd_r_cnt[8] = 8'h03;      
assign              comm_cmd[8][0]    = 8'hA8;              //V

assign              comm_cmd_w_cnt[9] = 8'h01;
assign              comm_cmd_r_cnt[9] = 8'h03;      
assign              comm_cmd[9][0]    = 8'hA9;              //I

reg             counter_dev_en;
reg             counter_dev_clr;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter_dev[7:0] <= #1 8'h0;
    else if( counter_dev_clr == 1'b1 )
        counter_dev[7:0] <= #1 8'h0;
    else if( counter_dev_en == 1'b1 )
        counter_dev[7:0] <= #1 counter_dev[7:0] + 1'b1;
end

wire            counter_dev_eq;
assign          counter_dev_eq = (counter_dev[7:0] == dev_number[7:0]) ? 1'b1 : 1'b0;

reg             counter_fram_en;
reg             counter_fram_clr;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter_fram[7:0] <= #1 8'h0;
    else if( counter_fram_clr == 1'b1 )
        counter_fram[7:0] <= #1 8'h0;
    else if( counter_fram_en == 1'b1 )
        counter_fram[7:0] <= #1 counter_fram[7:0] + 1'b1;
end

wire            counter_fram_eq;
assign          counter_fram_eq = (counter_fram[7:0] == comm_cmd_frame_cnt[7:0]) ? 1'b1 : 1'b0;

wire            trans_done;
wire            bus_busy;
reg             trans_en;

/************************************************************
******控制器状态机
************************************************************/
localparam [3:0] ST_IDLE        = 4'h0;
localparam [3:0] ST_INIT_DCLR   = 4'h1;
localparam [3:0] ST_INIT_TREN   = 4'h2;
localparam [3:0] ST_INIT_WAIT   = 4'h3;
localparam [3:0] ST_INIT_DADD   = 4'h4;
localparam [3:0] ST_INIT_DCOM   = 4'h5;
localparam [3:0] ST_COMM_IDLE   = 4'h6;
localparam [3:0] ST_COMM_TREN   = 4'h7;
localparam [3:0] ST_COMM_WAIT   = 4'h8;
localparam [3:0] ST_COMM_FADD   = 4'h9;
localparam [3:0] ST_COMM_FCOM   = 4'hA;
localparam [3:0] ST_COMM_DADD   = 4'hB;
localparam [3:0] ST_COMM_DCOM   = 4'hC;
localparam [3:0] ST_COMM_LOOP   = 4'hD;

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
    ST_IDLE      :  begin
                        if( (en_module == 1'b1) && (bus_busy == 1'b0) )
                            state_n[3:0] = ST_INIT_DCLR; 
                        else
                            state_n[3:0] = ST_IDLE;
                    end
    ST_INIT_DCLR :          state_n[3:0] = ST_INIT_TREN; 
    ST_INIT_TREN :          state_n[3:0] = ST_INIT_WAIT; 
    ST_INIT_WAIT :  begin
                        if( (aribitration_lose == 1'b1) || (slave_no_response == 1'b1) )
                            state_n[3:0] = ST_IDLE; 
                        else if( trans_done == 1'b1 )
                            state_n[3:0] = ST_INIT_DADD; 
                        else
                            state_n[3:0] = ST_INIT_WAIT;
                    end
    ST_INIT_DADD :          state_n[3:0] = ST_INIT_DCOM; 
    ST_INIT_DCOM :  begin
                        if( counter_dev_eq == 1'b1 )
                            state_n[3:0] = ST_COMM_IDLE; 
                        else
                            state_n[3:0] = ST_INIT_TREN;
                    end
    ST_COMM_IDLE :          state_n[3:0] = ST_COMM_TREN;
    ST_COMM_TREN :          state_n[3:0] = ST_COMM_WAIT;
    ST_COMM_WAIT :  begin
                        if( (aribitration_lose == 1'b1) || (slave_no_response == 1'b1) )
                            state_n[3:0] = ST_IDLE; 
                        else if( trans_done == 1'b1 )
                            state_n[3:0] = ST_COMM_FADD; 
                        else
                            state_n[3:0] = ST_COMM_WAIT;
                    end
    ST_COMM_FADD :          state_n[3:0] = ST_COMM_FCOM;
    ST_COMM_FCOM :  begin
                        if( counter_fram_eq == 1'b1 )
                            state_n[3:0] = ST_COMM_DADD; 
                        else
                            state_n[3:0] = ST_COMM_TREN;
                    end
    ST_COMM_DADD :          state_n[3:0] = ST_COMM_DCOM;
    ST_COMM_DCOM :  begin
                        if( counter_dev_eq == 1'b1 )
                            state_n[3:0] = ST_COMM_LOOP; 
                        else
                            state_n[3:0] = ST_COMM_TREN;
                    end
    ST_COMM_LOOP :  begin
                        if( (en_module == 1'b1) && (bus_busy == 1'b0) )
                            state_n[3:0] = ST_COMM_IDLE; 
                        else
                            state_n[3:0] = ST_IDLE;
                    end
    default :               state_n[3:0] = ST_IDLE;
    endcase
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        trans_en            <= #1 1'b0;
        counter_dev_en      <= #1 1'b0;
        counter_dev_clr     <= #1 1'b0;
        counter_fram_en     <= #1 1'b0;
        counter_fram_clr    <= #1 1'b0;
    end
    else begin
        case(state_n[3:0])
        ST_INIT_DCLR :  begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b1;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b0;
                        end
        ST_INIT_TREN :  begin
                            trans_en            <= #1 1'b1;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b0;
                        end
        ST_INIT_DADD :  begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b1;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b0;
                        end
        ST_COMM_IDLE :  begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b1;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b1;
                        end
        ST_COMM_TREN :  begin
                            trans_en            <= #1 1'b1;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b0;
                        end
        ST_COMM_FADD :  begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b1;
                            counter_fram_clr    <= #1 1'b0;
                        end
        ST_COMM_DADD :  begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b1;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b1;
                        end
        default :       begin
                            trans_en            <= #1 1'b0;
                            counter_dev_en      <= #1 1'b0;
                            counter_dev_clr     <= #1 1'b0;
                            counter_fram_en     <= #1 1'b0;
                            counter_fram_clr    <= #1 1'b0;
                        end
        endcase
    end
end

//设备地址
reg     [7:0]   slave_addr;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        slave_addr[7:0] <= #1 8'hff;
    else 
        slave_addr[7:0] <= #1 dev_addr[counter_dev[7:0]];
end

//写通道配置
reg     [15:0]  write_number;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        write_number[15:0] <= #1 16'h0;
    else if( state_n[3:0] == ST_INIT_TREN )
        write_number[15:0] <= #1 init_cmd_cnt;
    else if( state_n[3:0] == ST_COMM_TREN )
        write_number[15:0] <= #1 comm_cmd_w_cnt[counter_fram[7:0]];
end

wire    [15:0]  write_count;
reg     [7:0]   data_w;
always @(*) begin
    if( state_n[3:0] == ST_INIT_WAIT )
        data_w[7:0] = init_cmd[write_count[15:0]];
    else if( state_n[3:0] == ST_COMM_WAIT )
        data_w[7:0] = comm_cmd[counter_fram[7:0]][write_count[15:0]];
    else
        data_w[7:0] = 8'h0;
end

//读通道配置
reg     [15:0]  read_number;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        read_number[15:0] <= #1 16'h0;
    else if( state_n[3:0] == ST_COMM_TREN )
        read_number[15:0] <= #1 comm_cmd_r_cnt[counter_fram[7:0]];
end

wire    [15:0]  read_count;
wire    [7:0]   data_r;
wire            byte_r_done;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        v_ce0_0v8_l[7:0]     <= #1 8'h0;
        v_ce0_0v8_h[1:0]     <= #1 2'h0;
        i_ce0_0v8_l[7:0]     <= #1 8'h0;
        i_ce0_0v8_h[1:0]     <= #1 2'h0;
        v_ce0_0v9_l[7:0]     <= #1 8'h0;
        v_ce0_0v9_h[1:0]     <= #1 2'h0;
        i_ce0_0v9_l[7:0]     <= #1 8'h0;
        i_ce0_0v9_h[1:0]     <= #1 2'h0;
        v_ce0_1v2_l[7:0]     <= #1 8'h0;
        v_ce0_1v2_h[1:0]     <= #1 2'h0;
        i_ce0_1v2_l[7:0]     <= #1 8'h0;
        i_ce0_1v2_h[1:0]     <= #1 2'h0;
        t_ce0_power_l[7:0]   <= #1 8'h0;
        t_ce0_power_h[0:0]   <= #1 1'h0;
        v_ce1_0v8_l[7:0]     <= #1 8'h0;
        v_ce1_0v8_h[1:0]     <= #1 2'h0;
        i_ce1_0v8_l[7:0]     <= #1 8'h0;
        i_ce1_0v8_h[1:0]     <= #1 2'h0;
        v_ce1_0v9_l[7:0]     <= #1 8'h0;
        v_ce1_0v9_h[1:0]     <= #1 2'h0;
        i_ce1_0v9_l[7:0]     <= #1 8'h0;
        i_ce1_0v9_h[1:0]     <= #1 2'h0;
        v_ce1_1v2_l[7:0]     <= #1 8'h0;
        v_ce1_1v2_h[1:0]     <= #1 2'h0;
        i_ce1_1v2_l[7:0]     <= #1 8'h0;
        i_ce1_1v2_h[1:0]     <= #1 2'h0;
        t_ce1_power_l[7:0]   <= #1 8'h0;
        t_ce1_power_h[0:0]   <= #1 1'h0;
        v_ce2_0v8_l[7:0]     <= #1 8'h0;
        v_ce2_0v8_h[1:0]     <= #1 2'h0;
        i_ce2_0v8_l[7:0]     <= #1 8'h0;
        i_ce2_0v8_h[1:0]     <= #1 2'h0;
        v_ce2_0v9_l[7:0]     <= #1 8'h0;
        v_ce2_0v9_h[1:0]     <= #1 2'h0;
        i_ce2_0v9_l[7:0]     <= #1 8'h0;
        i_ce2_0v9_h[1:0]     <= #1 2'h0;
        v_ce2_1v2_l[7:0]     <= #1 8'h0;
        v_ce2_1v2_h[1:0]     <= #1 2'h0;
        i_ce2_1v2_l[7:0]     <= #1 8'h0;
        i_ce2_1v2_h[1:0]     <= #1 2'h0;
        t_ce2_power_l[7:0]   <= #1 8'h0;
        t_ce2_power_h[0:0]   <= #1 1'h0;
        v_ce3_0v8_l[7:0]     <= #1 8'h0;
        v_ce3_0v8_h[1:0]     <= #1 2'h0;
        i_ce3_0v8_l[7:0]     <= #1 8'h0;
        i_ce3_0v8_h[1:0]     <= #1 2'h0;
        v_ce3_0v9_l[7:0]     <= #1 8'h0;
        v_ce3_0v9_h[1:0]     <= #1 2'h0;
        i_ce3_0v9_l[7:0]     <= #1 8'h0;
        i_ce3_0v9_h[1:0]     <= #1 2'h0;
        v_ce3_1v2_l[7:0]     <= #1 8'h0;
        v_ce3_1v2_h[1:0]     <= #1 2'h0;
        i_ce3_1v2_l[7:0]     <= #1 8'h0;
        i_ce3_1v2_h[1:0]     <= #1 2'h0;
        t_ce3_power_l[7:0]   <= #1 8'h0;
        t_ce3_power_h[0:0]   <= #1 1'h0;
        v_ce4_0v8_l[7:0]     <= #1 8'h0;
        v_ce4_0v8_h[1:0]     <= #1 2'h0;
        i_ce4_0v8_l[7:0]     <= #1 8'h0;
        i_ce4_0v8_h[1:0]     <= #1 2'h0;
        v_ce4_0v9_l[7:0]     <= #1 8'h0;
        v_ce4_0v9_h[1:0]     <= #1 2'h0;
        i_ce4_0v9_l[7:0]     <= #1 8'h0;
        i_ce4_0v9_h[1:0]     <= #1 2'h0;
        v_ce4_1v2_l[7:0]     <= #1 8'h0;
        v_ce4_1v2_h[1:0]     <= #1 2'h0;
        i_ce4_1v2_l[7:0]     <= #1 8'h0;
        i_ce4_1v2_h[1:0]     <= #1 2'h0;
        t_ce4_power_l[7:0]   <= #1 8'h0;
        t_ce4_power_h[0:0]   <= #1 1'h0;
        v_ce5_0v8_l[7:0]     <= #1 8'h0;
        v_ce5_0v8_h[1:0]     <= #1 2'h0;
        i_ce5_0v8_l[7:0]     <= #1 8'h0;
        i_ce5_0v8_h[1:0]     <= #1 2'h0;
        v_ce5_0v9_l[7:0]     <= #1 8'h0;
        v_ce5_0v9_h[1:0]     <= #1 2'h0;
        i_ce5_0v9_l[7:0]     <= #1 8'h0;
        i_ce5_0v9_h[1:0]     <= #1 2'h0;
        v_ce5_1v2_l[7:0]     <= #1 8'h0;
        v_ce5_1v2_h[1:0]     <= #1 2'h0;
        i_ce5_1v2_l[7:0]     <= #1 8'h0;
        i_ce5_1v2_h[1:0]     <= #1 2'h0;
        t_ce5_power_l[7:0]   <= #1 8'h0;
        t_ce5_power_h[0:0]   <= #1 1'h0;
        v_ce6_0v8_l[7:0]     <= #1 8'h0;
        v_ce6_0v8_h[1:0]     <= #1 2'h0;
        i_ce6_0v8_l[7:0]     <= #1 8'h0;
        i_ce6_0v8_h[1:0]     <= #1 2'h0;
        v_ce6_0v9_l[7:0]     <= #1 8'h0;
        v_ce6_0v9_h[1:0]     <= #1 2'h0;
        i_ce6_0v9_l[7:0]     <= #1 8'h0;
        i_ce6_0v9_h[1:0]     <= #1 2'h0;
        v_ce6_1v2_l[7:0]     <= #1 8'h0;
        v_ce6_1v2_h[1:0]     <= #1 2'h0;
        i_ce6_1v2_l[7:0]     <= #1 8'h0;
        i_ce6_1v2_h[1:0]     <= #1 2'h0;
        t_ce6_power_l[7:0]   <= #1 8'h0;
        t_ce6_power_h[0:0]   <= #1 1'h0;
    end
    else if(byte_r_done == 1'b1) begin
        case({counter_dev[7:0], counter_fram[7:0], read_count[15:0]}) //设备, 帧, 字节
            32'h00_01_0000 :        v_ce0_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_01_0001 :        v_ce0_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h00_02_0000 :        i_ce0_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_02_0001 :        i_ce0_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h00_03_0000 :        t_ce0_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h00_03_0001 :        t_ce0_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h00_05_0000 :        v_ce0_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_05_0001 :        v_ce0_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h00_06_0000 :        i_ce0_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_06_0001 :        i_ce0_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h00_08_0000 :        v_ce0_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_08_0001 :        v_ce0_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h00_09_0000 :        i_ce0_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h00_09_0001 :        i_ce0_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_01_0000 :        v_ce1_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_01_0001 :        v_ce1_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_02_0000 :        i_ce1_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_02_0001 :        i_ce1_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_03_0000 :        t_ce1_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h01_03_0001 :        t_ce1_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h01_05_0000 :        v_ce1_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_05_0001 :        v_ce1_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_06_0000 :        i_ce1_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_06_0001 :        i_ce1_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_08_0000 :        v_ce1_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_08_0001 :        v_ce1_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h01_09_0000 :        i_ce1_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h01_09_0001 :        i_ce1_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_01_0000 :        v_ce2_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_01_0001 :        v_ce2_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_02_0000 :        i_ce2_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_02_0001 :        i_ce2_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_03_0000 :        t_ce2_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h02_03_0001 :        t_ce2_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h02_05_0000 :        v_ce2_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_05_0001 :        v_ce2_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_06_0000 :        i_ce2_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_06_0001 :        i_ce2_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_08_0000 :        v_ce2_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_08_0001 :        v_ce2_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h02_09_0000 :        i_ce2_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h02_09_0001 :        i_ce2_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_01_0000 :        v_ce3_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_01_0001 :        v_ce3_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_02_0000 :        i_ce3_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_02_0001 :        i_ce3_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_03_0000 :        t_ce3_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h03_03_0001 :        t_ce3_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h03_05_0000 :        v_ce3_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_05_0001 :        v_ce3_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_06_0000 :        i_ce3_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_06_0001 :        i_ce3_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_08_0000 :        v_ce3_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_08_0001 :        v_ce3_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h03_09_0000 :        i_ce3_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h03_09_0001 :        i_ce3_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_01_0000 :        v_ce4_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_01_0001 :        v_ce4_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_02_0000 :        i_ce4_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_02_0001 :        i_ce4_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_03_0000 :        t_ce4_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h04_03_0001 :        t_ce4_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h04_05_0000 :        v_ce4_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_05_0001 :        v_ce4_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_06_0000 :        i_ce4_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_06_0001 :        i_ce4_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_08_0000 :        v_ce4_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_08_0001 :        v_ce4_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h04_09_0000 :        i_ce4_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h04_09_0001 :        i_ce4_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_01_0000 :        v_ce5_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_01_0001 :        v_ce5_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_02_0000 :        i_ce5_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_02_0001 :        i_ce5_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_03_0000 :        t_ce5_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h05_03_0001 :        t_ce5_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h05_05_0000 :        v_ce5_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_05_0001 :        v_ce5_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_06_0000 :        i_ce5_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_06_0001 :        i_ce5_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_08_0000 :        v_ce5_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_08_0001 :        v_ce5_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h05_09_0000 :        i_ce5_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h05_09_0001 :        i_ce5_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_01_0000 :        v_ce6_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_01_0001 :        v_ce6_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_02_0000 :        i_ce6_0v8_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_02_0001 :        i_ce6_0v8_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_03_0000 :        t_ce6_power_l[7:0]  <= #1 data_r[7:0] ;
            32'h06_03_0001 :        t_ce6_power_h[0:0]  <= #1 data_r[0:0] ;
            32'h06_05_0000 :        v_ce6_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_05_0001 :        v_ce6_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_06_0000 :        i_ce6_0v9_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_06_0001 :        i_ce6_0v9_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_08_0000 :        v_ce6_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_08_0001 :        v_ce6_1v2_h[1:0]    <= #1 data_r[1:0] ;
            32'h06_09_0000 :        i_ce6_1v2_l[7:0]    <= #1 data_r[7:0] ;
            32'h06_09_0001 :        i_ce6_1v2_h[1:0]    <= #1 data_r[1:0] ;
        endcase
    end
end

smbus_master u_smbus_master(
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .slave_addr         (slave_addr[7:0]    ),      //从设备地址 
    .prescale           (prescale[15:0]     ),      //时钟分频系数 prescale = clk / ( 5 * desire scl ) - 1

    .trans_en           (trans_en           ),      //帧传输使能, 边沿触发
    .trans_abort        (1'b0               ),      //帧传输中止, 边沿触发
    .trans_done         (trans_done         ),      //帧传输结束, 边沿触发

    .write_number       (write_number[15:0] ),      //发送或接收的字节数量, 不包含器件地址
    .write_count        (write_count[15:0]  ),      //传输字节的数量, 不包含器件地址
    .data_w             (data_w[7:0]        ),      //master 发送的数据
    .byte_w_done        ( ),                        //字节发送完成

    .read_number        (read_number[15:0]  ),      //发送或接收的字节数量, 不包含器件地址
    .read_count         (read_count[15:0]   ),      //传输字节的数量, 不包含器件地址
    .data_r             (data_r[7:0]        ),      //master 接收的数据
    .byte_r_done        (byte_r_done        ),      //字节接收完成

    .bus_busy           (bus_busy           ),      //总线忙
    .aribitration_lose  (aribitration_lose  ),      //多主机仲裁丢失
    .slave_no_response  (slave_no_response  ),      //设备应答

    .scl_pad_i          (scl_pad_i          ),      //SCL-line input 
    .scl_padoen_o       (scl_padoen_o       ),      //SCL-line output enable (active low)
    .sda_pad_i          (sda_pad_i          ),      //SDA-line input
    .sda_padoen_o       (sda_padoen_o       )       //SDA-line output enable (active low)
);

endmodule