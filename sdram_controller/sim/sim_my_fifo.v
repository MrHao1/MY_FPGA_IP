`include "timescale.v"

module sim_myfifo(); 

reg     clk_100m_1;
reg     clk_100m_2;
reg     rst_n;

initial begin
        clk_100m_1 = 1'b0;
        clk_100m_2 = 1'b1;
        rst_n    = 1'b0;
    #50 rst_n    = 1'b1;
end

always begin
    #5  clk_100m_1 = ~clk_100m_1;
end

always begin
    #5  clk_100m_2 = ~clk_100m_2;
end

/*****************************************************/
wire            fifo_wr_almost_full;
wire            fifo_wr_full;
reg     [31:0]  fifo_wr_data;
always@(posedge clk_100m_1 or negedge rst_n) begin
    if(!rst_n) begin
        fifo_wr_data[31:0] <= #1 32'd0;
    end
    else if((fifo_wr_full != 1'h1) && (fifo_wr_data[31:0] < 32'd257))begin
        fifo_wr_data[31:0] <= #1 fifo_wr_data[31:0] + 32'd1;
    end
end

reg             fifo_wr_en;
always@(posedge clk_100m_1 or negedge rst_n) begin
    if(!rst_n) begin
       fifo_wr_en <= #1 1'h0;
    end
    else if(fifo_wr_data[31:0] == 32'd2)begin
       fifo_wr_en <= #1 1'h0;
    end
    else begin
       fifo_wr_en <= #1 1'h1;
    end
end

wire            fifo_rd_almost_empty;
wire            fifo_rd_empty;
wire    [31:0]  fifo_rd_data;
reg             fifo_rd_en;

initial begin
          fifo_rd_en = 1'b0;
    #2655 fifo_rd_en = 1'b1;
end

my_fifo u_my_fifo(
    //系统信号
    .rst_n           (rst_n                 ),//复位信号，低电平有效

    //写端口
    .wr_clk          (clk_100m_1            ),//i 写时钟
    .wr_en           (fifo_wr_en            ),//i 写使能
    .wr_data         (fifo_wr_data[31:0]    ),//i 写数据
    .wr_almost_full  (fifo_wr_almost_full   ),//o 
    .wr_full         (fifo_wr_full          ),//o 

    //读端口
    .rd_clk          (clk_100m_2            ),//i 读时钟
    .rd_en           (fifo_rd_en            ),//i 读使能
    .rd_data         (fifo_rd_data[31:0]    ),//o 读数据
    .rd_almost_empty (fifo_rd_almost_empty  ),//o 
    .rd_empty        (fifo_rd_empty         ) //o 
);

endmodule
