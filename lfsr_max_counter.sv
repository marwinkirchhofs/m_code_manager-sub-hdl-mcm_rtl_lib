
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
* !!! TESTED BITWIDTHS !!!
* Honestly, when writing this module, I did not bother seriously setting up 
* a testbench that would test any bitwidth out of [3,168] for somewhat 
* meaningful results (aka to make sure that I did not make a mistake when 
* hand-copying the tap coefficients from the application note table). Until the 
* day when I might do that, use this field to enter BITWIDTH values that you 
* have used in testbenches and that have produced somewhat useful results - as 
* an indicator that most likely those taps are correct.
* 4, 10, 41
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
           51: begin: LCL           localparam int TAP_INDICES [4] = '{35,36,50,51}; end
           52: begin: LCL           localparam int TAP_INDICES [2] = '{49,52}; end
           53: begin: LCL           localparam int TAP_INDICES [4] = '{37,38,52,53}; end
           54: begin: LCL           localparam int TAP_INDICES [4] = '{17,18,53,54}; end
           55: begin: LCL           localparam int TAP_INDICES [2] = '{31,55}; end
           56: begin: LCL           localparam int TAP_INDICES [4] = '{34,35,55,56}; end
           57: begin: LCL           localparam int TAP_INDICES [2] = '{57,50}; end
           58: begin: LCL           localparam int TAP_INDICES [2] = '{39,58}; end
           59: begin: LCL           localparam int TAP_INDICES [4] = '{37,38,58,59}; end
           60: begin: LCL           localparam int TAP_INDICES [2] = '{59,60}; end
           61: begin: LCL           localparam int TAP_INDICES [4] = '{45,46,60,61}; end
           62: begin: LCL           localparam int TAP_INDICES [4] = '{5,6,61,62}; end
           63: begin: LCL           localparam int TAP_INDICES [2] = '{62,63}; end
           64: begin: LCL           localparam int TAP_INDICES [4] = '{60,61,63,64}; end
           65: begin: LCL           localparam int TAP_INDICES [2] = '{47,65}; end
           66: begin: LCL           localparam int TAP_INDICES [4] = '{56,57,65,66}; end
           67: begin: LCL           localparam int TAP_INDICES [4] = '{57,58,66,67}; end
           68: begin: LCL           localparam int TAP_INDICES [2] = '{59,68}; end
           69: begin: LCL           localparam int TAP_INDICES [4] = '{40,42,67,69}; end
           70: begin: LCL           localparam int TAP_INDICES [4] = '{54,55,69,70}; end
           71: begin: LCL           localparam int TAP_INDICES [2] = '{65,71}; end
           72: begin: LCL           localparam int TAP_INDICES [4] = '{19,25,66,72}; end
           73: begin: LCL           localparam int TAP_INDICES [2] = '{48,73}; end
           74: begin: LCL           localparam int TAP_INDICES [4] = '{58,59,73,74}; end
           75: begin: LCL           localparam int TAP_INDICES [4] = '{64,65,74,75}; end
           76: begin: LCL           localparam int TAP_INDICES [4] = '{40,41,75,76}; end
           77: begin: LCL           localparam int TAP_INDICES [4] = '{46,47,76,77}; end
           78: begin: LCL           localparam int TAP_INDICES [4] = '{58,59,77,78}; end
           79: begin: LCL           localparam int TAP_INDICES [2] = '{70,79}; end
           80: begin: LCL           localparam int TAP_INDICES [4] = '{42,43,79,80}; end
           81: begin: LCL           localparam int TAP_INDICES [2] = '{77,81}; end
           82: begin: LCL           localparam int TAP_INDICES [4] = '{44,47,79,82}; end
           83: begin: LCL           localparam int TAP_INDICES [4] = '{37,38,82,83}; end
           84: begin: LCL           localparam int TAP_INDICES [2] = '{71,84}; end
           85: begin: LCL           localparam int TAP_INDICES [4] = '{57,58,84,85}; end
           86: begin: LCL           localparam int TAP_INDICES [4] = '{73,74,85,86}; end
           87: begin: LCL           localparam int TAP_INDICES [2] = '{74,87}; end
           88: begin: LCL           localparam int TAP_INDICES [4] = '{16,17,87,88}; end
           89: begin: LCL           localparam int TAP_INDICES [2] = '{51,89}; end
           90: begin: LCL           localparam int TAP_INDICES [4] = '{71,72,89,90}; end
           91: begin: LCL           localparam int TAP_INDICES [4] = '{7,8,90,91}; end
           92: begin: LCL           localparam int TAP_INDICES [4] = '{79,80,91,92}; end
           93: begin: LCL           localparam int TAP_INDICES [2] = '{91,93}; end
           94: begin: LCL           localparam int TAP_INDICES [2] = '{73,94}; end
           95: begin: LCL           localparam int TAP_INDICES [2] = '{84,95}; end
           96: begin: LCL           localparam int TAP_INDICES [4] = '{47,49,94,96}; end
           97: begin: LCL           localparam int TAP_INDICES [2] = '{91,97}; end
           98: begin: LCL           localparam int TAP_INDICES [2] = '{87,98}; end
           99: begin: LCL           localparam int TAP_INDICES [4] = '{52,54,97,99}; end
          100: begin: LCL           localparam int TAP_INDICES [2] = '{63,100}; end
          101: begin: LCL           localparam int TAP_INDICES [4] = '{94,95,100,101}; end
          102: begin: LCL           localparam int TAP_INDICES [4] = '{35,36,101,102}; end
          103: begin: LCL           localparam int TAP_INDICES [2] = '{94,103}; end
          104: begin: LCL           localparam int TAP_INDICES [4] = '{93,94,103,104}; end
          105: begin: LCL           localparam int TAP_INDICES [2] = '{89,105}; end
          106: begin: LCL           localparam int TAP_INDICES [2] = '{91,106}; end
          107: begin: LCL           localparam int TAP_INDICES [4] = '{42,44,105,107}; end
          108: begin: LCL           localparam int TAP_INDICES [2] = '{77,108}; end
          109: begin: LCL           localparam int TAP_INDICES [4] = '{102,103,108,109}; end
          110: begin: LCL           localparam int TAP_INDICES [4] = '{97,98,109,110}; end
          111: begin: LCL           localparam int TAP_INDICES [2] = '{101,111}; end
          112: begin: LCL           localparam int TAP_INDICES [4] = '{67,69,110,112}; end
          113: begin: LCL           localparam int TAP_INDICES [2] = '{104,113}; end
          114: begin: LCL           localparam int TAP_INDICES [4] = '{32,33,113,114}; end
          115: begin: LCL           localparam int TAP_INDICES [4] = '{100,101,114,115}; end
          116: begin: LCL           localparam int TAP_INDICES [4] = '{45,46,115,116}; end
          117: begin: LCL           localparam int TAP_INDICES [4] = '{97,99,115,117}; end
          118: begin: LCL           localparam int TAP_INDICES [2] = '{85,118}; end
          119: begin: LCL           localparam int TAP_INDICES [2] = '{111,119}; end
          120: begin: LCL           localparam int TAP_INDICES [4] = '{2,9,113,120}; end
          121: begin: LCL           localparam int TAP_INDICES [2] = '{103,121}; end
          122: begin: LCL           localparam int TAP_INDICES [4] = '{62,63,121,122}; end
          123: begin: LCL           localparam int TAP_INDICES [2] = '{121,123}; end
          124: begin: LCL           localparam int TAP_INDICES [2] = '{87,124}; end
          125: begin: LCL           localparam int TAP_INDICES [4] = '{17,18,124,125}; end
          126: begin: LCL           localparam int TAP_INDICES [4] = '{89,90,125,126}; end
          127: begin: LCL           localparam int TAP_INDICES [2] = '{126,127}; end
          128: begin: LCL           localparam int TAP_INDICES [4] = '{99,101,126,128}; end
          129: begin: LCL           localparam int TAP_INDICES [2] = '{124,129}; end
          130: begin: LCL           localparam int TAP_INDICES [2] = '{127,130}; end
          131: begin: LCL           localparam int TAP_INDICES [4] = '{83,84,130,131}; end
          132: begin: LCL           localparam int TAP_INDICES [2] = '{103,132}; end
          133: begin: LCL           localparam int TAP_INDICES [4] = '{81,82,132,133}; end
          134: begin: LCL           localparam int TAP_INDICES [2] = '{77,134}; end
          135: begin: LCL           localparam int TAP_INDICES [2] = '{124,135}; end
          136: begin: LCL           localparam int TAP_INDICES [4] = '{10,11,135,136}; end
          137: begin: LCL           localparam int TAP_INDICES [2] = '{116,137}; end
          138: begin: LCL           localparam int TAP_INDICES [4] = '{130,131,137,138}; end
          139: begin: LCL           localparam int TAP_INDICES [4] = '{131,134,136,139}; end
          140: begin: LCL           localparam int TAP_INDICES [2] = '{111,140}; end
          141: begin: LCL           localparam int TAP_INDICES [4] = '{109,110,140,141}; end
          142: begin: LCL           localparam int TAP_INDICES [2] = '{121,142}; end
          143: begin: LCL           localparam int TAP_INDICES [4] = '{122,123,142,143}; end
          144: begin: LCL           localparam int TAP_INDICES [4] = '{74,75,143,144}; end
          145: begin: LCL           localparam int TAP_INDICES [2] = '{93,145}; end
          146: begin: LCL           localparam int TAP_INDICES [4] = '{86,87,145,146}; end
          147: begin: LCL           localparam int TAP_INDICES [4] = '{109,110,156,147}; end
          148: begin: LCL           localparam int TAP_INDICES [2] = '{121,148}; end
          149: begin: LCL           localparam int TAP_INDICES [4] = '{39,40,148,149}; end
          150: begin: LCL           localparam int TAP_INDICES [2] = '{97,150}; end
          151: begin: LCL           localparam int TAP_INDICES [2] = '{148,151}; end
          152: begin: LCL           localparam int TAP_INDICES [4] = '{86,87,151,152}; end
          153: begin: LCL           localparam int TAP_INDICES [2] = '{152,153}; end
          154: begin: LCL           localparam int TAP_INDICES [4] = '{25,27,152,154}; end
          155: begin: LCL           localparam int TAP_INDICES [4] = '{123,124,154,155}; end
          156: begin: LCL           localparam int TAP_INDICES [4] = '{40,41,155,156}; end
          157: begin: LCL           localparam int TAP_INDICES [4] = '{130,131,156,157}; end
          158: begin: LCL           localparam int TAP_INDICES [4] = '{131,132,157,158}; end
          159: begin: LCL           localparam int TAP_INDICES [2] = '{128,159}; end
          160: begin: LCL           localparam int TAP_INDICES [4] = '{141,142,159,160}; end
          161: begin: LCL           localparam int TAP_INDICES [2] = '{161,143}; end
          162: begin: LCL           localparam int TAP_INDICES [4] = '{74,75,161,162}; end
          163: begin: LCL           localparam int TAP_INDICES [4] = '{103,104,162,163}; end
          164: begin: LCL           localparam int TAP_INDICES [4] = '{150,151,163,164}; end
          165: begin: LCL           localparam int TAP_INDICES [4] = '{134,135,164,165}; end
          166: begin: LCL           localparam int TAP_INDICES [4] = '{127,128,165,166}; end
          167: begin: LCL           localparam int TAP_INDICES [2] = '{161,167}; end
          168: begin: LCL           localparam int TAP_INDICES [4] = '{151,153,166,168}; end
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

