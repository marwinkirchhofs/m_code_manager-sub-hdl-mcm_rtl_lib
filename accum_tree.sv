
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* Parameterizable accumulation tree
*
* Currently: The only implemented option is pure DSP-based (using cascaded 
* 4-input 2-DSP units)
*
* * INTERFACE:
*		[port name]		- [port description]
*
* :BACKEND: FUTURE - select the implementation of the accumulation nodes. So far, 
* only "DSP" is implemented (and the parameter thus has no effect, until 
* anything else is added)
* TODO: the parameter descriptions are moved here from accum_dsp4_operand. need 
* an update as soon as any other backend is implemented
* parameters
* :RST_EN: (NOT IMPLEMENTED) if set to 1, the output reset is available via 
* rst_n (allowing for resetting an accumulating circuit without deasserting 
* i_accumulate). Has no effect if not (OUT_REG==1 || ACCUMULATE_EN==1), because 
* in those cases the register to be reset is deactivated
* :INTERM_REG: Activates registers in-between the tree levels (in which way 
* exactly depends on BACKEND - in the future, that is)
* :DSP_OPMODE_REG: activates the DSP OPMODEREG for the last-stage DSP (when 
* using DSP implementation of course), with the effect that i_accumulate has 
* a 1-cycle latency in taking effect. May help with timing, or with cycle 
* alignment of certain applications. Note that it's not necessary for the 
* higher-stage DSPs, because those have a fixed opmode input, so allow the tool 
* to hard-wire that.
*
* TODO: accommodate NUM_INPUTS that are not powers of 2
*/

import mcm_math_pkg::*;

module accum_tree #(
    parameter string                                BACKEND = "DSP",
    parameter int                                   DATA_WIDTH = DSP48E2_P_WIDTH,
    parameter int                                   NUM_INPUTS = 4,
    parameter int                                   RST_EN = 0,
    parameter int                                   INTERM_REG = 0,
    parameter int                                   DSP_OPMODE_REG = 0
) (
    input logic                                     clk,
    input logic                                     rst_n,
    input logic                                     i_accumulate,
    input logic [DATA_WIDTH-1:0]                    i_operands  [NUM_INPUTS],
    output logic [DATA_WIDTH-1:0]                   o_result
);

    localparam NUM_LEVELS = accum_tree_get_num_levels(NUM_INPUTS);
    localparam NUM_INPUTS_POW4 = accum_tree_get_num_operands_pow4(NUM_INPUTS);

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    genvar i;
    genvar j;
    genvar k;

    // the entire tree is built up on 4-to-1 compressors, so what do you do if 
    // you have a number of inputs that is not a power of 4? Because I don't 
    // have time: You build the same tree, and set every unneeded input to 0.  
    // Yes, that might spawn a few totally unused DSPs, at this point I take it 
    // (and get back to it should it ever become a problem).
    logic [DATA_WIDTH-1:0]                          operands_pow4 [NUM_INPUTS_POW4];

    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    generate begin: gen_input_pow4
        for (i=0; i<NUM_INPUTS_POW4; i++) begin
            if (i<NUM_INPUTS) begin
                assign operands_pow4[i] = i_operands[i];
            end else begin
                assign operands_pow4[i] = '0;
            end
        end
    end endgenerate

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

    generate begin: gen_accum_levels

        // intermediary connections for the layers (level_inputs[x] connects 
        // the output of layer x+1 to inputs of layer x). In theory, that would 
        // need an irregularly sized data structure, because the number of 
        // intermediary signals depends on the level depth. Since that is not 
        // how data structures work, we just make it a regular array, size that 
        // to the widest necessary connection (layer NUM_LEVELS-1 to layer 
        // NUM_LEVELS-2), and for the narrower connections ignore the unused 
        // signals.
        logic [DATA_WIDTH-1:0] level_inputs [NUM_LEVELS][NUM_INPUTS_POW4];

        for (i=0; i<NUM_INPUTS_POW4; i++) begin
            assign level_inputs[NUM_LEVELS-1][i] = operands_pow4[i];
        end

        for (i=0; i<NUM_LEVELS; i++) begin: gen_levels
            for (j=0; j<int'($pow(4, i)); j++) begin: gen_dsps

                logic [DATA_WIDTH-1:0]      operands_in [4];
                for (k=0; k<4; k++) begin: gen_level_inputs
                    assign operands_in[k] = level_inputs[i][j*4+k];
                end

                logic [DATA_WIDTH-1:0]      operand_out;
                if (i == 0) begin: gen_level_output
                    assign o_result = operand_out;
                end else begin
                    assign level_inputs[i-1][j] = operand_out;
                end

                accum_dsp_4_operand #(
                    .DATA_WIDTH             (DATA_WIDTH),
                    .RST_EN                 (i==0 ? RST_EN : 0),
                    .ACCUMULATE_EN          (i==0 ? 1 : 0),
                    .OUT_REG                (INTERM_REG),
                    .OPMODE_REG             (i==0 ? DSP_OPMODE_REG : 0)
                ) inst_accum_4_operand (
                    .clk                    (clk),
                    .rst_n                  (i==0 ? rst_n : 1'b1),
                    .i_accumulate           (i==0 ? i_accumulate : 1'b0),
                    .i_operands             (operands_in),
                    .o_result               (operand_out)
                );
            end
        end
    end endgenerate

endmodule

