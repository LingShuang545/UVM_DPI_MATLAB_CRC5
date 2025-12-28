module usb_link_top(
			//----------clk and rst-----------------
			input 	wire			clk				,
			input	wire			rst				,
			//-----------from register-------------
			input	wire	[6:0]	self_addr		,
			input	wire	[15:0]	time_threshold	,
			input	wire	[5:0]	delay_threshole	,
			//---------to transfer_layer--------
			output	wire			rx_pid_en		,
			output	wire	[3:0]	rx_pid			,
			output	wire	[3:0]	rx_endp			,
			output	wire			crc16_err		,
			output	wire			rx_lt_sop		,
			output	wire			rx_lt_eop		,
			output	wire			rx_lt_valid		,
			input	wire			rx_lt_ready		,
			output	wire	[7:0]	rx_lt_data		,
			output	wire			crc5_err		,

			//----------from phy layer------------	
			input	wire			rx_lp_valid		,
			input	wire	[7:0]	rx_lp_data		,
			input	wire			rx_lp_sop		,
			input	wire			rx_lp_eop		,
			output	wire			rx_lp_ready		,	


			//--------from transfer_layer_data-------
			input	wire			tx_lt_sop		,
			input	wire			tx_lt_eop		,
			input	wire			tx_lt_valid		,
			output	wire			tx_lt_ready		,
			input	wire	[7:0]	tx_lt_data		,
			input	wire			tx_lt_cancle	,
			//---------to phy layer-----------------
			output	wire			tx_lp_sop		,
			output	wire			tx_lp_eop		,
			output	wire			tx_lp_valid		,
			input	wire			tx_lp_ready		,
			output	wire	[7:0]	tx_lp_data		,
			output	wire			cancle			,	

			//----------from transfer_layer_pid-------
			input	wire	[3:0]	tx_pid			,
			input	wire	[6:0]	tx_addr			,
			input	wire	[3:0]	tx_endp			,
			input	wire			tx_valid		,
			output	wire			tx_ready		,

			//--------------with phy_layer-------------
			input	wire			ms				,
			output	wire			d_oe			,
			//--------------to transfer_layer----------
			output	wire			time_out

);





//--------to token_packet_analysis-------			
wire			rx_handshake_on	;
//-------------from control_t------------
wire			tx_lp_eop_en	;
wire			tx_lp_sop_en	;
//--------------to control_t-------------
wire			tx_data_on		;
wire			crc5_en			;


//-------token_packet_analysis_fifo-------	
wire	[9:0]	rx_data_d;
wire			rx_valid_d;	
wire			rx_ready_d;

//wire		rx_lt_valid_d;
//wire		rx_lt_ready_u;


wire	[7:0]	rx_lt_data_u;
wire			rx_lt_valid_u;
wire			rx_lt_sop_r;
wire			rx_lt_eop_r;
wire	[9:0]	rx_lt_data_d;

assign	rx_lt_data = rx_lt_data_d[8:1];
assign	rx_lt_sop = rx_lt_data_d[9];
assign	rx_lt_eop = rx_lt_data_d[0];


//---------transmit_control_fifo--------
wire			tx_valid_d;
wire			tx_ready_d;
wire	[14:0]	tx_lt_crc_data;
assign	tx_lt_crc_data = {tx_pid,tx_addr,tx_endp};
wire	[14:0]	tx_lt_crc_data_d;

wire			tx_lt_valid_d;
wire	[9:0]	tx_lt_data_d;
wire			tx_lt_ready_d;

wire			tx_lp_ready_u;
wire			tx_lp_valid_u;
wire	[9:0]	tx_lp_data_out;
wire	[7:0]	tx_lp_data_u;
wire			tx_lp_sop_tran;
wire			tx_lp_eop_tran;

assign	tx_lp_sop = tx_lp_data_out[9];
assign	tx_lp_eop = tx_lp_data_out[8];
assign	tx_lp_data = tx_lp_data_out[7:0];

