module Hex(clk, reset, we, memAddr, dataBusIn, dataBusOut, HEX0, HEX1, HEX2, HEX3);
    parameter HEX_WIDTH;
    parameter BITS;
    parameter BASE;
    
    input clk, reset;
    input we;
    input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
    output [BITS - 1: 0] dataBusOut;
    output [6: 0] HEX0, HEX1, HEX2, HEX3;
    
    wire deviceEnable;
    wire shouldRead;
    wire shouldWrite;
    assign deviceEnable = memAddr == BASE;
    assign shouldRead = we & deviceEnable;
    assign shouldWrite = (!we) & deviceEnable;
    
    wire [HEX_WIDTH - 1: 0] hexOut;
	Register #(.BIT_WIDTH(HEX_WIDTH), .RESET_VALUE({HEX_WIDTH{1'b0}})) hexReg (
        clk, reset, shouldRead, dataBusIn[HEX_WIDTH - 1: 0], hexOut
    );
    assign dataBusOut = shouldWrite ? {{(BITS - HEX_WIDTH){1'b0}}, hexOut} : {BITS{1'b0}};
	SevenSeg hex0Converter(hexOut[3:0], HEX0);
	SevenSeg hex1Converter(hexOut[7:4], HEX1);
	SevenSeg hex2Converter(hexOut[11:8], HEX2);
	SevenSeg hex3Converter(hexOut[15:12], HEX3);
    
endmodule
