//clk_divider를 제거 -> clockdivider
//DHT11의 debuging용으로 led 배치
// UART 추가, 블루투스 연결
// text 모듈에서 블루투스로 받은 메뉴 상태를 버튼 신호가 바로 다음 순간에 덮어써버리는 논리적인 오류 발생
//UART 수신 데이터를 mode_controller에 직접 연결하고, text 모듈에는 mode_controller의 최종 출력만 연결하도록 배선을 정리
//UART 수신 여부 확인을 위한 debuging용으로 LED 추가 -> 반응 없음
//모든 복잡한 로직을 배제하고 블루투스 모듈에서 오는 신호가 FPGA 핀에 물리적으로 도달하는지만 확인 -> 반응 확인 -> 수신된 신호를 해석하는 Uart_Rx 모듈의 내부 동작에 있는 것으로 보입니다. 신호는 들어오고 있는데, 모듈이 그것을 '데이터'로 인식하지 못하고 있을 가능성이 높습니다.
//top 모듈을 수정하여, Uart_Rx 모듈이 해석한 데이터의 실제 값과 데이터 수신 성공 여부(rvalid)를 LED에 직접 표시하도록 변경 -> 아무런 반응이 없음 -> Uart_Rx 모듈이 들어오는 신호를 데이터로 해석하지 못하고 있다는 의미
//Uart_Controller로부터 전달받은 debug_state 값을 led_bar[1:0]에 연결했습니다 -> 버튼을 누를때마다 M_IDLE(00)에서 M_RECEIVE(01)로 바뀜(잠시 깜빡임) = M_RECEIVE 상태에 머무르지 못하고, 즉시 M_IDLE 상태로 돌아가 버립니다.
//Uart_Controller, Uart_Rx, Uart_Tx 모듈 제거 -> uart_receiver 모듈 신규 추가(안정적인 UART 수신 모듈을 새로 작성하여 추가)
//서로 다른 속도의 클럭으로 동작하는 모듈 간에 신호를 주고받을 때 발생하는 전형적인 문제(Clock Domain Crossing)입니다 -> uart_receiver는 100MHz의 빠른 클럭으로 동작하여 1클럭짜리 짧은 '완료' 신호를 만들지만, mode_controller는 1MHz의 느린 클럭으로 동작하여 이 신호를 포착하지 못하는 것입니다.
// 동일하게 011이 깜빡임
//근본적으로 해결하기 위해, UART 수신부를 포함한 모든 제어 로직이 동일한 1MHz 클럭(clk_1MHz)으로 동작하도록 시스템의 구조를 변경
//복잡했던 클럭 동기화(CDC) 로직을 모두 제거하고, 모든 모듈이 clk_1MHz 하나로 동작하도록 연결 관계를 단순화했습니다. -> 변화없음
//led_bar[7]은 UART 데이터 수신이 완전히 성공했을 때만 한 번 깜빡이도록 uart_rx_valid 신호에 직접 연결(uart_receiver 모듈 교체)
// pwm_hum 모듈 추가
// uart_receiver PC용으로 추가
//top 모듈에서 OK 버튼 신호를 **디바운서(debounce)**를 거쳐 mode_controller에 전달했습니다. 디바운서는 버튼을 길게 눌러도 단 한 클럭짜리 '펄스' 신호만 만들어냅니다.
// -> 눌리고 있는 상태가 그대로 전달되는 원본(raw) btn_OK 신호를 직접 연결
module top(
    input           clk,
    input           rst_n,
    output          scl,
    inout           sda,
	input 			sw,
	input			spi_miso,
	output			spi_cs,
	output			spi_mosi,
	output			spi_sck,
	input			joy_ok,
	output 	[4:0] 	led_bar, // DHT11, UART의 debuging용으로 배치
	inout 			dht11_data, //output -> inout
	input 			uart_rxd,
	input 			uart_rxd_pc,
	output 			uart_txd,
	output 			uart_txd_pc,
	output	        pwm,
	output	[2:0]	pump_out
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
	wire 	[1:0]	btn_LR_out_W; 
    wire 	[1:0]	btn_UD_out_W;
	wire			btn_L_out,btn_R_out,btn_U_out,btn_D_out;
//----------DHT11 WIRE----------------	
	wire 	[3:0] 	humidity10, humidity0;
    wire 	[3:0] 	temperature10, temperature0;
//---------UART WIRE----------------
	wire 	[7:0] 	rx_data;
	wire			rx_valid;
	
	wire 	[7:0] 	rx_data_pc;
	wire			rx_valid_pc;
//----------PUMP WIRE--------------------
	wire			pump_on_trigger;
	wire			pump_off_trigger;
	wire			manual_on_trigger;
//----------JOYSTIC CONTROL PIPELINE-------
	wire	[9:0]	joystick_x_adc;
	wire	[9:0]	joystick_y_adc;
	wire			joystick_data_valid;
	reg				joystick_start_trigger;
//----------DISPLAY PIPELINE---------------
	wire			b2d_start;
	wire			b2d_done;
	wire	[15:0]	b2d_dout;
	wire	[15:0]	seg_display_data;
//----------DEBUGINH WIRE--------------------
	wire	[1:0]	joystick_fsm_state;
	wire	[1:0]	led_bar_w;
	
	// 주기적으로 조이스틱 값 읽기 시작 신호 생성 (예: 1초에 60번)
	reg [15:0] refresh_counter = 0;
	always@(posedge clk_1MHz) begin
		refresh_counter <= refresh_counter + 1;
		if(refresh_counter == 16666) begin
			joystick_start_trigger <= 1'b1;
			refresh_counter <= 0;
		end
		else begin
			joystick_start_trigger <= 1'b0;
		end
	end
	
	mcp3008_driver joystick_adc(
		.clk(clk_1MHz),
		.reset(rst_n),
		.start(joystick_start_trigger),
		.x_data_out(joystick_x_adc),
		.y_data_out(joystick_y_adc),
		.data_valid(joystick_data_valid),
		.spi_sck(spi_sck),
		.spi_cs(spi_cs),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso)
	);
	joystick_to_button joy_CTR(
		.clk(clk_1MHz),
		.rst_n(rst_n),
		.x_axis_in(joystick_x_adc),
		.y_axis_in(joystick_y_adc),
		.btn_L_out(btn_L_out),
		.btn_R_out(btn_R_out),
		.btn_U_out(btn_U_out),
		.btn_D_out(btn_D_out)
	);
	
	clockdivider clk_1MHz_gen(
		.clk(clk),
		.reset(rst_n),
		.clk1Mhz(clk_1MHz)
	);
	
	pump_controller pump_ctrl(
		.clk(clk_1MHz),
		.rst_n(rst_n),
		.fragrance_select(btn_LR_out_W),
		.timer_select(btn_UD_out_W),
		.manual_on(manual_on_trigger),
		.pump_on(pump_on_trigger),
		.pump_off(pump_off_trigger),
		.pump_out(pump_out)
	);
		
	
	pwm_hum pwm_DHT11(
	   .clk(clk_1MHz),
	   .rst(rst_n),
	   .humidity10(humidity10),
	   .pwm(pwm)
    );
	
	uart_receiver uart_pc(
        .clk        (clk_1MHz), // Use 100MHz clock
        .reset      (rst_n),
        .rxd        (uart_rxd_pc),
        .rx_data    (rx_data_pc),
        .rx_valid   (rx_valid_pc)
    );
	
	uart_receiver uart_inst(
        .clk        (clk_1MHz), // Use 100MHz clock
        .reset      (rst_n),
        .rxd        (uart_rxd),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid)
    );
	
	DHT11 DT(
		.clk1Mhz(clk_1MHz),
		.reset(rst_n),
		.dht11_data(dht11_data),
		.humidity10(humidity10),
		.humidity0(humidity0),
		.temperature10(temperature10),
		.temperature0(temperature0)
		//.led_bar(dht11_led_bar_internal)
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
		.btn_L(btn_L_out),
		.btn_R(btn_R_out),
		.btn_U(btn_U_out),
		.btn_D(btn_D_out),
		.btn_OK(joy_ok),
        .btn_LR_out(btn_LR_out_W),
        .btn_UD_out(btn_UD_out_W),
		.uart_data_valid(rx_valid),
		.uart_data_valid_pc(rx_valid_pc),
		.uart_data_in(rx_data),
		.uart_data_in_pc(rx_data_pc),
		.pump_on(pump_on_trigger),
		.manual_on(manual_on_trigger),
		.pump_off(pump_off_trigger),
		.led(led_bar_w)
    );
	
	
    assign uart_txd = 1'b1; // Keep TX line idle
    assign uart_txd_pc = 1'b1; // Keep TX line idle
	assign led_bar = {led_bar_w, joystick_fsm_state};
	
endmodule