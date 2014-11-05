module IO_Controller(dataAddr, isLoad, isStore, dataWrtEn, dataMemOutSel, swEn, keyEn, ledrEn, ledgEn, hexEn);

	input[31:0] dataAddr;
	input isLoad;
	input isStore;
	
	output reg dataWrtEn;
	output reg [1:0] dataMemOutSel;
	output reg swEn;
	output reg keyEn;
	output reg ledrEn;
	output reg ledgEn;
	output reg hexEn;
	
	always @(*)
	begin
	// STORE/LOAD?
	if(isLoad) // LOAD
	begin
		case (dataAddr[31:28])
			4'hF: // I/O
			begin
					case (dataAddr[7:0]) // select which I/O
							8'h14:begin
								dataWrtEn			<= 1'b0;
								dataMemOutSel		<= 2'd1;
								swEn 					<= 1'b1;
								keyEn					<= 1'b0;
								ledrEn 				<= 1'b0;
								ledgEn 				<= 1'b0;
								hexEn 				<= 1'b0;
							end
							8'h10:begin
								dataWrtEn			<= 1'b0;
								dataMemOutSel		<= 2'd2;
								swEn 					<= 1'b0;
								keyEn					<= 1'b1;
								ledrEn 				<= 1'b0;
								ledgEn 				<= 1'b0;
								hexEn 				<= 1'b0;
							end
							default:begin
								dataWrtEn			<= 1'b0;
								dataMemOutSel		<= 2'd0;
								swEn 					<= 1'b0;
								keyEn					<= 1'b0;
								ledrEn 				<= 1'b0;
								ledgEn 				<= 1'b0;
								hexEn 				<= 1'b0;
							end
					endcase
			end
			default:begin
				dataWrtEn			<= 1'b0;
				dataMemOutSel		<= 2'd0;
				swEn 					<= 1'b0;
				keyEn					<= 1'b0;
				ledrEn 				<= 1'b0;
				ledgEn 				<= 1'b0;
				hexEn 				<= 1'b0;
			end
		endcase
	end
	else if(isStore) // STORE
	begin
		case (dataAddr[31:28])
			4'hF: // I/O
			begin
				case (dataAddr[7:0]) // select which I/O
						8'h04:begin // LEDR
							dataWrtEn			<= 1'b0;
							dataMemOutSel		<= 2'd0;
							swEn 					<= 1'b0;
							keyEn					<= 1'b0;
							ledrEn 				<= 1'b1;
							ledgEn 				<= 1'b0;
							hexEn 				<= 1'b0;
						end
						8'h08:begin // LEDG
							dataWrtEn			<= 1'b0;
							dataMemOutSel		<= 2'd0;
							swEn 					<= 1'b0;
							keyEn					<= 1'b0;
							ledrEn 				<= 1'b0;
							ledgEn 				<= 1'b1;
							hexEn 				<= 1'b0;
						end
						8'h00:begin // HEX
							dataWrtEn			<= 1'b0;
							dataMemOutSel		<= 2'd0;
							swEn 					<= 1'b0;
							keyEn					<= 1'b0;
							ledrEn 				<= 1'b0;
							ledgEn 				<= 1'b0;
							hexEn 				<= 1'b1;
						end
						default:begin
							dataWrtEn			<= 1'b0;
							dataMemOutSel		<= 2'd0;
							swEn 					<= 1'b0;
							keyEn					<= 1'b0;
							ledrEn 				<= 1'b0;
							ledgEn 				<= 1'b0;
							hexEn 				<= 1'b0;
						end
				endcase
			end
			default:begin
				dataWrtEn			<= 1'b1;
				dataMemOutSel		<= 2'd0;
				swEn 					<= 1'b0;
				keyEn					<= 1'b0;
				ledrEn 				<= 1'b0;
				ledgEn 				<= 1'b0;
				hexEn 				<= 1'b0;
			end
		endcase
	end
	else // not LOAD neither STORE
	begin
		dataWrtEn			<= 1'b0;
		dataMemOutSel		<= 2'd0;
		swEn 					<= 1'b0;
		keyEn					<= 1'b0;
		ledrEn 				<= 1'b0;
		ledgEn 				<= 1'b0;
		hexEn 				<= 1'b0;
	end
end
	
endmodule
