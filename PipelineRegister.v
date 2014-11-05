module PiplelineRegister
(
    clk, reset,
    inRegWrEn, inMulSel, inAluOut, inData2Out, inPC, inInstType, inBrTaken, inIsLoad, inIsStore,
    outRegWrEn, outMulSel, outAluOut, outData2Out, outPC, outInstType, outBrTaken, outIsLoad, outIsStore,
    isStall
);
    parameter RESET_VALUE = 0;

    input clk, reset;

    input [0 : 0]   inRegWrEn;
    input [1 : 0]   inMulSel;
    input [31 : 0]  inAluOut;
    input [31 : 0]  inData2Out;
    input [31 : 0]  inPC;
    input [3 : 0]   inInstType;
    input [0 : 0]   inBrTaken;
    input [0 : 0]   inIsLoad;
    input [0 : 0]   inIsStore;


    output reg [0 : 0]  outRegWrEn;
    output reg [1 : 0]  outMulSel;
    output reg [31 : 0] outAluOut;
    output reg [31 : 0] outData2Out;
    output reg [31 : 0] outPC;
    output reg [3 : 0]  outInstType;
    output reg [0 : 0]  outBrTaken;
    output reg [0 : 0]  outIsLoad;
    output reg [0 : 0]  outIsStore;

    output [0 : 0]  isStall;
    wire   [0 : 0]  isStall;

    assign isStall = (inInstType == 4'b1011 || inInstType == 4'b0101 || inInstType == 4'b0110);

    always @(posedge clk) begin
        if (reset == 1'b1) begin
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
            outRegWrEn  <= inRegWrEn;
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