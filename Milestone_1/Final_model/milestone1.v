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

logic signed [31:0] YBufferEvenSub16;
logic signed [31:0] YBufferOddSub16;

logic [7:0] YBufferOddHolder;

logic [7:0] UOddBuf;
logic [7:0] VOddBuf;
logic [7:0] UEvenBuf;
logic [7:0] VEvenBuf;

logic signed[31:0] Multi_Op[7:0];			//32 bit 
logic signed[31:0] Multi_Result[3:0];		//64 bit

logic [31:0] UPrimeOdd;
logic [31:0] VPrimeOdd;

logic signed [7:0] UPrimeOddFinal;
logic signed [7:0] VPrimeOddFinal;

logic signed [7:0] UPrimeEvenFinal;
logic signed [7:0] VPrimeEvenFinal;

logic [31:0] RBufferEven;
logic [31:0] BBufferEven;
logic [31:0] GBufferEven;

logic [31:0] RBufferOdd;
logic [31:0] BBufferOdd;
logic [31:0] GBufferOdd;

logic [7:0] REvenFinal;
logic [7:0] GEvenFinal;
logic [7:0] BEvenFinal;

logic [7:0] ROddFinal;
logic [7:0] GOddFinal;
logic [7:0] BOddFinal;

logic [31:0] Yx76284Even;
logic [31:0] Yx76284Odd;

logic firstrun;

logic [32:0] CommonCounter;

logic [32:0] RowCounter;

logic [32:0] WriteCounter;


assign Multi_Result[0] = Multi_Op[0] * Multi_Op[1];
assign Multi_Result[1] = Multi_Op[2] * Multi_Op[3];
assign Multi_Result[2] = Multi_Op[4] * Multi_Op[5];
assign Multi_Result[3] = Multi_Op[6] * Multi_Op[7];


assign YBufferEvenSub16 = YBufferEven - 8'd16;
assign YBufferOddSub16 = YBufferOdd - 8'd16;


