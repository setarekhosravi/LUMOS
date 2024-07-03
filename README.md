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

### SQRT 
pass

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
![alt text]()