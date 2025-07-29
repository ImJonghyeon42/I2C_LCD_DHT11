module debounce (
    input  wire clk,
    input  wire button_in,
    output wire button_out
);
    // -- Parameters --
    // Debounce for ~20ms. 20ms * 100MHz = 2,000,000 ticks. 2^21 = 2,097,152
    localparam DEBOUNCE_MAX = 20_000;

    // -- Internal Registers --
    reg [14:0] debounce_counter = 0;
    reg        button_state = 0;
    reg        button_prev = 0;

    assign button_out = button_state & ~button_prev; // Output a single pulse

    always @(posedge clk) begin
        button_prev <= button_state;

        if (button_in == button_state) begin
            debounce_counter <= 0;
        end else begin
            debounce_counter <= debounce_counter + 1;
            if (debounce_counter >= DEBOUNCE_MAX) begin
                button_state <= ~button_state;
                debounce_counter <= 0;
            end
        end
    end
endmodule