wire	[7:0]	token_data;
wire			token_enable;
wire			handshake_pack;

usb_link_rx u_usb_link_rx(
		//----------clk and rst----------
		.clk(clk)				,
		.rst(rst)				,
		//-----------from register--------
		.self_addr(self_addr)	,		
		//----------from FIFO------------	
		.rx_valid(rx_valid_d)		,
		.rx_data (rx_data_d[8:1])		,
		.rx_sop	 (rx_data_d[9])		,
		.rx_eop	 (rx_data_d[0])		,
			
		.rx_ready(rx_ready_d)		,		
		//----------from link_control-------
		.rx_handshake_on(rx_handshake_on)	,
		//----------to link_control---------
		.rx_sop_en(rx_sop_en)		,
		.rx_eop_en(rx_eop_en)		,
		//---------to next level----------
		.rx_pid_en(rx_pid_en)		,
		.rx_pid	  (rx_pid	)		,
		.rx_endp  (rx_endp  )		,
		.crc16_err(crc16_err)		,
		.rx_lt_sop(rx_lt_sop_r)		,
		.rx_lt_eop(rx_lt_eop_r)		,
		.rx_lt_valid(rx_lt_valid_u)	,
		.rx_lt_ready(rx_lt_ready_u)	,
		.rx_lt_data (rx_lt_data_u )	,
		.crc5_err	(crc5_err)		
		
);


control_t u_control_t(
			//----------clk and rst-----------------
			.clk(clk)			,
			.rst(rst)			,
			//----------from link_control-----------
			.tx_data_on	 (tx_data_on)	,
			.tx_lp_eop_en(tx_lp_eop_en)	,
			.tx_lp_sop_en(tx_lp_sop_en)	,
			.crc5_en(crc5_en),
			//----------from crc5_token-------------
			.token_data	(token_data)	,
			.to_tx_sop	(to_tx_sop)	,
			.to_tx_eop	(to_tx_eop)	,
			.token_enable(token_enable),
			.handshake_pack(handshake_pack),
			//--------from transfer_layer_fifo-------
			.tx_lt_sop	 (tx_lt_data_d[9] )	,
			.tx_lt_eop	 (tx_lt_data_d[8] )	,
			.tx_lt_valid (tx_lt_valid_d )	,
			.tx_lt_ready (tx_lt_ready_d )	,
			.tx_lt_data	 (tx_lt_data_d[7:0] )	,
			.tx_lt_cancle(tx_lt_cancle)	,
			//---------to phy layer-----------------
			.tx_lp_sop	(tx_lp_sop_tran)	,
			.tx_lp_eop	(tx_lp_eop_tran	)	,
			.tx_lp_valid(tx_lp_valid_u)	,
			.tx_lp_ready(tx_lp_ready_u)	,
			.tx_lp_data	(tx_lp_data_u	)	,
			.cancle		(cancle		)	,
			//---------from tx_lp_fifo-----------
			.VALID_DOWN (tx_lp_valid)	,
			.READY_DOWN (tx_lp_ready)	,
			.tx_lp_data_out8(tx_lp_data_out[8])
);


crc5_t u_crc5_t(
			//----------clk and rst-------------------
			.clk(clk)				,
			.rst(rst)				,
			//----------from link_control-------------	
			.crc5_en(crc5_en)		,
			.tx_data_on(tx_data_on)	,
			//----------from transition_layer_pid-----
			.tx_pid	 (tx_lt_crc_data_d[14:11]) 	,
			.tx_addr (tx_lt_crc_data_d[10:4] ) 	,
			.tx_endp (tx_lt_crc_data_d[3:0] ) 	,
			.tx_valid(tx_valid_d)		,
			.tx_ready(tx_ready_d)		,
			.tx_lp_valid(tx_lp_valid_u),
			.tx_lp_ready(tx_lp_ready_u),
			//---------to next level-----------------
			.token_data_r(token_data)	,
			.to_tx_sop_r(to_tx_sop)	,
			.to_tx_eop_r(to_tx_eop)	,
			.token_enable_r(token_enable),
			.handshake_pack(handshake_pack)
			
);

