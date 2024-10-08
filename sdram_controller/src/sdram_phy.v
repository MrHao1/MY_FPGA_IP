`include "timescale.v"
`include "sdram_para.v"
/*-----------------------------------------------------------------------------
SDRAM接口说明：
    上电复位时，SDRAM会自动等待200us然后进行初始化，具体模式寄存器的
设置参看sdram_ctrl模块。
    SDRAM的操作：
        控制sys_en=1,sys_r_wn=0,sys_addr,sys_data_in进行SDRAM数据写入
    操作；控制sys_en=1,sys_r_wn=1,sys_addr即可从sys_data_out读出数据。
    同时可以通过查询sdram_busy的状态查看读写是否完成。	
-----------------------------------------------------------------------------*/

module sdram_phy(
    input                                                   clk                 ,//时钟
    input                                                   rst_n               ,//复位，低电平有效

    //用户接口
    input                                                   sdram_wr_req        ,//写请求, 边沿触发, 优先级高于读
    output                                                  sdram_wr_ack        ,//写响应,作为wrFIFO的输出有效信号
    input           [`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]   sys_wraddr          ,//写地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    input           [8:0]                                   sdwr_byte           ,//突发写字节数（1-256个）
    input           [`WIDTH_DATA-1:0]                       sys_data_in         ,//写数据

    input                                                   sdram_rd_req        ,//读请求, 边沿触发
    output                                                  sdram_rd_ack        ,//读响应
    input           [`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]   sys_rdaddr          ,//读地址，(bit20-19)L-Bank地址:(bit18-8)为行地址，(bit7-0)为列地址 
    input           [8:0]                                   sdrd_byte           ,//突发读字节数（1-256个）
    output          [`WIDTH_DATA-1:0]                       sys_data_out        ,//读数据

    output                                                  sdram_busy          ,//SDRAM忙标志
//  output                                                  sys_dout_rdy        ,//SDRAM数据输出完成标志
    output                                                  sdram_init_done     ,//SDRAM初始化完毕信号

    //SDRAM硬件接口
//  output                                                  sdram_clk           ,//SDRAM时钟信号
    output                                                  sdram_cke           ,//SDRAM时钟有效信号
    output                                                  sdram_cs_n          ,//SDRAM片选信号
    output                                                  sdram_ras_n         ,//SDRAM行地址选通脉冲
    output                                                  sdram_cas_n         ,//SDRAM列地址选通脉冲
    output                                                  sdram_we_n          ,//SDRAM写允许位
    output          [`WIDTH_ROW-1:0]                        sdram_addr          ,//SDRAM地址总线
    output          [`WIDTH_BA-1:0]                         sdram_ba            ,//SDRAM的L-Bank地址线
    inout           [`WIDTH_DATA-1:0]                       sdram_data          ,//SDRAM数据总线
    output          [`WIDTH_DM-1:0]                         sdram_dqm            //SDRAM低字节屏蔽
);

//SDRAM内部接口
wire    [3:0]   init_state;         //SDRAM初始化寄存器
wire    [3:0]   work_state;         //SDRAM工作状态寄存器
wire    [8:0]   cnt_clk;            //时钟计数	
wire            sys_r_wn;           //SDRAM读/写控制信号
                
//SDRAM状态控制模块
sdram_ctrl u_sdram_ctrl(    
    .clk                (clk                ),						
    .rst_n              (rst_n              ),
    .sdram_dqm          (sdram_dqm          ),
    .sdram_wr_req       (sdram_wr_req       ),
    .sdram_rd_req       (sdram_rd_req       ),
    .sdram_wr_ack       (sdram_wr_ack       ),
    .sdram_rd_ack       (sdram_rd_ack       ),
    .sdwr_byte          (sdwr_byte          ),
    .sdrd_byte          (sdrd_byte          ),							
    .sdram_busy         (sdram_busy         ),
//  .sys_dout_rdy       (sys_dout_rdy       ),
    .sdram_init_done    (sdram_init_done    ),
    .init_state         (init_state         ),
    .work_state         (work_state         ),
    .cnt_clk            (cnt_clk            ),
    .sys_r_wn           (sys_r_wn           )
);

//SDRAM命令模块
sdram_cmd u_sdram_cmd(		
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    .sdram_cke          (sdram_cke          ),		
    .sdram_cs_n         (sdram_cs_n         ),	
    .sdram_ras_n        (sdram_ras_n        ),	
    .sdram_cas_n        (sdram_cas_n        ),	
    .sdram_we_n         (sdram_we_n         ),	
    .sdram_ba           (sdram_ba           ),			
    .sdram_addr         (sdram_addr         ),									
    .sys_wraddr         (sys_wraddr         ),	
    .sys_rdaddr         (sys_rdaddr         ),
    .sdwr_byte          (sdwr_byte          ),
    .sdrd_byte          (sdrd_byte          ),		
    .init_state         (init_state         ),	
    .work_state         (work_state         ),
    .sys_r_wn           (sys_r_wn           ),
    .cnt_clk            (cnt_clk            )
);

//SDRAM数据读写模块
sdram_wr_data u_sdram_wr_data(		
    .clk                (clk                ),
    .rst_n              (rst_n              ),
//  .sdram_clk          (sdram_clk          ),
    .sdram_data         (sdram_data         ),
    .sys_data_in        (sys_data_in        ),
    .sys_data_out       (sys_data_out       ),
    .work_state         (work_state         )
//  .cnt_clk            (cnt_clk            )
);

endmodule