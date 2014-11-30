module SystemRegisterFile(
    clk, reset, sysWrtEn, wrtIndex, rdIndex, dataIn, pcIn, inta, isReti, idn,
    intaSig, dataOut, intaAddr, debugSysOut
);
    parameter DBITS;
    parameter PCS_INDEX = 4'b0000;
    parameter IHA_INDEX = 4'b0001;
    parameter IRA_INDEX = 4'b0010;
    parameter IDN_INDEX = 4'b0011;
    
    
    input clk, reset, sysWrtEn;
    input [DBITS - 1: 0] dataIn, pcIn;
    input [3: 0] wrtIndex, rdIndex;
    input [DBITS - 1: 0] idn;
    input inta, isReti;
    output intaSig;
    output [DBITS - 1: 0] dataOut, intaAddr, debugSysOut;
    
    assign intaSig = inta && pcsOut[0];
    
    assign debugSysOut = pcsOut;
    
    wire pcsWSR, idnWSR, iraWSR, ihaWSR;
    assign pcsWSR = sysWrtEn && wrtIndex == PCS_INDEX;
    assign ihaWSR = sysWrtEn && wrtIndex == IHA_INDEX;
    assign iraWSR = sysWrtEn && wrtIndex == IRA_INDEX;
    assign idnWSR = sysWrtEn && wrtIndex == IDN_INDEX;
    
    wire pcsWrtEn, idnWrtEn, iraWrtEn, ihaWrtEn;
    assign pcsWrtEn = pcsWSR || intaSig || isReti;
    assign idnWrtEn = idnWSR || intaSig;
    assign iraWrtEn = iraWSR || intaSig;
    assign ihaWrtEn = ihaWSR;
    
    wire [DBITS - 1: 0] pcsOut, idnOut, iraOut, ihaOut;
    Register #(.BIT_WIDTH(DBITS), .RESET_VALUE(0)) pcsReg (
        clk, reset, pcsWrtEn, 
            isReti ? {(DBITS){1'b1}} :
            intaSig ? {(DBITS){1'b0}} : 
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
            rdIndex == PCS_INDEX ? (pcsWSR ? dataIn : pcsOut) :
            rdIndex == IHA_INDEX ? (ihaWSR ? dataIn : ihaOut) :
            rdIndex == IRA_INDEX ? (iraWSR ? dataIn : iraOut) :
            rdIndex == IDN_INDEX ? (idnWSR ? dataIn : idnOut) :
            0;
         
    assign intaAddr = intaSig ? ihaOut: iraOut;

endmodule
