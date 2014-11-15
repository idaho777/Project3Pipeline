module Led(clk, reset, we, memAddr, dataBusIn, dataBusOut, led);
    parameter LED_WIDTH;
    parameter BITS;
    parameter BASE;
    
    input clk, reset;
    input we;
    input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
    output [BITS - 1: 0] dataBusOut;
    output [LED_WIDTH - 1: 0] led;
    
    wire deviceEnable;
    wire shouldRead;
    wire shouldWrite;
    assign deviceEnable = memAddr == BASE;
    assign shouldRead = we & deviceEnable;
    assign shouldWrite = (!we) & deviceEnable;
    
    wire [LED_WIDTH - 1: 0] ledOut;
	Register #(.BIT_WIDTH(LED_WIDTH), .RESET_VALUE({LED_WIDTH{1'b0}})) ledReg (
        clk, reset, shouldRead, dataBusIn[LED_WIDTH - 1: 0], ledOut
    );
    assign dataBusOut = shouldWrite ? {{(BITS - LED_WIDTH){1'b0}}, ledOut} : {BITS{1'b0}};
    assign led = ledOut;
    
endmodule
