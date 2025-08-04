// test용으로 period_seconds 수정
module pump_controller(
	input clk,
	input rst_n,
	input [1:0] fragrance_select,
	input [1:0] timer_select,
	input pump_on,
	input pump_off,
	input manual_on,
	output [2:0] pump_out
);
	reg [31:0] period_seconds;
	
	reg timer_start_p1,timer_start_p2,timer_start_p3;
	reg force_pulse_p1, force_pulse_p2, force_pulse_p3;
	
	wire [1:0] pump_out_p1,pump_out_p2,pump_out_p3;
	
	always @(*) begin
        case(timer_select)
            2'd0: period_seconds = 32'd10; // 30 minutes -> 32'd1800 -> 32'd10
            2'd1: period_seconds = 32'd30; // 60 minutes -> 32'd3600 -> 32'd30
            2'd2: period_seconds = 32'd60; // 120 minutes -> 32'd7200 -> 32'd60
            default: period_seconds = 32'd1800;
        endcase
    end
	
	always@(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			timer_start_p1 <= 1'b0;timer_start_p2 <= 1'b0;timer_start_p3 <= 1'b0;
			force_pulse_p1 <= 1'b0; force_pulse_p2 <= 1'b0; force_pulse_p3 <= 1'b0;
		end 
		else begin
			timer_start_p1 <= 1'b0;timer_start_p2 <= 1'b0;timer_start_p3 <= 1'b0;
			force_pulse_p1 <= 1'b0; force_pulse_p2 <= 1'b0; force_pulse_p3 <= 1'b0;	
			
			if(pump_on) begin
				case(fragrance_select)
					2'd0: timer_start_p1 <= 1'b1;
					2'd1: timer_start_p2 <= 1'b1;
					2'd2: timer_start_p3 <= 1'b1;
				endcase
			end
			else if(manual_on) begin
				case(fragrance_select) 
					2'd0: force_pulse_p1 <= 1'b1;
					2'd1: force_pulse_p2 <= 1'b1;
					2'd2: force_pulse_p3 <= 1'b1;
				endcase
			end
			else if(pump_off) begin
				timer_start_p1 <= 1'b1;
				timer_start_p2 <= 1'b1;
				timer_start_p3 <= 1'b1;			
			end
		end
	end
	
	pump_timer_logic #(.CLOCK_FREQ(1_000_000)) pump1_timer(
		.clk(clk),	.rst_n(rst_n),
		.pump_select(2'b01),
		.period_seconds(period_seconds),
		.pulse_on_time(32'd5),
		.timer_start(timer_start_p1),
		.force_pulse(force_pulse_p1),
		.pump_out(pump_out_p1)
	);
		pump_timer_logic #(.CLOCK_FREQ(1_000_000)) pump2_timer(
		.clk(clk),	.rst_n(rst_n),
		.pump_select(2'b10),
		.period_seconds(period_seconds),
		.pulse_on_time(32'd5),
		.timer_start(timer_start_p2),
		.force_pulse(force_pulse_p2),
		.pump_out(pump_out_p2)
	);
		pump_timer_logic #(.CLOCK_FREQ(1_000_000)) pump3_timer(
		.clk(clk),	.rst_n(rst_n),
		.pump_select(2'b11),
		.period_seconds(period_seconds),
		.pulse_on_time(32'd5),
		.timer_start(timer_start_p3),
		.force_pulse(force_pulse_p3),
		.pump_out(pump_out_p3)
	);
	
	assign pump_out[0] = (pump_out_p1 != 2'b00);
	assign pump_out[1] = (pump_out_p2 != 2'b00);
	assign pump_out[2] = (pump_out_p3 != 2'b00);
	
endmodule