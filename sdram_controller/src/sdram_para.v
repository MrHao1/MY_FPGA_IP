//SDRAM初始化状态定义
`define             I_NOP                       4'd0            //等待上电200us稳定期结束
`define             I_PRE                       4'd1            //预充电状态
`define             I_TRP                       4'd2            //等待预充电完成           tRP
`define             I_AR1                       4'd3            //第1次自刷新
`define             I_TRF1                      4'd4            //等待第1次自刷新结束      tRFC
`define             I_AR2                       4'd5            //第2次自刷新
`define             I_TRF2                      4'd6            //等待第2次自刷新结束       tRFC	
`define             I_MRS                       4'd7            //模式寄存器设置
`define             I_TMRD                      4'd8            //等待模式寄存器设置完成    tMRD
`define             I_DONE                      4'd9            //初始化完成

//SDRAM工作状态定义
`define             W_IDLE                      4'd0            //空闲状态
`define             W_ACTIVE                    4'd1            //行有效，判断读写
`define             W_TRCD                      4'd2            //行有效等待
`define             W_READ                      4'd3            //读数据状态
`define             W_CL                        4'd4            //等待潜伏期
`define             W_RD                        4'd5            //读数据
`define             W_RWAIT                     4'd6            //读完成后的预充电等待状态
`define             W_WRITE                     4'd7            //写数据状态
`define             W_WD                        4'd8            //写数据
`define             W_TDAL                      4'd9            //写完成后的预充电等待状态
`define             W_AR                        4'd10           //自刷新
`define             W_TRFC                      4'd11           //自刷新等待

//SDRAM控制命令
`define             CMD_INIT                    5'b01111        //上电初始化命令端口		
`define             CMD_NOP                     5'b10111        //NOP COMMAND
`define             CMD_ACTIVE                  5'b10011        //ACTIVE COMMAND
`define             CMD_READ                    5'b10101        //READ COMMADN
`define             CMD_WRITE                   5'b10100        //WRITE COMMAND
`define             CMD_B_STOP                  5'b10110        //BURST STOP
`define             CMD_PRGE                    5'b10010        //PRECHARGE
`define             CMD_A_REF                   5'b10001        //AOTO REFRESH
`define             CMD_LMR                     5'b10000        //LODE MODE REGISTER

//SDRAM时序参数(需针对具体硬件调整)
//100M 10ns
`define             TRP_CLK                     9'd2            //TRP=20ns min预充电有效周期
`define             TRFC_CLK                    9'd7            //TRC=70ns min自动预刷新周期
`define             TMRD_CLK                    9'd2            //2 cycle 模式寄存器设置等待时钟周期
`define             TRCD_CLK                    9'd2            //TRCD=20ns min行选通周期
`define             TCL_CLK                     9'd3            //3 cycle 潜伏期，在初始化模式寄存器中可设置
//`define           TREAD_CLK                   9'd256          //8 突发读数据周期8CLK
//`define           TWRITE_CLK                  9'd256          //8 突发写数据8CLK
`define             TDAL_CLK                    9'd5            //5 cycle,写入等待+预充电

`define             end_trp     (cnt_clk_r  ==  `TRP_CLK   )    
`define             end_trfc    (cnt_clk_r  ==  `TRFC_CLK  )    
`define             end_tmrd    (cnt_clk_r  ==  `TMRD_CLK  )    
`define             end_trcd    (cnt_clk_r  ==  `TRCD_CLK-1)    
`define             end_tcl     (cnt_clk_r  ==  `TCL_CLK-1 )    
`define             end_rdburst (cnt_clk    ==  sdrd_byte-4)    //TREAD_CLK-4   发出突发读中断命令
`define             end_tread   (cnt_clk_r  ==  sdrd_byte+2)    //TREAD_CLK+2   TREAD_CLK+2
`define             end_wrburst (cnt_clk    ==  sdwr_byte-1)    //TWRITE_CLK-1  发出突发写中断命令
`define             end_twrite  (cnt_clk_r  ==  sdwr_byte-1)    //TWRITE_CLK-1
`define             end_tdal    (cnt_clk_r  ==  `TDAL_CLK  )    
`define             end_trwait  (cnt_clk_r  ==  `TRP_CLK   )    

//SDRAM模式寄存器(需针对具体硬件调整)
`define             reg_burst_length            3'b111          //1, 2, 4, 8, full page(256, 列地址位宽为8bit). 突发传输时可以指定起始地址,但是数据无法跨页.
`define             reg_burst_type              1'b0            //0:顺序 1:交织
`define             reg_latency_mode            3'b011          //2, 3
`define             reg_mrs                     2'b00           //mode register set
`define             reg_burst_mode              1'b0            //0:burst write 1:single bit write

//SDRAM硬件接口(需针对具体硬件调整)(8M Byte)
`define             WIDTH_DATA                  32              //数据位宽
`define             WIDTH_ROW                   11              //行宽度
`define             WIDTH_COL                   8               //列宽度
`define             WIDTH_BA                    2               //BA位宽
`define             WIDTH_DM                    4               //DM位宽

//时间参数(需针对具体硬件调整)
`define             time_200us                  16'd20000       //sdram上电等待200us
`define             time_refresh                12'd1563        //sdram刷新周期 64ms/行数(4096)
