module control_t(
			//----------clk and rst-----------------
			input 	wire			clk				,
			input	wire			rst				,
			//----------from link_control-----------
			input	wire			tx_data_on		,
			output	reg				tx_lp_eop_en	,
			output	reg				tx_lp_sop_en	,
			input	wire			crc5_en			,
			//----------from crc5_token-------------
			input	wire	[7:0]	token_data		,
			input	wire			to_tx_sop		,
			input	wire			to_tx_eop		,
			input	wire			token_enable	,
			input	wire			handshake_pack	,
			//--------from transfer_layer_pid-------
			input	wire			tx_lt_sop		,
			input	wire			tx_lt_eop		,
			input	wire			tx_lt_valid		,
			output	wire			tx_lt_ready		,
			input	wire	[7:0]	tx_lt_data		,
			input	wire			tx_lt_cancle	,
			//---------to phy layer_FIFO-----------------
			output	reg				tx_lp_sop		,
			output	reg				tx_lp_eop		,
			output	reg				tx_lp_valid		,
			input	wire			tx_lp_ready		,
			output	reg		[7:0]	tx_lp_data		,
			output	wire			cancle			,	

			//---------from FIFO----------------
			input	wire			VALID_DOWN		,
			input	wire            READY_DOWN		,
			input	wire			tx_lp_data_out8
);
	



reg	[2:0]	tx_lp_ready_r;


reg	[2:0]	tx_lp_eop_delay;
//wire		tx_lp_ready_pos;
//reg			to_tx_sop_r;


//--------------cancle-----------------//
assign cancle = tx_lt_cancle;


//-------------tx_lp_ready_r-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_ready_r<=3'b0;
	else
		tx_lp_ready_r<={tx_lp_ready_r[1:0],tx_lp_ready};

//assign tx_lp_ready_pos = ~tx_lp_ready_r[1] & tx_lp_ready_r[0];



//----------tx_lp_eop_delay-------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_eop_delay<=3'b0;
	else if(tx_lp_valid & tx_lp_ready)
		tx_lp_eop_delay<={tx_lp_eop_delay[1:0],tx_lt_eop};




//-------------tx_lp_data-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_data<=8'b0;
	else if(~tx_data_on & token_enable)
		tx_lp_data<=token_data;
	else if( tx_data_on & tx_lt_ready & tx_lt_valid)
		tx_lp_data<=tx_lt_data;



//-------------tx_lp_sop-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_sop<=1'b0;
	else if(tx_data_on )//tx_lp_valid & tx_lp_ready
		tx_lp_sop<=tx_lt_sop;
	else if(~tx_data_on && token_enable)
		tx_lp_sop<=to_tx_sop;
	else if(VALID_DOWN & READY_DOWN)
		tx_lp_sop<=1'b0;
	

//-------------tx_lp_eop-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_eop<=1'b0;
	else if(tx_lp_eop && tx_lp_valid && tx_lp_ready)
		tx_lp_eop<=1'b0;
	else if( tx_data_on && tx_lp_valid && tx_lp_ready)
		tx_lp_eop<=tx_lt_eop;//tx_lp_eop_delay[1];
	else if(~tx_data_on && token_enable)
		tx_lp_eop<=to_tx_eop;

	

//-------------tx_lp_valid-------------//        
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_valid<=1'b0;
	else if(tx_lp_eop & tx_lp_ready & tx_lp_valid & ~tx_data_on & crc5_en)
		tx_lp_valid<=1'b0;
	else if(tx_lp_eop & tx_lp_ready & tx_lp_valid & ~tx_data_on & handshake_pack)
		tx_lp_valid<=1'b0;	
	else if(tx_lp_eop & tx_lp_valid & tx_lp_ready & tx_data_on)
		tx_lp_valid<=1'b0;
	else if(  to_tx_sop & token_enable & ~tx_data_on)
		tx_lp_valid<=1'b1;
	else if(tx_lt_sop & tx_data_on & tx_lt_valid & tx_lt_ready)
		tx_lp_valid<=1'b1;
		
		
		
//-------------tx_lt_ready-------------//
assign tx_lt_ready = tx_lp_ready & tx_data_on;


//------------tx_lp_eop_en------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_eop_en<=1'b0;
	else if(tx_lp_data_out8 & VALID_DOWN & READY_DOWN )
		tx_lp_eop_en<=1'b1;
	else
		tx_lp_eop_en<=1'b0;


//-----------tx_lp_sop_en-------------//
always @(posedge clk or negedge rst)
	if(!rst)
		tx_lp_sop_en<=1'b0;
	else if((tx_lt_sop & tx_data_on) || (to_tx_sop & ~tx_data_on) & tx_lp_valid & tx_lp_ready )
		tx_lp_sop_en<=1'b1;
	else
		tx_lp_sop_en<=1'b0;






endmodule