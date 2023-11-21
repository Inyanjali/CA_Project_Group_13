`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2023 23:47:37
// Design Name: 
// Module Name: RISCV_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RISCV_tb();
    reg clk;
    integer k;
    integer i;
    RISCV riscv(.clk(clk));
          always
           begin
           clk = 0;
           forever #10 clk = ~clk;
           end
           initial begin
            riscv.reset = 1'b1;
            #40
            riscv.reset = 1'b0;
            end
    
        initial
        begin
        
            //Register file is initiated with 32X32 values
            for(k=0; k<31; k=k+1)
		    riscv.Reg[k] = k;
		    riscv.Reg[31] = 32'd4000; //designated register which stores base address of MMR
		    
		    //Data Memory is initiated with 1024X32 values
		    for(i=0; i<1024; i=i+1)
            riscv.Mem_data[i]=i;
            
            //Initialization of Memory Mapped Register
            //for(i=32'h4000; i<4020; i=i+4)
            //{riscv.MMR[i],riscv.MMR[i+1],riscv.MMR[i+2],riscv.MMR[i+3]}=i;
           
           //Passing the file path of MMR where it is initialized
           $readmemb ("Memory Mapped Register.txt",riscv.MMR);
		    
		    //Passing binary file path of instruction and storing in instruction memory
		    $readmemb("binary.txt",riscv.Mem);
            //$readmemb("D:/XILINXSETUP/CA/project_5/binary.txt", data); // Path of the binary file
        end
        
     initial
        begin
            
        //riscv.HALTED=0;
        riscv.PC=0;
       //riscv.TAKEN_BRANCH=0;
       // riscv.reset=0;
        riscv.EX_MEM_cond=0;
		riscv.write_back=0;
        #600
        
        //displaying register values after operation
        for (k=0; k<32; k=k+1)
            $display ("R%1d -%2d", k, riscv.Reg[k]);
            
        //displaying data memory values after operation    
	    for (k=0;k<1024; k=k+1)
		    $display ("M%1d -%2d", k, riscv.Mem_data[k]);
		    
	    //displaying MMR values after operation for LOADNOC, instruction: LOADNOC rs2, R31, #8
//	      $display("MMR[4000]-%d",riscv.MMR[4000]);  //0x4000
//          $display("MMR[4008]-%d",riscv.MMR[4008]);   //0x4008
//          $display("MMR[4009]-%d",riscv.MMR[4009]);   //0x4009
//          $display("MMR[400A]-%d",riscv.MMR[4010]);   //0x400A
//          $display("MMR[400B]-%d",riscv.MMR[4011]);   //0x400B
          
        //displaying MMR values after operation for STORENOC
//          $display("MMR[4010]-%d",riscv.MMR[4016]);  //0x4010
//          $display("MMR[4011]-%d",riscv.MMR[4017]);  //0x4011
//          $display("MMR[4012]-%d",riscv.MMR[4018]);  //0x4012
//          $display("MMR[4013]-%d",riscv.MMR[4019]);  //0x4013	 
         
        //displaying MMR values after operation    
	    /*for (k=4000;k<4020; k=k+1)
		    $display ("MMR%1d -%2d", k, riscv.MMR[k]);   */

            #800 $finish;
        end
        
	initial
		begin
						
            $dumpfile ("riscv.vcd");
            $dumpvars (0,RISCV_tb);
		end

endmodule
