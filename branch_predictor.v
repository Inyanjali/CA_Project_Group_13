`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2023 08:42:21 PM
// Design Name: 
// Module Name: branch_predictor
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


module branch_predictor(
    input wire clk,          // Clock input
    input wire reset,        // Reset signal
    input wire branch_taken,
    input wire [31:0] IR, // Signal indicating whether branch was taken
    output reg predict      // Predicted branch outcome
    );
   
  parameter SNT = 2'b00,
            WNT = 2'b01,
            WT = 2'b10,
            ST = 2'b11;


  // Internal signals
  reg [1:0] present_state,next_state;
  reg taken = 1'b1;
  reg not_taken = 1'b0;

//state logic
always@(posedge clk) 
begin
    if(reset)
        present_state <= SNT;
    else
        present_state <= next_state;
end

 //Moore FSM
always @(*) 
begin
        if(IR [6:2] == 5'b11000) begin
        case(present_state)
            SNT: begin
                if (branch_taken) 
                    next_state <= WNT;
                else
                   next_state <= SNT;
            end
            WNT: begin
                 if (branch_taken) 
                    next_state <= WT;
                 else
                    next_state <= SNT;
            end
            WT: begin
                if (branch_taken) 
                    next_state <= ST;
                else 
                    next_state <= WNT;
                end
            ST: begin
                if (branch_taken) 
                    next_state <= ST;
                else
                    next_state <= WT;    
            end
            //default: next_state <= SNT;
        endcase
       end 
       else
             next_state <= present_state;
end

// Output prediction based on FSM state
always @(*)
begin
    case(present_state)
        SNT, WNT: predict <= not_taken;
        ST, WT: predict <= taken;
        default: predict <= not_taken;
    endcase
end


endmodule