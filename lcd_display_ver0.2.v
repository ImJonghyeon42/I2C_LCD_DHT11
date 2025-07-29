// 2025.07.29 -> row2 지지직 거리는 문제 해결을 위해 delay 수정
module lcd_display(
    input               clk_1MHz,
    input               rst_n,
    input               ena,
    input               done_write,
    input  [127:0]      row1,
    input  [127:0]      row2,
    output reg[7:0]     data,
    output              cmd_data,
    output reg          ena_write
);

    localparam  DELAY = 2000; // 50 -> 2000 : row2가 지지직 거리는거 수정할려다 row1도 지지직거림
							 

    localparam  WaitEn      = 0,
                Write       = 1,
                WaitWrite   = 2, 
                WaitDelay   = 3,
                Done        = 4;

    reg [2:0]   state, next_state;
    reg [20:0]  cnt;
    reg         cnt_clr;

    reg [7:0]   cmd_data_array [0:37]; 
    
    initial begin
        cmd_data_array[0]  = 8'h33; // Init
        cmd_data_array[1]  = 8'h32; // Init
        cmd_data_array[2]  = 8'h28; // 4-bit, 2-line
        cmd_data_array[3]  = 8'h0C; // Display ON, Cursor OFF
        cmd_data_array[4]  = 8'h01; // Clear Display
        cmd_data_array[5]  = 8'h80; // Cursor to Line 1
        cmd_data_array[22] = 8'hC0; // Cursor to Line 2
    end

    // [FIX] Declare loop variable 'i' outside the loop for compatibility.
    integer i;
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            cmd_data_array[6+i]  = row1[127 - i*8 -: 8];
            cmd_data_array[23+i] = row2[127 - i*8 -: 8];
        end
    end

    reg [5:0]   ptr;
    assign cmd_data = (ptr <= 5 || ptr == 22) ? 1'b0 : 1'b1;

    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) cnt <= 21'd0;
        else if (cnt_clr) cnt <= 21'd0;
        else cnt <= cnt + 1'b1;
    end

    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) state <= WaitEn;
        else state <= next_state;
    end

    always @(*) begin
        if (!rst_n) next_state = WaitEn;
        else begin
            case (state)
                WaitEn:    next_state = ena ? Write : WaitEn;
                Write:     next_state = WaitWrite;
                WaitWrite: next_state = done_write ? WaitDelay : WaitWrite;
                WaitDelay: next_state = (ptr == 38) ? Done : ((cnt >= DELAY) ? Write : WaitDelay);
                Done:      next_state = WaitEn;
            endcase
        end
    end

    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) begin
            cnt_clr   = 1'b1;
            ena_write <= 1'b0;
        end else begin
            case (state)
                WaitEn: begin
                    cnt_clr   = 1'b1;
                    ena_write <= 1'b0;
                end
                Write: begin
                    cnt_clr   = 1'b1;
                    data      <= cmd_data_array[ptr];
                    ena_write <= 1'b1;
                end
                WaitWrite: begin
                    ena_write <= 1'b0;
                end
                WaitDelay: begin
                    cnt_clr   = 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) ptr <= 6'd0;
        else if (state == Done) ptr <= 6'd0;
        else if (state == WaitDelay && cnt >= DELAY) ptr <= ptr + 1'b1;
    end

endmodule