`include "timescale.v"

module  my_fifo(
    //系统信号
    input                               rst_n           ,//复位信号，低电平有效

    //写端口
    input                               wr_clk          ,//写时钟
    input                               wr_en           ,//写使能
    input           [31:0]              wr_data         ,//写数据
    output  reg                         wr_almost_full  ,//
    output  reg                         wr_full         ,//

    //读端口
    input                               rd_clk          ,//读时钟
    input                               rd_en           ,//读使能
    output  reg     [31:0]              rd_data         ,//读数据
    output  reg                         rd_almost_empty ,//
    output  reg                         rd_empty         //
);

/*不同厂商对RAM的综合机制存在差异, 有些会使用BRAM资源, 有些则使用寄存器资源.
使用寄存器综合会占用大量寄存器和查找表, 应避免.*/
reg     [31:0]  ram_fifo[255:0];

//写指针
reg     [8:0]   wr_addr;
always@(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
        wr_addr[8:0] <= #1 9'h0;
    else if((wr_en == 1'b1) && (wr_full == 1'b0))
        wr_addr[8:0] <= #1 wr_addr[8:0] + 1'b1;
end

//读指针
reg     [8:0]   rd_addr;
always@(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        rd_addr[8:0] <= #1 9'h0;
    else if((rd_en == 1'b1) && (rd_empty == 1'b0))
        rd_addr[8:0] <= #1 rd_addr[8:0] + 1'b1;
end

//写入到FIFO
//integer i;
always@(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
//        for(i = 0; i < 256; i = i + 1)
//            ram_fifo[i] <= #1 32'h0;
    end
    else if((wr_en == 1'b1) && (wr_full == 1'b0))
        ram_fifo[wr_addr[7:0]] <= #1 wr_data[31:0];
end

//从FIFO读出
always@(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        rd_data[31:0] <= #1 32'h0;
    else if(rd_en == 1'b1)
        rd_data[31:0] <= #1 ram_fifo[rd_addr[7:0]];
end

//满标志, 亚稳态?
wire    [8:0]   wr_addr_add_1;
assign          wr_addr_add_1[8:0] = wr_addr[8:0] + 9'h1;
always@(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
        wr_full <= #1 1'h0;
    else if( ((wr_addr_add_1[8] != rd_addr[8]) && (wr_addr_add_1[7:0] == rd_addr[7:0])) ||
             ((wr_addr[8] != rd_addr[8]) && (wr_addr[7:0] == rd_addr[7:0])) )
        wr_full <= #1 1'h1;
    else
        wr_full <= #1 1'h0;
end

//将满标志, 亚稳态?
wire    [8:0]   wr_addr_add_2;
assign          wr_addr_add_2[8:0] = wr_addr[8:0] + 9'h2;
always@(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
        wr_almost_full <= #1 1'h0;
    else if((wr_addr_add_2[8] != rd_addr[8]) && (wr_addr_add_2[7:0] == rd_addr[7:0]))
        wr_almost_full <= #1 1'h1;
    else
        wr_almost_full <= #1 1'h0;
end

//空标志, 亚稳态?
wire    [8:0]   rd_addr_add_1;
assign          rd_addr_add_1[8:0] = rd_addr[8:0] + 9'h1;
always@(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        rd_empty <= #1 1'b1;
    else if( (wr_addr[8:0] == rd_addr_add_1[8:0]) || 
             (wr_addr[8:0] == rd_addr[8:0]) )
        rd_empty <= #1 1'b1;
    else
        rd_empty <= #1 1'b0;
end

//将空标志, 亚稳态?
wire    [8:0]   rd_addr_add_2;
assign          rd_addr_add_2[8:0] = rd_addr[8:0] + 9'h2;
always@(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        rd_almost_empty <= #1 1'b0;
    else if(wr_addr[8:0] == rd_addr_add_2[8:0])
        rd_almost_empty <= #1 1'b1;
    else
        rd_almost_empty <= #1 1'b0;
end

endmodule