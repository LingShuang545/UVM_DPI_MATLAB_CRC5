module usb_link_rx(
		//----------clk and rst----------
		input	wire			clk				,
		input	wire			rst				,
		
		//-----------from register--------
		input	wire	[6:0]	self_addr		,

		
		//----------from FIFO------------	
		input	wire			rx_valid		,
		input	wire	[7:0]	rx_data			,
		input	wire			rx_sop			,
		input	wire			rx_eop			,
			
		output	reg				rx_ready		,
		
		//----------from link_control-------
		input	wire			rx_handshake_on	,
		
		
		//----------to link_control---------
		output	reg			rx_sop_en		,
		output	reg			rx_eop_en		,
		
		
		
		//---------to transfer_layer--------
		output	reg				rx_pid_en		,
		output	reg		[3:0]	rx_pid			,
		output	reg		[3:0]	rx_endp			,
		output	reg				crc16_err		,
		output	reg				rx_lt_sop		,
		output	reg				rx_lt_eop		,
		output	reg				rx_lt_valid		,
		input	wire			rx_lt_ready		,
		output	reg		[7:0]	rx_lt_data		,
		output	reg				crc5_err		
);

reg		[7:0]	rx_data_r1			;
reg		[7:0]	rx_data_r2			;
reg		[7:0]	rx_data_r3			;


reg				rx_eop_r1			;



wire			pid_check			;

reg				addr_check			;

wire			pid_check_data		;
reg				rx_data_on			;


reg				pid_flag			;
reg				data_packet_flag	;		



wire			crc5_ok				;
wire	[4:0]	crc5_out			;
reg				crc5_sft			;


reg				crc16_en			;
//wire			crc16_err			;
wire	[15:0]	crc16_out			;


wire			handshake			;
wire			host_packet			;


wire	[10:0]	crc5_data_in		;
wire	[7:0]	crc16_data_in		;


reg				rst_crc5			;
reg				rst_crc16			;

reg		[2:0]	rst_crc16_r;
wire			rx_data_close;
//reg				data_valid			;







//----------------rx_ready------------------//
always @(posedge clk or negedge rst)
	if(!rst)
		rx_ready<=1'b0;
	else
		rx_ready<=1'b1;




//---------------rx_data_cache--------------//
always @(posedge clk or negedge rst)
	if(!rst )
		begin
			rx_data_r1<=8'b0;
			rx_data_r2<=8'b0;
			rx_data_r3<=8'b0;
		end
	else if(crc5_err)
		begin
			rx_data_r1<=8'b0;
			rx_data_r2<=8'b0;
			rx_data_r3<=8'b0;
		end
	else if(rx_valid&rx_ready)
		begin
			rx_data_r1<=rx_data;
			rx_data_r2<=rx_data_r1;
			rx_data_r3<=rx_data_r2;
		end
		

//---------------rx_eop_cache--------------//
always @(posedge clk or negedge rst)
	if(!rst )
		rx_eop_r1<=1'b0;
	else if(crc5_err)
		rx_eop_r1<=1'b0;
	else if(rx_valid&rx_ready)
		rx_eop_r1<=rx_eop;	
		
reg rx_eop_r1_delay;

//-------------rx_eop_delay--------------//
always @(posedge clk or negedge rst)
	if(!rst)begin
			rx_eop_r1_delay<=1'b0;
		end
	else begin
			rx_eop_r1_delay<=rx_eop_r1;
		end
		
		
		

//----------------pid_check-----------------//

assign	pid_check= (~rx_data_r3[7:4] == rx_data_r3[3:0]);
assign	pid_check_hs = (~rx_data[7:4] == rx_data[3:0]);

assign	pid_check_data= (~rx_data_r1[7:4] == rx_data_r1[3:0]);



always @(posedge clk or negedge rst)
	if(!rst)
		pid_flag<=1'b0;
	else if(rx_eop_r1)
		pid_flag<=1'b0;
	else if(pid_check)
		pid_flag<=1'b1;
	




