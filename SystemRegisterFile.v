module SystemRegisterFile(
    clk, reset, sysWrtEn, wrtIndex, rdIndex, dataIn, pcIn, inta, isReti, idn,
    intaSig, dataOut, intaAddr
);
    parameter DBITS;
    
    input clk, reset, sysWrtEn;
    input [DBITS - 1: 0] dataIn, pcIn;
    input [3: 0] wrtIndex, rdIndex;
    input [DBITS - 1: 0] idn;
    input inta, isReti;
    output intaSig;
    output [DBITS - 1: 0] dataOut, intaAddr;
    
    assign intaSig = inta && pcsOut[0];
    
    wire pcsWSR, idnWSR, iraWSR, ihaWSR;
    assign pcsWSR = sysWrtEn && wrtIndex == 4'b0000;
    assign idnWSR = sysWrtEn && wrtIndex == 4'b0001;
    assign iraWSR = sysWrtEn && wrtIndex == 4'b0010;
    assign ihaWSR = sysWrtEn && wrtIndex == 4'b0011;
    
    wire pcsOldWrtEn, pcsWrtEn, idnWrtEn, iraWrtEn, ihaWrtEn;
    assign pcsOldWrtEn = intaSig;
    assign pcsWrtEn = pcsWSR || intaSig || isReti;
    assign idnWrtEn = idnWSR || intaSig;
    assign iraWrtEn = iraWSR || intaSig;
    assign ihaWrtEn = ihaWSR;
    
    wire [DBITS - 1: 0] pcsOut, pcsOldOut, idnOut, iraOut, ihaOut;
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) pcsOldReg (
        clk, reset, pcsOldWrtEn, pcsOut, pcsOldOut
    );
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) pcsReg (
        clk, reset, pcsWrtEn, 
            intaSig ? 0: 
            isReti ? pcsOldOut : 
            dataIn,
        pcsOut
    );
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) idnReg (
        clk, reset, idnWrtEn, intaSig ? idn : dataIn, idnOut
    );
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) iraReg (
        clk, reset, iraWrtEn, intaSig ? pcIn : dataIn, iraOut
    );
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) ihaReg (
        clk, reset, ihaWrtEn, dataIn, ihaOut
    );

    assign dataOut =
            rdIndex == 4'b0000 ? (pcsWSR ? dataIn : pcsOut) :
            rdIndex == 4'b0001 ? (idnWSR ? dataIn : idnOut) :
            rdIndex == 4'b0010 ? (iraWSR ? dataIn : iraOut) :
            rdIndex == 4'b0011 ? (ihaWSR ? dataIn : ihaOut) :
            0;
    assign intaAddr = intaSig ? ihaOut << 2: iraOut;

endmodule
