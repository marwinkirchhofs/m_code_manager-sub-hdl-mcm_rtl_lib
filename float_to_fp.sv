
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* Arbitrarily parameterizable converter for floating point (base 2) to 
* fixed-point numbers
* The resulting total width of the floating point number is 
* (1+FP_WIDTH_INT+FP_WIDTH_FRAC) to account for the sign bit.
* The core does report an overflow into the fixed-point integer bits (but no 
* form of underflow).
* The core also reports special floating point numbers as per the IEEE754 
* standard: positive/negative zero, denormalized numbers, infinities, NaN (by 
* means of the respective o_* bits). Zero and denormalized numbers will be 
* converted into their fixed-point counterparts, while for infinities and NaN 
* o_fp is meaningless. Note that the detection is hard-coded, and not 
* parameterizable. Therefore regardless of whether or not FLOAT_STD is set 
* "None", the all 0's and all 1's exponents will be detected as special numbers.
*
* INTERFACE:
* * parameters:
*   :FLOAT_STD: setting to FLOAT_STD_IEEE_754_32 or FLOAT_STD_IEEE_754_64 overwrites any other 
*   "FLOAT_WIDTH_*" parameters and selects the respective ieee floating point 
*   format
*   :FP_2S_COMPLEMENT: if set to 1, fixed-point result will use 2's complement 
*   (standard signed int otherwise)
*   :FLOAT_LEADING_BIT: whether or not a leading 1 is added to the mantissa 
*   (make sure to only set to either 0 or 1)
*
* * ports:
*   :o_overflow: signalizes an overflow in o_fp (meaning that the input number 
*   was too large to be represented by FP_WIDTH_INT bits)
* 
* TODO: provide input registers, if I had to guess I'd say that the fanout from 
* the input mantissa to the dynamic shift LUTs can become pretty ugly
* TODO: FP_2S_COMPLEMENT=0 is untested (in fact, only tested with the ieee 
* formats)
*/

import mcm_decimal_pkg::*;

