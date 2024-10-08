`include "timescale.v"
`include "sdram_para.v"

module sim_sdram(); 

reg     rst_n;
reg     clk_100m;
reg     clk_100m_d;


initial begin
        clk_100m = 1'b0;
        clk_100m_d = 1'b0;
        rst_n    = 1'b0;
    #50 rst_n    = 1'b1;
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


wire    [31:0]  dram_Dq   ;
wire    [10:0]  dram_Addr ;
wire    [1:0]   dram_Ba   ;
wire            dram_Cke  ;
wire            dram_Cs_n ;
wire            dram_Ras_n;
wire            dram_Cas_n;
wire            dram_We_n ;
wire    [3:0]   dram_Dqm  ;

wire            sdram_rd_ack;
wire    [31:0]  sys_data_out;

wire            sdram_busy;
wire            sdram_init_done;
reg             sdram_wr_req;
reg     [31:0]  sys_data_in;

wire            sdram_wr_ack;
reg             wr_flag;
always@(posedge clk_100m or negedge rst_n) begin
    if(!rst_n) begin
        sdram_wr_req <= #1 1'b0;
        wr_flag      <= #1 1'b0;
    end
    else if(sdram_init_done == 1'b0) begin
        sdram_wr_req <= #1 1'b0;
        wr_flag      <= #1 1'b0;
    end
    else if(sdram_wr_ack == 1'b1) begin
        sdram_wr_req <= #1 1'b0;
        wr_flag      <= #1 1'b1;
    end
    else if(wr_flag == 1'b0) begin
        sdram_wr_req <= #1 1'b1;
        wr_flag      <= #1 1'b0;
    end
end

reg             sdram_rd_req;
always@(posedge clk_100m or negedge rst_n) begin
    if(!rst_n) begin
        sdram_rd_req <= #1 1'b0;
    end
    else if((sdram_init_done == 1'b1) && (sdram_busy == 1'b0) && (sys_data_in[31:0] == 32'd256)) begin
        sdram_rd_req <= #1 1'b1;
    end
    else begin
        sdram_rd_req <= #1 1'b0;
    end
end

//写入1到256
always@(posedge clk_100m or negedge rst_n) begin
    if(!rst_n) begin
        sys_data_in[31:0] <= #1 32'd0;
    end
    else if((sdram_wr_ack == 1'b1) && (sys_data_in[31:0] < 32'd256)) begin
        sys_data_in[31:0] <= #1 sys_data_in[31:0] + 32'd1;
    end
end

sdram_phy u_sdram_phy(
    .clk                 (clk_100m          ),//系统时钟
    .rst_n               (rst_n             ),//复位信号，低电平有效

    //用户接口
    .sdram_wr_req        (sdram_wr_req      ),//i系统写SDRAM请求信号
    .sdram_wr_ack        (sdram_wr_ack      ),//o系统写SDRAM响应信号,作为wrFIFO的输出有效信号
    .sys_wraddr          (21'h0             ),//i写SDRAM时地址暂存器，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址
    .sdwr_byte           (256               ),//i突发写SDRAM字节数（1-256个）
    .sys_data_in         (sys_data_in       ),//i写SDRAM时数据暂存器，4个突发读写字数据，默认为00地址bit15-0;01地址bit31-16;10地址bit47-32;11地址bit63-48

    .sdram_rd_req        (sdram_rd_req      ),//i系统读SDRAM请求信号
    .sdram_rd_ack        (sdram_rd_ack      ),//o系统读SDRAM响应信号
    .sys_rdaddr          (21'h0             ),//i读SDRAM时地址暂存器，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址
    .sdrd_byte           (2               ),//i突发读SDRAM字节数（1-256个）
    .sys_data_out        (sys_data_out      ), //o读SDRAM时数据暂存器,(格式同上)

    .sdram_busy          (sdram_busy        ),//oSDRAM忙标志，高表示SDRAM处于工作中
    .sdram_init_done     (sdram_init_done   ),//o系统初始化完毕信号

    //SDRAM硬件接口
    .sdram_cke           (dram_Cke          ),//SDRAM时钟有效信号
    .sdram_cs_n          (dram_Cs_n         ),//SDRAM片选信号
    .sdram_ras_n         (dram_Ras_n        ),//SDRAM行地址选通脉冲
    .sdram_cas_n         (dram_Cas_n        ),//SDRAM列地址选通脉冲
    .sdram_we_n          (dram_We_n         ),//SDRAM写允许位
    .sdram_addr          (dram_Addr         ),//SDRAM地址总线
    .sdram_ba            (dram_Ba           ),//SDRAM的L-Bank地址线
    .sdram_data          (dram_Dq           ),//SDRAM数据总线
    .sdram_dqm           (dram_Dqm          ) //SDRAM低字节屏蔽
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
