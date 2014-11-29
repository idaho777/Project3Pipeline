module CPU(
    clk, reset, dataBusIn, weBus, reBus, memAddrBus, dataBusOut,
    inta, idn
);
	parameter DBITS         				 = 32;
	parameter INST_SIZE      				 = 32'd4;
	parameter INST_BIT_WIDTH				 = 32;
	parameter START_PC       			 	 = 32'h40;
	parameter REG_INDEX_BIT_WIDTH 		     = 4;

	parameter IMEM_INIT_FILE;

	parameter IMEM_ADDR_BIT_WIDTH 		 = 11;
	parameter IMEM_DATA_BIT_WIDTH 		 = INST_BIT_WIDTH;
	parameter IMEM_PC_BITS_HI     		 = IMEM_ADDR_BIT_WIDTH + 2;
	parameter IMEM_PC_BITS_LO     		 = 2;

	parameter OP1_ALUR 					 = 4'b0000;
	parameter OP1_ALUI 					 = 4'b1000;
	parameter OP1_CMPR 					 = 4'b0010;
	parameter OP1_CMPI 					 = 4'b1010;
	parameter OP1_BCOND					 = 4'b0110;
	parameter OP1_SW   					 = 4'b0101;
	parameter OP1_LW   					 = 4'b1001;
	parameter OP1_JAL  					 = 4'b1011;
    parameter OP1_SYS  					 = 4'b1111;    

    input clk, reset;
    input [DBITS - 1: 0] dataBusIn;
    input inta;
    input [DBITS - 1: 0] idn;
    output weBus, reBus;
    output [DBITS - 1: 0] memAddrBus;
    output [DBITS - 1: 0] dataBusOut;
    
	wire [DBITS - 1: 0] aluIn2;
	wire immSel;
    wire [1:0] memOutSel;
	wire [3: 0] wrtIndex, rdIndex1, rdIndex2;
	wire [3: 0] fstOpcode;
	wire [4: 0] sndOpcode;
	wire [15: 0] imm;
	wire regFileEn;
	wire [DBITS - 1: 0] dataIn, dataOut1, dataOut2;
	wire cmpOut_top;
	wire [DBITS - 1: 0] aluOut;
	wire [DBITS - 1: 0] addrMemIn;
	wire [DBITS - 1: 0] dataMemIn;
	wire [DBITS - 1: 0] seImm;
	wire[IMEM_DATA_BIT_WIDTH - 1: 0] instWord;
	wire[DBITS - 1: 0] branchPc;
	wire isLoad, isStore;
    wire sysRegWrtEn, isReti, isRSR, isWSR;
    wire intaSig;
    wire [DBITS - 1:0] sysDataOut, intaAddr;
    
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
	wire[31 : 0] pipeSysDataOut;
	wire[31 : 0] pipeDataOut1, pipeDataOut2;
	wire[31 : 0] pipePcLogicOut;
	wire[3 : 0]  pipeFstOpcode;
    wire[3: 0]   pipeWrtIndex;
	wire[0 : 0]  pipeIsLoad;
	wire[0 : 0]  pipeIsStore;
	wire[0 : 0]  pipeIsStall;
	wire[0 : 0]  pipeIsWSR, pipeIsRSR;


	Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(START_PC)) pc (
        clk, reset, pcWrtEn, pcInTrue, pcOut
    );
	PcLogic pcLogic (pcOut, pcLogicOut);
	Mux4to1 muxPcOut (pcSel, pcLogicOut, branchPc, aluOut, intaAddr, pcIn);
    Mux2to1 #(.DATA_BIT_WIDTH(DBITS)) muxPcStall (pipeIsStall, pcIn, pcOut, pcInTrue);

	// Instruction Memory
	InstMemory #(IMEM_INIT_FILE, IMEM_ADDR_BIT_WIDTH, IMEM_DATA_BIT_WIDTH) instMem (
        pcOut[IMEM_PC_BITS_HI - 1: IMEM_PC_BITS_LO], instWord
    );

    
	// Controller
	Controller cont (
        .inst(instWord), .aluCmpIn(cmpOut_top), .intaSig(intaSig),
        .fstOpcode(fstOpcode), .sndOpcode(sndOpcode), .dRegAddr(wrtIndex),
        .s1RegAddr(rdIndex1), .s2RegAddr(rdIndex2), .imm(imm),
        .regFileWrtEn(regFileEn),
        .immSel(immSel), .memOutSel(memOutSel), .pcSel(pcSel),
        .isLoad(isLoad), .isStore(isStore),
        .sysRegWrtEn(sysRegWrtEn), .isReti(isReti), .isRSR(isRSR), .isWSR(isWSR)
    );

    SystemRegisterFile #(.DBITS(DBITS)) sysRegFile(
        .clk(clk), .reset(reset), .sysWrtEn(pipeIsWSR), .wrtIndex(pipeWrtIndex), .rdIndex(rdIndex1),
        .dataIn(pipeDataOut1), .pcIn(pcOut), .inta(inta), .isReti(isReti), .idn(idn),
        .intaSig(intaSig), .dataOut(sysDataOut), .intaAddr(intaAddr)
    );
    
	Mux4to1 muxRegIn (pipeMemOutSel, pipeAluOut, dataBusIn, pipePcLogicOut, pipeSysDataOut, dataIn);

	// RegisterFile
	RegisterFile #(.OP1_LW(OP1_LW)) regFile (
        .clk(clk), .wrtEn(pipeRegFileEn), .isRSR(pipeIsRSR),
        .fstOpcode(pipeFstOpcode),
        .wrtIndex(pipeWrtIndex), .rdIndex1(rdIndex1), .rdIndex2(rdIndex2),
        .dataIn(dataIn),
        .dataOut1(dataOut1), .dataOut2(dataOut2)
    );

    // Sign Extension
	SignExtension #(.IN_BIT_WIDTH(16), .OUT_BIT_WIDTH(32)) se (imm, seImm);

	// ALU Mux
	Mux2to1 #(.DATA_BIT_WIDTH(DBITS)) muxAluIn (immSel, dataOut2, seImm, aluIn2);

	// ALU
	Alu alu1 (
        .ctrl(sndOpcode), .rawDataIn1(dataOut1), .rawDataIn2(aluIn2),
        .dataOut(aluOut), .cmpOut(cmpOut_top)
    );

	// Branch Address Calculator
	BranchAddrCalculator bac (.nextPc(pcLogicOut), .pcRel(seImm), .branchAddr(branchPc));
    
	PipelineRegister #(.OP1_LW(OP1_LW), .OP1_BR(OP1_BCOND), .OP1_JAL(OP1_JAL)) pipelineRegister (
		.clk(clk), .reset(reset),
        .inRdIndex1(rdIndex1), .inRdIndex2(rdIndex2),
		.inWrtIndex(wrtIndex), .inRegWrEn(regFileEn), .inMulSel(memOutSel),
        .inAluOut(aluOut), .inSysDataOut(sysDataOut), .inData1Out(dataOut1), .inData2Out(dataOut2),
		.inPC(pcLogicOut), .inInstType(fstOpcode), .inBrTaken(cmpOut_top), .inIsLoad(isLoad), .inIsStore(isStore),
        .inIsWSR(isWSR), .inIsRSR(isRSR),
		.outWrtIndex(pipeWrtIndex), .outRegWrEn(pipeRegFileEn), .outMulSel(pipeMemOutSel), 
        .outAluOut(pipeAluOut),
        .outSysDataOut(pipeSysDataOut), .outData1Out(pipeDataOut1), .outData2Out(pipeDataOut2),
		.outPC(pipePcLogicOut), .outInstType(pipeFstOpcode), .outIsLoad(pipeIsLoad), .outIsStore(pipeIsStore),
		.isStall(pipeIsStall), .outIsWSR(pipeIsWSR), .outIsRSR(pipeIsRSR)
	);
    
    assign memAddrBus = pipeAluOut;
    assign weBus = pipeIsStore;
    assign reBus = pipeIsLoad;
    assign dataBusOut = weBus ? pipeDataOut2 : {DBITS{1'b0}};    

endmodule
