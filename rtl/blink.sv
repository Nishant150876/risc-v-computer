// blink.sv - 1Hz LED blink demo for Basys 3
// Week 1 checkpoint: verifies the complete toolchain works end-to-end.
// SystemVerilog source -> Vivado synthesis -> bitstream -> physical FPGA.

module blink (
    input  logic clk,    // 100 MHz onboard clock (Basys 3 pin W5)
    output logic led     // LED[0] (Basys 3 pin U16)
);

    // At 100 MHz, half a second = 50,000,000 clock cycles.
    // Toggling the LED every half-second produces a 1 Hz blink.
    localparam int HALF_PERIOD = 50_000_000;

    logic [25:0] counter = '0;
    logic        led_reg = 1'b0;

    always_ff @(posedge clk) begin
        if (counter == HALF_PERIOD - 1) begin
            counter <= '0;
            led_reg <= ~led_reg;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    assign led = led_reg;

endmodule
