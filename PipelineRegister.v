module PipelineRegister
(
    clk, reset, 
    inRdIndex1, inRdIndex2,
    inWrtIndex, inRegWrEn, inMulSel, inAluOut, inData2Out, inPC, inInstType, inBrTaken, inIsLoad, inIsStore,
    outWrtIndex, outRegWrEn, outMulSel, outAluOut, outData2Out, outPC, outInstType, outIsLoad, outIsStore,
    isStall
);
    parameter RESET_VALUE = 0;
    parameter OP1_LW;
    parameter OP1_BR;
    parameter OP1_JAL;

    input clk, reset;

    input [3: 0] inRdIndex1;
    input [3: 0] inRdIndex2;
    
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
    output [0 : 0]  isStall;

    reg [0 : 0]  prevStall;
    reg [0 : 0]  outBrTaken;


//    assign isStall = 1'b0;
    assign isStall = 
        (!prevStall) && 
        (   
            outRegWrEn
            && (outInstType == OP1_LW)
            && (outWrtIndex == inRdIndex1 | outWrtIndex == inRdIndex2)
        );

    wire isFlush;
    assign isFlush = 1'b0; // unnecessary because two stage
//    assign isFlush = 
//        (outInstType == OP1_BR && outBrTaken)
//        | outInstType == OP1_JAL;
    
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            outWrtIndex <= 1'b0;
            outRegWrEn  <= 1'b0;
            outMulSel   <= 2'b0;
            outAluOut   <= 32'b0;
            outData2Out <= 32'b0;
            outPC       <= 32'b0;
            outInstType <= 4'b0;
            outBrTaken  <= 1'b0;
            outIsLoad   <= 1'b0;
            outIsStore  <= 1'b0;
            prevStall   <= 1'b0;
        end
        else begin
            outWrtIndex <= inWrtIndex;
            outRegWrEn  <= (isFlush | isStall) ? 1'b0 : inRegWrEn;
            outMulSel   <= inMulSel;
            outAluOut   <= inAluOut;
            outData2Out <= inData2Out;
            outPC       <= inPC;
            outInstType <= inInstType;
            outBrTaken  <= inBrTaken;
            outIsLoad   <= (isFlush | isStall) ? 1'b0 : inIsLoad;
            outIsStore  <= (isFlush | isStall) ? 1'b0 : inIsStore;
            prevStall   <= isStall;
        end
    end

endmodule
