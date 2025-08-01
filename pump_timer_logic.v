module pump_timer_logic #(
    parameter CLOCK_FREQ = 100_000_000
)(
    input wire clk,
    input wire reset,
    input wire [1:0] pump_select,
    input wire [31:0] period_seconds,
    input wire [31:0] pulse_on_time,
    input wire timer_reset,
    input wire force_pulse,
    output reg [1:0] pump_out
);

    reg [31:0] timer_count = 0;
    reg [31:0] pulse_count = 0;
    reg timer_active = 0;
    reg pulse_active = 0;

    reg [31:0] force_count = 0;
    reg force_active = 0;

    reg [1:0] pump_select_reg = 2'b00;

    reg timer_reset_prev = 0;
    reg force_pulse_prev = 0;

    always @(posedge clk) begin
        timer_reset_prev <= timer_reset;
        force_pulse_prev <= force_pulse;

        if (~reset) begin
            timer_count <= 0;
            pulse_count <= 0;
            timer_active <= 0;
            pulse_active <= 0;
            pump_out <= 2'b00;
            force_count <= 0;
            force_active <= 0;
            pump_select_reg <= 2'b00;
            timer_reset_prev <= 0;
            force_pulse_prev <= 0;
        end else begin
     
            if (timer_reset && ~timer_reset_prev) begin
                timer_count <= 0;
                pulse_count <= 0;
                timer_active <= 1;
                pulse_active <= 0;
                pump_select_reg <= pump_select;
            end

        
            if (force_pulse && ~force_pulse_prev) begin
                force_active <= 1;
                force_count <= 0;
                pump_select_reg <= pump_select;
            end

            // 주기 타이머
            if (timer_active) begin
                if (timer_count >= period_seconds * CLOCK_FREQ) begin
                    timer_count <= 0;
                    pulse_active <= 1;
                    pulse_count <= 0;
                end else begin
                    timer_count <= timer_count + 1;
                end
            end

       
            if (pulse_active) begin
                if (pulse_count >= pulse_on_time * CLOCK_FREQ) begin
                    pulse_active <= 0;
                    pulse_count <= 0;
                end else begin
                    pulse_count <= pulse_count + 1;
                end
            end

       
            if (force_active) begin
                if (force_count >= pulse_on_time * CLOCK_FREQ) begin
                    force_active <= 0;
                    force_count <= 0;
                end else begin
                    force_count <= force_count + 1;
                end
            end

        
            if (pulse_active || force_active) begin
                pump_out <= pump_select_reg;
            end else begin
                pump_out <= 2'b00;
            end
        end
    end
endmodule