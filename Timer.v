module Timer(clk, reset, we, memAddr, dataBusIn, dataBusOut);
	parameter BITS;
	parameter BASE;
	parameter TLIM_BASE;
	parameter CTRL_BASE;
	
	input clk, reset;
	input we;
	input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
    output [BITS - 1: 0] dataBusOut;
    
	reg[BITS - 1: 0] timeCount = 0;
	
	wire deviceEnable;
    wire shouldReadData;
    wire shouldWriteData;
    assign deviceEnable = memAddr == BASE;
    assign shouldReadData = we & deviceEnable;
    assign shouldWriteData = (!we) & deviceEnable;

	always @(posedge clk) begin
		if (reset) begin
			timeCount <= 0;
		end
		else begin
			timeCount <= (shouldReadData) ? dataBusIn
					   : (timeCount == timeLimitOut - 1) ? 0
					   : timeCount + 1;
		end
	end
	
	/*

TLIM at F0000024
Write sets the value, read gets the value
When TLIM is zero, it has no effect (counter just keeps counting)
When TLIM!=0, it acts as the limit/target value for the counter
If  TCNT==TLIM-1 and we want to increment TCNT,
we reset TCNT back to zero and  set the ready bit (or overflow if Ready already set)
If TLIM>0, the TCNT never actually becomes equal to TLIM (wraps from TLIM-1 to 0)


*/
	
	wire limitEnable;
    wire shouldReadLimit;
    wire shouldWriteLimit;
    assign limitEnable = memAddr == TLIM_BASE;
    assign shouldReadLimit = we & limitEnable;
    assign shouldWriteLimit = (!we) & limitEnable;

	wire [BITS - 1: 0] timeLimitOut;
	Register #(.BIT_WIDTH(BITS), .RESET_VALUE({BITS{1'b0}})) timeLimitReg (
        clk, reset, shouldReadLimit, dataBusIn, timeLimitOut
    );
	

	wire controlEnable;
    wire shouldReadControl;
    wire shouldWriteControl;
    assign controlEnable = memAddr == CTRL_BASE;
    assign shouldReadControl = we & controlEnable;
    assign shouldWriteControl = (!we) & controlEnable;

	wire readyBit = (shouldWriteData) ? 1'b0 	// Changes to 0 if reading data
				  : (timeCount == timeLimitOut - 1) ? 1'b1	// Changes to 0 if timeCount reaches timeLimitOut
				  : ctrlOut[0];
						
					   // Changes to 1 if ready bit is 1 and timeCount reaches timeLimitOut again
	wire overrunBit = (ctrlOut[0] == 1'b1 & timeCount == timeLimitOut - 1) ? 1'b1	
					: (shouldReadControl & dataBusIn[2] == 1'b0) ? 1'b0		// Changes to 0 if reading in 0
					: ctrlOut[2];
	
	wire ieBit = (shouldReadControl) ? dataBusIn[8]
				: ctrlOut[8];
				
	wire [BITS - 1: 0] ctrlRegIn = {{(BITS - 9){1'b0}}, ieBit, {(5){1'b0}}, overrunBit, 1'b0, readyBit};
	
	wire [BITS - 1: 0] ctrlOut;
	Register #(.BIT_WIDTH(BITS), .RESET_VALUE(0)) ctrlReg (
		clk, reset, shouldReadControl, ctrlRegIn, ctrlOut
	);
	
	assign dataBusOut = shouldReadData ? timeCount
					  : shouldReadLimit ? timeLimitOut
					  : shouldReadControl ? ctrlOut
					  : {BITS{1'b0}};
endmodule

