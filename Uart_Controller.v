//Uart_Rx의 debug_state 출력을 상위 모듈로 전달하는 통로를 만들었습니다.
`timescale 1ns/1ps

module Uart_Controller( reset, mclk, baudrate, parity_sel, stop_sel, tdata, send, trdy, txd, rxd, ren, rdata, rvalid, overrun, frame_err, parity_err,debug_state);
	input reset, mclk;	input [15:0] baudrate; input [1:0] parity_sel; input stop_sel; input [7:0] tdata; input send;	input rxd, ren;
	output trdy, txd;	output [7:0] rdata;	output rvalid, overrun, frame_err, parity_err;
	output [1:0] debug_state;
	
	wire trdy;
	wire txd;
	
	Uart_Tx Uart_Tx_U0(.reset(reset),.mclk(mclk),.baudrate(baudrate),.parity_sel(parity_sel),.stop_sel(stop_sel),.send(send),.done(trdy),.txd(txd));
	
	wire [7:0] rdata;
	wire rvalid;
	wire overrun;
	wire frame_err;
	wire parity_err;
	
	Uart_Rx Uart_Rx_U1(.reset(reset),.mclk(mclk),.baudrate(baudrate),.parity_sel(parity_sel),.stop_sel(stop_sel),.rdata(rdata),.ren(ren),.rvalid(rvalid),.overrun(overrun),.frame_err(frame_err),.parity_err(parity_err),.rxd(rxd),.debug_state(debug_state));
endmodule