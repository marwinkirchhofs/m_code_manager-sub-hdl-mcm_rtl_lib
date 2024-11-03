
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
            4: begin: LCL   localparam int TAP_INDICES [2] = '{3,4}; end
            default: begin: LCL   localparam int TAP_INDICES [1] = '{-1}; end
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

