module ClkDivider(input clkIn, output clkOut);
	parameter divider = 2500000;
	parameter len = 31;
	reg[len: 0] counter = 0;
	reg clkReg = 0;

	assign clkOut = clkReg;

	always @(posedge clkIn) begin
		counter <= counter + 1;

		if (counter == divider) begin
			clkReg <= ~clkReg;
			counter <= 0;
		end
	end
endmodule