module float_to_fp #(
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
    input logic     [FLOAT_WIDTH-1:0]       i_float,
    output logic    [FP_WIDTH-1:0]          o_fp,
    output logic                            o_overflow,
    output logic                            o_zero,
    output logic                            o_denormalized_number,
    output logic                            o_infinity,
    output logic                            o_nan
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
            localparam FLOAT_WIDTH_EXPONENT = fun_float_width_exponent(FLOAT_STD);
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


    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    logic   [LCL.FLOAT_WIDTH_MANTISSA-1:0]      float_mantissa;
    logic   [LCL.FLOAT_WIDTH_EXPONENT-1:0]      float_exponent;
    logic                                       float_sign_bit;

    logic   [FP_WIDTH-2:0]                      fp_no_sign;
    // helper for type cast to avoid signal width warning
    typedef logic [FP_WIDTH-2:0] fp_no_sign_t;

    // variable to hold the mantissa extended by the hidden leading bit if there 
    // is one
    logic   [LCL.FLOAT_WIDTH_MANTISSA_NORM-1:0] float_mantissa_norm;

    assign float_mantissa = i_float[LCL.FLOAT_WIDTH_MANTISSA-1:0];
    assign float_exponent = i_float[LCL.FLOAT_WIDTH_MANTISSA +: LCL.FLOAT_WIDTH_EXPONENT];
    assign float_sign_bit = i_float[FLOAT_WIDTH-1];

    logic   [$clog2(LCL.FLOAT_WIDTH_MANTISSA)-1:0]      shift_mantissa_bits;
    logic                                               shift_mantissa_dir;


    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    generate begin: gen_float_mantissa_norm
        if (FLOAT_LEADING_BIT == 1) begin
            assign float_mantissa_norm = {1'b1, float_mantissa};
        end else begin
            assign float_mantissa_norm = float_mantissa;
        end
    end endgenerate

    always_comb begin: proc_float_mantissa_prepare_shift
        // note: shift_mantissa_bits is the *absolute value* of the 
        // bias-corrected float_exponent - the amount of bits that the mantissa 
        // needs to be shifted into *or* out of the fixed point integer part
        if (float_exponent >= LCL.FLOAT_EXPONENT_BIAS) begin
            shift_mantissa_bits = float_exponent - LCL.FLOAT_EXPONENT_BIAS;
            shift_mantissa_dir = 1'b1;
        end else begin
            shift_mantissa_bits = LCL.FLOAT_EXPONENT_BIAS - float_exponent;
            shift_mantissa_dir = 1'b0;
        end
    end

    generate begin: gen_overflow
        // - when determining an overflow need to take into account whether or 
        // not there is a silint leading bit in the mantissa, because if there 
        // is that takes away the first FP_WIDTH_INT bit from shifting
        if (LCL.FLOAT_LEADING_BIT == 1) begin
            assign overflow = shift_mantissa_bits > (FP_WIDTH_INT-1);
        end else begin
            assign overflow = shift_mantissa_bits > (FP_WIDTH_INT);
        end
    end endgenerate

    always_comb begin
        // quick note for the mantissa shifting/slicing: In theory, you have to 
        // position a dynamically changing slice width of the mantissa to 
        // a dynamically changing index in fp_no_sign. Since that is invalid with 
        // systemverilog operators, the solution is to do it the other way 
        // around: Chop the mantissa to the width of fp_no_sign, and then shift 
        // it "out" into the opposite direction, which effectively is a valid 
        // means for dynamically slicing off a portion of a vector.
        if (shift_mantissa_dir == 1'b1) begin
            // case 1: mantissa gets left-shifted - no need to check if the 
            // shift fits into the integer range, because if it doesn't, the 
            // result is useless whatever you do, and we have the o_overflow 
            // flag for that
            if (LCL.FLOAT_WIDTH_MANTISSA_NORM >= (FP_WIDTH-1)) begin
                fp_no_sign = float_mantissa_norm[LCL.FLOAT_WIDTH_MANTISSA_NORM-1 -: FP_WIDTH-1]>>
                                (FP_WIDTH_INT-LCL.FLOAT_LEADING_BIT-shift_mantissa_bits);
            end else begin
                // (if mantissa is narrower than the non-signed fixed-point, 
                // instead of cropping it, extend it to that size before 
                // shifting)
                fp_no_sign = ({ float_mantissa_norm,
                                {(FP_WIDTH-1-LCL.FLOAT_WIDTH_MANTISSA_NORM){1'b0}}})>>
                                (FP_WIDTH_INT-LCL.FLOAT_LEADING_BIT-shift_mantissa_bits);
            end
        end else begin
            // ugly shift, quick explanation: first cut float_mantissa_norm to 
            // only the FP_WIDTH_FRAC+LCL.FLOAT_LEADING_BIT bits (because 
            // anything below that is below the fp precision anyways), then 
            // right-shift that according to what we need

            // (testing for FLOAT_WIDTH_MANTISSA_NORM >= 
            // FP_WIDTH_FRAC+FLOAT_LEADING_BIT is equivalent)
            if (LCL.FLOAT_WIDTH_MANTISSA >= FP_WIDTH_FRAC) begin
                fp_no_sign = fp_no_sign_t'(
                        float_mantissa_norm[
                            LCL.FLOAT_WIDTH_MANTISSA_NORM-1 -: FP_WIDTH_FRAC+LCL.FLOAT_LEADING_BIT]
                            >>shift_mantissa_bits);
            end else begin
                fp_no_sign = fp_no_sign_t'(
                        ({float_mantissa_norm, {(FP_WIDTH_FRAC-LCL.FLOAT_WIDTH_MANTISSA){1'b1}}})
                            >>shift_mantissa_bits);
            end
        end
    end
    
    always_comb begin: proc_special_cases
        // logic of the output machine: Whenever there is a meaningful value to 
        // apply to o_fp, do so, otherwise set it to '0. Next to that, for any 
        // special case that occurs, regardless of whether or not it produces 
        // a meaningful o_fp, raise the corresponding (and leave it to the 
        // parent core to process those as they wish)
        o_fp                    = '0;
        o_zero                  = 1'b0;
        o_denormalized_number   = 1'b0;
        o_infinity              = 1'b0;
        o_nan                   = 1'b0;
        case (float_exponent)
            {(LCL.FLOAT_WIDTH_EXPONENT){1'b0}}: begin
                if (float_mantissa == '0) begin
                    // ALL 0'S - FLOATING POINT DEFINED 0
                    o_zero = 1'b1;
                    if (FP_2S_COMPLEMENT) begin
                        // for 2's complement no need to differentiate between 
                        // positive and negative 0, there is only one
                        o_fp = '0;
                    end else begin
                        o_fp = {float_sign_bit, {(FP_WIDTH-1){1'b0}}};
                    end
                end else begin
                    // DENORMALIZED NUMBER (leading 0's in mantissa)
                    if (LCL.FLOAT_WIDTH_MANTISSA >= FP_WIDTH_FRAC) begin
                        o_fp = {float_sign_bit, {FP_WIDTH_INT{1'b0}},
                                float_mantissa[LCL.FLOAT_WIDTH_MANTISSA-1 -: FP_WIDTH_FRAC]};
                    end else begin
                        o_fp = {float_sign_bit, {FP_WIDTH_INT{1'b0}},
                                float_mantissa, {(FP_WIDTH_FRAC-LCL.FLOAT_WIDTH_MANTISSA){1'b0}}};
                    end
                    o_denormalized_number = 1'b1;
                end
            end
            {(LCL.FLOAT_WIDTH_EXPONENT){1'b1}}: begin
                if (float_mantissa == '0) begin
                    // INFINITY
                    o_infinity = 1'b1;
                end else begin
                    // NAN
                    o_nan = 1'b1;
                end
            end
            default: begin
                // apply 2's complement if necessary
                if (FP_2S_COMPLEMENT) begin
                    o_fp = float_sign_bit == 1'b1 ? ~{1'b0, fp_no_sign} + 1 : {1'b0, fp_no_sign};
                end else begin
                    o_fp = {float_sign_bit, fp_no_sign};
                end
            end
        endcase
    end

    // when is there an overflow? Of course if we have to shift more than there 
    // is space, but: That would also be the case for the reserved exponents 
    // (all 1's and all 0's). Thus exclude those cases.
    assign o_overflow =
                (shift_mantissa_bits > (FP_WIDTH_INT-LCL.FLOAT_LEADING_BIT)) &
                !(float_exponent == '0) & !(float_exponent == '1);

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule

