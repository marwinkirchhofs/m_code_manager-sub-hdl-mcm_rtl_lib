
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
* point (base 2)
* The resulting total width of the floating point number is 
* (1+FP_WIDTH_INT+FP_WIDTH_FRAC) to account for the sign bit.
* TODO: what the core reports (overflow/underflow etc)
*
* * INTERFACE:
*		[port name]		- [port description]
* * inputs:
* * outputs:
*
* TODO: denormalized numbers
* TODO: special numbers (actually, only 0 I guess)
*/

import mcm_decimal_pkg::*;

module fp_to_float #(
    parameter enum_float_std_t  FLOAT_STD = FLOAT_STD_NONE,
    parameter                   FLOAT_WIDTH_EXPONENT = 8,
    parameter                   FLOAT_WIDTH_MANTISSA = 24,
    parameter                   FLOAT_EXPONENT_BIAS = $pow(2,7)-1,
    parameter                   FLOAT_LEADING_BIT = 1,
    parameter                   FP_WIDTH_INT = 8,
    parameter                   FP_WIDTH_FRAC = 7,
    parameter                   FP_2S_COMPLEMENT = 1,
    localparam FLOAT_WIDTH = 1 + LCL.FLOAT_WIDTH_EXPONENT + LCL.FLOAT_WIDTH_MANTISSA,
    localparam FP_WIDTH = 1 + FP_WIDTH_INT + FP_WIDTH_FRAC
) (
    input logic     [FP_WIDTH-1:0]          i_fp,
    output logic    [FLOAT_WIDTH-1:0]       o_float
//     output logic                            o_overflow,
//     output logic                            o_zero,
//     output logic                            o_denormalized_number,
//     output logic                            o_infinity,
//     output logic                            o_nan
);

    // (in fact, this is a generate statement. You just can't surround it by 
    // a `generate` because then resolving the hierarchical `LCL` doesn't work 
    // anymore. Guess you'd have to then add the gen name to the hierarchical 
    // reference, but I rather just removed the generate)
    case (FLOAT_STD)
        FLOAT_STD_IEEE_754_32: begin: LCL
            localparam FLOAT_WIDTH_EXPONENT = fun_float_width_exponent(FLOAT_STD);
            localparam FLOAT_EXPONENT_BIAS = fun_float_exponent_bias(FLOAT_STD);
            localparam FLOAT_WIDTH_MANTISSA = fun_float_width_mantissa(FLOAT_STD);
            localparam FLOAT_LEADING_BIT = fun_float_leading_bit(FLOAT_STD);
            localparam FLOAT_WIDTH_MANTISSA_NORM = fun_float_width_mantissa_norm(FLOAT_STD);
        end
        FLOAT_STD_IEEE_754_64: begin: LCL
            localparam FLOAT_WIDTH_EXPONENT = fun_float_width_exponent(FLOAT_STD_IEEE_754_64);
            localparam FLOAT_EXPONENT_BIAS = fun_float_exponent_bias(FLOAT_STD);
            localparam FLOAT_WIDTH_MANTISSA = fun_float_width_mantissa(FLOAT_STD);
            localparam FLOAT_LEADING_BIT = fun_float_leading_bit(FLOAT_STD);
            localparam FLOAT_WIDTH_MANTISSA_NORM = fun_float_width_mantissa_norm(FLOAT_STD);
        end
        default: begin: LCL
            localparam FLOAT_WIDTH_EXPONENT = FLOAT_WIDTH_EXPONENT;
            localparam FLOAT_EXPONENT_BIAS = FLOAT_EXPONENT_BIAS;
            localparam FLOAT_WIDTH_MANTISSA = FLOAT_WIDTH_MANTISSA;
            localparam FLOAT_LEADING_BIT = FLOAT_LEADING_BIT;
            localparam FLOAT_WIDTH_MANTISSA_NORM = FLOAT_WIDTH_MANTISSA + FLOAT_LEADING_BIT;
        end
    endcase

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

    logic   [LCL.FLOAT_WIDTH_MANTISSA-1:0]      float_mantissa;
    logic   [LCL.FLOAT_WIDTH_EXPONENT-1:0]      float_exponent;
    logic                                       float_sign_bit;
    logic   [FP_WIDTH_INT-1:0]                  fp_int;
    logic   [FP_WIDTH_FRAC-1:0]                 fp_frac;
    logic                                       fp_sign_bit;

    logic   [$clog2(FP_WIDTH-1)-1:0]            fp_leading_zeros;
    logic   [FP_WIDTH-2:0]                      fp_no_sign;
    // helper for type cast to avoid signal width warning
    typedef logic [FP_WIDTH-2:0] fp_no_sign_t;

    // variable to hold the mantissa extended by the hidden leading bit if there 
    // is one
    logic   [LCL.FLOAT_WIDTH_MANTISSA_NORM-1:0] float_mantissa_norm;

    logic   [$clog2(LCL.FLOAT_WIDTH_MANTISSA)-1:0]      shift_mantissa_bits;
    logic                                               shift_mantissa_dir;


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
    assign float_exponent = LCL.FLOAT_EXPONENT_BIAS +
                            FP_WIDTH_INT - fp_leading_zeros - LCL.FLOAT_LEADING_BIT;

//     always_comb begin: proc_float_mantissa
    generate begin: gen_float_mantissa
        logic [FP_WIDTH-2:0] float_mantissa_interm;
        // (same trick as in the float_to_fp module: Instead of dynamically 
        // selecting bits from fp_no_sign, just shift it out until the lsb/msb 
        // is correct, and then fill up or crop the rest depending on signal 
        // widths)
        if (LCL.FLOAT_WIDTH_MANTISSA >= (FP_WIDTH-1)) begin
            // 0-pad from right-hand side
            assign float_mantissa = {fp_no_sign<<(fp_leading_zeros + LCL.FLOAT_LEADING_BIT),
                            {(LCL.FLOAT_WIDTH_MANTISSA-(FP_WIDTH-1)){1'b0}}};
        end else begin
            // crop to size (interm necessary because with some tools you 
            // apparently can't first shift and then slice from the result)
            assign float_mantissa_interm = (fp_no_sign<<(fp_leading_zeros + LCL.FLOAT_LEADING_BIT));
            assign float_mantissa = float_mantissa_interm[(FP_WIDTH-2) -: LCL.FLOAT_WIDTH_MANTISSA];
        end
    end endgenerate

    assign float_sign_bit = fp_sign_bit;

    assign o_float = {float_sign_bit, float_exponent, float_mantissa};
    

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule

