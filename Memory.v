module Memory(clk, we, memAddr, dataBusIn, dataBusOut);
    parameter DMEM_ADDR_BITS_HI, DMEM_ADDR_BITS_LO, DMEM_ADDR_BIT_WIDTH, DMEM_DATA_BIT_WIDTH, BITS;
    parameter BASE = 0;
    parameter LIMIT = BASE + ((1 << DMEM_ADDR_BIT_WIDTH) << DMEM_ADDR_BITS_LO);
    
    input clk, we;
    input [BITS - 1: 0] memAddr;
    input [BITS - 1: 0] dataBusIn;
    output [BITS - 1: 0] dataBusOut;
    
    wire deviceEnable;
    wire shouldRead;
    wire shouldWrite;
    assign deviceEnable = memAddr >= BASE && memAddr < LIMIT;
    assign shouldRead = we & deviceEnable;
    assign shouldWrite = (!we) & deviceEnable;
    
    wire [BITS - 1: 0] memOut;
	DataMemory #(DMEM_ADDR_BIT_WIDTH, DMEM_DATA_BIT_WIDTH) dataMem (
        .clk(clk), .addr(memAddr[DMEM_ADDR_BITS_HI - 1: DMEM_ADDR_BITS_LO]),
        .dataWrtEn(shouldRead), .dataIn(dataBusIn), .dataOut(memOut)
    );
    assign dataBusOut = shouldWrite ? memOut : {BITS{1'b0}};
endmodule