link_control u_link_control(
			//----------clk and rst-----------------
			.clk(clk)				,
			.rst(rst)				,
			//-----------from register--------			
			.time_threshold	(time_threshold	)	,
			.delay_threshole(delay_threshole)	,
			//------from token_packet_analysis------
			.rx_sop		(rx_lp_sop		)	,
			.rx_eop		(rx_lp_eop		)	,
			.rx_pid		(rx_pid		)	,
			.rx_pid_en	(rx_pid_en	)	,
			//--------to token_packet_analysis-------			
			.rx_handshake_on(rx_handshake_on)	,
			//-------------from control_t------------
			.tx_lp_eop_en(tx_lp_eop_en)	,
			.tx_lp_sop_en(tx_lp_sop_en)	,
			//--------------to control_t-------------
			.tx_data_on	(tx_data_on	)		,
			.crc5_en	(crc5_en	)		,
			//--------------with phy_layer-------------
			.ms	 (ms  )				,
			.d_oe(d_oe)				,
			//--------------to transfer_layer----------
			.time_out(time_out)		
);


//----------------RX_FIFO---------------//
rx_fifo rx_lp_fifo
    (
    .CLK			(clk		),
    .RESET			(rst		),
    .DATA_UP		({rx_lp_sop,rx_lp_data,rx_lp_eop} ),
    .VALID_UP		(rx_lp_valid),
    .READY_UP		(rx_lp_ready),
    .DATA_DOWN		(rx_data_d	),
    .VALID_DOWN		(rx_valid_d	),
    .READY_DOWN		(rx_ready_d	)
    );
	
	
rx_fifo rx_lt_fifo
    (
    .CLK			(clk		),
    .RESET			(rst		),
    .DATA_UP		({rx_lt_sop_r,rx_lt_data_u,rx_lt_eop_r}	),
    .VALID_UP		(rx_lt_valid_u),
    .READY_UP		(rx_lt_ready_u),
    .DATA_DOWN		(rx_lt_data_d),
    .VALID_DOWN		(rx_lt_valid),
    .READY_DOWN		(rx_lt_ready)

    );	
	
	
	
//-----------------TX_FIFO---------------//
tx_lp_fifo tx_lp_fifo
    (
    .CLK			(clk		),
    .RESET			(rst		),
    .DATA_UP		({tx_lp_sop_tran,tx_lp_eop_tran,tx_lp_data_u}),
    .VALID_UP		(tx_lp_valid_u),
    .READY_UP		(tx_lp_ready_u),
    .DATA_DOWN		(tx_lp_data_out),
    .VALID_DOWN		(tx_lp_valid),
    .READY_DOWN		(tx_lp_ready)

    );
	
	
synchronous_fifo tx_lt_fifo_crc5
    (
    .CLK			(clk		),
    .RESET			(rst		),
    .DATA_UP		(tx_lt_crc_data	),
    .VALID_UP		(tx_valid	),
    .READY_UP		(tx_ready),
    .DATA_DOWN		(tx_lt_crc_data_d),
    .VALID_DOWN		(tx_valid_d),
    .READY_DOWN		(tx_ready_d)
    );	
defparam tx_lt_fifo_crc5.WIDTH	=15;
	
	
tx_lt_fifo tx_lt_fifo_data
    (
    .CLK			(clk		),
    .RESET			(rst		),
    .DATA_UP		({tx_lt_sop,tx_lt_eop,tx_lt_data}),	
    .VALID_UP		(tx_lt_valid),
    .READY_UP		(tx_lt_ready),
    .DATA_DOWN		(tx_lt_data_d),
    .VALID_DOWN		(tx_lt_valid_d),
    .READY_DOWN		(tx_lt_ready_d)
    );	
		

	




endmodule