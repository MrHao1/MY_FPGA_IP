`include "timescale.v"

module i2c_slave #(
    parameter           CLK_FREQ = 100
    )(
    input               clk             ,
    input               rst_n           ,

    input       [7:0]   slave_addr      ,   //器件地址
    output      [7:0]   reg_addr        ,   //寄存器地址 
    output              wr_en           ,   //master写  
    output      [7:0]   data_out        ,   //master发送的数据 
    input       [7:0]   data_in         ,   //master接收的数据 

    input               scl_pad_i       ,   //SCL-line input
    input               sda_pad_i       ,   //SDA-line input
    output              sda_pad_oen         //SDA-line output enable
);

// System clock frequency in MHz
// If you are using a clock frequency below 24MHz, then the macro
// for SDA_DEL_LEN will result in compile errors for i2cSlave.v
// you will need to hand tweak the SDA_DEL_LEN constant definition
`define DEB_I2C_LEN (10*CLK_FREQ)/100
`define SCL_DEL_LEN (10*CLK_FREQ)/100
`define SDA_DEL_LEN ( 4*CLK_FREQ)/100

// start stop detection states
`define NULL_DET 2'b00
`define START_DET 2'b01
`define STOP_DET 2'b10

reg                         sdaDeb;
reg                         sclDeb;
reg     [`DEB_I2C_LEN-1:0]  sdaPipe;
reg     [`DEB_I2C_LEN-1:0]  sclPipe;
reg     [`SCL_DEL_LEN-1:0]  sclDelayed;
reg     [`SDA_DEL_LEN-1:0]  sdaDelayed;
reg     [1:0]               startStopDetState;
wire                        clearStartStopDet;
reg                         startEdgeDet;

// debounce sda and scl
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sdaPipe <= #1 {`DEB_I2C_LEN{1'b1}};
        sdaDeb <= #1 1'b1;
        sclPipe <= #1 {`DEB_I2C_LEN{1'b1}};
        sclDeb <= #1 1'b1;
    end
    else begin
        sdaPipe <= #1 {sdaPipe[`DEB_I2C_LEN-2:0], sda_pad_i};
        sclPipe <= #1 {sclPipe[`DEB_I2C_LEN-2:0], scl_pad_i};
        if (&sclPipe[`DEB_I2C_LEN-1:1] == 1'b1)
            sclDeb <= #1 1'b1;
        else if (|sclPipe[`DEB_I2C_LEN-1:1] == 1'b0)
            sclDeb <= #1 1'b0;
        if (&sdaPipe[`DEB_I2C_LEN-1:1] == 1'b1)
            sdaDeb <= #1 1'b1;
        else if (|sdaPipe[`DEB_I2C_LEN-1:1] == 1'b0)
            sdaDeb <= #1 1'b0;
    end
end

// delay scl and sda
// sclDelayed is used as a delayed sampling clock
// sdaDelayed is only used for start stop detection
// Because sda hold time from scl falling is 0nS
// sda must be delayed with respect to scl to avoid incorrect
// detection of start/stop at scl falling edge. 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
    sclDelayed <= #1 {`SCL_DEL_LEN{1'b1}};
    sdaDelayed <= #1 {`SDA_DEL_LEN{1'b1}};
  end
  else begin
    sclDelayed <= #1 {sclDelayed[`SCL_DEL_LEN-2:0], sclDeb};
    sdaDelayed <= #1 {sdaDelayed[`SDA_DEL_LEN-2:0], sdaDeb};
  end
end

// start stop detection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        startStopDetState <= #1 `NULL_DET;
        startEdgeDet <= #1 1'b0;
    end
    else begin
        if (sclDeb == 1'b1 && sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)
            startEdgeDet <= #1 1'b1;
        else
            startEdgeDet <= #1 1'b0;
        if (clearStartStopDet == 1'b1)
            startStopDetState <= #1 `NULL_DET;
        else if (sclDeb == 1'b1) begin
            if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b1 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b0) 
                startStopDetState <= #1 `STOP_DET;
            else if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)
                startStopDetState <= #1 `START_DET;
        end
    end
end

serialInterface u_serialInterface (
    .clk                (clk                            ), 
//  .rst                (~rst_n | startEdgeDet          ),
    .rst                (~rst_n                         ),
    .dataIn             (data_in[7:0]                   ), 
    .dataOut            (data_out[7:0]                  ), 
    .writeEn            (wr_en                          ),
    .regAddr            (reg_addr[7:0]                  ), 
    .scl                (sclDelayed[`SCL_DEL_LEN-1]     ), 
    .sdaIn              (sdaDeb                         ), 
    .sdaOut             (sda_pad_oen                    ), 
    .startStopDetState  (startStopDetState              ),
    .clearStartStopDet  (clearStartStopDet              ),
    .slave_addr         (slave_addr[7:0]                )
);

endmodule
