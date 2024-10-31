
package mcm_decimal_pkg;

    typedef enum {
        FLOAT_STD_IEEE_754_32,
        FLOAT_STD_IEEE_754_64,
        FLOAT_STD_NONE
    } enum_float_std_t;

    typedef struct packed {
        logic           overflow;
        logic           zero;
        logic           denormalized;
        logic           infinity;
        logic           nan;
    } flags_float_to_fp_t;

    typedef struct packed {
        logic           denormalized;
        logic           zero;
    } flags_fp_to_float_t;

    // parameters for floating point standards (effectively, this set of 
    // functions represents an associative array)
    function automatic integer fun_float_width_exponent(enum_float_std_t float_std);
        case (float_std)
            FLOAT_STD_IEEE_754_32: return 8;
            FLOAT_STD_IEEE_754_64: return 11;
            default: return -1;
        endcase
    endfunction

    function integer fun_float_width_mantissa(enum_float_std_t float_std);
        case (float_std)
            FLOAT_STD_IEEE_754_32: return 23;
            FLOAT_STD_IEEE_754_64: return 52;
            default: return -1;
        endcase
    endfunction

    // (dummy params to get the $pow out of fun_float_exponent_bias. Otherwise 
    // it's not recognized as a constant function - at least by questa - and 
    // thus can't be used for parameters. Tried with `const ref` but parameter 
    // can't bind to that when calling, `function automatic` requires const 
    // arguments, and so on, this solution is what worked)
    localparam FLOAT_IEEE_754_32_EXPONENT_BIAS = $pow(2,7)-1;
    localparam FLOAT_IEEE_754_64_EXPONENT_BIAS = $pow(2,10)-1;
    function integer fun_float_exponent_bias(enum_float_std_t float_std);
        case (float_std)
            FLOAT_STD_IEEE_754_32: return FLOAT_IEEE_754_32_EXPONENT_BIAS;
            FLOAT_STD_IEEE_754_64: return FLOAT_IEEE_754_64_EXPONENT_BIAS;
            default: return -1;
        endcase
    endfunction

    // (returns an integer instead of a bit because the function is meant to 
    // assign to a localparam, which in turn is used in calculations)
    function integer fun_float_leading_bit(enum_float_std_t float_std);
        case (float_std)
            FLOAT_STD_IEEE_754_32: return 1;
            FLOAT_STD_IEEE_754_64: return 1;
            default: return -1;
        endcase
    endfunction

    function integer fun_float_width_mantissa_norm(enum_float_std_t float_std);
        case (float_std)
            FLOAT_STD_IEEE_754_32: return fun_float_width_mantissa(float_std)+1;
            FLOAT_STD_IEEE_754_64: return fun_float_width_mantissa(float_std)+1;
            default: return -1;
        endcase
    endfunction

endpackage
