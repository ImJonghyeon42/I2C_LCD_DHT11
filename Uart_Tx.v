module Uart_Tx(reset, mclk, baudrate, parity_sel, stop_sel, tdata, send, txd, done);
	input reset, mclk, stop_sel, send; input [15:0] baudrate; input [1:0] parity_sel; input [7:0] tdata;
	output txd, done;
	
/* define state */
	reg m_state;
	parameter M_IDLE = 1'b0;
	parameter M_RUN = 1'b1;
/* state flag */
	wire s_idle = (m_state == M_IDLE) ? 1'b1 : 1'b0;
	wire s_run = (m_state == M_RUN) ? 1'b1 : 1'b0;

/* code implementation */
	reg [15:0] cnt1;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cnt1<= 16'b0;
		else cnt1<=s_idle? 16'b0 : (cnt1 == baudrate)? 16'b0 : cnt1+1'b1;
	end
	
	reg [3:0] cnt2;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cnt2<= 4'b0;
		else cnt2<=s_idle? 4'b0 : (cnt1==baudrate)? cnt2+1'b1 : cnt2;
	end
	
	wire tdata_xor = tdata[0]^tdata[1]^tdata[2]^tdata[3]^tdata[4]^tdata[5]^tdata[6]^tdata[7];
	reg parity;
	always@(posedge mclk or negedge reset) begin
		if(~reset) parity<= 1'b0;
		else parity<=(parity_sel==2'b01)? tdata_xor : ~tdata_xor;
	end
	
	reg txd;
	always@(posedge mclk or negedge reset) begin
		if(~reset) txd<= 1'b1;
		else txd <= s_idle ? 1'b1 :
						((cnt2==4'd0) && (cnt1==16'd0))?1'b0 :
						((cnt2==4'd1) && (cnt1==16'd0))?tdata[0] :
						((cnt2==4'd2) && (cnt1==16'd0))?tdata[1] :
						((cnt2==4'd3) && (cnt1==16'd0))?tdata[2] :
						((cnt2==4'd4) && (cnt1==16'd0))?tdata[3] :
						((cnt2==4'd5) && (cnt1==16'd0))?tdata[4] :
						((cnt2==4'd6) && (cnt1==16'd0))?tdata[5] :
						((cnt2==4'd7) && (cnt1==16'd0))?tdata[6] :
						((cnt2==4'd8) && (cnt1==16'd0))?tdata[7] :
						((parity_sel==2'b0)&(~stop_sel)&(cnt2==4'd9)&(cnt1==16'd0))?1'b1 :
						((parity_sel==2'b0)&(stop_sel)&(cnt2==4'd9)&(cnt1==16'd0))?1'b1 :
						((parity_sel==2'b0)&(stop_sel)&(cnt2==4'd10)&(cnt1==16'd0))?1'b1 :
						
						((parity_sel!=2'b0)&(~stop_sel)&(cnt2==4'd9)&(cnt1==16'd0))? parity :
						((parity_sel!=2'b0)&(~stop_sel)&(cnt2==4'd10)&(cnt1==16'd0))?1'b1 :
						
						((parity_sel!=2'b0)&(stop_sel)&(cnt2==4'd9)&(cnt1==16'd0))? parity :
						((parity_sel!=2'b0)&(stop_sel)&(cnt2==4'd10)&(cnt1==16'd0))?1'b1 :
						((parity_sel!=2'b0)&(stop_sel)&(cnt2==4'd11)&(cnt1==16'd0))?1'b1 : txd;
	end
	wire done=s_idle;
	
/* state transition : m_state */
	always@(posedge mclk or negedge reset) begin
		if(~reset) m_state<= 1'b0;	
		else m_state<=(s_idle & send) ? M_RUN :
				(s_run & (parity_sel==2'b0)&(stop_sel==1'b0)&(cnt2==4'd10))?M_IDLE:
				(s_run & (parity_sel==2'b0)&(stop_sel==1'b1)&(cnt2==4'd11))?M_IDLE:
				(s_run & (parity_sel!=2'b0)&(stop_sel==1'b0)&(cnt2==4'd11))?M_IDLE:
				(s_run & (parity_sel!=2'b0)&(stop_sel==1'b1)&(cnt2==4'd12))?M_IDLE: m_state;
	end
endmodule
						
						
						