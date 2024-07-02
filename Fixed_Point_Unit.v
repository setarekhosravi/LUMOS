`include "Defines.vh"

module Fixed_Point_Unit 
#(
    parameter WIDTH = 32,
    parameter FBITS = 10
)
(
    input wire clk,
    input wire reset,
    
    input wire [WIDTH - 1 : 0] operand_1,
    input wire [WIDTH - 1 : 0] operand_2,
    
    input wire [ 1 : 0] operation,

    output reg [WIDTH - 1 : 0] result,
    output reg ready
);

    always @(*)
    begin
        case (operation)
            `FPU_ADD    : begin result <= operand_1 + operand_2; ready <= 1; end
            `FPU_SUB    : begin result <= operand_1 - operand_2; ready <= 1; end
            `FPU_MUL    : begin result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= product_ready; end
            `FPU_SQRT   : begin result <= root; ready <= root_ready; end
            default     : begin result <= 'bz; ready <= 0; end
        endcase
    end

    always @(posedge reset)
    begin
        if (reset)  ready = 0;
        else        ready = 'bz;
    end
    // ------------------- //
    // Square Root Circuit //
    // ------------------- //
    reg [WIDTH - 1 : 0] root;
    reg root_ready;

        // Square root calculation
        reg [WIDTH-1:0] x, x_next;  // radicand
        reg [WIDTH-1:0] q, q_next;  // result
        reg [WIDTH-1:0] m, m_next;  // bitmask
        reg [5:0] i, i_next;        // iteration counter
        reg [2:0] state, next_state;

        localparam IDLE = 3'd0, INIT = 3'd1, CALC = 3'd2, DONE = 3'd3;

        always @(posedge clk or posedge reset) begin
            if (reset) begin
                state <= IDLE;
                x <= 0;
                q <= 0;
                m <= 0;
                i <= 0;
                root_ready <= 0;
            end else begin
                state <= next_state;
                x <= x_next;
                q <= q_next;
                m <= m_next;
                i <= i_next;
            end
        end

        always @(*) begin
            next_state = state;
            x_next = x;
            q_next = q;
            m_next = m;
            i_next = i;
            root = q;
            root_ready = 0;

            case (state)
                IDLE: begin
                    if (operation == `FPU_SQRT) begin
                        next_state = INIT;
                    end
                end

                INIT: begin
                    x_next = operand_1;
                    q_next = 0;
                    m_next = 1 << (WIDTH - 2);
                    i_next = (WIDTH + FBITS) >> 1;
                    next_state = CALC;
                end

                CALC: begin
                    if (i == 0) begin
                        next_state = DONE;
                    end else begin
                        if ((q | m) <= x) begin
                            x_next = x - (q | m);
                            q_next = (q >> 1) | m;
                        end else begin
                            q_next = q >> 1;
                        end
                        m_next = m >> 2;
                        i_next = i - 1;
                    end
                end

                DONE: begin
                    root_ready = 1;
                    next_state = IDLE;
                end

                default: next_state = IDLE;
            endcase
        end

    // ------------------ //
    // Multiplier Circuit //
    // ------------------ //   
    reg [64 - 1 : 0] product;
    reg product_ready;

    reg     [15 : 0] multiplierCircuitInput1;
    reg     [15 : 0] multiplierCircuitInput2;
    wire    [31 : 0] multiplierCircuitResult;

    Multiplier multiplier_circuit
    (
        .operand_1(multiplierCircuitInput1),
        .operand_2(multiplierCircuitInput2),
        .product(multiplierCircuitResult)
    );

    reg     [31 : 0] partialProduct1;
    reg     [31 : 0] partialProduct2;
    reg     [31 : 0] partialProduct3;
    reg     [31 : 0] partialProduct4;

        /*
         *  Describe Your 32-bit Multiplier Circuit Here.
         */
         
endmodule

module Multiplier
(
    input wire [15 : 0] operand_1,
    input wire [15 : 0] operand_2,

    output reg [31 : 0] product
);

    always @(*)
    begin
        product <= operand_1 * operand_2;
    end
endmodule