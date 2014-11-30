module Processor(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
    parameter DBITS = 32;

    parameter ADDR_KEY                              = 32'hF0000010;
	parameter ADDR_SW                               = 32'hF0000014;
	parameter ADDR_HEX                              = 32'hF0000000;
	parameter ADDR_LEDR                     	    = 32'hF0000004;
	parameter ADDR_LEDG                             = 32'hF0000008;
	parameter ADDR_TIMER_COUNT                      = 32'hF0000020;
	parameter ADDR_TIMER_LIMIT                      = 32'hF0000024;
    parameter ADDR_KEY_CONTROL                      = 32'hF0000110;
	parameter ADDR_SW_CONTROL                       = 32'hF0000114;
	parameter ADDR_TIMER_CONTROL                    = 32'hF0000120;
    
    parameter DMEM_ADDR_BIT_WIDTH                   = 11;
    parameter DMEM_DATA_BIT_WIDTH                   = 32;
    parameter DMEM_ADDR_BITS_HI                     = DMEM_ADDR_BIT_WIDTH + 2;
    parameter DMEM_ADDR_BITS_LO                     = 2;

//    parameter IMEM_INIT_FILE               = "Combined.mif";
    parameter IMEM_INIT_FILE               = "Combined2.mif";
//    parameter IMEM_INIT_FILE				 = "Stopwatch.mif";
//    parameter IMEM_INIT_FILE				 = "Test2.mif";
//	  parameter IMEM_INIT_FILE				 = "Sort2.mif";
//	  parameter IMEM_INIT_FILE				 = "Sorter2_asm.mif";

    
    input  [9:0] SW;
	input  [3:0] KEY;
	input  CLOCK_50;
	output [9:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0,HEX1,HEX2,HEX3;

    //PLL, clock generation, and reset generation
	wire clk, lock;
 
    PLL PLL_inst (.inclk0 (CLOCK_50),.c0 (clk),.locked (lock));
    wire reset = ~lock;
    parameter CLOCK_LENGTH = 25000000;
//    parameter CLOCK_LENGTH = 65000000;

//    ClkDivider #(.divider(2500000)) clkdi(CLOCK_50, clk);
//    wire reset = SW[0];
//	parameter CLOCK_LENGTH = 1000;
//	parameter CLOCK_LENGTH = 25000000;

//    assign clk = CLOCK_50;
//    wire reset = SW[0];
//    parameter CLOCK_LENGTH = 50000000;
    
    wire we;
    wire re;
    wire [DBITS - 1: 0] memAddr;
    wire [DBITS - 1: 0] dataBus;
    wire inta_timer, inta_switch, inta_key;
    wire inta;
    wire [DBITS - 1: 0]idn;
    
    
    wire [DBITS - 1: 0] dataBusOut0;
    wire [DBITS - 1: 0] dataBusOut1;
    wire [DBITS - 1: 0] dataBusOut2;
    wire [DBITS - 1: 0] dataBusOut3;
    wire [DBITS - 1: 0] dataBusOut4;
    wire [DBITS - 1: 0] dataBusOut5;
    wire [DBITS - 1: 0] dataBusOut6;
    wire [DBITS - 1: 0] dataBusOut7;
    
    
    assign inta = (!reset) && (inta_timer || inta_switch || inta_key);
    assign idn = 
                inta_timer  ? 1 : 
                inta_key    ? 2 :
                inta_switch ? 3 :
                {(DBITS){1'b1}};
    
    wire [DBITS - 1: 0] debugCPU, debugTimer;
    
    CPU #(.IMEM_INIT_FILE(IMEM_INIT_FILE)) cpu(
        .clk(clk), .reset(reset), .dataBusIn(dataBus), .inta(inta), .idn(idn),
        .weBus(we), .reBus(re), .memAddrBus(memAddr), .dataBusOut(dataBusOut0), .debug(debugCPU)
    );

    Memory #(
        .DMEM_ADDR_BITS_HI(DMEM_ADDR_BITS_HI),
        .DMEM_ADDR_BITS_LO(DMEM_ADDR_BITS_LO),
        .DMEM_ADDR_BIT_WIDTH(DMEM_ADDR_BIT_WIDTH),
        .DMEM_DATA_BIT_WIDTH(DMEM_DATA_BIT_WIDTH),
        .BITS(DBITS)
    ) memory(
        .clk(clk), .we(we), .memAddr(memAddr), .dataBusIn(dataBus),
        .dataBusOut(dataBusOut1)
    );
    
//    assign dataBusOut2 = 0;
//    assign LEDR = {7'b0, inta_timer, inta_switch, inta_key};
    
    Led #(.LED_WIDTH(10), .BITS(DBITS), .BASE(ADDR_LEDR)) ledr(
        .clk(clk), .reset(reset), .we(we), .memAddr(memAddr), .dataBusIn(dataBus),
        .dataBusOut(dataBusOut2), .led(LEDR)
    );

    Led #(.LED_WIDTH(8), .BITS(DBITS), .BASE(ADDR_LEDG)) ledg(
        .clk(clk), .reset(reset), .we(we), .memAddr(memAddr), .dataBusIn(dataBus),
        .dataBusOut(dataBusOut3), .led(LEDG)
    );

    Hex #(.HEX_WIDTH(16), .BITS(DBITS), .BASE(ADDR_HEX)) hex(
        .clk(clk), .reset(reset), .we(we), .memAddr(memAddr), .dataBusIn(dataBus),
//        .clk(clk), .reset(reset), .we(1'b1), .memAddr(ADDR_HEX), .dataBusIn(debugCPU),
        .dataBusOut(dataBusOut4), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3)
    );
	
	Switch #(.SW_WIDTH(10), .BITS(DBITS), .BASE(ADDR_SW), .CTRL_BASE(ADDR_SW_CONTROL), .DEBOUNCE_TIME(CLOCK_LENGTH/100)) sw(
		.clk(clk), .reset(reset), .we(we), .re(re), .memAddr(memAddr), .dataBusIn(dataBus), .sw(SW),
		.dataBusOut(dataBusOut5), .inta_ready(inta_switch)
	);
	
	Key #(.KEY_WIDTH(4), .BITS(DBITS), .BASE(ADDR_KEY), .CTRL_BASE(ADDR_KEY_CONTROL)) key(
		.clk(clk), .reset(reset), .we(we), .re(re), .memAddr(memAddr), .dataBusIn(dataBus), .key(KEY),
		.dataBusOut(dataBusOut6), .inta_ready(inta_key)
	);
    
	Timer #(.BITS(DBITS), .BASE(ADDR_TIMER_COUNT), .TLIM_BASE(ADDR_TIMER_LIMIT), .CTRL_BASE(ADDR_TIMER_CONTROL), .TIME_LENGTH(CLOCK_LENGTH/1000)) timer(
		.clk(clk), .reset(reset), .we(we), .re(re), .memAddr(memAddr), .dataBusIn(dataBus),
		.dataBusOut(dataBusOut7), .inta_ready(inta_timer), .debug(debugTimer)
	);

    assign dataBus = dataBusOut0    //cpu
                    | dataBusOut1   //memory
                    | dataBusOut2   //ledr
                    | dataBusOut3   //ledg
                    | dataBusOut4   //hex
                    | dataBusOut5   //switch
                    | dataBusOut6   //key
                    | dataBusOut7   //timer
    ;
    
endmodule
