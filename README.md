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