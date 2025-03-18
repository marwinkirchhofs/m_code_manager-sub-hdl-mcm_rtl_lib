
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* Arbitrarily parameterizable converter for fixed-point numbers to floating 
* point (base 2). It explicitly supports IEEE-754 32-bit and 64-bit formats (see 
* parameter :FLOAT_STD:). Notice that regardless of whether or not a specific 
* standard is chosen, special numbers (exponent all 1's or all 0's) are treated 
* as per the IEEE standard.
* The resulting total width of the floating point number is 
* (1+FP_WIDTH_INT+FP_WIDTH_FRAC) to account for the sign bit.
* The core reports a zero and a denormalized number.
*
* INTERFACE:
* * parameters:
*   -> see float_to_fp module, the parameters are the same and behave in the 
*   same way
*
* IMPLEMENTATION:
* (some vivado implementation results - isolated synthesis/implementation 
* (module directly surrounded by input and output registers)
* * 27bit fp (1/1/25 sign/int/frac), FLOAT_STD_IEEE_754_64
*     * Ultrascale+ (xcvu37p-fsvh2892-2L-e)
*         * 450MHz
*           * default strategies: WNS -0.016ns, WHS 0.041ns, 193LUTs, (63FFs)
*           * synth flow_perfoptimized_high, impl 
*           performance_explorePostRoutePhysOpt: WNS 0.070ns, WHS 0.026ns, 191LUTs, 
*           (63FFs)
*         * 465MHz (and 500MHz)
*           * synth flow_perfoptimized_high, impl 
*           performance_explorePostRoutePhysOpt: failed (WNS 0.236ns @500MHz)
*         * 460MHz
*           * synth flow_perfoptimized_high, impl 
*           performance_explorePostRoutePhysOpt: WNS 0.034ns, WHS 0.063ns, 
*           192LUTs, (63FFs)
*     * 7series (xc7z020clg484-1), 150MHz
*         * default strategies: WNS -0.365ns, WHS -0.575ns, 193LUTs, (63FFs)
*         * synth flow_perfoptimized_high, impl 
*         performance_explorePostRoutePhysOpt: WNS 0.003ns, WHS 0.308ns, 192LUTs, 
*         (63FFs)
*
* TODO: untested with any non-ieee formats
* TODO: add parameterizable input registers
*/

import mcm_decimal_pkg::*;

module fp_to_float #(
    parameter enum_float_std_t  FLOAT_STD = FLOAT_STD_NONE,
    parameter                   FLOAT_WIDTH_EXPONENT = 8,
    parameter                   FLOAT_WIDTH_MANTISSA = 24,
    parameter                   FLOAT_EXPONENT_BIAS = int'($pow(2,7)-1),
    parameter                   FLOAT_LEADING_BIT = 1,
    parameter                   FP_WIDTH_INT = 8,
    parameter                   FP_WIDTH_FRAC = 7,
    parameter                   FP_2S_COMPLEMENT = 1,
    localparam LCL_FLOAT_WIDTH_EXPONENT =       (FLOAT_STD == FLOAT_STD_NONE) ?
                                                FLOAT_WIDTH_EXPONENT :
                                                fun_float_width_exponent(FLOAT_STD),
    localparam LCL_FLOAT_EXPONENT_BIAS =        (FLOAT_STD == FLOAT_STD_NONE) ?
                                                FLOAT_EXPONENT_BIAS :
                                                fun_float_exponent_bias(FLOAT_STD),
    localparam LCL_FLOAT_WIDTH_MANTISSA =       (FLOAT_STD == FLOAT_STD_NONE) ?
                                                FLOAT_WIDTH_MANTISSA :
                                                fun_float_width_mantissa(FLOAT_STD),
    localparam LCL_FLOAT_LEADING_BIT =          (FLOAT_STD == FLOAT_STD_NONE) ?
                                                FLOAT_LEADING_BIT :
                                                fun_float_leading_bit(FLOAT_STD),
    localparam LCL_FLOAT_WIDTH_MANTISSA_NORM =  (FLOAT_STD == FLOAT_STD_NONE) ?
                                                FLOAT_WIDTH_MANTISSA + FLOAT_LEADING_BIT :
                                                fun_float_width_mantissa_norm(FLOAT_STD),
    localparam FLOAT_WIDTH = 1 + LCL_FLOAT_WIDTH_EXPONENT + LCL_FLOAT_WIDTH_MANTISSA,
    localparam FP_WIDTH = 1 + FP_WIDTH_INT + FP_WIDTH_FRAC
) (
    input logic     [FP_WIDTH-1:0]          i_fp,
    output logic    [FLOAT_WIDTH-1:0]       o_float,
    output flags_fp_to_float_t              o_flags
);

    // find-first-set function (counting from msb)
    function logic [$clog2(FP_WIDTH-1)-1:0] fun_ffs(logic [FP_WIDTH-2:0] vec_in);
        int count;
        for (int count=FP_WIDTH-2; count>=0; count--) begin
            if (vec_in[count] == 1'b1) begin
                return (FP_WIDTH-2)-count;
            end
        end
        return (FP_WIDTH-1);
    endfunction


    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    logic   [LCL_FLOAT_WIDTH_MANTISSA-1:0]      float_mantissa;
    logic   [LCL_FLOAT_WIDTH_EXPONENT-1:0]      float_exponent;
    logic                                       float_sign_bit;
    logic   [FLOAT_WIDTH-1:0]                   float_denormalized;
    logic   [FP_WIDTH_INT-1:0]                  fp_int;
    logic   [FP_WIDTH_FRAC-1:0]                 fp_frac;
    logic                                       fp_sign_bit;

    logic   [$clog2(FP_WIDTH-1)-1:0]            fp_leading_zeros;
    logic   [FP_WIDTH-2:0]                      fp_no_sign;


    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    // decompose the fixed-point number and resolve 2's complement
    assign fp_sign_bit = i_fp[FP_WIDTH-1];
    generate begin: gen_2s_compl_resolve
        if (FP_2S_COMPLEMENT) begin
            assign fp_no_sign = fp_sign_bit==1'b1 ? (~i_fp[FP_WIDTH-2:0])+1 : i_fp[FP_WIDTH-2:0];
        end else begin
            assign fp_no_sign = i_fp[FP_WIDTH-2:0];
        end
    end endgenerate
    assign fp_int = fp_no_sign[FP_WIDTH-2:FP_WIDTH_FRAC];
    assign fp_frac = fp_no_sign[FP_WIDTH_FRAC-1:0];

    assign fp_leading_zeros = fun_ffs(fp_no_sign);

    // (remember that if there is a leading bit, that will be eliminated when 
    // setting the mantissa, so deduct that from the shift)
    assign float_exponent = LCL_FLOAT_EXPONENT_BIAS +
                            FP_WIDTH_INT - fp_leading_zeros - LCL_FLOAT_LEADING_BIT;

    generate begin: gen_float_mantissa
        logic [FP_WIDTH-2:0] float_mantissa_interm;
        // (same trick as in the float_to_fp module: Instead of dynamically 
        // selecting bits from fp_no_sign, just shift it out until the lsb/msb 
        // is correct, and then fill up or crop the rest depending on signal 
        // widths)
        if (LCL_FLOAT_WIDTH_MANTISSA >= (FP_WIDTH-1)) begin
            // 0-pad from right-hand side
            assign float_mantissa = {fp_no_sign<<(fp_leading_zeros + LCL_FLOAT_LEADING_BIT),
                            {(LCL_FLOAT_WIDTH_MANTISSA-(FP_WIDTH-1)){1'b0}}};
        end else begin
            // crop to size (interm necessary because with some tools you 
            // apparently can't first shift and then slice from the result)
            assign float_mantissa_interm = (fp_no_sign<<(fp_leading_zeros + LCL_FLOAT_LEADING_BIT));
            assign float_mantissa = float_mantissa_interm[(FP_WIDTH-2) -: LCL_FLOAT_WIDTH_MANTISSA];
        end
    end endgenerate

    assign float_sign_bit = fp_sign_bit;

    generate begin: gen_float_denormalized
        if (LCL_FLOAT_WIDTH_MANTISSA > FP_WIDTH_FRAC) begin
            assign float_denormalized = {float_sign_bit, {LCL_FLOAT_WIDTH_EXPONENT{1'b0}},
                        fp_frac, {(LCL_FLOAT_WIDTH_MANTISSA-FP_WIDTH_FRAC){1'b0}}};
        end else begin
            assign float_denormalized = {float_sign_bit, {LCL_FLOAT_WIDTH_EXPONENT{1'b0}},
                // TODO: figure out why here it was FLOAT_WIDTH_MANTISSA, and 
                // not LCL.FLOAT_WIDTH_MANTISSA
//                         fp_frac[FP_WIDTH_FRAC-1 -: FLOAT_WIDTH_MANTISSA]};
                        fp_frac[FP_WIDTH_FRAC-1 -: LCL_FLOAT_WIDTH_MANTISSA]};
        end
    end endgenerate

    always_comb begin: proc_output_float
        o_flags.denormalized = 1'b0;
        o_flags.zero = 1'b0;
        // TODO: if you can turn that as much as possible of that if chain into 
        // a case statement for better synthesizability

        // (FP_WIDTH_INT needs to be on the right hand side although it's 
        // unintuitive because you can't have negative numbers in the comparison 
        // since fp_leading_zeros is not a signed datatype)
        if ({fp_int, fp_frac} == '0) begin
            o_float = {float_sign_bit, {FLOAT_WIDTH-1{1'b0}}};
            o_flags.zero = 1'b1;
        end else if (fp_leading_zeros+LCL_FLOAT_LEADING_BIT >=
                        LCL_FLOAT_EXPONENT_BIAS+FP_WIDTH_INT) begin
            o_float = float_denormalized;
            o_flags.denormalized = 1'b1;
        end else begin
            o_float = {float_sign_bit, float_exponent, float_mantissa};
        end

    end
    
endmodule

