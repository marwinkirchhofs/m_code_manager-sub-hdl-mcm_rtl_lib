
package mcm_math_pkg;

    function int accum_tree_get_latency(int num_operands, int accumulate_en, int out_reg);
        // TODO: num_levels depend on the implementation type, once there are 
        // different implementations
        // (basically clog4 - just that doesn't exist)
        // TODO: might be unstable, if e.g. ln(4**2) is just not exactly =2*ln(4)
        // . If that happens, I'll have to introduce some epsilon, because 
        // otherwise it can happen that you actually report a wrong latency, 
        // which would be terrible.
        int num_levels = int'($ceil($ln(num_operands)/$ln(4)));
        int combined_out_reg = accumulate_en || out_reg ? 1 : 0;

        return num_levels * (1+combined_out_reg);
    endfunction

endpackage // mcm_math_pkg
