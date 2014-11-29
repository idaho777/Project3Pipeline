module Timer(clk, reset, we, re, memAddr, dataBusIn, dataBusOut, inta_ready);
	parameter BITS;
	parameter BASE;
	parameter TLIM_BASE;
	parameter CTRL_BASE;
	parameter TIME_LENGTH;
	
	input clk, reset;
	input we, re;
	input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
    output [BITS - 1: 0] dataBusOut;
    output inta_ready;
    
	reg[BITS - 1: 0] timeCount = 0;
	reg[BITS - 1: 0] counter = 0;
	
	wire deviceEnable;
    wire shouldReadData;
    wire shouldWriteData;
    assign deviceEnable = memAddr == BASE;
    assign shouldReadData = we & deviceEnable;
    assign shouldWriteData = re & (!we) & deviceEnable;

	always @(posedge clk) begin
		if (reset) begin
			timeCount <= 0;
		end
        else if (shouldReadLimit) begin
            counter <= 0;
            timeCount <= 0;
        end
		else if (shouldReadData) begin
			counter <= 0;
			timeCount <= (dataBusIn > timeLimitOut - 1) ? 0 : dataBusIn;
		end
		else begin
			counter <= counter + 1;
			if (counter == TIME_LENGTH - 1) begin
				counter <= 0;
				timeCount <= (timeCount == timeLimitOut - 1) ? 0
						    : timeCount + 1;
			end
		end
	end
	
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
				  : (timeCount == timeLimitOut - 1 & counter == 0) ? 1'b1	// Changes to 1 if timeCount reaches timeLimitOut
				  : ctrlOut[0];
						
					   // Changes to 1 if ready bit is 1 and timeCount reaches timeLimitOut again
	wire overrunBit = (ctrlOut[0] == 1'b1 & timeCount == timeLimitOut - 1 & counter == 0) ? 1'b1	
					: (shouldReadControl & dataBusIn[2] == 1'b0) ? 1'b0		// Changes to 0 if reading in 0
					: ctrlOut[2];

	wire ieBit = (shouldReadControl) ? dataBusIn[8]
				: ctrlOut[8];
				
	wire [BITS - 1: 0] ctrlRegIn = {{(BITS - 9){1'b0}}, ieBit, {(5){1'b0}}, overrunBit, 1'b0, readyBit};
	
	wire [BITS - 1: 0] ctrlOut;
	Register #(.BIT_WIDTH(BITS), .RESET_VALUE(0)) ctrlReg (
		clk, reset, 1'b1, ctrlRegIn, ctrlOut
	);
	
	assign dataBusOut = shouldWriteData ? timeCount
					  : shouldWriteLimit ? timeLimitOut
					  : shouldWriteControl ? ctrlOut
					  : {BITS{1'b0}};

    assign inta_ready = ieBit & readyBit;
endmodule

