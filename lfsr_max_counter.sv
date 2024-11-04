
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* Parameterizable-length XNOR-based LFSR counter with maximum sequence lengths.  
* Based on Xilinx Application Note XAPP 052. For any bitwidth, the XNOR will be 
* tapped as per the application note (table 3), to provide a maximum sequence 
* length lfsr. The initialization state is all 0's. The maximum supported 
* bitwidth is 168.
*
* INTERFACE:
* * parameters
* :ALL_1S_CIRCUIT: - NOT IMPLEMENTED - If 1, add an extra AND circuit to 
* incorporate the all 1's state into the repeat cycle (see application note 
* figure 1). 
*
* TODO: implement a parameterizable reset
*/

module lfsr_max_counter #(
    parameter               BITWIDTH = 4,
    parameter               ALL_1S_CIRCUIT = 0
) (
    input logic                             clk,
    output logic    [BITWIDTH-1:0]          o_counter = '0
);

    generate begin: gen_check_params
        if (BITWIDTH<3) begin
            $error("Minimum bitwidth is 3");
        end
        if (BITWIDTH>168) begin
            $error("Bitwidth can not exceed 168");
        end
        if (ALL_1S_CIRCUIT == 1) begin
            $error("All 1's option not implemented yet");
        end
    end endgenerate

    // note: for the sake of consistency with the application note and the 
    // literature (according to xilinx), the indices here are human-counting, 
    // not machine-counting. This is corrected for later on when actually 
    // tapping the counter.
    generate
        // !!! notice: TAP_INDICES HAS to be an unpacked array in order for 
        // $size(LCL.TAP_INDICES) to work properly later on. $size doesn't work 
        // (the way we'd want it to) with packed arrays. !!!
        // !!! also: the arrays need to be in ascending order. Otherwise the 
        // tap_cascade assigments in the gen statement below don't work properly 
        // !!!
        case (BITWIDTH)
            3: begin: LCL           localparam int TAP_INDICES [2] = '{2,3}; end
            4: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
            5: begin: LCL           localparam int TAP_INDICES [2] = '{3,5}; end
            6: begin: LCL           localparam int TAP_INDICES [2] = '{5,6}; end
            7: begin: LCL           localparam int TAP_INDICES [2] = '{6,7}; end
            8: begin: LCL           localparam int TAP_INDICES [4] = '{4,5,6,8}; end
            9: begin: LCL           localparam int TAP_INDICES [2] = '{5,9}; end
           10: begin: LCL           localparam int TAP_INDICES [2] = '{7,10}; end
           11: begin: LCL           localparam int TAP_INDICES [2] = '{9,11}; end
           12: begin: LCL           localparam int TAP_INDICES [4] = '{1,4,6,12}; end
           13: begin: LCL           localparam int TAP_INDICES [4] = '{1,3,4,13}; end
           14: begin: LCL           localparam int TAP_INDICES [4] = '{1,3,5,14}; end
           15: begin: LCL           localparam int TAP_INDICES [2] = '{14,15}; end
           16: begin: LCL           localparam int TAP_INDICES [4] = '{4,13,15,16}; end
           17: begin: LCL           localparam int TAP_INDICES [2] = '{14,17}; end
           18: begin: LCL           localparam int TAP_INDICES [2] = '{11,18}; end
           19: begin: LCL           localparam int TAP_INDICES [4] = '{1,2,6,19}; end
           20: begin: LCL           localparam int TAP_INDICES [2] = '{17,20}; end
           21: begin: LCL           localparam int TAP_INDICES [2] = '{19,21}; end
           22: begin: LCL           localparam int TAP_INDICES [2] = '{21,22}; end
           23: begin: LCL           localparam int TAP_INDICES [2] = '{18,23}; end
           24: begin: LCL           localparam int TAP_INDICES [4] = '{17,22,23,24}; end
           25: begin: LCL           localparam int TAP_INDICES [2] = '{22,25}; end
           26: begin: LCL           localparam int TAP_INDICES [4] = '{1,2,6,26}; end
           27: begin: LCL           localparam int TAP_INDICES [4] = '{1,2,5,27}; end
           28: begin: LCL           localparam int TAP_INDICES [2] = '{25,28}; end
           29: begin: LCL           localparam int TAP_INDICES [2] = '{27,29}; end
           30: begin: LCL           localparam int TAP_INDICES [4] = '{1,4,6,30}; end
           31: begin: LCL           localparam int TAP_INDICES [2] = '{28,31}; end
           32: begin: LCL           localparam int TAP_INDICES [4] = '{1,2,22,32}; end
           33: begin: LCL           localparam int TAP_INDICES [2] = '{20,33}; end
           34: begin: LCL           localparam int TAP_INDICES [4] = '{1,2,27,34}; end
           35: begin: LCL           localparam int TAP_INDICES [2] = '{33,35}; end
           36: begin: LCL           localparam int TAP_INDICES [2] = '{25,36}; end
           37: begin: LCL           localparam int TAP_INDICES [6] = '{1,2,3,4,5,37}; end
           38: begin: LCL           localparam int TAP_INDICES [4] = '{1,5,6,38}; end
           39: begin: LCL           localparam int TAP_INDICES [2] = '{35,39}; end
           40: begin: LCL           localparam int TAP_INDICES [4] = '{19,21,38,40}; end
           41: begin: LCL           localparam int TAP_INDICES [2] = '{38,41}; end
           42: begin: LCL           localparam int TAP_INDICES [4] = '{19,20,41,42}; end
           43: begin: LCL           localparam int TAP_INDICES [4] = '{37,38,42,43}; end
           44: begin: LCL           localparam int TAP_INDICES [4] = '{17,18,43,44}; end
           45: begin: LCL           localparam int TAP_INDICES [4] = '{41,42,44,45}; end
           46: begin: LCL           localparam int TAP_INDICES [4] = '{25,26,45,46}; end
           47: begin: LCL           localparam int TAP_INDICES [2] = '{42,47}; end
           48: begin: LCL           localparam int TAP_INDICES [4] = '{20,21,47,48}; end
           49: begin: LCL           localparam int TAP_INDICES [2] = '{40,49}; end
           50: begin: LCL           localparam int TAP_INDICES [4] = '{23,24,49,50}; end
