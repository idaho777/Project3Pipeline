module PipelineRegister
(
    clk, reset,
    inWrtIndex, inRegWrEn, inMulSel, inAluOut, inData2Out, inPC, inInstType, inBrTaken, inIsLoad, inIsStore,
    outWrtIndex, outRegWrEn, outMulSel, outAluOut, outData2Out, outPC, outInstType, outIsLoad, outIsStore,
    isStall
);
    parameter RESET_VALUE = 0;
    parameter OP1_LW;
    parameter OP1_BR;
    parameter OP1_JAL;

    input clk, reset;

    input [0 : 0]   inRegWrEn;
    input [3 : 0]   inWrtIndex;
    
    input [1 : 0]   inMulSel;
    input [31 : 0]  inAluOut;
    input [31 : 0]  inData2Out;
    input [31 : 0]  inPC;
    input [3 : 0]   inInstType;
    input [0 : 0]   inBrTaken;
    input [0 : 0]   inIsLoad;
    input [0 : 0]   inIsStore;


    output reg [3 : 0]  outWrtIndex;
    output reg [0 : 0]  outRegWrEn;
    output reg [1 : 0]  outMulSel;
    output reg [31 : 0] outAluOut;
    output reg [31 : 0] outData2Out;
    output reg [31 : 0] outPC;
    output reg [3 : 0]  outInstType;
    output reg [0 : 0]  outIsLoad;
    output reg [0 : 0]  outIsStore;

    reg [0 : 0]  outBrTaken;

    output [0 : 0]  isStall;

    assign isStall =  (
        outInstType == OP1_LW |
        (outInstType == OP1_BR && outBrTaken) |
        outInstType == OP1_JAL
    );

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            outWrtIndex <= RESET_VALUE;
            outRegWrEn  <= RESET_VALUE;
            outMulSel   <= RESET_VALUE;
            outAluOut   <= RESET_VALUE;
            outData2Out <= RESET_VALUE;
            outPC       <= RESET_VALUE;
            outInstType <= RESET_VALUE;
            outBrTaken  <= RESET_VALUE;
            outIsLoad   <= RESET_VALUE;
            outIsStore  <= RESET_VALUE;
        end
        else begin
            outWrtIndex <= inWrtIndex;
            outRegWrEn  <= (isStall) ? 1'b0 : inRegWrEn;
            outMulSel   <= inMulSel;
            outAluOut   <= inAluOut;
            outData2Out <= inData2Out;
            outPC       <= inPC;
            outInstType <= inInstType;
            outBrTaken  <= inBrTaken;
            outIsLoad   <= (isStall) ? 1'b0 : inIsLoad;
            outIsStore  <= (isStall) ? 1'b0 : inIsStore;
        end
    end

endmodule
