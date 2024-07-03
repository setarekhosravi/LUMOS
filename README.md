FPU Design Project
====================
<div align="justify">

## Assembly.s Explanation
Here is the explaination of RISC-V assembly code:

```
    li          sp,     0x3C00
    addi        gp,     sp,     392
```

This initializes the stack pointer (sp) to 0x3C00 and sets the global pointer (gp) to sp + 392.

```
    flw         f1,     0(sp)
    flw         f2,     4(sp)
```

This starts a loop that loads two floating-point values from memory into f1 and f2 registers.

```
    fmul.s      f10,    f1,     f1
    fmul.s      f20,    f2,     f2
    fadd.s      f30,    f10,    f20
    fsqrt.s     x3,     f30
```

These instructions compute f1^2 + f2^2 and then take the square root of the result.

```
    fadd.s      f0,     f0,     f3
    addi        sp,     sp,     8
    blt         sp,     gp,     loop
````

This adds the result to f0, increments the stack pointer by 8, and loops back if sp < gp.

### More Information

<div align="justify">

It's iterating through pairs of floating-point numbers (which could represent x and y coordinates).
For each pair, it's computing sqrt(x^2 + y^2), which is the formula for the magnitude of a 2D vector or the distance of a point from the origin.
It's accumulating these results in the f0 register.

So, in essence, this code is likely doing one of these tasks:

Calculating the total length of a path defined by a series of 2D points.
Computing the sum of magnitudes for a set of 2D vectors.
Calculating the root mean square (RMS) of a set of 2D points or vectors (though it would need to divide by the count of points at the end to complete the RMS calculation).

The code processes these points/vectors in a loop, starting from memory address 0x3C00 and continuing for 49 iterations (since it adds 8 bytes per iteration and loops 392 bytes in total).

</div>

## Fixed Point Unit

This module implements a Fixed Point Unit with support for addition, subtraction, multiplication, and square root operations.

### Square Root Implementation

The square root calculation uses a non-restoring algorithm implemented as a state machine. Here's how it works:

#### States

* IDLE: Waiting for a square root operation
* INIT: Initializing variables for calculation
* CALC: Performing the square root calculation
* DONE: Calculation complete, result ready

#### Key Variables

* x: The radicand (input number)
* q: The result (square root)
* m: A bitmask used in the calculation
* i: Iteration counter

#### Algorithm

In the INIT state, variables are set up:

* x is set to the input operand
* q is initialized to 0
* m is set to 1 shifted left by (WIDTH - 2) bits
* i is set to (WIDTH + FBITS) / 2, determining the number of iterations


In the CALC state, for each iteration:

If (q | m) <= x, then:

x is updated to x - (q | m)
q is updated to (q >> 1) | m


Otherwise:

q is just right-shifted by 1


m is right-shifted by 2
i is decremented

<div align="justify">

The calculation continues until i reaches 0, then moves to the DONE state
In the DONE state, the result is made available and the state returns to IDLE.
This implementation provides an efficient fixed-point square root calculation.

</div>

### More Information

#### State Machine Details

##### IDLE State

* The module waits here until a square root operation (FPU_SQRT) is requested.
* This state ensures that the square root circuit doesn't consume power when not in use.


##### INIT State

* x_next = operand_1: The input number is loaded into x.
* q_next = 0: The result is initialized to 0.
* m_next = 1 << (WIDTH - 2): Sets the initial bitmask. For a 32-bit number, this would be 0x40000000.
* i_next = (WIDTH + FBITS) >> 1: Calculates the number of iterations. For WIDTH=32 and FBITS=10, this would be 21 iterations.


##### CALC State

* This is where the core algorithm runs.
* The condition (q | m) <= x checks if we can subtract the current test bit without going negative.
* If true, we perform the subtraction and set the corresponding bit in the result.
* The right shift of q and m prepares for the next iteration.
* This process continues for i iterations, ensuring we calculate to the precision of our fixed-point format.


##### DONE State

* Sets root_ready to 1, signaling that the result is available.
* Transitions back to IDLE, ready for the next operation.


#### Fixed-Point Considerations

* The algorithm naturally works with fixed-point numbers because it operates on the bits directly.
* The number of iterations (WIDTH + FBITS) / 2 ensures we calculate enough bits for our fixed-point representation.
* No explicit scaling is needed in the algorithm itself; the result is inherently in the correct fixed-point format.

### Multiplier Implementation

The multiplication is performed using a state machine and a 16x16 bit multiplier module. Here's how it works:

#### States

The multiplier goes through 6 states to complete a multiplication.

#### Key Variables

* a_high, a_low: Upper and lower 16 bits of operand_1
* b_high, b_low: Upper and lower 16 bits of operand_2
* partialProduct1 to partialProduct4: Store results of partial multiplications

#### Features

* Performs 32x32 bit fixed-point multiplication
* Uses a smaller 16x16 bit multiplier to save resources
* Implements a state machine for controlled execution
* Provides a ready signal to indicate when the result is available

### Implementation Details
#### State Machine
The multiplier uses a 6-state machine to control the multiplication process:

* FRST: Initialization
* SEC: Multiply a_low * b_low
* THRD: Multiply a_high * b_low
* FRTH: Multiply a_low * b_high
* FFTH: Multiply a_high * b_high
* FNL: Combine partial products and finalize result

#### Key Components

* multiplierCircuitInput1, multiplierCircuitInput2: Inputs to the 16x16 multiplier
* multiplierCircuitResult: Output from the 16x16 multiplier
* partialProduct1 to partialProduct4: Store results of partial multiplications
* product: 64-bit register to store the final result
* product_ready: Flag to indicate when the multiplication is complete

#### Multiplication Process

The 32-bit operands are split into 16-bit high and low parts.
Four 16x16 multiplications are performed sequentially:

```
a_low * b_low
a_high * b_low
a_low * b_high
a_high * b_high
```


The partial products are combined with appropriate shifts:
```
product <= partialProduct1 + (partialProduct2 << 16) + (partialProduct3 << 16) + (partialProduct4 << 32);
```

The product_ready flag is set to indicate completion.

#### Usage
The multiplier is triggered when the operation input is set to FPU_MUL. The result is available in the product register, with the product_ready flag indicating when it's valid.

#### Performance
The multiplication completes in 6 clock cycles.
The design balances resource usage and performance by utilizing a smaller multiplier multiple times.

### Waveforms
![alt text](https://github.com/setarekhosravi/LUMOS/blob/main/Images/waveform%20(1).png)
![alt text](https://github.com/setarekhosravi/LUMOS/blob/main/Images/waveform%20(2).png)
![alt text](https://github.com/setarekhosravi/LUMOS/blob/main/Images/waveform%20(3).png)
![alt text](https://github.com/setarekhosravi/LUMOS/blob/main/Images/waveform%20(4).png)