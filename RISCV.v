`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2023 19:00:05
// Design Name: 
// Module Name: RISCV
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


module RISCV(input clk, output B);

reg signed [31:0] PC, IF_ID_IR, IF_ID_NPC; //Registers are used in FETCH-DECODE statge
reg signed [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B;//Registers are used in DECODE-EXECUTION statge
reg signed [31:0] ID_EX_Imm_A,ID_EX_Imm_Unsi,ID_EX_Imm_U,ID_EX_Imm_S, ID_EX_Imm_L, ID_EX_Imm_B, ID_EX_Imm_Jal, ID_EX_Imm_Jalr, ID_EX_Imm_loadnoc; // FOR SIGN EXTENSION
reg [4:0] ID_EX_type, EX_MEM_type, MEM_WB_type; //REGISTERS TO HOLD TYPE OF INSTRUCTIONS
//reg signed [31:0]EX_FWD,  MEM_WB_ALUout_ex;
reg signed [31:0] EX_MEM_IR, EX_MEM_ALUout, EX_MEM_B, EX_MEM_NPC, MEM_WB_NPC; //Registers are used in EXECUTE-MEMORY statge
reg EX_MEM_cond; //Flag used for branch
reg signed [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD; //Registers are used in MEMORY-WRITE BACK statge
assign B = EX_MEM_ALUout;
reg signed [31:0] Reg [0:31]; //32X32 Regiter Bank
reg signed [31:0] Mem [0:31]; //32X32 memory_instruction
reg signed [31:0] Mem_data [0:1023]; //1024X32 memory_data
reg signed [7:0] MMR [4000:4019]; //20X8 Memory Mapped Register
wire predict;
reg reset;
//no operation for stalling
parameter NOP = 5'b01111; 
             

//DEFINED TO DISTINGUISH BETWEEN DIFFERENT TYPES OF INSTRUCTION USNING 6-2 bits OF OPCODE
parameter RR_ALU = 5'b01100, 
          RM_ALU = 5'b00100,
          LOAD = 5'b00000,
          STORE = 5'b01000,
          BRANCH = 5'b11000,
          LOADNOC = 5'b11111,
          STORENOC = 5'b11100;
          
//PARAMETERS ARE USED FOR REGISTER-REGISTER OPERATIONS USING 3-bit FUNCTION DEFINITION
parameter ADD = 3'b000, 
          AND = 3'b111,
          OR = 3'b110,
          SLL = 3'b001,
          SRA = 3'b101,
          SLT = 3'b010,
          SLTU = 3'b011,
          XOR = 3'b100;
         
//PARAMETERS ARE USED FOR REGISTER-IMMEDIATE OPERATIONS USING 3-bit FUNCTION DEFINITION        
parameter ADDI = 3'b000,
          SLTI = 3'b010, 
          SLTIU = 3'b011,
          XORI = 3'b100,
          ORI = 3'b110,
          ANDI = 3'b111,
          SLLI = 3'b001,
          SRLI = 3'b101;
          //SRAI = 3'b101;
          
//PARAMETERS ARE USED FOR BRANCH OPERATIONS USING 3-bit FUNCTION DEFINITION        
parameter BEQ = 3'b000,
          BNE = 3'b001, 
          BLT = 3'b100,
          BGE = 3'b101,
          BLTU = 3'b110,
          BGEU = 3'b111;          
          
//PARAMETERS ARE USED FOR LOAD OPERATIONS USING 3-bit FUNCTION DEFINITION        
parameter LB = 3'b000,
          LH = 3'b001, 
          LW = 3'b010,
          LBU = 3'b100,
          LHU = 3'b101;  
          
//PARAMETERS ARE USED FOR STORE OPERATIONS USING 3-bit FUNCTION DEFINITION        
parameter SB = 3'b000,
          SH = 3'b001, 
          SW = 3'b010;                
          
//PARAMETERS ARE USED FOR U-type OPERATIONS USING OPCODE       
parameter LUI = 5'b01101,
          AUIPC = 5'b00101;
          
//PARAMETERS ARE USED FOR UJ-type OPERATIONS USING OPCODE       
parameter JAL = 5'b11011,
          JALR = 5'b11001;                    
         
//reg HALTED; // Flag used for stop the program
reg TAKEN_BRANCH; // Flag used for branch taken
reg write_back; // Flag used for write back
reg [31:0] pred_ir;
branch_predictor a(
    .clk(clk),          // Clock input
    .reset(reset),        // Reset signal
    .branch_taken(TAKEN_BRANCH),.IR(pred_ir), // Signal indicating whether branch was taken
    .predict(predict)      // Predicted branch outcome
    );

//FETCH STAGE
always @ (posedge clk) //Computation statted at positive edge of clk1
begin
        case(EX_MEM_IR[6:2])
        BRANCH:
            if(EX_MEM_cond == 1'b1) //checking for branch instructions
            begin
                IF_ID_IR <= Mem[EX_MEM_ALUout];
                TAKEN_BRANCH <= 1'b1;
                IF_ID_NPC <= EX_MEM_ALUout;
                PC <= EX_MEM_ALUout + 1;
                ID_EX_NPC <= 0;
                ID_EX_IR <= 0;
                pred_ir<=EX_MEM_IR;
                EX_MEM_NPC <= 0;      
                EX_MEM_type  <= 0;
                EX_MEM_IR    <= 0;
                MEM_WB_type <= 0; 
                MEM_WB_IR   <= 0;
                MEM_WB_NPC <= 0;
                EX_MEM_cond <=0;
            end
            else
            pred_ir<=EX_MEM_IR;
       
        JAL,JALR: 
            begin
                IF_ID_IR <= Mem[EX_MEM_ALUout];
                IF_ID_NPC <= PC;
                PC <= PC + 1;
            end
       default:
            begin  //for normal fetch operations
                IF_ID_IR <= Mem[PC];
                IF_ID_NPC <= PC;
                PC <= PC+1;
                TAKEN_BRANCH <= 1'b0;
                pred_ir<=0;
            end
            
       endcase
end     
   
//DECODE STAGE
always @ (posedge clk)
begin
if(EX_MEM_cond != 1'b1) //checking for branch instructions
            begin
            ID_EX_NPC <= IF_ID_NPC;
            ID_EX_IR <= IF_ID_IR;
            end
             //checking whether rd is equal to rs1 (RAW hazard) except for LOAD type instruction 
              if((ID_EX_IR[11:7] == IF_ID_IR[19:15])& ID_EX_type!=LOAD )   
                  begin
                      ID_EX_A <= EX_MEM_ALUout; //reading value of ALU
                  end
             else if((EX_MEM_IR[11:7] == IF_ID_IR[19:15])& ID_EX_type!=LOAD)   
                  begin
                      ID_EX_A <= EX_MEM_ALUout; //reading value of ALU
                  end
              else if((MEM_WB_IR[11:7] == IF_ID_IR[19:15])& MEM_WB_type==LOAD)   
                  begin
                      ID_EX_A <= MEM_WB_LMD; //reading value of ALU
                  end
             else
                  begin
                     if (IF_ID_IR[19:15] == 5'b00000) //Incorporating rs1
                        ID_EX_A <= 0;
                     else 
                        ID_EX_A <= Reg[IF_ID_IR[19:15]];
                  end   
           //similarly for rd and rs2
           if((ID_EX_IR[11:7] == IF_ID_IR[24:20])& ID_EX_type!=LOAD)     
                  begin
                        ID_EX_B <= EX_MEM_ALUout;
                  end
           else if((EX_MEM_IR[11:7] == IF_ID_IR[24:20])& ID_EX_type!=LOAD)     
                  begin
                        ID_EX_B <= EX_MEM_ALUout;
                  end 
           else if((MEM_WB_IR[11:7] == IF_ID_IR[24:20])& MEM_WB_type==LOAD)     
                  begin
                        ID_EX_B <= MEM_WB_LMD;
                  end 
           else
                  begin
                     if (IF_ID_IR[24:20] == 5'b00000) //Incorporating rs1
                        ID_EX_B <= 0;
                     else 
                        ID_EX_B <= Reg[IF_ID_IR[24:20]];
                  end   
   
          //Source Register Value and Sign-Extended Immediate value calculation for different types of instructions
           case (IF_ID_IR[6:2])
                RR_ALU: ID_EX_Imm_A <= 0;
                RM_ALU: begin  
                         if(IF_ID_IR[14:12]==3'b011)
                             ID_EX_Imm_Unsi <= {{20{1'b0}},{IF_ID_IR[31:20]}};  // immediate value of SLTIU
                         else if (IF_ID_IR[14:12]==3'b001 || IF_ID_IR[14:12]==3'b101 )
                             ID_EX_Imm_A <= IF_ID_IR[24:20] ;   //shift amount value of SLLI, SRLI, SRAI 
                         else
                             ID_EX_Imm_A <= {{20{IF_ID_IR[31]}},{IF_ID_IR[31:20]}};     // immediate value of ADDI, SLTI, XORI, ORI, ANDI
                        end
                LOAD :  ID_EX_Imm_L <= {{20{IF_ID_IR[31]}},{IF_ID_IR[31:20]}};   //immediate value of LOAD
                STORE : ID_EX_Imm_S <= {{20{IF_ID_IR[31]}},{IF_ID_IR[31:25]},{IF_ID_IR[11:7]}};  //immediate value of store
                BRANCH : ID_EX_Imm_B <= {{20{IF_ID_IR[31]}},{IF_ID_IR[31]},{IF_ID_IR[7]},{IF_ID_IR[30:25]},{IF_ID_IR[11:8]}};  // immediate value for branch
                LUI, AUIPC : ID_EX_Imm_U <= {{IF_ID_IR[31:12]},{12{1'b0}}};   //immediate value of U-type
                JAL : ID_EX_Imm_Jal <= {{12{IF_ID_IR[31]}},{IF_ID_IR[31]},{IF_ID_IR[19:12]},{IF_ID_IR[20]},{IF_ID_IR[30:21]}};
                JALR : ID_EX_Imm_Jalr <= {{20{IF_ID_IR[31]}},{IF_ID_IR[31:20]}};
                LOADNOC :   begin          //format :   imm(15 bits) , rs2(5-bits), rs1(5-bits) , opcode(7-bits)
                            ID_EX_A <= Reg[IF_ID_IR[11:7]];    //rs1 = R31 is the designated register , which holds the address X4000
                            ID_EX_B <= Reg[IF_ID_IR[16:12]];   //rs2 
                            ID_EX_Imm_loadnoc <= {{17{IF_ID_IR[31]}},IF_ID_IR[31:17]};  
                            end
          endcase
          
          //for computing type of instructions.
            case(IF_ID_IR[6:2]) 
                RR_ALU: ID_EX_type <= RR_ALU;                           
                RM_ALU: ID_EX_type <= RM_ALU;
                LOAD:   ID_EX_type <= LOAD;
                STORE:  ID_EX_type <= STORE;
                BRANCH: ID_EX_type <= BRANCH;
                NOP:    ID_EX_type <= NOP;
                LUI:    ID_EX_type <= LUI;
                AUIPC:  ID_EX_type <= AUIPC;
                JAL:    ID_EX_type <= JAL;
                JALR:   ID_EX_type <= JALR;
                LOADNOC: ID_EX_type <= LOADNOC;
                STORENOC: ID_EX_type <= STORENOC;
                default:  ID_EX_type <= NOP;
            endcase
end
     
//EXECUTE STAGE 

always @(posedge clk)
begin
      if(EX_MEM_cond != 1'b1) //checking for branch instructions
            begin
        EX_MEM_NPC <= ID_EX_NPC;      
        EX_MEM_type  <= ID_EX_type;
        EX_MEM_IR    <= ID_EX_IR;
        //TAKEN_BRANCH <= 1'b0;
        end
        
        //fOR CCOMPUING OPERATIONS
        case (ID_EX_type) 
        RR_ALU : begin  //ARITHEMATIC OPERATIONS
                       case(ID_EX_IR[14:12])
                           ADD: begin //func7 comparision
                                  if(ID_EX_IR[31:27]==5'b00000) 
                                     EX_MEM_ALUout <= ID_EX_A + ID_EX_B; //addition                                                         
                                  else if(ID_EX_IR[31:27]==5'b01000)   
                                     EX_MEM_ALUout <= ID_EX_A - ID_EX_B; //subtraction
                                end
                           AND:    EX_MEM_ALUout <= ID_EX_A & ID_EX_B;
                           OR:     EX_MEM_ALUout <= ID_EX_A | ID_EX_B;
                           SLL:    EX_MEM_ALUout <= ID_EX_A << ID_EX_B; //Logical Left Shift   
                           SRA: begin
                                   if(ID_EX_IR[31:27]==5'b01000)
                                       EX_MEM_ALUout <= ID_EX_A >>> ID_EX_B; //SRA: Arithmatic Right Shift
                                   else if(ID_EX_IR[31:27]==5'b00000)
                                       EX_MEM_ALUout <= ID_EX_A >> ID_EX_B;  //SRL: Logical Right Shift
                                end
                           XOR:    EX_MEM_ALUout <= ID_EX_A ^ ID_EX_B;
                           SLT:    EX_MEM_ALUout <= $signed(ID_EX_A) < $signed(ID_EX_B);
                           SLTU:   EX_MEM_ALUout <= $unsigned(ID_EX_A) < $unsigned(ID_EX_B);
                           default:EX_MEM_ALUout <= 32'hxxxxxxxx;    
                       endcase
                 end
        RM_ALU : begin //IMMEDIATE OPERATIONS
                        case (ID_EX_IR[14:12]) //func7 comparision
                            ADDI:  EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm_A;
                            SLTI:  EX_MEM_ALUout <= ID_EX_A < ID_EX_Imm_A; 
                            SLTIU: EX_MEM_ALUout <= $unsigned(ID_EX_A) < ID_EX_Imm_Unsi; 
                            XORI:  EX_MEM_ALUout <= ID_EX_A ^ ID_EX_Imm_A;
                            ORI:   EX_MEM_ALUout <= ID_EX_A | ID_EX_Imm_A;     
                            ANDI:  EX_MEM_ALUout <= ID_EX_A & ID_EX_Imm_A; 
                            SLLI:  EX_MEM_ALUout <= ID_EX_A << ID_EX_Imm_A;   
                            SRLI: begin
                                   if(ID_EX_IR[31:27]==5'b01000)
                                       EX_MEM_ALUout <= ID_EX_A >>> ID_EX_Imm_A; //SRAI: Arithmatic Right Shift
                                   else if(ID_EX_IR[31:27]==5'b00000)
                                       EX_MEM_ALUout <= ID_EX_A >> ID_EX_Imm_A;  //SRLI: Logical Right Shift
                                 end  
                            default: EX_MEM_ALUout <= 32'hxxxxxxxx;  
                        endcase     
                 end            
       LOAD: //LOAD AND STORE INSTRUCTION
                begin
                    EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm_L;
                    EX_MEM_B      <= ID_EX_B;  
                     //hazard <= #2 0;
                end
       STORE: //STORE INSTRUCTION
                begin
                    EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm_S;
                    EX_MEM_B      <= ID_EX_B;  
                     //hazard <= #2 0;
                end 
       BRANCH: //BRANCH INSTRUCTION
                begin
                    case(ID_EX_IR[14:12] )
                    BEQ: begin
                        if(ID_EX_A == ID_EX_B)
                            begin
                                EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm_B;
                                EX_MEM_cond <= 1'b1;
                            end
                        else
                           begin
                               //EX_MEM_ALUout <= ID_EX_NPC;
                               EX_MEM_cond <= 1'b0;
                           end    
                       end
                            
                   BNE: begin
                       if(ID_EX_A != ID_EX_B)
                           begin
                                EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm_B;
                                EX_MEM_cond <= 1'b1;
                            end
                        else
                           begin
                               //EX_MEM_ALUout <= ID_EX_NPC;
                               EX_MEM_cond <= 1'b0;
                           end    
                       end
                    
             
                   BLTU: begin
                           if($unsigned(ID_EX_A) < $unsigned(ID_EX_B))
                            begin
                                EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm_B;
                                EX_MEM_cond <= 1'b1;
                            end
                            
                            else
                            begin
                                //EX_MEM_ALUout <= ID_EX_NPC;
		                        EX_MEM_cond <= 1'b0;    
                            end
                        end
                      
                    BGEU: begin
                              if($unsigned(ID_EX_A) >= $unsigned(ID_EX_B))
                              begin
                              EX_MEM_ALUout <= ID_EX_NPC+ ID_EX_Imm_B;
                              EX_MEM_cond <= 1'b1;
                             end
                             else
                             begin
                                //EX_MEM_ALUout <= ID_EX_NPC;
		                        EX_MEM_cond <= 1'b0;    
                             end
                         end
                
                    endcase
                end
       
       LOADNOC: begin      // format: LOADNOC B A imm i.e B--> MMR[A+imm]
                //ID_EX_A <= 32'h4000;
                EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm_loadnoc;
                EX_MEM_B      <= ID_EX_B; 
                end

       LUI: //LUI INSTRUCTION
            EX_MEM_ALUout <= ID_EX_Imm_U;
               
       AUIPC: //AUIPC INSTRUCTION
            EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm_U;
            
       JAL: //JAL INSTRUCTION,  [rd] -> PC + 1; PC -> PC + Immediate
            EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm_Jal;   
       
       JALR: //JALR INSTRUCTION, [rd] -> PC + 1; PC -> (Immediate + [rs1]) &~1
            EX_MEM_ALUout <= (ID_EX_Imm_Jalr + Reg[EX_MEM_IR[19:15]]) &~ 1;       
                             
       NOP : //FOR STALLING
            EX_MEM_ALUout <= 0;
            
       
       default: EX_MEM_ALUout  <= 32'hxxxxxxxx;       
                
    endcase 

end


// MEMORY STAGE
always @ (posedge clk)
begin
    if(EX_MEM_cond != 1'b1) //checking for branch instructions
            begin
        MEM_WB_type <= EX_MEM_type; 
        MEM_WB_IR   <= EX_MEM_IR;
         end
         
     case (EX_MEM_type)
        RR_ALU,RM_ALU,NOP,LUI,AUIPC:
            begin
                MEM_WB_ALUout <= EX_MEM_ALUout; 

            end
                
        LOAD:   begin
                    MEM_WB_LMD  <= Mem_data[EX_MEM_ALUout];
                end
        STORE:  if(TAKEN_BRANCH ==0)
                begin
                  case(EX_MEM_IR[14:12])
                  SB : Mem_data[EX_MEM_ALUout] <= EX_MEM_B[7:0];
                  SH : Mem_data[EX_MEM_ALUout] <= EX_MEM_B[15:0];
                  SW : Mem_data[EX_MEM_ALUout] <= EX_MEM_B[31:0];       
                  endcase
                end
        LOADNOC:  begin //following big endian approach
                    MMR[EX_MEM_ALUout] <= EX_MEM_B[31:24];
                    MMR[EX_MEM_ALUout+1] <= EX_MEM_B[23:16];
                    MMR[EX_MEM_ALUout+2] <= EX_MEM_B[15:8];
                    MMR[EX_MEM_ALUout+3] <= EX_MEM_B[7:0];
                  end  
        STORENOC:  // decimal '1' will be stored in the address X4010 to X4013
                 begin
                  MMR[4016] <= 8'd0;
                  MMR[4017] <= 8'd0;
                  MMR[4018] <= 8'd0;
                  MMR[4019] <= 8'd1;
                 end 
                               
        endcase
end

//WRITE-BACK STAGE
integer reg_mem, data_mem, mmr_mem;
integer i,j,k;

always @(posedge clk)
 
    begin
   
      if(EX_MEM_cond != 1'b1) //checking for branch instructions
            begin
        MEM_WB_NPC <= EX_MEM_NPC; 
        end
        if(TAKEN_BRANCH ==0)  //Disable write if branch taken
        begin
        write_back <= #2 1'b1;
        case (MEM_WB_type)
//            RR_ALU: Reg[MEM_WB_IR[11:7]] <= MEM_WB_ALUout;  //rd
//            RM_ALU: Reg[MEM_WB_IR[11:7]] <= MEM_WB_ALUout; 
            RR_ALU: Reg[MEM_WB_IR[11:7]] <= (MEM_WB_IR[11:7]==0)? 0: MEM_WB_ALUout;  //rd
            RM_ALU: Reg[MEM_WB_IR[11:7]] <= (MEM_WB_IR[11:7]==0)? 0: MEM_WB_ALUout;
            LOAD: begin
                  case(MEM_WB_IR[14:12])
                  LB : Reg[MEM_WB_IR[11:7]] <= {{24{MEM_WB_LMD[7]}} ,MEM_WB_LMD[7:0]} ;
                  LH : Reg[MEM_WB_IR[11:7]] <= {{16{MEM_WB_LMD[15]}}   ,MEM_WB_LMD[15:0]} ;
                  LW : Reg[MEM_WB_IR[11:7]] <= MEM_WB_LMD ;  //32 bit value
                  LBU : Reg[MEM_WB_IR[11:7]] <= {{24{1'b0}} ,MEM_WB_LMD[7:0]} ;
                  LHU : Reg[MEM_WB_IR[11:7]] <= {{16{1'b0}} ,MEM_WB_LMD[15:0]} ;
                  endcase  
                  end       
            LUI,AUIPC: Reg[MEM_WB_IR[11:7]] <= MEM_WB_ALUout;
            JAL, JALR: Reg[MEM_WB_IR[11:7]] <= EX_MEM_NPC + 1;    
            NOP:    Reg[MEM_WB_IR[11:7]] <= MEM_WB_ALUout;    
        endcase
   end
   
  //Dump file for Register Bank and Data Memory created 
  reg_mem = $fopen("Register_Dump.txt","w");
        for (i = 0; i < 32; i = i + 1)
        begin
            //Reading the contents of the register
            $fdisplay(reg_mem,"Reg[%0d] = %h\n",i,Reg[i]);
        end
        $fclose(reg_mem);
  data_mem = $fopen("DataMemory_Dump.txt","w");
        for (j = 0; j < 1024; j = j + 1)
        begin
            //Reading the contents of the Memory
            $fdisplay(data_mem,"DataMem[%0d] = %h\n",j,Mem_data[j]);
        end
        $fclose(data_mem);
        
mmr_mem = $fopen("MMR_Dump.txt","w");
        for (k = 4000; k < 4020; k = k + 1)
        begin
        //Reading the contents of the Memory Mapped Register
        $fdisplay(mmr_mem,"MMR[%0d] = %h\n",k,MMR[k]);
        end
        $fclose(mmr_mem);
end

endmodule
