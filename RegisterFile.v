module RegisterFile (
    clk, wrtEn, 
    fstOpcode, wrtIndex, rdIndex1, rdIndex2, dataIn,
    dataOut1, dataOut2, isRSR
);
	parameter INDEX_BIT_WIDTH = 4;
	parameter DATA_BIT_WIDTH = 32;
	parameter N_REGS = (1 << INDEX_BIT_WIDTH);
	parameter OP1_LW;
    
	input clk;
	input wrtEn;
	input [3: 0] wrtIndex, rdIndex1, rdIndex2;
    input [3: 0] fstOpcode;
	input [31: 0] dataIn;
    input isRSR;
	output [31: 0] dataOut1, dataOut2;
	
	reg[DATA_BIT_WIDTH - 1: 0] data [0: N_REGS];
	
	always @(posedge clk) begin
		if (wrtEn == 1'b1)
			data[wrtIndex] <= dataIn;
    end

    wire shouldForwardData1, shouldForwardData2;
    assign shouldForwardData1 = wrtEn & wrtIndex == rdIndex1 & !isRSR;
    assign shouldForwardData2 = wrtEn & wrtIndex == rdIndex2 & !isRSR;
//    assign shouldForwardData1 = 1'b0;
//    assign shouldForwardData2 = 1'b0;
			
	assign dataOut1 = shouldForwardData1 ? dataIn : data[rdIndex1];
	assign dataOut2 = shouldForwardData2 ? dataIn : data[rdIndex2];
	
endmodule
