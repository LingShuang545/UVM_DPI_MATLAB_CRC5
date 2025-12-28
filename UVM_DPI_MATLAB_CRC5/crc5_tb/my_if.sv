`ifndef MY_IF__SV
`define MY_IF__SV

interface my_if(input clk, input rst_n);


    logic   [6:0]	self_addr		;
    logic   [15:0]	time_threshold	;
    logic   [5:0]	delay_threshole	;

    logic   		rx_pid_en		;
    logic   [3:0]	rx_pid			;
    logic   [3:0]	rx_endp			;
    logic   		crc16_err		;
    logic   		rx_lt_sop		;
    logic   		rx_lt_eop		;
    logic   		rx_lt_valid		;
    logic   		rx_lt_ready		;
    logic   [7:0]	rx_lt_data		;
    logic   		crc5_err		;

    logic   		rx_lp_valid		;
    logic   [7:0]	rx_lp_data		;
    logic   		rx_lp_sop		;
    logic   		rx_lp_eop		;
    logic   		rx_lp_ready		;

    logic   		tx_lt_sop		;
    logic   		tx_lt_eop		;
    logic   		tx_lt_valid		;
    logic   		tx_lt_ready		;
    logic   [7:0]	tx_lt_data		;
    logic   		tx_lt_cancle	;

    logic   		tx_lp_sop		;
    logic   		tx_lp_eop		;
    logic   		tx_lp_valid		;
    logic   		tx_lp_ready		;
    logic   [7:0]	tx_lp_data		;
    logic   		cancle			;

    logic   [3:0]	tx_pid			;
    logic   [6:0]	tx_addr			;
    logic   [3:0]	tx_endp			;
    logic   		tx_valid		;
    logic   		tx_ready		;

    logic   		ms				;
    logic   		d_oe			;

    logic   		time_out        ;

endinterface

`endif
