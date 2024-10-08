`include "timescale.v"
`include "sdram_para.v"

module sdram_cmd(
    //系统信号
    input                                                   clk             ,
    input                                                   rst_n           ,
    
    //SDRAM硬件接口
    output                                                  sdram_cke       ,//SDRAM时钟有效信号
    output                                                  sdram_cs_n      ,//SDRAM片选信号
    output                                                  sdram_ras_n     ,//SDRAM行地址选通脉冲
    output                                                  sdram_cas_n     ,//SDRAM列地址选通脉冲
    output                                                  sdram_we_n      ,//SDRAM写允许位
    output          [`WIDTH_BA-1:0]                         sdram_ba        ,//SDRAM的L-Bank地址线
    output          [`WIDTH_ROW-1:0]                        sdram_addr      ,//SDRAM地址总线
    
    //SDRAM封装接口
    input           [`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]   sys_wraddr      ,//写SDRAM时地址暂存器，Bank地址,行地址,列地址
    input           [`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]   sys_rdaddr      ,//读SDRAM时地址暂存器，Bank地址,行地址,列地址  
    input           [8:0]                                   sdwr_byte       ,//突发写SDRAM字节数（1-256个）
    input           [8:0]                                   sdrd_byte       ,//突发读SDRAM字节数（1-256个）
    
    //SDRAM内部接口
    input           [3:0]                                   init_state      ,//SDRAM初始化状态寄存器
    input           [3:0]                                   work_state      ,//SDRAM读写状态寄存器
    input                                                   sys_r_wn        ,//SDRAM读/写控制信号
    input           [8:0]                                   cnt_clk          //时钟计数	
);

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
reg     [4:0]                               sdram_cmd_r;
reg     [`WIDTH_BA-1:0]                     sdram_ba_r;
reg     [`WIDTH_ROW-1:0]                    sdram_addr_r;

assign          {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n}   = sdram_cmd_r;
assign          sdram_ba[`WIDTH_BA-1:0]                                     = sdram_ba_r[`WIDTH_BA-1:0];
assign          sdram_addr[`WIDTH_ROW-1:0]                                  = sdram_addr_r[`WIDTH_ROW-1:0];

//-------------------------------------------------------------------------------
//SDRAM命令参数赋值
wire    [`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]  sys_addr;   
//读/写地址总线切换控制
assign          sys_addr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]               = sys_r_wn ? 
                                                                              sys_rdaddr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0]:
                                                                              sys_wraddr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:0];        

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sdram_cmd_r[4:0]                <= #1 `CMD_INIT;
        sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
        sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};
    end
    else begin
        case (init_state)
            `I_NOP,`I_TRP,`I_TRF1,`I_TRF2,`I_TMRD:  
                begin //上电等待, 预充电完成, 自刷新完成, 模式寄存器设置完成
                    sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};	
                end
            `I_PRE:                                 
                begin //预充电
                    sdram_cmd_r[4:0]                <= #1 `CMD_PRGE;
                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};
                end 
            `I_AR1,`I_AR2:                          
                begin //自刷新
                    sdram_cmd_r[4:0]                <= #1 `CMD_A_REF;
                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};						
                end 			 	
            `I_MRS: 
                begin //模式寄存器设置，可根据实际需要进行设置
                    sdram_cmd_r[4:0]                <= #1 `CMD_LMR;
                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b0}};
                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {
                                                           {(`WIDTH_ROW-10){1'b0}},
                                                           `reg_burst_mode,
                                                           `reg_mrs,
                                                           `reg_latency_mode,
                                                           `reg_burst_type,
                                                           `reg_burst_length
                                                          };
                end
            `I_DONE:
                begin //初始化完成
                    case (work_state)
                        `W_IDLE,`W_TRCD,`W_CL,`W_TRFC,`W_TDAL: 
                            begin //空闲, 行有效等待, 等待潜伏期, 自刷新等待, 等待写数据并完成自刷新
                                sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                                sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                                sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};
                            end
                        `W_ACTIVE: 
                            begin //行激活
                                sdram_cmd_r[4:0]                <= #1 `CMD_ACTIVE;
                                sdram_ba_r[`WIDTH_BA-1:0]       <= #1 sys_addr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:`WIDTH_ROW+`WIDTH_COL];//L-Bank地址
                                sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 sys_addr[`WIDTH_ROW+`WIDTH_COL-1:`WIDTH_COL];  //行地址
                            end
                        `W_READ: 
                            begin //读状态
                                sdram_cmd_r[4:0]                <= #1 `CMD_READ;
                                sdram_ba_r[`WIDTH_BA-1:0]       <= #1 sys_addr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:`WIDTH_ROW+`WIDTH_COL];//L-Bank地址
                                sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {
                                                                       {(`WIDTH_ROW-11){1'b0}},
                                                                       3'b100,                   //A10=1,设置读完成允许预充电
                                                                       sys_addr[`WIDTH_COL-1:0]  //列地址  
                                                                      };
                            end
                        `W_RD: 
                            begin //读
                                if(`end_rdburst) 
                                    sdram_cmd_r[4:0]                <= #1 `CMD_B_STOP;
                                else begin
                                    sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};
                                end
                            end
                        `W_WRITE: 
                            begin //写状态
                                sdram_cmd_r[4:0]                <= #1 `CMD_WRITE;
                                sdram_ba_r[`WIDTH_BA-1:0]       <= #1 sys_addr[`WIDTH_BA+`WIDTH_ROW+`WIDTH_COL-1:`WIDTH_ROW+`WIDTH_COL];//L-Bank地址
                                sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {
                                                                       {(`WIDTH_ROW-11){1'b0}},
                                                                       3'b100,                   //A10=1,设置写完成允许预充电
                                                                       sys_addr[`WIDTH_COL-1:0]  //列地址  
                                                                      };
                            end		
                        `W_WD: 
                            begin //写
                                if(`end_wrburst) 
                                    sdram_cmd_r[4:0]                <= #1 `CMD_B_STOP;
                                else begin
                                    sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};
                                end
                            end
                        `W_AR: 
                            begin //自刷新
                                    sdram_cmd_r[4:0]                <= #1 `CMD_A_REF;
                                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};	
                            end
                        default: 
                            begin
                                    sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                                    sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                                    sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};	
                            end
                    endcase
                end
            default:
                    begin
                        sdram_cmd_r[4:0]                <= #1 `CMD_NOP;
                        sdram_ba_r[`WIDTH_BA-1:0]       <= #1 {`WIDTH_BA{1'b1}};
                        sdram_addr_r[`WIDTH_ROW-1:0]    <= #1 {`WIDTH_ROW{1'b1}};	
                    end
        endcase
    end
end

endmodule