module Controller (
    inst, aluCmpIn, intaSig,
    fstOpcode, sndOpcode, dRegAddr, s1RegAddr, s2RegAddr,
    imm, regFileWrtEn, immSel, memOutSel, pcSel, isLoad, isStore,
    isReti, isRSR, isWSR
);
	
	parameter INST_BIT_WIDTH = 32;
	
	// inputs
	input [INST_BIT_WIDTH-1:0] inst;
	input aluCmpIn, intaSig;
	
	// output opcodes
	output reg [3: 0] fstOpcode;
	output reg [4: 0] sndOpcode;
	
	// register addresses
	output reg [3: 0] dRegAddr;
	output reg [3: 0] s1RegAddr;
	output reg [3: 0] s2RegAddr;
	
	// immediate value
	output reg [15: 0] imm;
	
	// control signals
	output reg regFileWrtEn;
	output reg immSel;  
	output reg [1:0] memOutSel;
	output reg [1:0] pcSel;
	output reg isLoad, isStore;

    // inta signals
    output reg isReti, isRSR, isWSR;
	
	always @(*)
	begin
        if (intaSig) begin            
            fstOpcode       <= 4'b0;
            sndOpcode 		<= 5'd0;
            dRegAddr  		<= 4'd0;
            s1RegAddr 		<= 4'd0;
            s2RegAddr 		<= 4'd0;
            imm 		 		<= 15'd0; // relative pc
            regFileWrtEn 	<= 1'b0; // no write to register
            immSel			<= 1'b0; // relative pc
            memOutSel		<= 2'b00; // load data from memory
            pcSel 			<= 2'b11; // intaAddr
            isLoad 			<= 1'b0;
            isStore 			<= 1'b0;
            isReti          <= 1'b0;
            isRSR           <= 1'b0;
            isWSR           <= 1'b0;
        end else begin
            case(inst[31:28])
            4'b0000:begin // arithmetic
                    fstOpcode       <= 4'b0000;
                    sndOpcode 		<= {1'b0, inst[27:24]};
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= inst[15:12];
                    imm 		 		<= 16'd0;
                    regFileWrtEn 	<= 1'b1; // write to register
                    //dataWrtEn 		<= 1'b0; // no write to data memory
                    immSel			<= 1'b0; // doesn't matter
                    memOutSel		<= 2'b00; // doesn't matter
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b1000:begin // immediate arithmetic
                    fstOpcode       <= 4'b1000;
                    sndOpcode 		<= {1'b0, inst[27:24]};
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= 4'd0;
                    imm 		 		<= inst[15:0];
                    regFileWrtEn 	<= 1'b1; // write to register
                    //dataWrtEn 		<= 1'b0; // no write to data memory
                    immSel			<= 1'b1; // get the data from immediate
                    memOutSel		<= 2'b00; // doesn't matter
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b0010:begin // comparison
                    fstOpcode       <= 4'b0010;
                    sndOpcode 		<= {1'b1, inst[27:24]};
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= inst[15:12];
                    imm 		 		<= 16'd0;
                    regFileWrtEn 	<= 1'b1; // write to register
                    immSel			<= 1'b0; // doesn't matter
                    memOutSel		<= 2'b00; // doesn't matter
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b1010:begin // immediate comparison
                    fstOpcode       <= 4'b1010;
                    sndOpcode 		<= {1'b1, inst[27:24]};
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= 4'd0;
                    imm 		 		<= inst[15:0];
                    regFileWrtEn 	<= 1'b1; // write to register
                    //dataWrtEn 		<= 1'b0; // no write to data memory
                    immSel			<= 1'b1; // get the data from immediate
                    memOutSel		<= 2'b00; // doesn't matter
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b0110:begin // compare and branch
                    fstOpcode       <= 4'b0110;
                    sndOpcode 		<= {1'b1, inst[27:24]};
                    dRegAddr  		<= 4'd0;
                    s1RegAddr 		<= inst[23:20];
                    s2RegAddr 		<= inst[19:16];
                    imm 		 		<= inst[15:0]; // relative pc
                    regFileWrtEn 	<= 1'b0; // no write to register
                    immSel			<= 1'b0; // relative pc
                    memOutSel		<= 2'b00; // doesn't matter
                    if(aluCmpIn)
                        pcSel 		<= 2'b01; // branch
                    else
                        pcSel	  		<= 2'b00; // do not branch
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b1001:begin // load instruction
                    fstOpcode       <= 4'b1001;
                    sndOpcode 		<= 5'b00000;
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= 4'd0;
                    imm 		 		<= inst[15:0]; // relative pc
                    regFileWrtEn 	<= 1'b1; // write to register
                    immSel			<= 1'b1; // relative pc
                    memOutSel		<= 2'b01; // load data from memory
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b1;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b0101:begin // store instruction
                    fstOpcode       <= 4'b0101;
                    sndOpcode 		<= 5'b00000;
                    dRegAddr  		<= 4'd0;
                    s1RegAddr 		<= inst[23:20];
                    s2RegAddr 		<= inst[19:16];
                    imm 		 		<= inst[15:0]; // relative pc
                    regFileWrtEn 	<= 1'b0; // no write to register
                    immSel			<= 1'b1; // relative pc
                    memOutSel		<= 2'b00; // load data from memory
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b1;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b1011:begin // JAL instruction
                    fstOpcode       <= 4'b1011;
                    sndOpcode 		<= 5'b00000; // addition
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= 4'd0;
                    imm 		 		<= inst[15:0] << 2; // relative pc
                    regFileWrtEn 	<= 1'b1; // no write to register
                    immSel			<= 1'b1; // relative pc
                    memOutSel		<= 2'b10; // load data from memory
                    pcSel 			<= 2'b10; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end
            4'b1111:begin
                    fstOpcode       <= 4'b1111;
                    sndOpcode 		<= 5'b0;
                    dRegAddr  		<= inst[23:20];
                    s1RegAddr 		<= inst[19:16];
                    s2RegAddr 		<= 4'd0;
                    imm             <= 15'd0;
                    immSel          <= 1'b0; // relative pc
                    isLoad          <= 1'b0;
                    isStore         <= 1'b0;
                    case(inst[27:24])
                    4'b0001:begin // RETI
                        pcSel           <= 2'b11; // intaAddr
                        regFileWrtEn    <= 1'b0;
                        memOutSel       <= 2'b00;
                        isReti          <= 1'b1;
                        isRSR           <= 1'b0;
                        isWSR           <= 1'b0;
                        end
                    4'b0010:begin // RSR
                        pcSel           <= 2'b00; // pc + 4
                        regFileWrtEn    <= 1'b1;
                        memOutSel       <= 2'b11; // sysDataOut1
                        isReti          <= 1'b0;
                        isRSR           <= 1'b1;
                        isWSR           <= 1'b0;
                        end
                    4'b0011:begin // WSR
                        pcSel           <= 2'b00; // pc + 4
                        regFileWrtEn    <= 1'b0;
                        memOutSel       <= 2'b00;
                        isReti          <= 1'b0;
                        isRSR           <= 1'b0;
                        isWSR           <= 1'b1;
                        end
                    default:begin
                        pcSel           <= 2'b00; // pc + 4
                        regFileWrtEn    <= 1'b0;
                        memOutSel       <= 2'b00;
                        isReti          <= 1'b0;
                        isRSR           <= 1'b0;
                        isWSR           <= 1'b0;
                        end
                    endcase
                end
            default:begin
                    fstOpcode       <= 4'b0;
                    sndOpcode 		<= 5'd0;
                    dRegAddr  		<= 4'd0;
                    s1RegAddr 		<= 4'd0;
                    s2RegAddr 		<= 4'd0;
                    imm 		 		<= 15'd0; // relative pc
                    regFileWrtEn 	<= 1'b0; // no write to register
                    immSel			<= 1'b0; // relative pc
                    memOutSel		<= 2'b00; // load data from memory
                    pcSel 			<= 2'b00; // pc + 4
                    isLoad 			<= 1'b0;
                    isStore 			<= 1'b0;
                    isReti          <= 1'b0;
                    isRSR           <= 1'b0;
                    isWSR           <= 1'b0;
                end				
            endcase
        end
	end
endmodule