//            51: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            52: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            53: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            54: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            55: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            56: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            57: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            58: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            59: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            60: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            61: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            62: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            63: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            64: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            65: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            66: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            67: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            68: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            69: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            70: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            71: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            72: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            73: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            74: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            75: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            76: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            77: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            78: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            79: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            80: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            81: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            82: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            83: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            84: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            85: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            86: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            87: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            88: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            89: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            90: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            91: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            92: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            93: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            94: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            95: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            96: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            97: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            98: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//            99: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           100: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           101: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           102: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           103: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           104: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           105: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           106: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           107: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           108: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           109: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           110: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           111: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           112: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           113: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           114: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           115: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           116: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           117: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           118: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           119: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           120: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           121: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           122: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           123: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           124: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           125: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           126: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           127: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           128: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           129: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           130: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           131: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           132: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           133: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           134: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           135: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           136: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           137: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           138: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           139: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           141: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           142: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           143: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           144: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           145: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           146: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           147: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           148: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           149: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           150: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           151: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           152: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           153: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           154: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           155: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           156: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           157: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           158: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           159: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           160: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           161: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           162: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           163: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           164: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           165: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           166: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           167: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
//           168: begin: LCL           localparam int TAP_INDICES [2] = '{3,4}; end
            default: begin: LCL     localparam int TAP_INDICES [1] = '{-1}; end
        endcase
    endgenerate

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    logic                               bit_feedback;

    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    genvar i;
    generate begin: gen_taps
        logic [$size(LCL.TAP_INDICES)-1:0] tap_cascade;
        for (i=0; i<$size(LCL.TAP_INDICES); i++) begin
            if (i != $size(LCL.TAP_INDICES)-1) begin
                // (remember -1 to account for human counting in the tap indices)
                assign tap_cascade[i] = ~(o_counter[LCL.TAP_INDICES[i]-1] ^ tap_cascade[i+1]);
            end else begin
                assign tap_cascade[i] = o_counter[LCL.TAP_INDICES[i]-1];
            end
        end
        assign bit_feedback = tap_cascade[0];
    end endgenerate

    always_ff @(posedge clk) begin
        o_counter[0] <= bit_feedback;
        o_counter[BITWIDTH-1:1] <= o_counter[BITWIDTH-2:0];
    end

endmodule

