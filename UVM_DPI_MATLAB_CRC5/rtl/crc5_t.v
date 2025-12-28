module crc5_t(
			//----------clk and rst-------------------
			input 	wire			clk				,
			input	wire			rst				,
			//----------from link_control-------------	
			input	wire			crc5_en			,
			input	wire			tx_data_on		,
			//----------from transfer_layer_pid-------
			input	wire	[3:0]	tx_pid			,
			input	wire	[6:0]	tx_addr			,
			input	wire	[3:0]	tx_endp			,
			input	wire			tx_valid		,
			output	reg				tx_ready		,
			//----------from transmit_control---------
			input	wire			tx_lp_valid		,
			input	wire			tx_lp_ready		,
			//---------to next level-----------------
			output	reg		[7:0]	token_data_r	,
			output	reg				to_tx_sop_r		,
			output	reg				to_tx_eop_r		,		
			output	reg				token_enable_r	,
			output	wire			handshake_pack
			//---------to tx_lp_fifo---------------
			//output	wire			fifo_rst
);

//--------input signal------
reg				tx_ready_r1;
reg				tx_ready_r2;
reg				tx_ready_r3;

reg				tx_valid_r1;
reg				tx_valid_r2;
reg				tx_valid_r3;


reg		[6:0]	tx_addr_r;
reg		[3:0]	tx_endp_r;



reg		[3:0]	tx_con_pid;
reg				handshake_en;


//--------crc5----------
reg		[10:0]	crc5_data_in;
reg				crc_en;
wire	[4:0]	crc5_out;
wire	[4:0]	crc5_out_RI;
reg		[4:0]	crc5_out_RI_r;
//-------output delay-------
reg				to_tx_eop;
reg				to_tx_sop;
reg		[7:0]	token_data;
wire			token_enable;


//---------------tx_ready----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_ready<=1'b1;
	else if(tx_valid)
		tx_ready<=1'b0;
	else if(to_tx_eop_r)
		tx_ready<=1'b1;
//---------------tx_ready_r----------------//		
always @(posedge clk or negedge rst)
	if(!rst)begin
		tx_ready_r1<=1'b1;
		tx_ready_r2<=1'b1;
		tx_ready_r3<=1'b1;
	end
	else begin
		tx_ready_r1<=tx_ready;
		tx_ready_r2<=tx_ready_r1;
		tx_ready_r3<=tx_ready_r2;
	end
	
assign token_enable = 	(tx_ready_r1&tx_valid_r1) || (crc5_en & tx_ready_r2 & tx_valid_r2 & ~handshake_en) ||(crc5_en & tx_ready_r3 & tx_valid_r3 & ~handshake_en);
	
	
//---------------tx_valid_r----------------//		
always @(posedge clk or negedge rst)
	if(!rst)begin
		tx_valid_r1<=1'b0;
		tx_valid_r2<=1'b0;
		tx_valid_r3<=1'b0;
	end
	else begin
		tx_valid_r1<=tx_valid;	
		tx_valid_r2<=tx_valid_r1;
		tx_valid_r3<=tx_valid_r2;
	end

//---------------tx_addr_r----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_addr_r<=7'b0;
	else if(tx_ready & tx_valid)
		tx_addr_r<=tx_addr;	

//---------------tx_endp_r----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_endp_r<=4'b0;
	else if(tx_ready & tx_valid)
		tx_endp_r<=tx_endp;	


		
		
		
//--------------tx_con_pid----------------//		
always @(posedge clk or negedge rst)
	if(!rst)
		tx_con_pid<= 4'b0;
	else if(tx_ready & tx_valid)
		tx_con_pid<= tx_pid;
		

assign handshake_pack = (tx_pid == 4'b0010) || (tx_pid == 4'b1010) || (tx_pid == 4'b1110);

//--------------handshake_en-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		handshake_en<= 1'b0;
	else if(tx_valid_r3 & tx_ready_r3)
		handshake_en<= 1'b0;
	else if(handshake_pack)
		handshake_en<= 1'b1;


		
		
		

//-------------crc5_gen-----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		crc5_data_in<= 11'b0;
	else if(tx_ready & tx_valid & crc5_en)
		crc5_data_in<= {tx_addr[0],tx_addr[1],tx_addr[2],tx_addr[3],tx_addr[4],tx_addr[5],tx_addr[6],tx_endp[0],tx_endp[1],tx_endp[2],tx_endp[3]};		


//-------------crc_en-----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		crc_en<= 1'b0;
	else if(tx_ready & tx_valid & crc5_en)
		crc_en<= 1'b1;
	else
		crc_en<= 1'b0;

//-------------crc5_out_RI---------//reverse+invert
assign crc5_out_RI=  (~{crc5_out[0],crc5_out[1],crc5_out[2],crc5_out[3],crc5_out[4]});
always @(posedge clk or negedge rst)
	if(!rst)
		crc5_out_RI_r<=5'b0;
	else if(tx_ready_r2 & tx_valid_r2 & crc5_en)
		crc5_out_RI_r<=crc5_out_RI;






//------------token_data----------//
always @(*)
	if(tx_valid_r1 & tx_ready_r1 )//token and handshake
		token_data = {~tx_con_pid,tx_con_pid};
	else if(tx_valid_r2 & tx_ready_r2 & crc5_en)
		token_data = {tx_endp_r[0],tx_addr_r[6:0]};
	else if(tx_valid_r3 & tx_ready_r3 & crc5_en)
		token_data = {crc5_out_RI_r,tx_endp_r[3:1]};
	else
		token_data = 8'b0;



		
		
//-----------to_tx_sop-------------//	
always @(posedge clk or negedge rst)
	if(!rst)
		to_tx_sop<=1'b0;
	else if( tx_valid & tx_ready)
		to_tx_sop<=1'b1;
	else
		to_tx_sop<=1'b0;
		
		
//-----------to_tx_eop-------------//	
always @(posedge clk or negedge rst)
	if(!rst)
		to_tx_eop<=1'b0;
	else if(handshake_pack)
		to_tx_eop<=1'b1;
	else if(crc5_en & tx_valid_r2 & tx_ready_r2 & ~handshake_en)
		to_tx_eop<=1'b1;
	else
		to_tx_eop<=1'b0;


//---------output delay----------//
always @(posedge clk or negedge rst)
	if(!rst)begin
		to_tx_eop_r <= 1'b0;
		to_tx_sop_r <= 1'b0;
		token_data_r<= 8'b0;
		token_enable_r <= 1'b0;
	end
	else begin
		to_tx_eop_r <= to_tx_eop;
		to_tx_sop_r <= to_tx_sop;
		token_data_r<= token_data;
		token_enable_r <= token_enable;
	end









wire	crc_rst;
assign crc_rst=((tx_ready_r1 & tx_valid_r1) | (tx_ready_r2 & tx_valid_r2)) & crc5_en & handshake_en;

crc5 crc5_t(
  .data_in	(crc5_data_in)	,				//reverse
  .crc_en	(crc_en)		,				//one clock
  .crc_out	(crc5_out)		,				//reverse+invert
  .rst		(crc_rst)	,
  .clk		(clk)
  );





endmodule