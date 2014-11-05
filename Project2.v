module ClkDivider(input clkIn, output clkOut);
	parameter divider = 25000000;
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


module Project2(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
	input  [9:0] SW;
	input  [3:0] KEY;
	input  CLOCK_50;
	output [9:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0,HEX1,HEX2,HEX3;

	parameter DBITS         				 = 32;
	parameter INST_SIZE      				 = 32'd4;
	parameter INST_BIT_WIDTH				 = 32;
	parameter START_PC       			 	 = 32'h40;
	parameter REG_INDEX_BIT_WIDTH 		 = 4;
	parameter ADDR_KEY  						 = 32'hF0000010;
	parameter ADDR_SW   						 = 32'hF0000014;
	parameter ADDR_HEX  						 = 32'hF0000000;
	parameter ADDR_LEDR 						 = 32'hF0000004;
	parameter ADDR_LEDG 						 = 32'hF0000008;

	parameter IMEM_INIT_FILE				 = "Test2.mif";//"Sort2_counter.mif"; //"Sorter2.mif";
	parameter IMEM_ADDR_BIT_WIDTH 		 = 11;
	parameter IMEM_DATA_BIT_WIDTH 		 = INST_BIT_WIDTH;
	parameter IMEM_PC_BITS_HI     		 = IMEM_ADDR_BIT_WIDTH + 2;
	parameter IMEM_PC_BITS_LO     		 = 2;

	parameter DMEM_ADDR_BIT_WIDTH 		 = 11;
	parameter DMEM_DATA_BIT_WIDTH 		 = 32;
	parameter DMEM_ADDR_BITS_HI     		 = DMEM_ADDR_BIT_WIDTH + 2;
	parameter DMEM_ADDR_BITS_LO     		 = 2;

	parameter OP1_ALUR 					 = 4'b0000;
	parameter OP1_ALUI 					 = 4'b1000;
	parameter OP1_CMPR 					 = 4'b0010;
	parameter OP1_CMPI 					 = 4'b1010;
	parameter OP1_BCOND					 = 4'b0110;
	parameter OP1_SW   					 = 4'b0101;
	parameter OP1_LW   					 = 4'b1001;
	parameter OP1_JAL  					 = 4'b1011;

	// Add parameters for various secondary opcode values

	//PLL, clock genration, and reset generation
	wire clk, lock;
	//Pll pll(.inclk0(CLOCK_50), .c0(clk), .locked(lock));
	//PLL	PLL_inst (.inclk0 (CLOCK_50),.c0 (clk),.locked (lock));
	ClkDivider clkdi(CLOCK_50, clk);

	wire reset = SW[0]; //~lock;

	wire [DMEM_DATA_BIT_WIDTH - 1: 0] aluIn2;
	wire immSel;
    wire [1:0] memOutSel;
	wire [3: 0] wrtIndex, rdIndex1, rdIndex2;
	wire [3: 0] fstOpcode;
	wire [4: 0] sndOpcode;
	wire [15: 0] imm;
	wire regFileEn;
	wire [DMEM_DATA_BIT_WIDTH - 1: 0] dataIn, dataOut1, dataOut2;
	wire cmpOut_top;
	wire [DMEM_DATA_BIT_WIDTH - 1: 0] aluOut;
	wire [DMEM_DATA_BIT_WIDTH - 1: 0] addrMemIn;
	wire [DMEM_DATA_BIT_WIDTH - 1: 0] dataMemIn;
	wire [DMEM_DATA_BIT_WIDTH - 1: 0] seImm;
	wire[IMEM_DATA_BIT_WIDTH - 1: 0] instWord;
	wire[DBITS - 1: 0] branchPc;
	wire isLoad, isStore;

	// PC register
	wire pcWrtEn = 1'b1; // always right to PC
	wire[DBITS - 1: 0] pcIn, pcInTrue; // Implement the logic that generates pcIn; you may change pcIn to reg if necessary
	wire[DBITS - 1: 0] pcOut;
	wire[DBITS - 1: 0] pcLogicOut;
	wire [1:0] pcSel; // 0: pcOut + 4, 1: branchPc

	// Pipeline Register
	wire[0 : 0]  pipeRegFileEn;
	wire[1 : 0]  pipeMemOutSel;
	wire[31 : 0] pipeAluOut;
	wire[31 : 0] pipeDataOut2;
	wire[31 : 0] pipePcLogicOut;
	wire[3 : 0]  pipeFstOpcode;
    wire[3: 0]   pipeWrtIndex;
	wire[0 : 0]  pipeIsLoad;
	wire[0 : 0]  pipeIsStore;
	wire[0 : 0]  pipeIsStall;


	Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(START_PC)) pc (
        clk, reset, pcWrtEn, pcInTrue, pcOut
    );
	PcLogic pcLogic (pcOut, pcLogicOut);
	//Mux2to1 #(.DATA_BIT_WIDTH(DBITS)) muxPcOut (pcSel, pcLogicOut, branchPc, pcIn);
	Mux4to1 muxPcOut (pcSel, pcLogicOut, branchPc, aluOut, 32'd0, pcIn);
    Mux2to1 #(.DATA_BIT_WIDTH(DBITS)) muxPcStall (pipeIsStall, pcIn, pcOut, pcInTrue);

	// Branch Address Calculator
	BranchAddrCalculator bac (.nextPc(pcLogicOut), .pcRel(seImm), .branchAddr(branchPc));

	// Instruction Memory
	InstMemory #(IMEM_INIT_FILE, IMEM_ADDR_BIT_WIDTH, IMEM_DATA_BIT_WIDTH) instMem (
        pcOut[IMEM_PC_BITS_HI - 1: IMEM_PC_BITS_LO], instWord
    );

	// Controller
	Controller cont (
        .inst(instWord), .aluCmpIn(cmpOut_top),
        .fstOpcode(fstOpcode), .sndOpcode(sndOpcode), .dRegAddr(wrtIndex),
        .s1RegAddr(rdIndex1), .s2RegAddr(rdIndex2), .imm(imm),
        .regFileWrtEn(regFileEn),
        .immSel(immSel), .memOutSel(memOutSel), .pcSel(pcSel),
        .isLoad(isLoad), .isStore(isStore)
    );

	// RegisterFile
	RegisterFile #(.OP1_LW(OP1_LW)) regFile (
        .clk(clk), .wrtEn(pipeRegFileEn),
        .fstOpcode(pipeFstOpcode),
        .wrtIndex(pipeWrtIndex), .rdIndex1(rdIndex1), .rdIndex2(rdIndex2),
        .dataIn(dataIn),
        .dataOut1(dataOut1), .dataOut2(dataOut2)
    );

	// ALU
	Alu alu1 (
        .ctrl(sndOpcode), .rawDataIn1(dataOut1), .rawDataIn2(aluIn2),
        .dataOut(aluOut), .cmpOut(cmpOut_top)
    );

   // Sign Extension
	SignExtension #(.IN_BIT_WIDTH(16), .OUT_BIT_WIDTH(32)) se (imm, seImm);

	// ALU Mux
	Mux2to1 #(.DATA_BIT_WIDTH(DBITS)) muxAluIn (immSel, pipeDataOut2, seImm, aluIn2);
    
	PipelineRegister #(.OP1_LW(OP1_LW), .OP1_BR(OP1_BCOND), .OP1_JAL(OP1_JAL)) pipelineRegister (
		.clk(clk), .reset(reset),
		.inWrtIndex(wrtIndex), .inRegWrEn(regFileEn), .inMulSel(memOutSel), .inAluOut(aluOut), .inData2Out(dataOut2),
		.inPC(pcLogicOut), .inInstType(fstOpcode), .inBrTaken(cmpOut_top), .inIsLoad(isLoad), .inIsStore(isStore),
		.outWrtIndex(pipeWrtIndex), .outRegWrEn(pipeRegFileEn), .outMulSel(pipeMemOutSel), .outAluOut(pipeAluOut), .outData2Out(pipeDataOut2),
		.outPC(pipePcLogicOut), .outInstType(pipeFstOpcode), .outIsLoad(pipeIsLoad), .outIsStore(pipeIsStore),
		.isStall(pipeIsStall)
	);

	// Data Memory and I/O
    MemoryUnit #(
        .DMEM_ADDR_BITS_HI(DMEM_ADDR_BITS_HI),
        .DMEM_ADDR_BITS_LO(DMEM_ADDR_BITS_LO),
        .DMEM_ADDR_BIT_WIDTH(DMEM_ADDR_BIT_WIDTH),
        .DMEM_DATA_BIT_WIDTH(DMEM_DATA_BIT_WIDTH),
        .DBITS(DBITS)
    ) memUnit(
        .clk(clk), .reset(reset), .addrMemIn(pipeAluOut),
        .isLoad(pipeIsLoad), .isStore(pipeIsStore),
        .dataOut2(pipeDataOut2), .aluOut(pipeAluOut), .pcLogicOut(pipePcLogicOut),
        .memOutSel(pipeMemOutSel),
        .KEY(KEY), .SW(SW),
        .dataIn(dataIn),
        .LEDG(LEDG), .LEDR(LEDR), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3)
    );


endmodule
