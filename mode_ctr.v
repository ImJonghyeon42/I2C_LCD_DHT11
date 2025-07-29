//==============================================================================
module mode_controller (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
    output reg [1:0] btn_LR_out, 
    output reg [1:0] btn_UD_out,
    output reg [3:0] led
); 
    localparam LED_ON_DURATION = 100_000; // 0.1√ 

    reg btn_R_reg, btn_R_prev;
    reg btn_L_reg, btn_L_prev;
    reg btn_U_reg, btn_U_prev;
    reg btn_D_reg, btn_D_prev;
    reg [16:0] led_counter = 0; 
    
    wire btn_R_rise, btn_U_rise, btn_L_rise, btn_D_rise;
    assign btn_R_rise = ~btn_R_prev & btn_R_reg;
    assign btn_L_rise = ~btn_L_prev & btn_L_reg;
    assign btn_U_rise = ~btn_U_prev & btn_U_reg;
    assign btn_D_rise = ~btn_D_prev & btn_D_reg;

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            btn_R_reg  <= 0; btn_R_prev  <= 0;
            btn_L_reg  <= 0; btn_L_prev  <= 0;
            btn_U_reg  <= 0; btn_U_prev  <= 0;
            btn_D_reg  <= 0; btn_D_prev  <= 0;
            btn_UD_out <= 0; btn_LR_out  <= 0;
            led        <= 4'b0000;
            led_counter<= 0;
        end else begin
            btn_R_prev <= btn_R_reg;
            btn_L_prev <= btn_L_reg;
            btn_U_prev <= btn_U_reg;
            btn_D_prev <= btn_D_reg;
            
            btn_R_reg <= btn_R;
            btn_L_reg <= btn_L;
            btn_U_reg <= btn_U;
            btn_D_reg <= btn_D;
            
            if (btn_R_rise) begin
                if (btn_LR_out < 2'd2) btn_LR_out <= btn_LR_out + 1;
                else btn_LR_out <= 2'd0;
            end else if (btn_L_rise) begin
                if (btn_LR_out > 2'd0) btn_LR_out <= btn_LR_out - 1;
                else btn_LR_out <= 2'd2;
            end

            if (btn_U_rise) begin
                if (btn_UD_out < 2'd2) btn_UD_out <= btn_UD_out + 1;
                else btn_UD_out <= 2'd0;
            end else if (btn_D_rise) begin
                if (btn_UD_out > 2'd0) btn_UD_out <= btn_UD_out - 1;
                else btn_UD_out <= 2'd2;
            end
            
            if (led_counter == 0) begin
                if (btn_R_rise)      begin led <= 4'b0001; led_counter <= 1; end 
                else if (btn_L_rise) begin led <= 4'b0010; led_counter <= 1; end 
                else if (btn_U_rise) begin led <= 4'b0100; led_counter <= 1; end 
                else if (btn_D_rise) begin led <= 4'b1000; led_counter <= 1; end
            end else begin
                if (led_counter >= LED_ON_DURATION) begin
                    led <= 4'b0000;
                    led_counter <= 0;
                end else begin
                    led_counter <= led_counter + 1;
                end
            end
        end
    end
endmodule