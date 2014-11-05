module MemoryUnit(
    clk, reset, addrMemIn, isLoad, isStore, 
    dataOut2, aluOut, pcLogicOut, memOutSel,
    KEY, SW,
    dataIn, LEDG, LEDR, HEX0, HEX1, HEX2, HEX3
);
    parameter DMEM_ADDR_BITS_HI, DMEM_ADDR_BITS_LO, 
                DMEM_ADDR_BIT_WIDTH, DMEM_DATA_BIT_WIDTH, DBITS;
    input clk, reset;
    input [DMEM_DATA_BIT_WIDTH - 1: 0] addrMemIn;
    input isLoad, isStore;
    input [DMEM_DATA_BIT_WIDTH - 1: 0] dataOut2;
    input [DMEM_DATA_BIT_WIDTH - 1: 0] aluOut;
    input [DMEM_DATA_BIT_WIDTH - 1: 0] pcLogicOut;
    input [1: 0] memOutSel;
    input [3: 0] KEY;
    input [9: 0] SW;
    output [DMEM_DATA_BIT_WIDTH - 1:0] dataIn;
    output [7:0] LEDG;
    output [9:0] LEDR;
    output [6: 0] HEX0, HEX1, HEX2, HEX3;

	wire[DMEM_DATA_BIT_WIDTH - 1: 0] dataWord;
	wire dataWrtEn, swEn, ledrEn, ledgEn, keyEn, hexEn;
	wire [1:0] dataMemOutSel;
    wire [31:0] dataMemoryOut;
	wire[DBITS - 1: 0] switchOut;
	wire[DBITS - 1: 0] keyOut;
	wire[DBITS - 1: 0] ledrOut;
	wire[DBITS - 1: 0] ledgOut;
	wire[DBITS - 1: 0] hexOut;

    
	DataMemory #(DMEM_ADDR_BIT_WIDTH, DMEM_DATA_BIT_WIDTH) dataMem (
        .clk(clk), .addr(addrMemIn[DMEM_ADDR_BITS_HI - 1: DMEM_ADDR_BITS_LO]), 
        .dataWrtEn(dataWrtEn), .dataIn(dataOut2), .dataOut(dataWord)
    );
	Mux4to1 muxMemOut (memOutSel, aluOut, dataMemoryOut, pcLogicOut, 32'd0, dataIn);
	Mux4to1 muxDataMemOut (dataMemOutSel, dataWord, switchOut, keyOut, 32'd0, dataMemoryOut);
	
	// IO controller
	IO_Controller ioCtrl (
        .dataAddr(aluOut), .isLoad(isLoad), .isStore(isStore), .dataWrtEn(dataWrtEn), 
        .dataMemOutSel(dataMemOutSel), 
		.swEn(swEn), .keyEn(keyEn), .ledrEn(ledrEn), .ledgEn(ledgEn), .hexEn(hexEn)
    );

	// KEYS, SWITCHES, HEXS, and LEDS are memory mapped IO
	// SWITCH
	negRegister switchReg (clk, reset, swEn, {22'd0,SW}, switchOut);
	// LEDR
	negRegister ledrReg 	 (clk, reset, ledrEn, dataOut2, ledrOut); // 
	assign LEDR = ledrOut[9:0];
	// LEDG
	negRegister ledgReg 	 (clk, reset, ledgEn, dataOut2, ledgOut); // 
	assign LEDG = ledgOut[7:0];
	// KEY
	negRegister keyReg 	 (clk, reset, keyEn, {28'd0,KEY}, keyOut);
	// HEXS
	negRegister hexReg 	 (clk, reset, hexEn, dataOut2, hexOut); //
	SevenSeg hex0Converter(hexOut[3:0], HEX0);
	SevenSeg hex1Converter(hexOut[7:4], HEX1);
	SevenSeg hex2Converter(hexOut[11:8], HEX2);
	SevenSeg hex3Converter(hexOut[15:12], HEX3);

endmodule
