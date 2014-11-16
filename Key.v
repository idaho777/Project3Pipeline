module Key(clk, reset, we, re, memAddr, dataBusIn, key, dataBusOut);
	parameter KEY_WIDTH;
	parameter BITS;
	parameter BASE;
	parameter CTRL_BASE;

	input clk, reset;
	input we, re;
	input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
	input [KEY_WIDTH - 1: 0] key;
    output [BITS - 1: 0] dataBusOut;
    
	wire deviceEnable;
    wire shouldReadData;
    wire shouldWriteData;
    assign deviceEnable = memAddr == BASE;
    assign shouldReadData = we & deviceEnable;
    assign shouldWriteData = re & (!we) & deviceEnable;

	wire [KEY_WIDTH - 1: 0] keyOut;
	Register #(.BIT_WIDTH(KEY_WIDTH), .RESET_VALUE({KEY_WIDTH{1'b0}})) keyReg (
        clk, reset, 1'b1, key, keyOut
    );
	
	wire controlEnable;
    wire shouldReadControl;
    wire shouldWriteControl;
    assign controlEnable = memAddr == CTRL_BASE;
    assign shouldReadControl = we & controlEnable;
    assign shouldWriteControl = (!we) & controlEnable;
	
	wire readyBit = (shouldWriteData) ? 1'b0 	// Changes to 0 if reading data
				  : (key != keyOut) ? 1'b1		// Changes to 0 if key data is changed
				  : ctrlOut[0];
	
	wire overrunBit = (ctrlOut[0] == 1'b1 & key != keyOut) ? 1'b1	// Changes to 1 if ready bit is 1 and key data changes
					: (shouldReadControl & dataBusIn[2] == 1'b0) ? 1'b0		// Changes to 0 if reading in 0
					: ctrlOut[2];
	
	wire ieBit = (shouldReadControl) ? dataBusIn[8]
				: ctrlOut[8];
				
	wire [BITS - 1: 0] ctrlRegIn = {{(BITS - 9){1'b0}}, ieBit, {(5){1'b0}}, overrunBit, 1'b0, readyBit};
	
	wire [BITS - 1: 0] ctrlOut;
	Register #(.BIT_WIDTH(BITS), .RESET_VALUE(0)) ctrlReg (
		clk, reset, shouldReadControl, ctrlRegIn, ctrlOut
	);
    assign dataBusOut = shouldWriteData ? {{(BITS - KEY_WIDTH){1'b0}}, keyOut} 
					  :	(shouldWriteControl) ? ctrlOut
					  : {BITS{1'b0}};
					  
endmodule
