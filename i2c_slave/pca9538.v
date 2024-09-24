`include "timescale.v"

module pca9538 #(
    parameter           CLK_FREQ = 100
)(
    input               clk             ,
    input               rst_n           ,
    
    input       [7:0]   slave_addr      ,

    input       [7:0]   p_in            ,
    output      [7:0]   p_out           ,
    output      [7:0]   p_oe_n          ,

    input               scl_pad_i       ,   //SCL-line input
    input               sda_pad_i       ,   //SDA-line input
    output              sda_pad_oen         //SDA-line output enable
);

reg     [7:0]   reg_0;  //input port reg
reg     [7:0]   reg_1;  //output port reg
reg     [7:0]   reg_2;  //polarity inversion reg    (1反转)
reg     [7:0]   reg_3;  //configuration reg         (0输出)

//发送到master
wire    [7:0]   regaddr;  
reg     [7:0]   data_in;
always @(*) begin
    case (regaddr[7:0])
        8'h00:      data_in[7:0] <= reg_0[7:0] ;
        8'h01:      data_in[7:0] <= reg_1[7:0] ;
        8'h02:      data_in[7:0] <= reg_2[7:0] ;
        8'h03:      data_in[7:0] <= reg_3[7:0] ;
        default:    data_in[7:0] <= 8'hff      ;
    endcase
end

//从master接收
wire            wr_en;
wire    [7:0]   data_out;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_1[7:0] <= #1 8'hff;
        reg_2[7:0] <= #1 8'h0;
        reg_3[7:0] <= #1 8'hff;
    end
    else if(wr_en == 1'b1) begin
        case(regaddr[7:0])
            8'h01: reg_1[7:0] <= #1 data_out[7:0] ;
            8'h02: reg_2[7:0] <= #1 data_out[7:0] ;
            8'h03: reg_3[7:0] <= #1 data_out[7:0] ;    
        endcase
    end
end

assign          p_out[7:0]  = reg_1[7:0];
assign          p_oe_n[7:0] = reg_3[7:0];
always @(posedge clk) begin
    reg_0[7:0]  <= #1 p_in[7:0] ^ (reg_2[7:0] & reg_3[7:0]);
end

i2c_slave #(
    .CLK_FREQ       (CLK_FREQ           )
)u_i2c_slave(
    .clk            (clk                ),
    .rst_n          (rst_n              ),
    .slave_addr     (slave_addr[7:0]    ),   //器件地址
    .reg_addr       (regaddr[7:0]       ),   //寄存器地址 
    .wr_en          (wr_en              ),   //master写  
    .data_out       (data_out[7:0]      ),   //master发送的数据 
    .data_in        (data_in[7:0]       ),   //master接收的数据 
    .scl_pad_i      (scl_pad_i          ),   //SCL-line input
    .sda_pad_i      (sda_pad_i          ),   //SDA-line input
    .sda_pad_oen    (sda_pad_oen        )    //SDA-line output enable
);

endmodule
