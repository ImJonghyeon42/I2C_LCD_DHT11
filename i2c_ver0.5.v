//clk_divider를 제거 -> clockdivider
//DHT11의 debuging용으로 led 배치
// UART 추가, 블루투스 연결
// text 모듈에서 블루투스로 받은 메뉴 상태를 버튼 신호가 바로 다음 순간에 덮어써버리는 논리적인 오류 발생
//UART 수신 데이터를 mode_controller에 직접 연결하고, text 모듈에는 mode_controller의 최종 출력만 연결하도록 배선을 정리
//UART 수신 여부 확인을 위한 debuging용으로 LED 추가
module top(
    input           clk,
    input           rst_n,
    output          scl,
    inout           sda,
	input 			sw,
	input 			btn_L,
	input 			btn_R,
	input 			btn_U,
	input 			btn_D,
	output 	[8:0] 	led_bar, // DHT11, UART의 debuging용으로 배치
	inout 			dht11_data, //output -> inout
	input 			uart_rxd,
	output 			uart_txd
);
//------CLK WIRE-----------------------
	wire 		   clk_1MHz;
//------LCD WIRE-------------------------	
    wire            done_write;
    wire [7:0]      data;
    wire            cmd_data;
    wire            ena_write;
    wire [127:0]    row1;
    wire [127:0]    row2;
//--------BTN WIRE--------------------	
	wire 			btn_R_debounced,btn_L_debounced,btn_U_debounced,btn_D_debounced; // 명확하게 수정
	wire 	[1:0]	btn_LR_out_W; 
    wire 	[1:0]	btn_UD_out_W;
//----------DHT11 WIRE----------------	
	wire 	[3:0] 	humidity10, humidity0;
    wire 	[3:0] 	temperature10, temperature0;
//---------UART WIRE----------------
	wire 	[7:0] 	tx_data;
	wire 			tx_send;
	wire 			tx_ready;
	wire 	[7:0] 	rx_data;
	wire			rx_valid;
	
	reg 			rx_read_en;
//----------DEBUG WIRE-----------------
	wire [7:0]    dht11_led_bar_internal;
	reg uart_received_flag;
	
	clockdivider clk_1MHz_gen(
		.clk(clk),
		.reset(rst_n),
		.clk1Mhz(clk_1MHz)
	);
	
	Uart_Controller UC(
		.reset(rst_n),
		.mclk(clk), // baudrate 를 위해 원 clk을 넣어줘야 함
		.baudrate(16'd10416), //100,000,000번 (1초당 클럭 수) / 9600번 (1초당 비트 수) = 10416.6번 (1비트당 클럭 수)
		.parity_sel(2'b00),
		.stop_sel(1'b0),
		.tdata(8'h00),
		.send(1'b0),
		.trdy(),//tx를 사용하지 않아 정지 시킴
		.txd(uart_txd),
		.rxd(uart_rxd),
		.ren(rx_read_en),
		.rdata(rx_data),
		.rvalid(rx_valid)
	);
	
	DHT11 DT(
		.clk1Mhz(clk_1MHz),
		.reset(rst_n),
		.dht11_data(dht11_data),
		.humidity10(humidity10),
		.humidity0(humidity0),
		.temperature10(temperature10),
		.temperature0(temperature0),
		.led_bar(dht11_led_bar_internal)
	);

    lcd_display lcd_display_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .ena        (1'b1),
        .done_write (done_write),
        .row1       (row1),
        .row2       (row2),
        .data       (data),
        .cmd_data   (cmd_data),
        .ena_write  (ena_write)
    );

    lcd_write_cmd_data lcd_write_cmd_data_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .data       (data),
        .cmd_data   (cmd_data),
        .ena        (ena_write),
        .i2c_addr   (7'h27),
        .sda        (sda),
        .scl        (scl),
        .done       (done_write)
    );
	
	text U3(
		.clk(clk_1MHz),
		.rst(rst_n),
		.row1(row1),
		.row2(row2),
		.humidity10(humidity10),
		.humidity0(humidity0),
		.temperature10(temperature10),
		.temperature0(temperature0),
		.sw(sw),
        .btn_LR(btn_LR_out_W),
        .btn_UD(btn_UD_out_W)
	);
	
	mode_controller mode_ctrl (
        .clk(clk_1MHz),
        .reset(rst_n),
		.btn_L(btn_L_debounced),
		.btn_R(btn_R_debounced),
		.btn_U(btn_U_debounced),
		.btn_D(btn_D_debounced),
        .btn_LR_out(btn_LR_out_W),
        .btn_UD_out(btn_UD_out_W),
		.uart_data_valid(rx_valid),
		.uart_data_in(rx_data)
    );
	
	debounce BBF_R(
		.clk(clk_1MHz),
		.button_in(btn_R),
		.button_out(btn_R_debounced)
	);
	debounce BBF_L(
		.clk(clk_1MHz),
		.button_in(btn_L),
		.button_out(btn_L_debounced)
	);
	debounce BBF_U(
		.clk(clk_1MHz),
		.button_in(btn_U),
		.button_out(btn_U_debounced)
	);
	debounce BBF_D(
		.clk(clk_1MHz),
		.button_in(btn_D),
		.button_out(btn_D_debounced)
	);
	
	always@(posedge clk_1MHz or negedge rst_n) begin
		if(~rst_n) begin
			rx_read_en 	<= 1'b0;
			uart_received_flag  <= 1'b0;
		end
		else begin
			rx_read_en 	<= rx_valid;
			if(rx_valid)begin
				uart_received_flag <= 1'b1;
			end
		end
	end
	assign led_bar = {uart_received_flag, dht11_led_bar_internal};
	
endmodule