module link_control(
			//-----------clk and rst---------------
			input 	wire			clk				,
			input	wire			rst				,
			//-----------from register-------------			
			input	wire	[15:0]	time_threshold	,
			input	wire	[5:0]	delay_threshole	,
			//------from token_packet_analysis------
			input	wire			rx_sop			,
			input	wire			rx_eop			,
			input	wire	[3:0]	rx_pid			,
			input	wire			rx_pid_en		,
			//--------to token_packet_analysis-------			
			output	reg				rx_handshake_on	,
			//-------------from control_t------------
			input	wire			tx_lp_eop_en	,
			input	wire			tx_lp_sop_en	,			
			//--------------to control_t-------------
			output	reg				tx_data_on		,
			output	reg				crc5_en			,
			//--------------with phy_layer-------------
			input	wire			ms				,
			output	reg				d_oe			,
			//--------------to transfer_layer----------
			output	reg				time_out		
);
	
	
reg	[15:0]	delay_cnt;
reg	[5:0]	delay_cnt_doe;
reg	[3:0]	pid;
reg			rx_eop_r;

reg			time_flag;
reg			doe_flag;

wire		handshake_packet;
wire		data_packet;
wire		clear; 		//模块复位信号


assign handshake_packet = (pid==4'b0010)|(pid==4'b1010)|(pid==4'b1110);
assign data_packet = (rx_pid==4'b0011 | rx_pid==4'b1011);

assign clear = time_out | (~ms & handshake_packet) | (ms & (handshake_packet | data_packet));


//---------------pid-----------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		pid<= 4'b0;
	else if(clear || tx_data_on)
		pid<= 4'b0;
	else if(rx_pid_en)
		pid<= rx_pid;


//--------------rx_eop_r-----------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		rx_eop_r<= 1'b0;
	else if(rx_pid_en)
		rx_eop_r<= rx_eop;
	else
		rx_eop_r<= 1'b0;



//-------------time_flag-------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		time_flag<= 1'b0;
	else if(clear || tx_lp_sop_en)
		time_flag<= 1'b0;
	else if(  (ms & tx_lp_eop_en) | (tx_lp_eop_en & tx_data_on) )
		time_flag<= 1'b1;

//-------------doe_flag-------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		doe_flag<= 1'b0;
	else if( tx_lp_sop_en || (delay_cnt_doe==delay_threshole))
		doe_flag<= 1'b0;
	else if(  (ms & tx_lp_eop_en) | (tx_lp_eop_en & tx_data_on) )
		doe_flag<= 1'b1;


//-------------delay_cnt---------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		delay_cnt<= 16'b0;
	else if(clear || tx_lp_sop_en)
		delay_cnt<= 16'b0;
	else if(time_flag)
		delay_cnt<= delay_cnt+1'b1;

//-------------delay_cnt_doe---------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		delay_cnt_doe<= 6'b0;
	else if( tx_lp_sop_en ||(delay_cnt_doe==delay_threshole))
		delay_cnt_doe<= 6'b0;
	else if(doe_flag)
		delay_cnt_doe<= delay_cnt_doe+1'b1;


//-------------d_oe-----------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		d_oe<= 1'b0;
	else if( (delay_cnt_doe==delay_threshole) )
		d_oe<= 1'b0;
	else if( ms )
		d_oe<= 1'b1;
	else if( ~ms & rx_eop_r & pid==4'b1001 )
		d_oe<= 1'b1;




//------------crc5_en---------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		crc5_en<= 1'b0;
	else if(ms & ~tx_data_on)
		crc5_en<= 1'b1;
	else if(~ms | tx_data_on)
		crc5_en<= 1'b0;

	

//-------------tx_data_on-------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		tx_data_on<= 1'b0;
	else if(clear)
		tx_data_on<= 1'b0;
	else if(~ms & rx_eop_r & pid==4'b1001 )
		tx_data_on<=1'b1;
	else if(tx_lp_eop_en)
		tx_data_on<= ~tx_data_on;
	

//-------------time_out---------------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		time_out<= 1'b0;
	else if(delay_cnt==time_threshold )
		time_out<= 1'b1;
	else
		time_out<= 1'b0;
		
//----------rx_handshake_on-----------//  ok
always @(posedge clk or negedge rst)
	if(!rst)
		rx_handshake_on<= 1'b0;
	else if(clear)
		rx_handshake_on<= 1'b0;
	else if(rx_pid_en)
		rx_handshake_on<= 1'b0;
	else if(tx_lp_eop_en & tx_data_on )
		rx_handshake_on<= 1'b1;







endmodule