
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
* form of underflow)
*
* INTERFACE:
* * parameters:
*   :FLOAT_STD: setting to "IEEE_754_32" or "IEEE_754_64" overwrites any other 
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
* TODO: special numbers (all 0's, all 1's)
*/

module float_to_fp #(
    parameter                   FLOAT_STD = "None",
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
        "IEEE_754_32": begin: LCL
            localparam FLOAT_WIDTH_EXPONENT = 8;
            localparam FLOAT_EXPONENT_BIAS = $pow(2,7)-1;
            localparam FLOAT_WIDTH_MANTISSA = 23;
            localparam FLOAT_LEADING_BIT = 1;
            localparam FLOAT_WIDTH_MANTISSA_NORM = FLOAT_WIDTH_MANTISSA + 1;
        end
        "IEEE_754_64": begin: LCL
            localparam FLOAT_WIDTH_EXPONENT = 11;
            localparam FLOAT_EXPONENT_BIAS = $pow(2,10)-1;
            localparam FLOAT_WIDTH_MANTISSA = 52;
            localparam FLOAT_LEADING_BIT = 1;
            localparam FLOAT_WIDTH_MANTISSA_NORM = FLOAT_WIDTH_MANTISSA + 1;
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
    logic   [FP_WIDTH_INT-1:0]                  fp_int;
    logic   [FP_WIDTH_FRAC-1:0]                 fp_frac;

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

    // TODO: if that works, put the variable above (and if it doesn't, this 
    // block is obsolete)
    logic [FP_WIDTH-2:0]                fp_interm;
    typedef logic [FP_WIDTH-2:0] temp_t;
    always_comb begin
        // quick note for the mantissa shifting/slicing: In theory, you have to 
        // position a dynamically changing slice width of the mantissa to 
        // a dynamically changing index in fp_interm. Since that is invalid with 
        // systemverilog operators, the solution is to do it the other way 
        // around: Chop the mantissa to the width of fp_interm, and then shift 
        // it "out" into the opposite direction, which effectively is a valid 
        // means for dynamically slicing off a portion of a vector.
        if (shift_mantissa_dir == 1'b1) begin
            // case 1: mantissa gets left-shifted - no need to check if the 
            // shift fits into the integer range, because if it doesn't, the 
            // result is useless whatever you do, and we have the o_overflow 
            // flag for that
            fp_interm = float_mantissa_norm[LCL.FLOAT_WIDTH_MANTISSA_NORM-1 -: FP_WIDTH-1]>>
                            (FP_WIDTH_INT-LCL.FLOAT_LEADING_BIT-shift_mantissa_bits);
            // TODO: handle if the mantissa is narrower than FP_WIDTH-1 (you 
            // have to left-justify before shifting in that case)
        end else begin
            // ugly shift, quick explanation: first cut float_mantissa_norm to 
            // only the FP_WIDTH_FRAC+LCL.FLOAT_LEADING_BIT bits (because 
            // anything below that is below the fp precision anyways), then 
            // right-sheft that according to what we need
            fp_interm = temp_t'(
                    float_mantissa_norm[
                            LCL.FLOAT_WIDTH_MANTISSA_NORM-1 -: FP_WIDTH_FRAC+LCL.FLOAT_LEADING_BIT]
                            >>shift_mantissa_bits);
            // TODO: handle if the mantissa is narrower than fractional bits 
            // + leading bit
        end
    end
    
    // TODO: this might only apply to IEEE standards
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
                    // TODO: cover if the mantissa is shorter than the 
                    // fractional width
                    o_fp = {float_sign_bit, {FP_WIDTH_INT{1'b0}},
                            float_mantissa[LCL.FLOAT_WIDTH_MANTISSA-1 -: FP_WIDTH_FRAC]};
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
                    o_fp = float_sign_bit == 1'b1 ? ~{1'b0, fp_interm} + 1 : {1'b0, fp_interm};
                end else begin
                    o_fp = {float_sign_bit, fp_interm};
                end
            end
        endcase
    end

    assign o_overflow =
        (shift_mantissa_bits > (FP_WIDTH_INT-LCL.FLOAT_LEADING_BIT)) &
        ~o_denormalized_number & ~o_zero;

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule

