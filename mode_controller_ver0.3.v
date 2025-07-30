//UART로부터 데이터(uart_data_valid, uart_data_in)를 직접 입력받도록 포트를 추가
//블루투스 데이터가 들어오면, 버튼 입력보다 우선하여 메뉴 상태(btn_LR_out, btn_UD_out)를 변경
//Cotton -> Woody, Woody -> Citrus, Citrus->Cotton -> 잘 못 들어감
module mode_controller (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
	input uart_data_valid,
    input [7:0] uart_data_in,
    output reg [1:0] btn_LR_out, 
    output reg [1:0] btn_UD_out
); 
    localparam LED_ON_DURATION = 100_000; // 0.1초

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
        end else begin
            btn_R_prev <= btn_R_reg;
            btn_L_prev <= btn_L_reg;
            btn_U_prev <= btn_U_reg;
            btn_D_prev <= btn_D_reg;
            
            btn_R_reg <= btn_R;
            btn_L_reg <= btn_L;
            btn_U_reg <= btn_U;
            btn_D_reg <= btn_D;
			
			if (uart_data_valid) begin
                case (uart_data_in)
                    8'h01: btn_LR_out <= 2'd2; // Cotton -> 2'd0 -> 2'd2 
                    8'h02: btn_LR_out <= 2'd0; // Woody -> 2'd1 -> 2'd0
                    8'h03: btn_LR_out <= 2'd1; // Citrus -> 2'd2 -> 2'd1
                    8'h1E: btn_UD_out <= 2'd0; // Timer 30min
                    8'h3C: btn_UD_out <= 2'd1; // Timer 60min
                    8'h78: btn_UD_out <= 2'd2; // Timer 120min
                    default: ;
                endcase
            end
            
            else begin
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
			end
		end
	end
endmodule