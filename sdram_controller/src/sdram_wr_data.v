`include "timescale.v"
`include "sdram_para.v"

module  sdram_wr_data(
    //系统信号
    input                               clk             ,//系统时钟，100MHz
    input                               rst_n           ,//复位信号，低电平有效

    //SDRAM硬件接口
//  output                              sdram_clk       ,//SDRAM时钟信号
    inout           [`WIDTH_DATA-1:0]   sdram_data      ,//SDRAM数据总线
    
    //SDRAM封装接口
    input           [`WIDTH_DATA-1:0]   sys_data_in     ,//写SDRAM时数据暂存器
    output          [`WIDTH_DATA-1:0]   sys_data_out    ,//读SDRAM时数据暂存器

    //SDRAM内部接口
    input           [3:0]               work_state       //读写SDRAM时数据状态寄存器
//  input           [8:0]               cnt_clk          //时钟计数
);
                    
//assign sdram_clk = ~clk;                                          //SDRAM时钟信号

//------------------------------------------------------------------------------
//数据写入控制
//------------------------------------------------------------------------------

//将待写入数据送到SDRAM数据总线上
reg     [`WIDTH_DATA-1:0]   sdr_din;                                //突发数据写寄存器
always @ (posedge clk or negedge rst_n) 
    if(!rst_n) 
        sdr_din[`WIDTH_DATA-1:0] <= #1 {`WIDTH_DATA{1'b0}};         //突发数据写寄存器复位
    else if((work_state == `W_WRITE) | (work_state == `W_WD)) 
        sdr_din[`WIDTH_DATA-1:0] <= #1 sys_data_in[`WIDTH_DATA-1:0];//连续写入存储在wrFIFO中的数据

//产生双向数据线方向控制逻辑
reg             sdr_dlink;                                          //SDRAM数据总线输入输出控制
always @ (posedge clk or negedge rst_n) 
    if(!rst_n) 
        sdr_dlink <= #1 1'b0;
    else if((work_state == `W_WRITE) | (work_state == `W_WD)) 
        sdr_dlink <= #1 1'b1;
    else 
        sdr_dlink <= #1 1'b0;

assign  sdram_data[`WIDTH_DATA-1:0] = sdr_dlink ? sdr_din[`WIDTH_DATA-1:0] : {`WIDTH_DATA{1'bZ}};

//------------------------------------------------------------------------------
//数据读出控制
//------------------------------------------------------------------------------

//将数据从SDRAM读出
reg     [`WIDTH_DATA-1:0]   sdr_dout;                               //突发数据读寄存器	
always @ (posedge clk or negedge rst_n)
    if(!rst_n) 
        sdr_dout[`WIDTH_DATA-1:0] <= #1 {`WIDTH_DATA{1'b0}};        //突发数据读寄存器复位
    else if((work_state == `W_RD)/* & (cnt_clk > 9'd0) & (cnt_clk < 9'd10)*/) 
        sdr_dout[`WIDTH_DATA-1:0] <= #1 sdram_data[`WIDTH_DATA-1:0];//连续读出数据存储到rdFIFO中

assign sys_data_out[`WIDTH_DATA-1:0] = sdr_dout[`WIDTH_DATA-1:0];

//------------------------------------------------------------------------------

endmodule
