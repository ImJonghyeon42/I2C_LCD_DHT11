module DHT11(
    input reset, clk1Mhz,
    inout dht11_data,
    output [3:0] humidity10, humidity0,
    output [3:0] temperature10, temperature0,
    output reg [7:0] led_bar
);

    reg [7:0] humidity, temperature;
    assign humidity10    = humidity / 10;
    assign humidity0     = humidity % 10;
    assign temperature10 = temperature / 10;
    assign temperature0  = temperature % 10;

    localparam S_IDLE        = 3'b000,
               S_LOW_18MS    = 3'b001,
               S_HIGH_20US   = 3'b010,
               S_LOW_80US    = 3'b011,
               S_HIGH_80US   = 3'b100,
               S_READ_DATA   = 3'b101;

    reg [2:0] state, next_state;
    reg [21:0] count_usec;
    reg count_usec_e;
    reg dht11_data_oe, dht_buffer;
    reg [5:0] data_count;
    reg [39:0] temp_data;
    reg [1:0] bit_state; // 2鍮꾪듃濡� read_state ��泥�

    wire dht_nedge, dht_pedge;
    assign dht11_data = dht11_data_oe ? dht_buffer : 1'bz;

    // 1us 移댁슫�꽣
    always @(negedge clk1Mhz or negedge reset) begin
        if (!reset) count_usec <= 0;
        else if (count_usec_e) count_usec <= count_usec + 1'b1;
        else count_usec <= 0;
    end

    // FSM �긽�깭 �젅吏��뒪�꽣
    always @(negedge clk1Mhz or negedge reset) begin
        if (!reset) state <= S_IDLE;
        else state <= next_state;
    end

    // �뿣吏� 寃�異쒓린 �씤�뒪�꽩�뒪
    edge_detector ed_dec(
        .clk(clk1Mhz),
        .cp_in(dht11_data),
        .reset(reset),
        .n_edge(dht_nedge),
        .p_edge(dht_pedge)
    );

    // FSM 議고빀 �끉由� 諛� �뜲�씠�꽣 泥섎━
    always @(posedge clk1Mhz or negedge reset) begin
        if (!reset) begin
            count_usec_e   <= 1'b0;
            next_state     <= S_IDLE;
            dht11_data_oe  <= 1'b0;
            dht_buffer     <= 1'bz;
            data_count     <= 0;
            temp_data      <= 0;
            humidity       <= 0;
            temperature    <= 0;
            led_bar        <= 8'hFF;
            bit_state      <= 2'b00;
        end else begin
            case (state)
                S_IDLE: begin
                    led_bar <= 8'hFE;
                    dht11_data_oe <= 1'b1;
                    dht_buffer    <= 1'b1;
                    count_usec_e  <= 1'b1;
                    if (count_usec >= 22'd3_000_000) begin // 3珥� ��湲�
                        next_state <= S_LOW_18MS;
                        count_usec_e <= 1'b0;
                    end
                end
                S_LOW_18MS: begin
                    led_bar <= 8'hFD;
                    dht11_data_oe <= 1'b1;
                    dht_buffer    <= 1'b0;
                    count_usec_e  <= 1'b1;
                    if (count_usec >= 22'd18_000) begin // 18ms
                        next_state <= S_HIGH_20US;
                        count_usec_e <= 1'b0;
                    end
                end
                S_HIGH_20US: begin
                    led_bar <= 8'hFB;
                    dht11_data_oe <= 1'b1;
                    dht_buffer    <= 1'b1;
                    count_usec_e  <= 1'b1;
                    if (count_usec >= 22'd20) begin // 20us
                        dht11_data_oe <= 1'b0; // Release line
                        next_state <= S_LOW_80US;
                        count_usec_e <= 1'b0;
                    end
                end
                S_LOW_80US: begin
                    led_bar <= 8'hF7;
                    count_usec_e <= 1'b1;
                    if (dht_pedge) begin
                        next_state <= S_HIGH_80US;
                        count_usec_e <= 1'b0;
                    end
                end
                S_HIGH_80US: begin
                    led_bar <= 8'hEF;
                    count_usec_e <= 1'b1;
                    if (dht_nedge) begin
                        next_state <= S_READ_DATA;
                        count_usec_e <= 1'b0;
                        data_count <= 0;
                        temp_data  <= 0;
                        bit_state  <= 2'b00;
                    end
                end
                S_READ_DATA: begin
                    led_bar <= 8'hDF;
                    // 鍮꾪듃 �떒�쐞 �뜲�씠�꽣 �닔�떊
                    case (bit_state)
                        2'b00: if (dht_pedge) begin // start of bit
                            count_usec_e <= 1'b1;
                            bit_state <= 2'b01;
                        end
                        2'b01: if (dht_nedge) begin // end of bit
                            data_count <= data_count + 1'b1;
                            temp_data <= {temp_data[38:0], (count_usec > 40)}; // 0: '0', 1: '1'
                            count_usec_e <= 1'b0;
                            bit_state <= 2'b00;
                        end
                    endcase
                    if (data_count == 6'd40) begin
                        next_state <= S_IDLE;
                        // 泥댄겕�꽟 寃�利�
                        if (temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8] == temp_data[7:0]) begin
                            humidity    <= temp_data[39:32];
                            temperature <= temp_data[23:16];
                        end
                    end
                end
                default: next_state <= S_IDLE;
            endcase
        end
    end
endmodule
