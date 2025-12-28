module tx_lt_fifo	
	#(
		parameter	WIDTH=10 ,
		parameter	DEPTH=2 )
	(
		input	CLK,
		input	RESET,
		
		input	wire	[(WIDTH-1):0]	DATA_UP,
		input	wire					VALID_UP,
		output	reg						READY_UP,
		
		output	wire	[(WIDTH-1):0]	DATA_DOWN,
		output	reg						VALID_DOWN,
		input	wire					READY_DOWN
		
	);
	
	
localparam	PRT_WIDTH = ( $clog2(DEPTH) );


reg	[(WIDTH-1):0]	men	[0:(DEPTH-1)];
reg	[PRT_WIDTH:0]	w_prt;
reg	[PRT_WIDTH:0]	r_prt;


always @(posedge CLK or negedge RESET)
	if(!RESET)
		r_prt <= {(PRT_WIDTH+1){1'b0}};
	else if(VALID_DOWN && READY_DOWN)
		r_prt <= r_prt +1'b1;

always @(posedge CLK or negedge RESET)
	if(!RESET)
		w_prt <= {(PRT_WIDTH+1){1'b0}};
	else if(VALID_UP && READY_UP)
		w_prt <= w_prt +1'b1;
		

		
		
		
genvar i;
generate
for( i=0; i<DEPTH; i=i+1 )
	begin:gen
		always @(posedge CLK or negedge RESET)
			if(!RESET)
				men[i] <= {WIDTH{1'b0}};
			else if( VALID_UP && READY_UP && (w_prt[(PRT_WIDTH-1):0]==i) )
				men[i] <= DATA_UP;
	end
endgenerate









assign DATA_DOWN = men[r_prt[(PRT_WIDTH-1):0]];



always@(*)
	if( (w_prt[(PRT_WIDTH-1):0]==r_prt[(PRT_WIDTH-1):0]) && (w_prt[PRT_WIDTH]^r_prt[PRT_WIDTH]) )
		READY_UP = 1'b0;
	else
		READY_UP = 1'b1;

always@(*)
	if( (w_prt[PRT_WIDTH:0]==r_prt[PRT_WIDTH:0])  )
		VALID_DOWN = 1'b0;
	else
		VALID_DOWN = 1'b1;







endmodule