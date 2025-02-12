`timescale 1ns/1ps

interface ifc_fp_float_converter (
        input clk
);

    real num_dut_in;
    real num_dut_out;

    clocking cb @(posedge clk);
        default input #0.7 output #0.3;
        output num_dut_in;
        input num_dut_out;
    endclocking

endinterface
