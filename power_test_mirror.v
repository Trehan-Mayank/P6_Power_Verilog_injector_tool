`timescale 1ns / 1ps

// Generated from .pv file
// Power-aware Verilog

// To enable corruption, uncomment the following line:

// `define DISABLE_CORRUPTION 0


// ============================================
// COPY BELOW INTO YOUR TESTBENCH
// ============================================

// Power signals (define in tb)
// logic VDD;
// logic VDD_1;
// logic VSS;
// logic VSS_1;

// Domain control task (define in tb)
// Usage: domain(1, 2'b10); // value: 00=off, 10=pwr, 01=gnd, 11=both
// task domain(input int num, input bit [1:0] value);
//     if (num == 1) begin VDD = value[1]; VSS = value[0]; end
//     if (num == 2) begin VDD_1 = value[1]; VSS_1 = value[0]; end
// endtask

// ============================================

module top (
    input VDD,
    input VSS,
    input VDD_1,
    input VSS_1,
    input a1,
    input b1,
    input a2,
    input b2,
    output o1,
    output o2
);

    // Supply port description: VDD->power, VSS->ground, VDD_1->power, VSS_1->ground


    leaf_m2091 #() leaf_inst1 (
        .VDD(VDD),
        .VSS(VSS),
        .a(a1),
        .b(b1),
        .o(o1)
    );
    leaf_m1860 #() leaf_inst2 (
        .VDD(VDD_1),
        .VSS(VSS_1),
        .a(a2),
        .b(b2),
        .o(o2)
    );
endmodule

module leaf_m2091 (
    input VDD,
    input VSS,
    input a,
    input b,
    output o
);

    // Supply port description: VDD->VDD, VSS->VSS

    `ifndef DISABLE_CORRUPTION
    assign o = (VDD && !(VSS)) ? a & b : 'x;
    `else
    assign o = a & b;
    `endif
endmodule

module leaf_m1860 (
    input VDD,
    input VSS,
    input a,
    input b,
    output o
);

    // Supply port description: VDD->VDD_1, VSS->VSS_1

    `ifndef DISABLE_CORRUPTION
    assign o = (VDD && !(VSS)) ? a & b : 'x;
    `else
    assign o = a & b;
    `endif
endmodule