always_comb begin			// Combinational Block used to clip values

	if (RBufferEven[31] == 1'b1) begin
		REvenFinal = 8'h00; 
	end else if ((RBufferEven[30:24] > 7'd0)&&(RBufferEven[31] == 1'b0)) begin
		REvenFinal = 8'hff;
	end else REvenFinal = RBufferEven[23:16]; 
	
	if (GBufferEven[31] == 1'b1) begin
		GEvenFinal = 8'h00; 
	end else if ((GBufferEven[30:24] > 7'd0)&&(GBufferEven[31] == 1'b0)) begin
		GEvenFinal = 8'hff;
	end else GEvenFinal = GBufferEven[23:16]; 
	
	if (BBufferEven[31] == 1'b1) begin
		BEvenFinal = 8'h00; 
	end else if ((BBufferEven[30:24] > 7'd0)&&(BBufferEven[31] == 1'b0)) begin
		BEvenFinal = 8'hff;
	end else BEvenFinal = BBufferEven[23:16]; 
	
	if (RBufferOdd[31] == 1'b1) begin
		ROddFinal = 8'h00; 
	end else if ((RBufferOdd[30:24] > 7'd0)&&(RBufferOdd[31] == 1'b0)) begin
		ROddFinal = 8'hff;
	end else ROddFinal = RBufferOdd[23:16]; 
	
	if (GBufferOdd[31] == 1'b1) begin
		GOddFinal = 8'h00; 
	end else if ((GBufferOdd[30:24] > 7'd0)&&(GBufferOdd[31] == 1'b0)) begin
		GOddFinal= 8'hff;
	end else GOddFinal = GBufferOdd[23:16]; 
	
	if (BBufferOdd[31] == 1'b1) begin
		BOddFinal = 8'h00;
	end else if ((BBufferOdd[30:24] > 7'd0)&&(BBufferOdd[31] == 1'b0)) begin
		BOddFinal = 8'hff;
	end else BOddFinal = BBufferOdd[23:16]; 
	
	


end


always_comb begin
	
	UPrimeOddFinal = UPrimeOdd[15:8] - 8'd128;
	
	VPrimeOddFinal = VPrimeOdd[15:8] - 8'd128;
	
	UPrimeEvenFinal = UReg[2] - 8'd128;
	
	VPrimeEvenFinal = VReg[2] - 8'd128;


end
			 




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
		YBufferEven <= 8'd0;
		YBufferOdd <= 8'd0;

		UOddBuf <= 8'd0;
		VOddBuf <= 8'd0;
		UEvenBuf <= 8'd0;
		VEvenBuf <= 8'd0;
		
		Multi_Op[0] <= 32'd0;			//32 bit 
		Multi_Op[1] <= 32'd0;			//32 bit 
		Multi_Op[2] <= 32'd0;			//32 bit 
		Multi_Op[3] <= 32'd0;			//32 bit 
		Multi_Op[4] <= 32'd0;			//32 bit 
		Multi_Op[5] <= 32'd0;			//32 bit 
		Multi_Op[6] <= 32'd0;			//32 bit 
		Multi_Op[7] <= 32'd0;			//32 bit 
		
		UPrimeOdd <= 32'd0;
		VPrimeOdd <= 32'd0;

		RBufferEven <= 32'd0;
		BBufferEven <= 32'd0;
		GBufferEven <= 32'd0;

		RBufferOdd <= 32'd0;
		BBufferOdd <= 32'd0;
		GBufferOdd <= 32'd0;
		
		Yx76284Even <= 32'd0;
		Yx76284Odd <= 32'd0; 
		
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
		
		YBufferOddHolder <= 8'd0;
		
		CommonCounter <= 32'd0;
		
		RowCounter <= 32'd0;
		
		WriteCounter <= 32'd0;
		
//		REvenFinal <= 8'd0;
//		GEvenFinal <= 8'd0;
//		BEvenFinal <= 8'd0;
//		
//		ROddFinal <= 8'd0;
//		GOddFinal <= 8'd0;
//		BOddFinal <= 8'd0;


	end else begin
		case (state_m1)
		S_IDLE_M1: begin
				if((M1_START)&&(~M1_END)) begin 
				
					state_m1 <= S_LEADIN_0;
					
				end	
		end
		
		S_LEADIN_0: begin
		
			SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			SRAM_we_n_m1 <= 1'b1;
			
			
			U_address <= U_address + 18'd1;
			
			RowCounter <= RowCounter + 32'd1;
			
			state_m1 <= S_LEADIN_1;
		
		end
		
		S_LEADIN_1: begin
		
			SRAM_ADDRESS_m1 <= V_address + V_OFFSET;
		
			V_address <= V_address + 18'd1;
			state_m1 <= S_LEADIN_2;
		
		end
		
		S_LEADIN_2: begin
		
			SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			
			U_address <= U_address + 18'd1;
			
			RowCounter <= RowCounter + 32'd1;
			
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
		
			SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			
			U_address <= U_address + 18'd1;
			
			RowCounter <= RowCounter + 32'd1;
		
			UReg[4] <= SRAM_read_data[15:8];		//U[2]
			UReg[5] <= SRAM_read_data[7:0];		//U[3]
			state_m1 <= S_LEADIN_6;
			
		end
		
		S_LEADIN_6: begin
		
			SRAM_ADDRESS_m1 <= V_address + V_OFFSET;
			
			V_address <= V_address + 18'd1;
		
			VReg[4] <= SRAM_read_data[15:8];		//V[2]
			VReg[5] <= SRAM_read_data[7:0];		//V[3]
			
			
			
		
			state_m1 <= S_LEADIN_7;
		end
		
		S_LEADIN_7: begin
		
			YBufferEven <= SRAM_read_data[15:8];
			YBufferOdd  <= SRAM_read_data[7:0];
			
		
		
			state_m1 <= S_LEADIN_8;
		end
		
		S_LEADIN_8: begin
			
			UEvenBuf <= SRAM_read_data[15:8];
			
			UOddBuf <= SRAM_read_data[7:0];
		
			
			state_m1 <= S_LEADIN_9;
		end
		
		S_LEADIN_9: begin
			
			VEvenBuf <= SRAM_read_data[15:8];
			
			VOddBuf <= SRAM_read_data[7:0];
		
		
			state_m1 <= S_COMMONCASE_0;
		end
		
		S_COMMONCASE_0: begin	//__++--^^--++__
		
			Multi_Op[0] <= 8'd21;
			Multi_Op[1] <= UReg[5];
			
			Multi_Op[2] <= 8'd52;
			Multi_Op[3] <= UReg[4];
			
			Multi_Op[4] <= 8'd21;
			Multi_Op[5] <= VReg[5];
			
			Multi_Op[6] <= 8'd52;
			Multi_Op[7] <= VReg[4];
			
				
			if (firstrun) begin
				GBufferEven <= Yx76284Even - Multi_Result[0] - Multi_Result[1];
				GBufferOdd <= Yx76284Odd - Multi_Result[2] - Multi_Result[3];
				
				if (WriteCounter < 32'd156) begin
				
					SRAM_ADDRESS_m1 <= U_address + U_OFFSET;
			
					U_address <= U_address + 18'd1;
				
				end
				
				RowCounter <= RowCounter + 32'd1;
				
			end	
			
			
			state_m1 <= S_COMMONCASE_1;
		
		
		end
		
		S_COMMONCASE_1: begin
		
			Multi_Op[0] <= 8'd159;
			Multi_Op[1] <= UReg[3];
			
			Multi_Op[2] <= 8'd159;
			Multi_Op[3] <= UReg[2];
			
			Multi_Op[4] <= 8'd159;
			Multi_Op[5] <= VReg[3];
			
			Multi_Op[6] <= 8'd159;
			Multi_Op[7] <= VReg[2];
			
			UPrimeOdd <= Multi_Result[0] - Multi_Result[1] + 32'd128;
			VPrimeOdd <= Multi_Result[2] - Multi_Result[3] + 32'd128;
			
			if (firstrun) begin
			
				if (WriteCounter < 32'd156) begin
				
					SRAM_ADDRESS_m1 <= V_address + V_OFFSET;
			
					V_address <= V_address + 18'd1;
				
				end
				
			end
		
			

			state_m1 <= S_COMMONCASE_2;
		
		end
		
		S_COMMONCASE_2: begin
		
			if (firstrun == 1'b1) begin
			
				SRAM_write_data_m1[15:8] <= REvenFinal;
				SRAM_write_data_m1[7:0]  <= GEvenFinal;
				
				SRAM_we_n_m1 <= 1'b0;
			
				SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				RGB_address <= RGB_address + 18'd1;
				
					YBufferEven <= SRAM_read_data[15:8];
					YBufferOdd  <= SRAM_read_data[7:0];

			
			end
			
			
			
		
			Multi_Op[0] <= 8'd52;
			Multi_Op[1] <= UReg[1];
			
			Multi_Op[2] <= 8'd21;
			Multi_Op[3] <= UReg[0];
			
			Multi_Op[4] <= 8'd52;
			Multi_Op[5] <= VReg[1];
			
			Multi_Op[6] <= 8'd21;
			Multi_Op[7] <= VReg[0];
			
			UPrimeOdd <= UPrimeOdd + Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd + Multi_Result[2] + Multi_Result[3];
		
			

			state_m1 <= S_COMMONCASE_3;
		
		
		end
		
		S_COMMONCASE_3: begin
			
			if (firstrun == 1'b1) begin
			
				SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				
				RGB_address <= RGB_address + 18'd1;
			
				SRAM_write_data_m1[15:8]  <= BEvenFinal;
				SRAM_write_data_m1[7:0] <= ROddFinal;
				
				SRAM_we_n_m1 <= 1'b0;
				
				if (WriteCounter < 32'd156) begin
					UEvenBuf <= SRAM_read_data[15:8];
					UOddBuf <= SRAM_read_data[7:0];
				end
				
			
			end
			
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferEvenSub16;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeEvenFinal;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeEvenFinal;
			
			Multi_Op[6] <= 32'd76284;
			Multi_Op[7] <= YBufferOddSub16;
			
			UPrimeOdd <= UPrimeOdd - Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd - Multi_Result[2] + Multi_Result[3];
			
			
			
			state_m1 <= S_COMMONCASE_4;
		
		
		end
		
		S_COMMONCASE_4: begin
		
			if (firstrun) begin	
				
				SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				
				RGB_address <= RGB_address + 18'd1;
			
				SRAM_write_data_m1[15:8]  <= GOddFinal;
				SRAM_write_data_m1[7:0] <= BOddFinal;
				
				SRAM_we_n_m1 <= 1'b0;
				
				
				
				if (WriteCounter < 32'd156) begin
					VEvenBuf <= SRAM_read_data[15:8];
					VOddBuf <= SRAM_read_data[7:0];
				end	

			end
			
			firstrun <= 1'b1;
			
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferOddSub16;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeOddFinal;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeOddFinal;
			
			RBufferEven <= Multi_Result[0] + Multi_Result[1];
			BBufferEven <= Multi_Result[0] + Multi_Result[2];
			
			Yx76284Odd <= Multi_Result[3];
			Yx76284Even <= Multi_Result[0];

			

			state_m1 <= S_COMMONCASE_5;
		
		
		end
		
		S_COMMONCASE_5: begin

				SRAM_ADDRESS_m1 <= Y_address;
				Y_address <= Y_address + 18'd1;	
		
			SRAM_we_n_m1 <= 1'b1;
			
			Multi_Op[0] <= 32'd25624;
			Multi_Op[1] <= UPrimeEvenFinal;

			Multi_Op[2] <= 32'd53281;
			Multi_Op[3] <= VPrimeEvenFinal;

			Multi_Op[4] <= 32'd25624;
			Multi_Op[5] <= UPrimeOddFinal;

			Multi_Op[6] <= 32'd53281;
			Multi_Op[7] <= VPrimeOddFinal;
			
			RBufferOdd <= Multi_Result[0] + Multi_Result[1];
			BBufferOdd <= Multi_Result[0] + Multi_Result[2];

			
			
			
			if (WriteCounter < 32'd156) begin
			
				UReg[0] <= UReg[1];
				UReg[1] <= UReg[2];
				UReg[2] <= UReg[3];
				UReg[3] <= UReg[4];
				UReg[4] <= UReg[5];
				UReg[5] <= UEvenBuf;
			
				VReg[0] <= VReg[1];
				VReg[1] <= VReg[2];
				VReg[2] <= VReg[3];
				VReg[3] <= VReg[4];
				VReg[4] <= VReg[5];
				VReg[5] <= VEvenBuf;
				
			end
		
			if (WriteCounter >= 32'd156) begin
			
				UReg[0] <= UReg[1];
				UReg[1] <= UReg[2];
				UReg[2] <= UReg[3];
				UReg[3] <= UReg[4];
				UReg[4] <= UReg[5];
				//UReg[5] <= UOddBuf;
			
				VReg[0] <= VReg[1];
				VReg[1] <= VReg[2];
				VReg[2] <= VReg[3];
				VReg[3] <= VReg[4];
				VReg[4] <= VReg[5];
				//VReg[5] <= VOddBuf;
			
			
			end
			
			WriteCounter <= WriteCounter + 32'd1;
			

			state_m1 <= S_COMMONCASE_6; 
		
		
		end
		
		S_COMMONCASE_6: begin	//__++--^^--++__
			
			
		
		
			Multi_Op[0] <= 8'd21;
			Multi_Op[1] <= UReg[5];
			
			Multi_Op[2] <= 8'd52;
			Multi_Op[3] <= UReg[4];
			
			Multi_Op[4] <= 8'd21;
			Multi_Op[5] <= VReg[5];

			
			Multi_Op[6] <= 8'd52;
			Multi_Op[7] <= VReg[4];
			
			GBufferEven <= Yx76284Even - Multi_Result[0] - Multi_Result[1];
			GBufferOdd <= Yx76284Odd - Multi_Result[2] - Multi_Result[3];
			
			
		

			state_m1 <= S_COMMONCASE_7;
		end
		
		S_COMMONCASE_7: begin
		
			SRAM_write_data_m1[15:8] <= REvenFinal;
			SRAM_write_data_m1[7:0] <= GEvenFinal;
			
			
			SRAM_we_n_m1 <= 1'b0;
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
			
			RGB_address <= RGB_address + 18'd1;
		
		
			Multi_Op[0] <= 8'd159;
			Multi_Op[1] <= UReg[3];
			
			Multi_Op[2] <= 8'd159;
			Multi_Op[3] <= UReg[2];
			
			Multi_Op[4] <= 8'd159;
			Multi_Op[5] <= VReg[3];
			
			Multi_Op[6] <= 8'd159;
			Multi_Op[7] <= VReg[2];
			
			UPrimeOdd <= Multi_Result[0] - Multi_Result[1] + 32'd128;
			VPrimeOdd <= Multi_Result[2] - Multi_Result[3] + 32'd128;
		
			
		
		
			state_m1 <= S_COMMONCASE_8;
		end
		
		S_COMMONCASE_8: begin
		

				YBufferEven <= SRAM_read_data[15:8];
				YBufferOdd  <= SRAM_read_data[7:0];

		
			SRAM_we_n_m1 <= 1'b1;
			
			
			Multi_Op[0] <= 8'd52;
			Multi_Op[1] <= UReg[1];
			
			Multi_Op[2] <= 8'd21;
			Multi_Op[3] <= UReg[0];
			
			Multi_Op[4] <= 8'd52;
			Multi_Op[5] <= VReg[1];
			
			Multi_Op[6] <= 8'd21;
			Multi_Op[7] <= VReg[0];
			
			UPrimeOdd <= UPrimeOdd + Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd + Multi_Result[2] + Multi_Result[3];
		
			
		
		
			state_m1 <= S_COMMONCASE_9;
		end
		
		S_COMMONCASE_9: begin
		
			SRAM_write_data_m1[15:8] <= BEvenFinal;
			SRAM_write_data_m1[7:0]  <= ROddFinal;
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_we_n_m1 <= 1'b0;
		
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferEvenSub16;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeEvenFinal;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeEvenFinal;
			
			UPrimeOdd <= UPrimeOdd - Multi_Result[0] + Multi_Result[1];
			VPrimeOdd <= VPrimeOdd - Multi_Result[2] + Multi_Result[3];
		
		
			state_m1 <= S_COMMONCASE_10;
		end
		
		S_COMMONCASE_10: begin
		
			SRAM_write_data_m1[15:8] <= GOddFinal;
			SRAM_write_data_m1[7:0]  <= BOddFinal;
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
			
			RGB_address <= RGB_address + 18'd1;

			SRAM_we_n_m1 <= 1'b0;
			
			
		
			Multi_Op[0] <= 32'd76284;
			Multi_Op[1] <= YBufferOddSub16;

			Multi_Op[2] <= 32'd104595;
			Multi_Op[3] <= VPrimeOddFinal;

			Multi_Op[4] <= 32'd132251;
			Multi_Op[5] <= UPrimeOddFinal;
			
			Multi_Op[6] <= 32'd76284;
			Multi_Op[7] <= YBufferEvenSub16;
			
			RBufferEven <= Multi_Result[0] + Multi_Result[1];
			BBufferEven <= Multi_Result[0] + Multi_Result[2];
		
			state_m1 <= S_COMMONCASE_11;
		end
		
		S_COMMONCASE_11: begin	//__++--^^--++__
			
				SRAM_ADDRESS_m1 <= Y_address;
				Y_address <= Y_address + 18'd1;
			
			SRAM_we_n_m1 <= 1'b1;
			
			Multi_Op[0] <= 32'd25624;
			Multi_Op[1] <= UPrimeEvenFinal;

			Multi_Op[2] <= 32'd53281;
			Multi_Op[3] <= VPrimeEvenFinal;

			Multi_Op[4] <= 32'd25624;
			Multi_Op[5] <= UPrimeOddFinal;

			Multi_Op[6] <= 32'd53281;
			Multi_Op[7] <= VPrimeOddFinal;
			
			RBufferOdd <= Multi_Result[0] + Multi_Result[1];
			BBufferOdd <= Multi_Result[0] + Multi_Result[2];

			Yx76284Odd <= Multi_Result[0];
			Yx76284Even <= Multi_Result[3];
			
			if (WriteCounter < 32'd156) begin
			
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
				
			end
		
			if (WriteCounter >= 32'd156) begin
			
				UReg[0] <= UReg[1];
				UReg[1] <= UReg[2];
				UReg[2] <= UReg[3];
				UReg[3] <= UReg[4];
				UReg[4] <= UReg[5];
				//UReg[5] <= UOddBuf;
			
				VReg[0] <= VReg[1];
				VReg[1] <= VReg[2];
				VReg[2] <= VReg[3];
				VReg[3] <= VReg[4];
				VReg[4] <= VReg[5];
				//VReg[5] <= VOddBuf;
			
			
			end
			
			
		
		
			CommonCounter <= CommonCounter + 32'd1;
		
		
			if (WriteCounter >= 32'd159) begin // U_address index starts at 0
				
				WriteCounter <= 32'd0;
				
				state_m1 <= S_LEADOUT_0;
				
			end else begin
		
		
				WriteCounter <= WriteCounter + 32'd1;
				
				state_m1 <= S_COMMONCASE_0;
	
			end
		end
		
		
		
		S_LEADOUT_0: begin
			
			GBufferEven <= Yx76284Even - Multi_Result[0] - Multi_Result[1];
			GBufferOdd <= Yx76284Odd - Multi_Result[2] - Multi_Result[3];
			
			state_m1 <= S_LEADOUT_1;
		
		end
		
		S_LEADOUT_1: begin
			
			SRAM_write_data_m1[15:8] <= REvenFinal;
			SRAM_write_data_m1[7:0]  <= GEvenFinal;
				
			SRAM_we_n_m1 <= 1'b0;
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
			RGB_address <= RGB_address + 18'd1;

			state_m1 <= S_LEADOUT_2;
		end
		
		S_LEADOUT_2: begin
		
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data_m1[15:8]  <= BEvenFinal;
			SRAM_write_data_m1[7:0] <= ROddFinal;
				
			SRAM_we_n_m1 <= 1'b0;
			
			
			state_m1 <= S_LEADOUT_3;
		end
		
		S_LEADOUT_3: begin
		
			
			SRAM_ADDRESS_m1 <= RGB_address + RGB_OFFSET;
				
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data_m1[15:8]  <= GOddFinal;
			SRAM_write_data_m1[7:0] <= BOddFinal;
				
			SRAM_we_n_m1 <= 1'b0;
			
		
			state_m1 <= S_LEADOUT_4;
		end
		
		S_LEADOUT_4: begin
		
			if (U_address >= 18'd19199) begin
				M1_END <= 1'b1;
		
				state_m1 <= S_IDLE_M1;
			end else begin
			
				SRAM_we_n_m1 <= 1'b1;
				
				Y_address <= Y_address - 18'd1;
				
				firstrun <= 1'b0;
				
				state_m1 <= S_LEADIN_0;
				
			end	
		
		end
		
		
		default: state_m1 <= S_IDLE_M1;
		endcase
	end
end



endmodule