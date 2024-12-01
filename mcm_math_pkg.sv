
package mcm_math_pkg;

    localparam                      DSP48E2_A_WIDTH = 30;
    localparam                      DSP48E2_B_WIDTH = 18;
    localparam                      DSP48E2_C_WIDTH = 48;
    localparam                      DSP48E2_D_WIDTH = 27;
    localparam                      DSP48E2_P_WIDTH = 48;

    /*
    * Reverting to stupid binning implementation because questa thinks this is 
    * not a constant function, due to the use of system function (if I remove 
    * ceil() and ln(), it stops complaining. From everything I can see, by the 
    * LRM the function is fine because you could also use ceil() and ln() in 
    * a constant expression (as we are doing all the time with clog2()). Well, 
    * there is no way of doing this in a general way without using logarithm.  
    * Leaving the comment here as a warning. If you figured out why I'm wrong, 
    * or convinced questa that this is indeed fine, let me know.
    */
//     function int accum_tree_get_latency(int num_operands, int accumulate_en, int out_reg);
//         // TODO: num_levels depend on the implementation type, once there are 
//         // different implementations
//         // (basically clog4 - just that doesn't exist)
//         // TODO: might be unstable, if e.g. ln(4**2) is just not exactly =2*ln(4)
//         // . If that happens, I'll have to introduce some epsilon, because 
//         // otherwise it can happen that you actually report a wrong latency, 
//         // which would be terrible.
//         automatic int num_levels = ($ceil($ln(num_operands)/$ln(4)));
//         automatic int combined_out_reg = (accumulate_en || out_reg) ? 1 : 0;
// 
//         return num_levels * (1+combined_out_reg);
//     endfunction
    function int accum_tree_get_num_levels(int num_operands);

        automatic int num_levels = 1;

        if (num_operands > 256) begin
$error("This function does not support more than 256 operands. (Feel free to extend it accordingly)");
        end

        if (num_operands > 64) begin
            num_levels = 4;
        end else if (num_operands > 16) begin
            num_levels = 3;
        end else if (num_operands > 4) begin
            num_levels = 2;
        end else begin
            num_levels = 1;
        end
        return num_levels;
    endfunction

    function int accum_tree_get_latency(
            int num_operands, int accumulate_en, int out_reg, int interm_reg);
        automatic int combined_out_reg;
        automatic int num_levels = accum_tree_get_num_levels(num_operands);
        automatic int latency_levels;
        automatic int latency_interm_reg;

        combined_out_reg = (accumulate_en || out_reg) ? 1 : 0;

        // latency_interm_reg: contribution caused by intermediary out registers 
        // (thus additionally to the one cycle that every level always causes)
        if (num_levels > 0) begin
            latency_interm_reg = (num_levels-1) * (interm_reg);
        end else begin
            latency_interm_reg = 0;
        end
        // one cycle because every level has a DSP cascade, on top of that 
        // intermediary registers
        latency_levels = num_levels + latency_interm_reg;

//         return num_levels * (1+combined_out_reg);
        return num_levels + combined_out_reg;
    endfunction

    /*
    * round up to the next power of 4 - again with respect to the fact that 
    * apparently questa does not allow system function calls in constant 
    * functions.
    */
    function int accum_tree_get_num_operands_pow4(int num_operands);

        automatic int num_operands_pow4;

        if (num_operands > 256) begin
$error("This function does not support more than 256 operands. (Feel free to extend it accordingly)");
        end

        if (num_operands > 64) begin
            num_operands_pow4 = 256;
        end else if (num_operands > 16) begin
            num_operands_pow4 = 64;
        end else if (num_operands > 4) begin
            num_operands_pow4 = 16;
        end else begin
            num_operands_pow4 = 4;
        end
        return num_operands_pow4;
    endfunction

endpackage // mcm_math_pkg
