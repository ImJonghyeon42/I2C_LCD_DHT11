//Uart_Rx 모듈에서 FIFO IP를 호출할 때, 데이터를 저장하라는 신호인 wr_en(Write Enable) 포트에 fifo_wen이라는 와이어를 연결했습니다. 하지만 이 fifo_wen 와이어를 선언하거나 만드는 코드가 파일 전체에 누락
//FIFO의 리셋 포트인 srst를 1'b0으로 고정해 두셨습니다. 이렇게 하면 모듈 전체에 리셋이 걸려도 FIFO만 리셋되지 않아, 시스템이 불안정해지거나 예측 불가능한 상태가 될 수 있습니다.
//m_state라는 내부 상태 값을 밖으로 볼 수 있도록 debug_state라는 2비트짜리 출력 포트를 추가
module Uart_Rx(reset, mclk, baudrate, parity_sel, stop_sel, ren, rdata, rvalid, overrun, frame_err, parity_err, rxd, debug_state);
	input reset, mclk, stop_sel,ren, rxd;	input [15:0] baudrate; input [1:0] parity_sel; 
	output [7:0] rdata;	output rvalid, overrun, frame_err, parity_err;
	output [1:0] debug_state;

/* define state */
	reg [1:0] m_state;
	parameter M_IDLE = 2'b0;
	parameter M_RECEIVE = 2'd1;
	parameter M_DONE = 2'd2;
	
	assign debug_state = m_state;

/*state flag */
	wire s_idle = (m_state==M_IDLE) ? 1'b1 : 1'b0;
	wire s_receive = (m_state==M_RECEIVE) ? 1'b1 : 1'b0;
	wire s_done = (m_state==M_DONE) ? 1'b1 : 1'b0;
	
/* code implementation */
	reg rxd_1d, rxd_2d, rxd_3d;
	wire rxd_nedge = ~rxd_2d & rxd_3d;
	always@(posedge mclk or negedge reset) begin
		if(~reset) begin
			rxd_1d<=1'b1;
			rxd_2d<=1'b1;
			rxd_3d<=1'b1;
		end
		else begin
			rxd_1d<=rxd;
			rxd_2d<=rxd_1d;
			rxd_3d<=rxd_2d;
		end
	end
	reg [15:0] cnt1;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cnt1 <= 16'b0;
		else cnt1 <= ~s_receive ? 16'b0 : (cnt1==baudrate)? 16'b0 : cnt1+1'b1;
	end
	reg [3:0] cnt2;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cnt2 <= 4'b0;
		else cnt2 <= ~s_receive ? 4'b0 : (cnt1==baudrate)? cnt2+1'b1 : cnt2;
	end	
	
	reg [7:0] rxd_data;
	always@(posedge mclk or negedge reset) begin
		if(~reset) rxd_data <= 8'b0;	
		else if ((cnt1=={1'b0,baudrate[15:1]})) begin // Sample in the middle of the bit
			case(cnt2)
				4'd1: rxd_data[0] <= rxd_3d;
				4'd2: rxd_data[1] <= rxd_3d;
				4'd3: rxd_data[2] <= rxd_3d;
				4'd4: rxd_data[3] <= rxd_3d;
				4'd5: rxd_data[4] <= rxd_3d;
				4'd6: rxd_data[5] <= rxd_3d;
				4'd7: rxd_data[6] <= rxd_3d;
				4'd8: rxd_data[7] <= rxd_3d;
			endcase
		end
	end
	
	wire cal_parity = ^rxd_data;
	reg cal_parity2;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cal_parity2 <= 1'b0;	
		else cal_parity2 <= (parity_sel==2'b01)?cal_parity : (parity_sel==2'b10)?~cal_parity:1'b0;
	end
	reg rxd_parity;
	always@(posedge mclk or negedge reset) begin
		if(~reset) rxd_parity <= 1'b0;		
		else rxd_parity <= ((cnt2==4'd9)&(cnt1=={1'b0,baudrate[15:1]}))?rxd_3d : rxd_parity;
	end
	
	reg stop_bit1;
	always@(posedge mclk or negedge reset) begin
		if(~reset) stop_bit1 <= 1'b0;		
		else stop_bit1<=((parity_sel==2'b00)&(cnt2==4'd9)&(cnt1=={1'b0,baudrate[15:1]}))?rxd_3d :
									((parity_sel !=2'b00)&(cnt2==4'd10)&(cnt1=={1'b0,baudrate[15:1]}))?rxd_3d : stop_bit1;
	end
	reg stop_bit2;
	always@(posedge mclk or negedge reset) begin
		if(~reset) stop_bit2 <= 1'b0;		
		else stop_bit2<=((parity_sel==2'b00)&(cnt2==4'd10)&(cnt1=={1'b0,baudrate[15:1]}))?rxd_3d :
									((parity_sel !=2'b00)&(cnt2==4'd11)&(cnt1=={1'b0,baudrate[15:1]}))?rxd_3d : stop_bit2;
	end
	reg [2:0] cnt_done;
	always@(posedge mclk or negedge reset) begin
		if(~reset) cnt_done <= 3'b0;		
		else cnt_done<=~s_done?3'b0: cnt_done+1'b1;
	end
	
/*state transition */
	always@(posedge mclk or negedge reset) begin
		if(~reset) m_state <= 1'b0;			
		else m_state<=(s_idle & rxd_nedge) ? M_RECEIVE :
				((parity_sel==2'b0)&(stop_sel==1'b0)&(cnt2==4'd9)&(cnt1==baudrate))?M_DONE : 
				((parity_sel==2'b0)&(stop_sel==1'b1)&(cnt2==4'd10)&(cnt1==baudrate))?M_DONE : 
				((parity_sel==2'b0)&(stop_sel==1'b0)&(cnt2==4'd10)&(cnt1==baudrate))?M_DONE : 
				((parity_sel==2'b0)&(stop_sel==1'b1)&(cnt2==4'd11)&(cnt1==baudrate))?M_DONE : 
				(cnt_done==3'd7)?M_IDLE : m_state;
	end
/*uart receive state & fifo */
	reg frame_err;
	always@(posedge mclk or negedge reset) begin
		if(~reset) frame_err <= 1'b0;	
		else frame_err<=((cnt_done==3'd5)&(stop_sel==1'b0))? ~stop_bit1 :
									((cnt_done==3'd5)&(stop_sel==1'b1))? ~(stop_bit1&stop_bit2) : frame_err;
	end
	reg parity_err;
	always@(posedge mclk or negedge reset) begin
		if(~reset) parity_err <= 1'b0;		
		else parity_err<=(parity_sel==2'b0)?1'b0 : 
									((cnt_done==3'd5) & (cal_parity2==rxd_parity))?1'b0 :
									((cnt_done==3'd5) & (cal_parity2!=rxd_parity))?1'b1 : parity_err;
	end
	wire fifo_full;
	wire overrun = fifo_full;
	wire fifo_empty;
	wire rvalid = ~fifo_empty;
	wire [7:0] fifo_din = rxd_data;
	wire fifo_ren = ren;
	wire [7:0] fifo_dout;
	wire [7:0] rdata = fifo_dout;
	
	wire fifo_wen = (m_state == M_DONE) && (cnt_done == 3'd0); //추가
	
	fifo_16x8 rxd_fifo(.clk(mclk),.srst(~reset),.din(fifo_din),.wr_en(fifo_wen),.rd_en(fifo_ren),.dout(fifo_dout),.full(fifo_full),.empty(fifo_empty),.valid());//srst(1'b0) -> srst(~reset)
endmodule
									