//---------------packet_type--------------//
assign host_packet =( (rx_data_r3[3:0]==4'b0001) || (rx_data_r3[3:0]==4'b1001) || (rx_data_r3[3:0]==4'b0101) || (rx_data_r3[3:0]==4'b1101) ) ;
assign handshake = ( (rx_data_r1[3:0]==4'b0010) || (rx_data_r1[3:0]==4'b1010) || (rx_data_r1[3:0]==4'b1110) );
assign data_packet = rx_data_on & pid_check_data & (rx_data_r1[3:0]==4'b0011 || rx_data_r1[3:0]==4'b1011);








//---------------rx_pid--------------------//

always @(posedge clk or negedge rst)
	if(!rst)
		rx_pid<=4'b0;
	else if(rx_handshake_on & rx_valid & rx_ready)
		rx_pid<=rx_data[3:0];
	else if(data_packet)
		rx_pid<=rx_data_r1[3:0];
	else if(~rx_data_on & pid_check & ~pid_flag)
		rx_pid<=rx_data_r3[3:0];
	else
		rx_pid<=rx_pid;
	
//--------------rx_endp------------------//
always @(posedge clk or negedge rst)
	if(!rst)
		rx_endp<=4'b0;
	else if(pid_check & host_packet)
		rx_endp<={rx_data_r1[2:0],rx_data_r2[7]};
	else
		rx_endp<=rx_endp;
	
//--------------addr_check----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		addr_check<=1'b0;
	else if(pid_check & (rx_data_r2[6:0] == self_addr[6:0]) & host_packet)
		addr_check<=1'b1;
	else
		addr_check<=1'b0;
		
//--------------rx_data_on----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		rx_data_on<=1'b0;
	else if(rx_data_close || rx_handshake_on)
		rx_data_on<=1'b0;
	else if(pid_check & (rx_data_r2[6:0] != self_addr[6:0]) & host_packet)
		rx_data_on<=1'b0;
	else if(addr_check & crc5_ok )
		rx_data_on<=1'b1;	
		


//--------------rx_pid_en----------------//
assign crc5_ok= rst_crc5 & (~{crc5_out[0],crc5_out[1],crc5_out[2],crc5_out[3],crc5_out[4]}==rx_data_r1[7:3]);

reg	crc5_ok_invert;
always @(posedge clk or negedge rst) 
	if(!rst)
		crc5_ok_invert<=1'b1;
	else if(rst_crc5 & ~crc5_ok)
		crc5_ok_invert<=1'b0;
	else if(rx_eop_r1)
		crc5_ok_invert<=1'b1;





//assign rx_pid_en = pid_ok & rx_eop;	
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_pid_en<=1'b0;
	else if(rx_handshake_on & rx_valid & rx_ready & pid_check_hs)
		rx_pid_en<=1'b1;
	else if (rst_crc5 & addr_check &crc5_sft)
		rx_pid_en<=1'b1;
	else
		rx_pid_en<=1'b0;
		
	
//--------------rx_lt_eop----------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_lt_eop<=1'b0;
	else if(rst_crc16 & rx_eop_r1_delay)
		rx_lt_eop<=1'b1;
	else
		rx_lt_eop<=1'b0;




//------------rx_lt_sop----------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_lt_sop<=1'b0;
	else if(rx_data_on & rx_valid & rx_ready)
		rx_lt_sop<=rx_sop;
	else
		rx_lt_sop<=1'b0;

//-------------rx_lt_valid---------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_lt_valid<=1'b0;
	else if(rst_crc16 & rx_eop_r1_delay)
		rx_lt_valid<=1'b1;
	else if(rx_lt_eop)
		rx_lt_valid<=1'b0;
	else if(rx_data_on & ~rx_handshake_on)
		rx_lt_valid<=(rx_valid & ~rx_eop);



//-------------rx_lt_data---------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_lt_data<=8'b0;
	else if(rx_valid & rx_ready)
		rx_lt_data<=rx_data;
//////////////////////to link_control/////////////////////
//--------------rx_sop_en---------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_sop_en<=1'b0;
	else if(rx_handshake_on & rx_valid & rx_ready)
		rx_sop_en<=rx_sop;

//--------------rx_eop_en---------------//
always @(posedge clk or negedge rst) 
	if(!rst)
		rx_eop_en<=1'b0;
	else if(rx_handshake_on & rx_valid & rx_ready)
		rx_eop_en<=rx_eop;
//////////////////////////////////////////////////////////



	
//--------------crc5_sft----------------//	
always @(posedge clk or negedge rst) 
	if(!rst)
		crc5_sft<=1'b0;
	else if(rst_crc5 & ~crc5_ok & crc5_ok_invert)
		crc5_sft<=1'b1;	
	else 
		crc5_sft<=1'b0;	 	
	
	
	


//--------------crc5_err----------------//	
always @(posedge clk or negedge rst) 
	if(!rst)
		crc5_err<=1'b0;
	else if(crc5_sft & ~crc5_ok )
		crc5_err<=1'b1;	
	else 
		crc5_err<=1'b0;
		


	
reg	[1:0] rst_crc5_flag;
//------------rst_crc5_cnt---------------//	
always @(posedge clk or negedge rst)
	if(!rst)
		rst_crc5_flag<=2'b0;
	else if(rx_sop)
		rst_crc5_flag<=2'b0;
	else if(rst_crc5_flag==2'd2)
		rst_crc5_flag<=rst_crc5_flag;
	else if(pid_check & ~rx_handshake_on & host_packet)
		rst_crc5_flag<=rst_crc5_flag+1'b1;


	
//--------------rst_crc5-------------------//	
always @(posedge clk or negedge rst)
	if(!rst)
		rst_crc5<=1'b0;
	else if(rst_crc5_flag==2'd2)
		rst_crc5<=1'b0;
	else if(pid_check & ~rx_handshake_on & host_packet)
		rst_crc5<=1'b1;
	else
		rst_crc5<=1'b0;	


//--------------rst_crc16-------------------//	
always @(posedge clk or negedge rst)
	if(!rst)
		rst_crc16<=1'b0;
	else if(rx_eop_r1_delay)                    
		rst_crc16<=1'b0;		
	else if(pid_check_data & ~rx_handshake_on & data_packet)
		rst_crc16<=1'b1;


//--------------data_packet_flag------------//
always @(posedge clk or negedge rst)
	if(!rst)
		data_packet_flag<=1'b0;
	else if(rx_eop & rx_ready & rx_valid)              
		data_packet_flag<=1'b0;
	else if(pid_check_data & data_packet)
		data_packet_flag<=1'b1;



	

//--------------crc16_en-------------------//		
always @(posedge clk or negedge rst)
	if(!rst)
		crc16_en<=1'b0;	
	else if( rx_ready & rx_valid & data_packet_flag  )
		crc16_en<=1'b1;
	else
		crc16_en<=1'b0;


//--------------crc16_err-------------------//
always @(posedge clk or negedge rst)
	if(!rst)
		crc16_err<=1'b0;
	else if(rx_sop)
		crc16_err<=1'b0;
	else if( (crc16_out != 16'h800d) & rx_eop_r1_delay & rst_crc16 )
		crc16_err<=1'b1;
		
//--------------rst_crc16_r----------------//
always @(posedge clk or negedge rst)
	if(!rst)
		rst_crc16_r<=3'b0;
	else
		rst_crc16_r<={rst_crc16_r[2:0],rst_crc16};
		
assign	rx_data_close = rst_crc16_r[1] & ~rst_crc16_r[0];
		
		
		
		


		
assign crc5_data_in={rx_data_r2[0],rx_data_r2[1],rx_data_r2[2],rx_data_r2[3],rx_data_r2[4],rx_data_r2[5],rx_data_r2[6],rx_data_r2[7],rx_data_r1[0],rx_data_r1[1],rx_data_r1[2]};		
assign crc16_data_in={rx_data_r1[0],rx_data_r1[1],rx_data_r1[2],rx_data_r1[3],rx_data_r1[4],rx_data_r1[5],rx_data_r1[6],rx_data_r1[7]};		

//----------------crc5_inst-------------------//
crc5 crc5_r(
  .data_in	(crc5_data_in),				//reverse
  .crc_en	(pid_check)	,				//one clock
  .crc_out	(crc5_out)	,				//reverse+invert
  .rst		(rst_crc5)		,
  .clk		(clk)
  );


//----------------crc16_inst-----------------//
crc16 crc16_r(
  .data_in		(crc16_data_in)	,
  .crc_en		(crc16_en)	,			//The entire data clock cycle
  .crc_out		(crc16_out)	,
  .rst			(rst_crc16)		,
  .clk			(clk)
  );







endmodule