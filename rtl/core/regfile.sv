`timescale 1ns/1ps

module regfile #(
    parameter bit BYPASS = 1'b0
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        we,
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    input  logic [4:0]  raddr1,
    input  logic [4:0]  raddr2,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] regs [0:31];

    // This is the only state writer. Later debug/BIST ownership must mux into
    // this write port rather than add an independent writer.
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int unsigned index = 0; index < 32; index++) begin
                regs[index] <= '0;
            end
        end else if (we && waddr != 5'd0) begin
            regs[waddr] <= wdata;
        end
    end

    always_comb begin
        rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];
        rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];
        // Bypass is deliberately OFF in the single-cycle configuration.
        // During reset a prospective write must not appear on either port.
        if (BYPASS && !rst && we && waddr != 5'd0) begin
            if (raddr1 == waddr) rdata1 = wdata;
            if (raddr2 == waddr) rdata2 = wdata;
        end
    end
endmodule
