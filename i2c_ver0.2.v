//clk_divider를 제거 -> clockdivider
//DHT11의 debuging용으로 led 배치
// 해결

module top(
    input           clk,
    input           rst_n,
    output          scl,
    inout           sda,
	input sw,
	input btn_L,
	input btn_R,
	input btn_U,
	input btn_D,
	output [7:0] led_bar, // DHT11의 debuging용으로 배치
	inout dht11_data //output -> inout
);
	wire 		   clk_1MHz;
    wire            done_write;
    wire [7:0]      data;
    wire            cmd_data;
    wire            ena_write;
    wire [127:0]    row1;
    wire [127:0]    row2;
	wire btn_R_debounced,btn_L_debounced,btn_U_debounced,btn_D_debounced; // 명확하게 수정
	wire [1:0] btn_LR_out_W; 
    wire [1:0] btn_UD_out_W;
	wire [3:0] humidity10, humidity0;
    wire [3:0] temperature10, temperature0;
	
	//assign raw_btn_L = btn_L;
	//assign raw_btn_R = btn_R;
	//assign raw_btn_U = btn_U;
	//assign raw_btn_D = btn_D;
    
	clockdivider clk_1MHz_gen(
		.clk(clk),
		.reset(rst_n),
		.clk1Mhz(clk_1MHz)
	);
	
	DHT11 DT(
		.clk1Mhz(clk_1MHz),
		.reset(rst_n),
		.dht11_data(dht11_data),
		.humidity10(humidity10),
		.humidity0(humidity0),
		.temperature10(temperature10),
		.temperature0(temperature0),
		.led_bar(led_bar)
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
        .btn_UD_out(btn_UD_out_W)
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
endmodule