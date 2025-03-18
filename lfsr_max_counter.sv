
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

/*
* hold a set of lfsr tap indices -> num_indices is necessary because depending 
* on bitwidth, there are between 2 and 6 valid indices, but the array is 
* fixed-size
*/
typedef struct {
    int         num_indices;
    int         indices [6];
} tap_indices_t;

module lfsr_max_counter #(
    parameter               BITWIDTH = 4,
    parameter               ALL_1S_CIRCUIT = 0,
    // tap indices 1-indexed, for consistency with xilinx documented (indexing 
    // is corrected when applying the taps)
    // !!! the valid part of the arrays needs to be in ascending order.  
    // Otherwise the tap_cascade assigments in the gen statement below don't 
    // work properly !!!
    localparam tap_indices_t TAP_INDICES =
        BITWIDTH == 3 ?     '{num_indices: 2, indices: '{2,3,-1,-1,-1,-1}} :
        BITWIDTH == 4 ?     '{num_indices: 2, indices: '{3,4,-1,-1,-1,-1}} :
        BITWIDTH == 5 ?     '{num_indices: 2, indices: '{3,5,-1,-1,-1,-1}} :
        BITWIDTH == 6 ?     '{num_indices: 2, indices: '{5,6,-1,-1,-1,-1}} :
        BITWIDTH == 7 ?     '{num_indices: 2, indices: '{6,7,-1,-1,-1,-1}} :
        BITWIDTH == 8 ?     '{num_indices: 4, indices: '{4,5,6,8,-1,-1}} :
        BITWIDTH == 9 ?     '{num_indices: 2, indices: '{5,9,-1,-1,-1,-1}} :
        BITWIDTH == 10 ?    '{num_indices: 2, indices: '{7,10,-1,-1,-1,-1}} :
        BITWIDTH == 11 ?    '{num_indices: 2, indices: '{9,11,-1,-1,-1,-1}} :
        BITWIDTH == 12 ?    '{num_indices: 4, indices: '{1,4,6,12,-1,-1}} :
        BITWIDTH == 13 ?    '{num_indices: 4, indices: '{1,3,4,13,-1,-1}} :
        BITWIDTH == 14 ?    '{num_indices: 4, indices: '{1,3,5,14,-1,-1}} :
        BITWIDTH == 15 ?    '{num_indices: 2, indices: '{14,15,-1,-1,-1,-1}} :
        BITWIDTH == 16 ?    '{num_indices: 4, indices: '{4,13,15,16,-1,-1}} :
        BITWIDTH == 17 ?    '{num_indices: 2, indices: '{14,17,-1,-1,-1,-1}} :
        BITWIDTH == 18 ?    '{num_indices: 2, indices: '{11,18,-1,-1,-1,-1}} :
        BITWIDTH == 19 ?    '{num_indices: 4, indices: '{1,2,6,19,-1,-1}} :
        BITWIDTH == 20 ?    '{num_indices: 2, indices: '{17,20,-1,-1,-1,-1}} :
        BITWIDTH == 21 ?    '{num_indices: 2, indices: '{19,21,-1,-1,-1,-1}} :
        BITWIDTH == 22 ?    '{num_indices: 2, indices: '{21,22,-1,-1,-1,-1}} :
        BITWIDTH == 23 ?    '{num_indices: 2, indices: '{18,23,-1,-1,-1,-1}} :
        BITWIDTH == 24 ?    '{num_indices: 4, indices: '{17,22,23,24,-1,-1}} :
        BITWIDTH == 25 ?    '{num_indices: 2, indices: '{22,25,-1,-1,-1,-1}} :
        BITWIDTH == 26 ?    '{num_indices: 4, indices: '{1,2,6,26,-1,-1}} :
        BITWIDTH == 27 ?    '{num_indices: 4, indices: '{1,2,5,27,-1,-1}} :
        BITWIDTH == 28 ?    '{num_indices: 2, indices: '{25,28,-1,-1,-1,-1}} :
        BITWIDTH == 29 ?    '{num_indices: 2, indices: '{27,29,-1,-1,-1,-1}} :
        BITWIDTH == 30 ?    '{num_indices: 4, indices: '{1,4,6,30,-1,-1}} :
        BITWIDTH == 31 ?    '{num_indices: 2, indices: '{28,31,-1,-1,-1,-1}} :
        BITWIDTH == 32 ?    '{num_indices: 4, indices: '{1,2,22,32,-1,-1}} :
        BITWIDTH == 33 ?    '{num_indices: 2, indices: '{20,33,-1,-1,-1,-1}} :
        BITWIDTH == 34 ?    '{num_indices: 4, indices: '{1,2,27,34,-1,-1}} :
        BITWIDTH == 35 ?    '{num_indices: 2, indices: '{33,35,-1,-1,-1,-1}} :
        BITWIDTH == 36 ?    '{num_indices: 2, indices: '{25,36,-1,-1,-1,-1}} :
        BITWIDTH == 37 ?    '{num_indices: 6, indices: '{1,2,3,4,5,37}} :
        BITWIDTH == 38 ?    '{num_indices: 4, indices: '{1,5,6,38,-1,-1}} :
        BITWIDTH == 39 ?    '{num_indices: 2, indices: '{35,39,-1,-1,-1,-1}} :
        BITWIDTH == 40 ?    '{num_indices: 4, indices: '{19,21,38,40,-1,-1}} :
        BITWIDTH == 41 ?    '{num_indices: 2, indices: '{38,41,-1,-1,-1,-1}} :
        BITWIDTH == 42 ?    '{num_indices: 4, indices: '{19,20,41,42,-1,-1}} :
        BITWIDTH == 43 ?    '{num_indices: 4, indices: '{37,38,42,43,-1,-1}} :
        BITWIDTH == 44 ?    '{num_indices: 4, indices: '{17,18,43,44,-1,-1}} :
        BITWIDTH == 45 ?    '{num_indices: 4, indices: '{41,42,44,45,-1,-1}} :
        BITWIDTH == 46 ?    '{num_indices: 4, indices: '{25,26,45,46,-1,-1}} :
        BITWIDTH == 47 ?    '{num_indices: 2, indices: '{42,47,-1,-1,-1,-1}} :
        BITWIDTH == 48 ?    '{num_indices: 4, indices: '{20,21,47,48,-1,-1}} :
        BITWIDTH == 49 ?    '{num_indices: 2, indices: '{40,49,-1,-1,-1,-1}} :
        BITWIDTH == 50 ?    '{num_indices: 4, indices: '{23,24,49,50,-1,-1}} :
        BITWIDTH == 51 ?    '{num_indices: 4, indices: '{35,36,50,51,-1,-1}} :
        BITWIDTH == 52 ?    '{num_indices: 2, indices: '{49,52,-1,-1,-1,-1}} :
        BITWIDTH == 53 ?    '{num_indices: 4, indices: '{37,38,52,53,-1,-1}} :
        BITWIDTH == 54 ?    '{num_indices: 4, indices: '{17,18,53,54,-1,-1}} :
        BITWIDTH == 55 ?    '{num_indices: 2, indices: '{31,55,-1,-1,-1,-1}} :
        BITWIDTH == 56 ?    '{num_indices: 4, indices: '{34,35,55,56,-1,-1}} :
        BITWIDTH == 57 ?    '{num_indices: 2, indices: '{57,50,-1,-1,-1,-1}} :
        BITWIDTH == 58 ?    '{num_indices: 2, indices: '{39,58,-1,-1,-1,-1}} :
        BITWIDTH == 59 ?    '{num_indices: 4, indices: '{37,38,58,59,-1,-1}} :
        BITWIDTH == 60 ?    '{num_indices: 2, indices: '{59,60,-1,-1,-1,-1}} :
        BITWIDTH == 61 ?    '{num_indices: 4, indices: '{45,46,60,61,-1,-1}} :
        BITWIDTH == 62 ?    '{num_indices: 4, indices: '{5,6,61,62,-1,-1}} :
        BITWIDTH == 63 ?    '{num_indices: 2, indices: '{62,63,-1,-1,-1,-1}} :
        BITWIDTH == 64 ?    '{num_indices: 4, indices: '{60,61,63,64,-1,-1}} :
        BITWIDTH == 65 ?    '{num_indices: 2, indices: '{47,65,-1,-1,-1,-1}} :
        BITWIDTH == 66 ?    '{num_indices: 4, indices: '{56,57,65,66,-1,-1}} :
        BITWIDTH == 67 ?    '{num_indices: 4, indices: '{57,58,66,67,-1,-1}} :
        BITWIDTH == 68 ?    '{num_indices: 2, indices: '{59,68,-1,-1,-1,-1}} :
        BITWIDTH == 69 ?    '{num_indices: 4, indices: '{40,42,67,69,-1,-1}} :
        BITWIDTH == 70 ?    '{num_indices: 4, indices: '{54,55,69,70,-1,-1}} :
        BITWIDTH == 71 ?    '{num_indices: 2, indices: '{65,71,-1,-1,-1,-1}} :
        BITWIDTH == 72 ?    '{num_indices: 4, indices: '{19,25,66,72,-1,-1}} :
        BITWIDTH == 73 ?    '{num_indices: 2, indices: '{48,73,-1,-1,-1,-1}} :
        BITWIDTH == 74 ?    '{num_indices: 4, indices: '{58,59,73,74,-1,-1}} :
        BITWIDTH == 75 ?    '{num_indices: 4, indices: '{64,65,74,75,-1,-1}} :
        BITWIDTH == 76 ?    '{num_indices: 4, indices: '{40,41,75,76,-1,-1}} :
        BITWIDTH == 77 ?    '{num_indices: 4, indices: '{46,47,76,77,-1,-1}} :
        BITWIDTH == 78 ?    '{num_indices: 4, indices: '{58,59,77,78,-1,-1}} :
        BITWIDTH == 79 ?    '{num_indices: 2, indices: '{70,79,-1,-1,-1,-1}} :
        BITWIDTH == 80 ?    '{num_indices: 4, indices: '{42,43,79,80,-1,-1}} :
        BITWIDTH == 81 ?    '{num_indices: 2, indices: '{77,81,-1,-1,-1,-1}} :
        BITWIDTH == 82 ?    '{num_indices: 4, indices: '{44,47,79,82,-1,-1}} :
        BITWIDTH == 83 ?    '{num_indices: 4, indices: '{37,38,82,83,-1,-1}} :
        BITWIDTH == 84 ?    '{num_indices: 2, indices: '{71,84,-1,-1,-1,-1}} :
        BITWIDTH == 85 ?    '{num_indices: 4, indices: '{57,58,84,85,-1,-1}} :
        BITWIDTH == 86 ?    '{num_indices: 4, indices: '{73,74,85,86,-1,-1}} :
        BITWIDTH == 87 ?    '{num_indices: 2, indices: '{74,87,-1,-1,-1,-1}} :
        BITWIDTH == 88 ?    '{num_indices: 4, indices: '{16,17,87,88,-1,-1}} :
        BITWIDTH == 89 ?    '{num_indices: 2, indices: '{51,89,-1,-1,-1,-1}} :
        BITWIDTH == 90 ?    '{num_indices: 4, indices: '{71,72,89,90,-1,-1}} :
        BITWIDTH == 91 ?    '{num_indices: 4, indices: '{7,8,90,91,-1,-1}} :
        BITWIDTH == 92 ?    '{num_indices: 4, indices: '{79,80,91,92,-1,-1}} :
        BITWIDTH == 93 ?    '{num_indices: 2, indices: '{91,93,-1,-1,-1,-1}} :
        BITWIDTH == 94 ?    '{num_indices: 2, indices: '{73,94,-1,-1,-1,-1}} :
        BITWIDTH == 95 ?    '{num_indices: 2, indices: '{84,95,-1,-1,-1,-1}} :
        BITWIDTH == 96 ?    '{num_indices: 4, indices: '{47,49,94,96,-1,-1}} :
        BITWIDTH == 97 ?    '{num_indices: 2, indices: '{91,97,-1,-1,-1,-1}} :
        BITWIDTH == 98 ?    '{num_indices: 2, indices: '{87,98,-1,-1,-1,-1}} :
        BITWIDTH == 99 ?    '{num_indices: 4, indices: '{52,54,97,99,-1,-1}} :
        BITWIDTH == 100 ?   '{num_indices: 2, indices: '{63,100,-1,-1,-1,-1}} :
        BITWIDTH == 101 ?   '{num_indices: 4, indices: '{94,95,100,101,-1,-1}} :
        BITWIDTH == 102 ?   '{num_indices: 4, indices: '{35,36,101,102,-1,-1}} :
        BITWIDTH == 103 ?   '{num_indices: 2, indices: '{94,103,-1,-1,-1,-1}} :
        BITWIDTH == 104 ?   '{num_indices: 4, indices: '{93,94,103,104,-1,-1}} :
        BITWIDTH == 105 ?   '{num_indices: 2, indices: '{89,105,-1,-1,-1,-1}} :
        BITWIDTH == 106 ?   '{num_indices: 2, indices: '{91,106,-1,-1,-1,-1}} :
        BITWIDTH == 107 ?   '{num_indices: 4, indices: '{42,44,105,107,-1,-1}} :
        BITWIDTH == 108 ?   '{num_indices: 2, indices: '{77,108,-1,-1,-1,-1}} :
        BITWIDTH == 109 ?   '{num_indices: 4, indices: '{102,103,108,109,-1,-1}} :
        BITWIDTH == 110 ?   '{num_indices: 4, indices: '{97,98,109,110,-1,-1}} :
        BITWIDTH == 111 ?   '{num_indices: 2, indices: '{101,111,-1,-1,-1,-1}} :
        BITWIDTH == 112 ?   '{num_indices: 4, indices: '{67,69,110,112,-1,-1}} :
        BITWIDTH == 113 ?   '{num_indices: 2, indices: '{104,113,-1,-1,-1,-1}} :
        BITWIDTH == 114 ?   '{num_indices: 4, indices: '{32,33,113,114,-1,-1}} :
        BITWIDTH == 115 ?   '{num_indices: 4, indices: '{100,101,114,115,-1,-1}} :
        BITWIDTH == 116 ?   '{num_indices: 4, indices: '{45,46,115,116,-1,-1}} :
        BITWIDTH == 117 ?   '{num_indices: 4, indices: '{97,99,115,117,-1,-1}} :
        BITWIDTH == 118 ?   '{num_indices: 2, indices: '{85,118,-1,-1,-1,-1}} :
        BITWIDTH == 119 ?   '{num_indices: 2, indices: '{111,119,-1,-1,-1,-1}} :
        BITWIDTH == 120 ?   '{num_indices: 4, indices: '{2,9,113,120,-1,-1}} :
        BITWIDTH == 121 ?   '{num_indices: 2, indices: '{103,121,-1,-1,-1,-1}} :
        BITWIDTH == 122 ?   '{num_indices: 4, indices: '{62,63,121,122,-1,-1}} :
        BITWIDTH == 123 ?   '{num_indices: 2, indices: '{121,123,-1,-1,-1,-1}} :
        BITWIDTH == 124 ?   '{num_indices: 2, indices: '{87,124,-1,-1,-1,-1}} :
        BITWIDTH == 125 ?   '{num_indices: 4, indices: '{17,18,124,125,-1,-1}} :
        BITWIDTH == 126 ?   '{num_indices: 4, indices: '{89,90,125,126,-1,-1}} :
        BITWIDTH == 127 ?   '{num_indices: 2, indices: '{126,127,-1,-1,-1,-1}} :
        BITWIDTH == 128 ?   '{num_indices: 4, indices: '{99,101,126,128,-1,-1}} :
        BITWIDTH == 129 ?   '{num_indices: 2, indices: '{124,129,-1,-1,-1,-1}} :
        BITWIDTH == 130 ?   '{num_indices: 2, indices: '{127,130,-1,-1,-1,-1}} :
        BITWIDTH == 131 ?   '{num_indices: 4, indices: '{83,84,130,131,-1,-1}} :
        BITWIDTH == 132 ?   '{num_indices: 2, indices: '{103,132,-1,-1,-1,-1}} :
        BITWIDTH == 133 ?   '{num_indices: 4, indices: '{81,82,132,133,-1,-1}} :
        BITWIDTH == 134 ?   '{num_indices: 2, indices: '{77,134,-1,-1,-1,-1}} :
        BITWIDTH == 135 ?   '{num_indices: 2, indices: '{124,135,-1,-1,-1,-1}} :
        BITWIDTH == 136 ?   '{num_indices: 4, indices: '{10,11,135,136,-1,-1}} :
        BITWIDTH == 137 ?   '{num_indices: 2, indices: '{116,137,-1,-1,-1,-1}} :
        BITWIDTH == 138 ?   '{num_indices: 4, indices: '{130,131,137,138,-1,-1}} :
        BITWIDTH == 139 ?   '{num_indices: 4, indices: '{131,134,136,139,-1,-1}} :
        BITWIDTH == 140 ?   '{num_indices: 2, indices: '{111,140,-1,-1,-1,-1}} :
        BITWIDTH == 141 ?   '{num_indices: 4, indices: '{109,110,140,141,-1,-1}} :
        BITWIDTH == 142 ?   '{num_indices: 2, indices: '{121,142,-1,-1,-1,-1}} :
        BITWIDTH == 143 ?   '{num_indices: 4, indices: '{122,123,142,143,-1,-1}} :
        BITWIDTH == 144 ?   '{num_indices: 4, indices: '{74,75,143,144,-1,-1}} :
        BITWIDTH == 145 ?   '{num_indices: 2, indices: '{93,145,-1,-1,-1,-1}} :
        BITWIDTH == 146 ?   '{num_indices: 4, indices: '{86,87,145,146,-1,-1}} :
        BITWIDTH == 147 ?   '{num_indices: 4, indices: '{109,110,156,147,-1,-1}} :
        BITWIDTH == 148 ?   '{num_indices: 2, indices: '{121,148,-1,-1,-1,-1}} :
        BITWIDTH == 149 ?   '{num_indices: 4, indices: '{39,40,148,149,-1,-1}} :
        BITWIDTH == 150 ?   '{num_indices: 2, indices: '{97,150,-1,-1,-1,-1}} :
        BITWIDTH == 151 ?   '{num_indices: 2, indices: '{148,151,-1,-1,-1,-1}} :
        BITWIDTH == 152 ?   '{num_indices: 4, indices: '{86,87,151,152,-1,-1}} :
        BITWIDTH == 153 ?   '{num_indices: 2, indices: '{152,153,-1,-1,-1,-1}} :
        BITWIDTH == 154 ?   '{num_indices: 4, indices: '{25,27,152,154,-1,-1}} :
        BITWIDTH == 155 ?   '{num_indices: 4, indices: '{123,124,154,155,-1,-1}} :
        BITWIDTH == 156 ?   '{num_indices: 4, indices: '{40,41,155,156,-1,-1}} :
        BITWIDTH == 157 ?   '{num_indices: 4, indices: '{130,131,156,157,-1,-1}} :
        BITWIDTH == 158 ?   '{num_indices: 4, indices: '{131,132,157,158,-1,-1}} :
        BITWIDTH == 159 ?   '{num_indices: 2, indices: '{128,159,-1,-1,-1,-1}} :
        BITWIDTH == 160 ?   '{num_indices: 4, indices: '{141,142,159,160,-1,-1}} :
        BITWIDTH == 161 ?   '{num_indices: 2, indices: '{161,143,-1,-1,-1,-1}} :
        BITWIDTH == 162 ?   '{num_indices: 4, indices: '{74,75,161,162,-1,-1}} :
        BITWIDTH == 163 ?   '{num_indices: 4, indices: '{103,104,162,163,-1,-1}} :
        BITWIDTH == 164 ?   '{num_indices: 4, indices: '{150,151,163,164,-1,-1}} :
        BITWIDTH == 165 ?   '{num_indices: 4, indices: '{134,135,164,165,-1,-1}} :
        BITWIDTH == 166 ?   '{num_indices: 4, indices: '{127,128,165,166,-1,-1}} :
        BITWIDTH == 167 ?   '{num_indices: 2, indices: '{161,167,-1,-1,-1,-1}} :
        BITWIDTH == 168 ?   '{num_indices: 4, indices: '{151,153,166,168,-1,-1}} :
        '{num_indices: 1, indices: '{-1,-1,-1,-1,-1,-1}}
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


    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    logic                               bit_feedback;


    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    genvar i;
    generate begin: gen_taps
        logic [TAP_INDICES.num_indices-1:0] tap_cascade;
        for (i=0; i<TAP_INDICES.num_indices; i++) begin
            if (i != TAP_INDICES.num_indices-1) begin
                // (remember -1 to account for human counting in the tap indices)
                assign tap_cascade[i] = ~(o_counter[TAP_INDICES.indices[i]-1] ^ tap_cascade[i+1]);
            end else begin
                assign tap_cascade[i] = o_counter[TAP_INDICES.indices[i]-1];
            end
        end
        assign bit_feedback = tap_cascade[0];
    end endgenerate

    always_ff @(posedge clk) begin
        o_counter[0] <= bit_feedback;
        o_counter[BITWIDTH-1:1] <= o_counter[BITWIDTH-2:0];
    end

endmodule

