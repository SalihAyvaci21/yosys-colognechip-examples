module SOC_tb();
   reg CLK;
   wire RESET = 0; 
   wire [7:0] LEDS;
   reg  RXD = 1'b0;
   wire TXD;

   SOC uut(
     .CLK(CLK),
     .RESET(~RESET),
     .LEDS(LEDS),
     .RXD(RXD),
     .TXD(TXD)
   );

   reg[7:0] prev_LEDS = 0;

   // Dumpfile and dumpvars for waveform generation
initial begin
    $dumpfile("SOC_tb.vcd"); // Specify dump file name
    $dumpvars(0, SOC_tb); // Dump all signals in the testbench
end

   initial begin
      CLK = 0;
      forever begin
	 #1 CLK = ~CLK;
	 if(LEDS != prev_LEDS) begin
	    $display("LEDS = %b",LEDS);
	 end
	 prev_LEDS <= LEDS;
         // stop test after one cycle
         if(prev_LEDS == 8'b11100000) $finish();
      end
   end
endmodule