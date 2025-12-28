`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_if.sv"
`include "my_transaction.sv"
`include "my_sequencer.sv"
`include "my_driver.sv"
`include "my_monitor.sv"
`include "my_agent.sv"
`include "my_model.sv"
`include "my_scoreboard.sv"
`include "my_env.sv"
`include "base_test.sv"
`include "my_case0.sv"

module top_tb;

reg clk;
reg rst_n;

my_if if_inst(clk, rst_n);

usb_link_top dut(
			//----------clk and rst-----------------
			.clk				(clk),
			.rst				(rst_n),
			//-----------from register-------------
			.self_addr			(if_inst.self_addr		),
			.time_threshold		(if_inst.time_threshold	),
			.delay_threshole	(if_inst.delay_threshole),
			//---------to transfer_layer--------
			.rx_pid_en			(if_inst.rx_pid_en		),
			.rx_pid				(if_inst.rx_pid			),
			.rx_endp			(if_inst.rx_endp		),
			.crc16_err			(if_inst.crc16_err		),
			.rx_lt_sop			(if_inst.rx_lt_sop		),
			.rx_lt_eop			(if_inst.rx_lt_eop		),
			.rx_lt_valid		(if_inst.rx_lt_valid	),
			.rx_lt_ready		(if_inst.rx_lt_ready	),
			.rx_lt_data			(if_inst.rx_lt_data 	),
			.crc5_err			(if_inst.crc5_err		),
			//----------from phy layer------------	
			.rx_lp_valid			(if_inst.rx_lp_valid),
			.rx_lp_data				(if_inst.rx_lp_data	),
			.rx_lp_sop				(if_inst.rx_lp_sop	),
			.rx_lp_eop				(if_inst.rx_lp_eop	),
			.rx_lp_ready			(if_inst.rx_lp_ready),	
			//--------from transfer_layer_data-------
			.tx_lt_sop			(if_inst.tx_lt_sop		),
			.tx_lt_eop			(if_inst.tx_lt_eop		),
			.tx_lt_valid		(if_inst.tx_lt_valid	),
			.tx_lt_ready		(if_inst.tx_lt_ready	),
			.tx_lt_data			(if_inst.tx_lt_data		),
			.tx_lt_cancle		(if_inst.tx_lt_cancle	),
			//---------to phy layer-----------------
			.tx_lp_sop			(if_inst.tx_lp_sop		),
			.tx_lp_eop			(if_inst.tx_lp_eop		),
			.tx_lp_valid		(if_inst.tx_lp_valid	),
			.tx_lp_ready		(if_inst.tx_lp_ready	),
			.tx_lp_data			(if_inst.tx_lp_data	),
			.cancle				(if_inst.cancle			),	
			//----------from transfer_layer_pid-------
			.tx_pid				(if_inst.tx_pid		),
			.tx_addr			(if_inst.tx_addr	),
			.tx_endp			(if_inst.tx_endp	),
			.tx_valid			(if_inst.tx_valid	),
			.tx_ready			(if_inst.tx_ready	),
			//--------------with phy_layer-------------
			.ms					(if_inst.ms		),
			.d_oe				(if_inst.d_oe	),
			//--------------to transfer_layer----------
			.time_out			(if_inst.time_out)

);

initial begin
   $display("initial clk");
   clk = 0;
   forever begin
      #10 clk = ~clk;
   end
end

initial begin
   rst_n = 1'b0;
   #50 rst_n=1'b1;

end

initial begin
   run_test();
end

initial begin
   
   uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.agt.drv", "vif", if_inst);
   uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.agt.mon", "vif", if_inst);
end

initial begin
   $timeformat(-9,2,"ns",14);
   $fsdbDumpfile("top_tb.fsdb");
   $fsdbDumpvars(0,top_tb);
end

endmodule
