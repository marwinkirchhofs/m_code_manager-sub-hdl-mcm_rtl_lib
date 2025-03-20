
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* DESCRIPTION:
* standard flip-flop based single-bit signal clock synchronizer (no reset 
* synchronizer)
*
* resets to all RESET_BIT (assuming you want to cdc some sort of status signal.  
* set RESET_BIT to the reset value of the source signal, and you should be safe 
* right when the reset deasserts)
*/
// false_path constraint (assuming every instance has inst_cdc_sync_ff in the 
// name):
// set_false_path -to [get_pins -filter {REF_PIN_NAME==D} -of_objects \
//     [get_cells -hierarchical -regexp ".*inst_cdc_sync_ff.*/sr_sync.*\\[0\\]"]]
/*
* INTERFACE:
*
*/

import mcm_decimal_pkg::*;

module cdc_sync_ff #(
    parameter                   DEPTH = 3,
    parameter                   RESET_BIT = 1'b0
) (
    input logic                             clk_dest,
    input logic                             rst_n_dest,
    input logic                             i_sig,
    output logic                            o_sig
);

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    (* ASYNC_REG = "TRUE" *) logic [DEPTH-1:0]  sr_sync;

    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    assign o_sig = sr_sync[$bits(sr_sync)-1];

    always_ff @(posedge clk_dest) begin
        if (~rst_n_dest) begin
            sr_sync <= {DEPTH{RESET_BIT}};
        end else begin
            sr_sync[0] <= i_sig;
            sr_sync[1 +: $bits(sr_sync)-1] <= sr_sync[0 +: $bits(sr_sync)-1];
        end
    end

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule

