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
            `FPU_ADD    : begin result = operand_1 + operand_2; ready = 1; end
            `FPU_SUB    : begin result = operand_1 - operand_2; ready = 1; end
            `FPU_MUL    : begin result = product[WIDTH + FBITS - 1 : FBITS]; ready = product_ready; end
            `FPU_SQRT   : begin result = root; ready = root_ready; end
            default     : begin result = 'bz; ready = 0; end
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
    reg [WIDTH - 1 : 0] rem;

    reg root_ready;

    // here is the code for sqrt module
    // reference: https://projectf.io/posts/square-root-in-verilog/

    reg [WIDTH - 1 : 0] x, x_next;              
    reg [WIDTH - 1 : 0] q, q_next;              
    reg [WIDTH + 1 : 0] ac, ac_next;            
    reg [WIDTH + 1 : 0] test_res;   


    reg valid;
    reg start;
    reg busy;
    

    localparam ITER = (WIDTH + FBITS) >> 1;     
    reg [4 : 0] i = 0;                              

    
    always @(*) begin
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    end
    
    always @(posedge clk)  begin
        if (start) begin
            busy <= 1;
            valid <= 0;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, operand_1, 2'b0};
        end else if (busy) begin
            if (i == ITER-1) begin  // we're done
                busy <= 0;
                valid <= 1;
                root <= q_next;
                rem <= ac_next[WIDTH+1:2];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
            end
        end
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

    reg [2 : 0] mult_stage;
    reg [2 : 0] mult_stage_next;
    reg [15:0] a_high, a_low, b_high, b_low;

    // define mul stages
    localparam FRST = 3'b000, SEC = 3'b001, THRD = 3'b010, FRTH = 3'b011, FFTH = 3'b100, FNL = 3'b101;   

    always @(posedge clk) 
    begin
        if (operation == `FPU_MUL)  mult_stage <= mult_stage_next;
        else                        mult_stage <= 'b0;
    end

    always @(*) 
    begin
        mult_stage_next <= 0;
        case (mult_stage)
            FRST : begin
                product_ready <= 0;

                multiplierCircuitInput1 <= 0;
                multiplierCircuitInput2 <= 0;

                partialProduct1 <= 0;
                partialProduct2 <= 0;
                partialProduct3 <= 0;
                partialProduct4 <= 0;

                a_high <= operand_1[31:16];
                a_low <= operand_1[15:0];
                b_high <= operand_2[31:16];
                b_low <= operand_2[15:0];

                mult_stage_next <= SEC;
            end 
            SEC : begin // Multiply a_low * b_low
                multiplierCircuitInput1 <= a_low;
                multiplierCircuitInput2 <= b_low;
                partialProduct1 <= multiplierCircuitResult;
                mult_stage_next <= THRD;
            end
            THRD : begin // Store result and multiply a_high * b_low
                multiplierCircuitInput1 <= a_high;
                multiplierCircuitInput2 <= b_low;
                partialProduct2 <= multiplierCircuitResult;
                mult_stage_next <= FRTH;
            end
            FRTH : begin // Store result and multiply a_low * b_high
                multiplierCircuitInput1 <= a_low;
                multiplierCircuitInput2 <= b_high;
                partialProduct3 <= multiplierCircuitResult;
                mult_stage_next <= FFTH;
            end
            FFTH : begin // Store result and multiply a_high * b_high
                multiplierCircuitInput1 <= a_high;
                multiplierCircuitInput2 <= b_high;
                partialProduct4 <= multiplierCircuitResult;
                mult_stage_next <= FNL;
            end
            FNL : begin // Store final partial product and combine results
                product <= partialProduct1 + (partialProduct2 << 16) + (partialProduct3 << 16) + (partialProduct4 << 32);
                mult_stage_next <= FRST;
                product_ready <= 1;
            end

            default: mult_stage_next <= FRST;
        endcase    
    end
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