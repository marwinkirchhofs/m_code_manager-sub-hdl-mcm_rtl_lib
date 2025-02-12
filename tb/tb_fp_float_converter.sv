`timescale 1ns/1ps

/*
* testbench depends on the util_pkg from
* https://github.com/marwinkirchhofs/m_code_manager-sub-hdl-sim_util_pkg
*/

import fp_float_converter_sim_pkg::*;
import mcm_decimal_pkg::*;
import util_pkg::*;

module tb_fp_float_converter;

localparam                      FLOAT_STD = FLOAT_STD_IEEE_754_64;
localparam                      FP_WIDTH_INT = 7;
localparam                      FP_WIDTH_FRAC = 8;
localparam                      FP_2S_COMPLEMENT = 1;

localparam                      CLK_PERIOD = 10;
localparam                      RST_CYCLES = 6;
localparam                      RST_ACTIVE = RST_ACTIVE_LOW;

//----------------------------
// CLOCK/RESET
//----------------------------

logic                           clk;

initial begin
    clk <= 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

ifc_rst #(CLK_PERIOD) if_rst (clk);
cls_rst_ctrl #(RST_ACTIVE) rst_ctrl;

//----------------------------
// SUBMODULES
//----------------------------

cls_agent_fp_float_converter agent_fp_float_converter;
ifc_fp_float_converter if_dut(clk);

logic [63:0] float_dut_out;
logic [63:0] float_dut_in;
// why +1 -1 ? FP_WIDTH_INT and FP_WIDTH_FRAC do not contain the sign bit
logic [(FP_WIDTH_INT+FP_WIDTH_FRAC+1)-1:0] fp_dut_connect;
// necessary explicit conversion from logic to real. output has shown to be 
// nonsense otherwise, I don't exactly know why, but this way it works 
// consistently, just do it
assign if_dut.num_dut_out = $bitstoreal(float_dut_out);
// (iirc this second conversion is actually optional, but doesn't hurt to be 
// consistent)
assign float_dut_in = $realtobits(if_dut.num_dut_in);

// DUT MODULES
float_to_fp #(
    .FLOAT_STD              (FLOAT_STD),
    .FP_WIDTH_INT           (FP_WIDTH_INT),
    .FP_WIDTH_FRAC          (FP_WIDTH_FRAC)
) inst_float_to_fp (
    .i_float                (float_dut_in),
    .o_fp                   (fp_dut_connect),
    .o_flags                ()  // TODO
);
fp_to_float #(
    .FLOAT_STD              (FLOAT_STD),
    .FP_WIDTH_INT           (FP_WIDTH_INT),
    .FP_WIDTH_FRAC          (FP_WIDTH_FRAC)
) inst_fp_to_float (
    .i_fp                   (fp_dut_connect),
    .o_float                (float_dut_out),
    .o_flags                ()  // TODO
);

//----------------------------
// OPERATION
//----------------------------

initial begin
    $timeformat(-9, 1, "ns", 3);

//     rst_ctrl = new(if_rst);
    agent_fp_float_converter = new(if_dut);

    $display("here");
// 
//     rst_ctrl.init();
//     rst_ctrl.trigger(RST_CYCLES);

    agent_fp_float_converter.run();
    
    $stop;
end

endmodule
