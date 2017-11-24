/*

Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// Milestone 1 file for computing all the colourspace conversion pixel values

module milestone1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock
		input logic Resetn,
	
		/////// SRAM Interface                    ////////////
//		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
//		output logic[17:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
//		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
//		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
//		output logic SRAM_WE_N_O,                 // SRAM write enable
//		output logic SRAM_CE_N_O,                 // SRAM chip enable
//		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
//		/////// MILESTONE 1 SIGNALS	                              ////////////

		input logic M1_START,
		input logic [15:0] SRAM_read_data,
		output logic [17:0] SRAM_ADDRESS_m1,
		output logic [15:0] SRAM_write_data_m1,
		output logic SRAM_we_n_m1,
		output logic M1_END
		//input logic SRAM_we_n,
		//input logic [15:0] SRAM_write_data,
		//input logic [17:0] SRAM_address
		
		

// Dont know if this is necessary 

);

// Top level FSM block

//logic resetn;

milestone_1_state_type state_m1;		// renamed to just state_m1

logic resetn;

// For SRAM
//logic SRAM_we_n_m1;
//logic [17:0] SRAM_ADDRESS_m1;
//logic [15:0] SRAM_write_data_m1;
//logic [15:0] SRAM_read_data_m1;
logic SRAM_ready;
//logic SRAM_we_n_m1;


// Assigning the states

logic [7:0] UReg[5:0];	//UReg[0] = (j-5)/2 ---- UReg[5] = (j+5)/2
logic [7:0] VReg[5:0];



parameter U_OFFSET = 18'd38400,
			 V_OFFSET = 18'd57600,
			 RGB_OFFSET = 18'd146944;
			 
logic [17:0] U_address;
logic [17:0] V_address;
logic [17:0] Y_address;
logic [17:0] RGB_address;

logic [7:0] YBufferEven;
logic [7:0] YBufferOdd;

logic [7:0] UOddBuf;
logic [7:0] VOddBuf;
logic [7:0] UEvenBuf;
logic [7:0] VEvenBuf;

logic signed[31:0] Multi_Op[7:0];			//32 bit 
wire signed[31:0] Multi_Result[3:0];		//64 bit

logic [31:0] UPrimeOdd;
logic [31:0] VPrimeOdd;

logic unsigned[31:0] RBufferEven;
logic unsigned[31:0] BBufferEven;
logic unsigned[31:0] GBufferEven;

logic unsigned[31:0] RBufferOdd;
logic unsigned[31:0] BBufferOdd;
logic unsigned[31:0] GBufferOdd;

logic [31:0] Yx76284;

logic firstrun;


assign Multi_Result[0] = Multi_Op[0] * Multi_Op[1];
assign Multi_Result[1] = Multi_Op[2] * Multi_Op[3];
assign Multi_Result[2] = Multi_Op[4] * Multi_Op[5];
assign Multi_Result[3] = Multi_Op[6] * Multi_Op[7];
			 




always_ff @(posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		state_m1 <= S_IDLE_M1;
		SRAM_we_n_m1 <= 1'b1;  			// Set Initially to reading for SRAM

		
		U_address <= 18'd0;
		V_address <= 18'd0;
		Y_address <= 18'd0;
		SRAM_ADDRESS_m1 <= 18'd0;
		SRAM_write_data_m1 <= 16'd0;
		//SRAM_read_data <= 18'h0;
		
		M1_END <= 1'b0;
		
		RGB_address <= 18'd0;
		YBufferEven <= 8'h0;
		YBufferOdd <= 8'h0;

		UOddBuf <= 8'h0;
		VOddBuf <= 8'h0;
		UEvenBuf <= 8'h0;
		VEvenBuf <= 8'h0;
		
		Multi_Op[0] <= 32'h0;			//32 bit 
		Multi_Op[1] <= 32'h0;			//32 bit 
		Multi_Op[2] <= 32'h0;			//32 bit 
		Multi_Op[3] <= 32'h0;			//32 bit 
		Multi_Op[4] <= 32'h0;			//32 bit 
		Multi_Op[5] <= 32'h0;			//32 bit 
		Multi_Op[6] <= 32'h0;			//32 bit 
		Multi_Op[7] <= 32'h0;			//32 bit 
		
		UPrimeOdd <= 32'h0;
		VPrimeOdd <= 32'h0;

		RBufferEven <= 32'h0;
		BBufferEven <= 32'h0;
		GBufferEven <= 32'h0;

		RBufferOdd <= 32'h0;
		BBufferOdd <= 32'h0;
		GBufferOdd <= 32'h0;
		Yx76284 <= 32'h0;
		
		UReg[0] <= 8'd0;
		UReg[1] <= 8'd0;
		UReg[2] <= 8'd0;
		UReg[3] <= 8'd0;
		UReg[4] <= 8'd0;
		UReg[5] <= 8'd0;
		
		VReg[0] <= 8'd0;
		VReg[1] <= 8'd0;
		VReg[2] <= 8'd0;
		VReg[3] <= 8'd0;
		VReg[4] <= 8'd0;
		VReg[5] <= 8'd0;

		firstrun <= 1'b0;


	end else begin
		case (state_m1)
		S_IDLE_M1: begin
				if((M1_START)&&(~M1_END)) begin 
				
					state_m1 <= S_LEADIN_0;
					
				end	
		end
		
		S_LEADIN_0: begin
		
			SRAM_ADDRESS_m1 <= 18'd0 + U_OFFSET;
			SRAM_we_n_m1 <= 1'b1;
			
			
			U_address <= 18'd1;
			
			state_m1 <= S_LEADIN_1;
		
		end
		
		S_LEADIN_1: begin
		
			SRAM_ADDRESS_m1 <= 18'd0 + V_OFFSET;
		
			V_address <= 18'd1;
			state_m1 <= S_LEADIN_2;
		
		end
		
		S_LEADIN_2: begin
		
			SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			
			U_address <= U_address + 18'd1;
			state_m1 <= S_LEADIN_3;
		
		
		end
		
		S_LEADIN_3: begin
		
			SRAM_ADDRESS_m1 <= V_address + V_OFFSET;
			
			V_address <= V_address + 18'd1;
			
			
			UReg[0] <= SRAM_read_data[15:8];		//U[0]
			UReg[1] <= SRAM_read_data[15:8];
			UReg[2] <= SRAM_read_data[15:8];
			UReg[3] <= SRAM_read_data[7:0];		//U[1]
		
			state_m1 <= S_LEADIN_4;
		
		
		end
		
		S_LEADIN_4: begin
		
			SRAM_ADDRESS_m1 <= Y_address;
			Y_address <= Y_address + 18'd1;
			
			VReg[0] <= SRAM_read_data[15:8];		//V[0]
			VReg[1] <= SRAM_read_data[15:8];		
			VReg[2] <= SRAM_read_data[15:8];
			VReg[3] <= SRAM_read_data[7:0];		//V[1]
			state_m1 <= S_LEADIN_5;
		
		end
		
		S_LEADIN_5: begin
		
			UReg[4] <= SRAM_read_data[15:8];		//U[2]
			UReg[5] <= SRAM_read_data[7:0];		//U[3]
			state_m1 <= S_LEADIN_6;
			
		end
		
		S_LEADIN_6: begin
		
			VReg[4] <= SRAM_read_data[15:8];		//V[2]
			VReg[5] <= SRAM_read_data[7:0];		//V[3]
			
			
			
		
			state_m1 <= S_LEADIN_7;
		end
		
		S_LEADIN_7: begin
		
			YBufferEven <= SRAM_read_data[15:8] - 32'd16;
			YBufferOdd  <= SRAM_read_data[7:0] - 32'd16;
			
		
		
			state_m1 <= S_COMMONCASE_0;
		end
		
		S_COMMONCASE_0: begin	//__++--^^--++__
		
			if (firstrun == 1'b1) begin
			
				SRAM_write_data_m1[7:0] <= RBufferOdd[31:24];
				SRAM_we_n_m1 <= 1'b0;
			
				SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				RGB_address <= RGB_address + 18'd1;
			
			end
			
			
			Multi_Op[0] <= 8'd21;
			Multi_Op[1] <= UReg[5];
			
			Multi_Op[2] <= 8'd52;
			Multi_Op[3] <= UReg[4];
			
			Multi_Op[4] <= 8'd21;
			Multi_Op[5] <= VReg[5];
			
			Multi_Op[6] <= 8'd52;
			Multi_Op[7] <= VReg[4];
			
			UPrimeOdd <= Multi_Result[0] - Multi_Result[1];
			VPrimeOdd <= Multi_Result[2] - Multi_Result[3];
			
			
			state_m1 <= S_COMMONCASE_1;
		
		
		end
		
		S_COMMONCASE_1: begin
		
			if (firstrun == 1'b1) begin
			
				SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				
				RGB_address <= RGB_address + 18'd1;
			
				SRAM_write_data_m1[15:8]  <= GBufferOdd[31:24];
				SRAM_write_data_m1[7:0] <= BBufferOdd[31:24];
				
				SRAM_we_n_m1 <= 1'b0;
				
			
			end
		
			
		
		
		
			Multi_Op[0] <= 8'd159;
			Multi_Op[1] <= UReg[3];
			
			Multi_Op[2] <= 8'd159;
			Multi_Op[3] <= UReg[2];
			
			Multi_Op[4] <= 8'd159;
			Multi_Op[5] <= VReg[3];
			
			Multi_Op[6] <= 8'd159;
			Multi_Op[7] <= VReg[2];
		
			UPrimeOdd <= UPrimeOdd + Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd + Multi_Result[2] + Multi_Result[3];

			state_m1 <= S_COMMONCASE_2;
		
		end
		
		S_COMMONCASE_2: begin
		
			
			SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			U_address <= U_address + 18'd1;
			
			SRAM_we_n_m1 <= 1'b1;
			
			
			
			firstrun <= 1'b1;
		
			Multi_Op[0] <= 8'd52;
			Multi_Op[1] <= UReg[1];
			
			Multi_Op[2] <= 8'd21;
			Multi_Op[3] <= UReg[0];
			
			Multi_Op[4] <= 8'd52;
			Multi_Op[5] <= VReg[1];
			
			Multi_Op[6] <= 8'd21;
			Multi_Op[7] <= VReg[0];
		
			UPrimeOdd <= UPrimeOdd - Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd - Multi_Result[2] + Multi_Result[3];

			state_m1 <= S_COMMONCASE_3;
		
		
		end
		
		S_COMMONCASE_3: begin
			
			SRAM_ADDRESS_m1 <= V_address + V_OFFSET;
			V_address <= V_address + 18'd1;
			
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferEven;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VReg[2] - 8'd128;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UReg[2] - 8'd128;

			
			RBufferEven <= Multi_Result[0] + Multi_Result[1];
			BBufferEven <= Multi_Result[0] + Multi_Result[3];

			Yx76284 <= Multi_Result[0];
			
			
//			UPrimeOdd[7:0] <= UPrimeOdd[31:24];
//			UPrimeOdd[31:8] <= 23'd0;
//		
//			VPrimeOdd[7:0] <= VPrimeOdd[31:24];
//			VPrimeOdd[31:8] <= 23'd0;	
			
			state_m1 <= S_COMMONCASE_4;
		
		
		end
		
		S_COMMONCASE_4: begin
		
			
			
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferOdd;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeOdd - 32'd128;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeOdd - 32'd128;

			RBufferOdd <= Multi_Result[0] + Multi_Result[1];
			BBufferOdd <= Multi_Result[0] + Multi_Result[3];

			state_m1 <= S_COMMONCASE_5;
		
		
		end
		
		S_COMMONCASE_5: begin
		
			UEvenBuf <= SRAM_read_data[15:8];
			UOddBuf <=  SRAM_read_data[7:0];
			
			SRAM_ADDRESS_m1 <= Y_address;
			Y_address <= Y_address + 18'd1;
		
		
		
			
		
			Multi_Op[0] <= 32'd25624;
			Multi_Op[1] <= UReg[2];

			Multi_Op[2] <= 32'd53281;
			Multi_Op[3] <= VReg[2];

			Multi_Op[4] <= 32'd25624;
			Multi_Op[5] <= UPrimeOdd;

			Multi_Op[6] <= 32'd53281;
			Multi_Op[7] <= VPrimeOdd;

			GBufferEven <= Yx76284 - Multi_Result[0] - Multi_Result[1];
			GBufferOdd <= Yx76284 - Multi_Result[2] - Multi_Result[3];
			
			
			UReg[0] <= UReg[1];
			UReg[1] <= UReg[2];
			UReg[2] <= UReg[3];
			UReg[3] <= UReg[4];
			UReg[5] <= UEvenBuf;
			
			VReg[0] <= VReg[1];
			VReg[1] <= VReg[2];
			VReg[2] <= VReg[3];
			VReg[3] <= VReg[4];
			VReg[5] <= VEvenBuf;
			
			

			state_m1 <= S_COMMONCASE_6; 
		
		
		end
		
		S_COMMONCASE_6: begin	//__++--^^--++__
		
		
			VEvenBuf <= SRAM_read_data[15:8];
			VOddBuf <=  SRAM_read_data[7:0];
		
			SRAM_write_data_m1[15:8] <= RBufferEven[31:24];
			SRAM_write_data_m1[7:0] <= GBufferEven[31:24];
			
			SRAM_we_n_m1 <= 1'b0;
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
			
			RGB_address <= RGB_address + 18'd1;
		
		
		
			Multi_Op[0] <= 8'd21;
			Multi_Op[1] <= UReg[5];
			
			Multi_Op[2] <= 8'd52;
			Multi_Op[3] <= UReg[4];
			
			Multi_Op[4] <= 8'd21;
			Multi_Op[5] <= VReg[5];
			
			Multi_Op[6] <= 8'd52;
			Multi_Op[7] <= VReg[4];
			
			UPrimeOdd <= Multi_Result[0] - Multi_Result[1] + 32'd128;
			VPrimeOdd <= Multi_Result[2] - Multi_Result[3] + 32'd128;
		

			state_m1 <= S_COMMONCASE_7;
		end
		
		S_COMMONCASE_7: begin
		
		
			
			SRAM_write_data_m1[15:8] <= BBufferEven[31:24];
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
		
		
		
			Multi_Op[0] <= 8'd159;
			Multi_Op[1] <= UReg[3];
			
			Multi_Op[2] <= 8'd159;
			Multi_Op[3] <= UReg[2];
			
			Multi_Op[4] <= 8'd159;
			Multi_Op[5] <= VReg[3];
			
			Multi_Op[6] <= 8'd159;
			Multi_Op[7] <= VReg[2];
		
			UPrimeOdd <= UPrimeOdd + Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd + Multi_Result[2] + Multi_Result[3];
		
		
			state_m1 <= S_COMMONCASE_8;
		end
		
		S_COMMONCASE_8: begin
		
			
			YBufferEven <= SRAM_read_data[15:8] - 32'd16;
			YBufferOdd  <= SRAM_read_data[7:0] - 32'd16;
			
			SRAM_we_n_m1 <= 1'b1;
			
			
			Multi_Op[0] <= 8'd52;
			Multi_Op[1] <= UReg[1];
			
			Multi_Op[2] <= 8'd21;
			Multi_Op[3] <= UReg[0];
			
			Multi_Op[4] <= 8'd52;
			Multi_Op[5] <= VReg[1];
			
			Multi_Op[6] <= 8'd21;
			Multi_Op[7] <= VReg[0];
		
			UPrimeOdd <= UPrimeOdd - Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd - Multi_Result[2] + Multi_Result[3];
		
		
			state_m1 <= S_COMMONCASE_9;
		end
		
		S_COMMONCASE_9: begin
		
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferEven;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VReg[2];

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UReg[2];

			
			RBufferEven <= Multi_Result[0] + Multi_Result[1];
			BBufferEven <= Multi_Result[0] + Multi_Result[3];

			Yx76284 <= Multi_Result[0];
			
//			UPrimeOdd[7:0] <= UPrimeOdd[31:24];
//			UPrimeOdd[31:8] <= 23'd0;
//			
//			VPrimeOdd[7:0] <= VPrimeOdd[31:24];
//			VPrimeOdd[31:8] <= 23'd0;
		
		
			state_m1 <= S_COMMONCASE_10;
		end
		
		S_COMMONCASE_10: begin
		
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferOdd;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeOdd;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeOdd;

			RBufferOdd <= Multi_Result[0] + Multi_Result[1];
			BBufferOdd <= Multi_Result[0] + Multi_Result[3];
		
		
			state_m1 <= S_COMMONCASE_11;
		end
		
		S_COMMONCASE_11: begin	//__++--^^--++__
			
			
			Multi_Op[0] <= 32'd25624;
			Multi_Op[1] <= UReg[2];

			Multi_Op[2] <= 32'd53281;
			Multi_Op[3] <= VReg[2];

			Multi_Op[4] <= 32'd25624;
			Multi_Op[5] <= UPrimeOdd;

			Multi_Op[6] <= 32'd53281;
			Multi_Op[7] <= VPrimeOdd;

			GBufferEven <= Yx76284 - Multi_Result[0] - Multi_Result[1];
			GBufferOdd <= Yx76284 - Multi_Result[2] - Multi_Result[3];
			
			UReg[0] <= UReg[1];
			UReg[1] <= UReg[2];
			UReg[2] <= UReg[3];
			UReg[3] <= UReg[4];
			UReg[4] <= UReg[5];
			UReg[5] <= UOddBuf;
			
			VReg[0] <= VReg[1];
			VReg[1] <= VReg[2];
			VReg[2] <= VReg[3];
			VReg[3] <= VReg[4];
			VReg[4] <= VReg[5];
			VReg[5] <= VOddBuf;
		
		
		
			if (U_address >= 18'd38400) begin
				state_m1 <= S_LEADOUT_0;
				
			end else begin
		
				state_m1 <= S_COMMONCASE_0;
	
			end
		end
		
		
		
		S_LEADOUT_0: begin
			
			SRAM_we_n_m1 <= 1'b0;
			SRAM_write_data_m1[15:8] <= RBufferEven[31:24];
			SRAM_write_data_m1[7:0]  <= GBufferEven[31:24];
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET + 18'd1;
			RGB_address <= RGB_address + 18'd1;
			
			state_m1 <= S_LEADOUT_1;
		
		end
		
		S_LEADOUT_1: begin
		
			SRAM_write_data_m1[15:8] <= BBufferEven[31:24];
		
			state_m1 <= S_LEADOUT_2;
		end
		
		S_LEADOUT_2: begin
		
		
			state_m1 <= S_LEADOUT_3;
		end
		
		S_LEADOUT_3: begin
		
		
		
			state_m1 <= S_LEADOUT_4;
		end
		
		S_LEADOUT_4: begin
		
		
		M1_END <= 1'b1;			// Finished leadouts now transmit the output signal back to the top level fsm
		
			state_m1 <= S_IDLE_M1;
		end
		
		
		
		
		
		
		default: state_m1 <= S_IDLE_M1;
		endcase
	end
end



endmodule