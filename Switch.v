module Switch(clk, reset, we, re, memAddr, dataBusIn, sw, dataBusOut, inta_ready);
	parameter SW_WIDTH;
	parameter BITS;
	parameter BASE;
	parameter CTRL_BASE;
	parameter DEBOUNCE_TIME;

	input clk, reset;
	input we, re;
	input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
	input [SW_WIDTH - 1: 0] sw;
    output [BITS - 1: 0] dataBusOut;
    output inta_ready;
    
	wire deviceEnable;
    wire shouldReadData;
    wire shouldWriteData;
    assign deviceEnable = memAddr == BASE;
    assign shouldReadData = we & deviceEnable;
    assign shouldWriteData = re & (!we) & deviceEnable;
	
	reg[BITS - 1: 0] counter = 0;
	wire swWrtEn;
	always @(posedge clk) begin
        if (reset || sw != debounceOut) begin
            counter <= 0;
        end else if (sw != swOut) begin
            counter <= (counter == DEBOUNCE_TIME) ? 0 : counter + 1;
        end
	end

	wire [SW_WIDTH - 1: 0] debounceOut;
	Register #(.BIT_WIDTH(SW_WIDTH), .RESET_VALUE({SW_WIDTH{1'b0}})) debounceReg (
        clk, reset, 1'b1, sw, debounceOut
    );

	assign swWrtEn = (counter == DEBOUNCE_TIME) ? 1'b1 : 1'b0;
	wire [SW_WIDTH - 1: 0] swOut;
	Register #(.BIT_WIDTH(SW_WIDTH), .RESET_VALUE({SW_WIDTH{1'b0}})) swReg (
        clk, reset, swWrtEn, debounceOut, swOut
    );
	
	wire controlEnable;
    wire shouldReadControl;
    wire shouldWriteControl;
    assign controlEnable = memAddr == CTRL_BASE;
    assign shouldReadControl = we & controlEnable;
    assign shouldWriteControl = (!we) & controlEnable;
	
	wire readyBit = (shouldWriteData) ? 1'b0 	// Changes to 0 if reading data
				  : (swWrtEn) ? 1'b1		// Changes to 1 if sw data is changed
				  : ctrlOut[0];
	
	wire overrunBit = (ctrlOut[0] == 1'b1 && swWrtEn) ? 1'b1		// Changes to 1 if ready bit is 1 and sw data changes
					: (shouldReadControl & dataBusIn[2] == 1'b0) ? 1'b0		// Changes to 0 if reading in 0
					: ctrlOut[2];
	
	wire ieBit = (shouldReadControl) ? dataBusIn[8]
				: ctrlOut[8];
				
	wire [BITS - 1: 0] ctrlRegIn = {{(BITS - 9){1'b0}}, ieBit, {(5){1'b0}}, overrunBit, 1'b0, readyBit};
	
	wire [BITS - 1: 0] ctrlOut;
	Register #(.BIT_WIDTH(BITS), .RESET_VALUE(0)) ctrlReg (
		clk, reset, 1'b1, ctrlRegIn, ctrlOut
	);
    assign dataBusOut = shouldWriteData ? {{(BITS - SW_WIDTH){1'b0}}, swOut}
					  :	(shouldWriteControl) ? ctrlOut
					  : {BITS{1'b0}};

    assign inta_ready = ctrlOut[8] & ctrlOut[0];
endmodule
