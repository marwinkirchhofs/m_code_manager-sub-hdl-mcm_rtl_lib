
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* how does the module handle same-cycle write accesses? the lower-indexed master 
* interfaces take precedence. Any other write access in the same cycles is 
* dropped.
*
* * INTERFACE:
*		[port name]		- [port description]
* * inputs:
* * outputs:
*/

import reg_file_pkg::*;

module reg_file_direct_access #(
    parameter                   REGISTER_WIDTH = 32,
    parameter                   NUM_REGISTERS = 16,
    parameter                   NUM_MASTERS = 2
) (
    input                                   clk,
    input                                   rst_n,

    ifc_reg_file_direct_access.slave        if_reg_file [NUM_MASTERS]
);

    localparam                  MASTER_ID_WIDTH = $clog2(NUM_MASTERS);

    /*
    * quick learning note to myself: this actually does synthesize -> nice way 
    * to use pseudo-procedural code in hardware
    * how it synthesizes (with 2 masters):
    * - one "write enable" LUT: global or of the write requests, connects to the 
    *   CEs of the register FFs
    * - one "data" LUT per register FF with control input: the control acts as 
    *   a multiplexer for the data inputs. With 2 masters, the multiplexer is in 
    *   fact just a switch. With more masters it should be an actual multiplexer, 
*   and a bit of LUT cascading depending on the number of inputs (once again 
*   being a design that needs way more LUTs than registers).
    */

    // https:
    // //github.com/gsw73/find_first_bit_arbiter/blob/dc610adcdb0164aa4d29d73b58042baa33cc8d5a/design.sv
    // (would like to put this function into the pkg, instead of here, but then 
    // you'd need a way to pass a way to pass the NUM_MASTERS parameter. This 
    // way is nicer for user abstraction)
    function automatic logic [MASTER_ID_WIDTH:0] find_first_bit(
        input logic [NUM_MASTERS-1:0] _write_req
    );
        logic write_en_glob = 1'b0;
        logic [MASTER_ID_WIDTH-1:0] id = '0;

        // why starting at NUM_MASTERS instead of NUM_MASTERS-1, and then 
        // subtracting? Because otherwise you'd have to check for >=0, and if 
        // whatever tool synthesizes an unsigned wraparound that check will 
        // always be true. Aborting at ==0 should be fail-safe.
        for (int i=NUM_MASTERS; i > 0; i--)
            if (_write_req[i-1] == 1'b1) begin
                write_en_glob = 1'b1;
//                 id = i[MASTER_ID_WIDTH-1:0] - 1;
                id = i - 1;
            end

        return ({write_en_glob, id});
    endfunction

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    genvar i, j;
    logic   [REGISTER_WIDTH-1:0]            register    [NUM_REGISTERS];

    // why no unpacked array? Because you have to dynamically index with 
    // writen_id[i], and you can't do that with an array, but you can with 
    // a packed data type.
    logic   [NUM_REGISTERS-1:0][NUM_MASTERS-1:0]                        write_req;
    logic   [NUM_REGISTERS-1:0][NUM_MASTERS-1:0][REGISTER_WIDTH-1:0]    write_data;
    logic                                   write_en    [NUM_REGISTERS];
    logic   [MASTER_ID_WIDTH-1:0]           write_id    [NUM_REGISTERS];

    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    // gather the write request bits
    generate
        for (i=0; i<NUM_REGISTERS; i++) begin
            for (j=0; j<NUM_MASTERS; j++) begin
                assign write_req[i][j] = if_reg_file[j].write_req[i];
                assign write_data[i][j] = if_reg_file[j].write_data[i];
            end
        end
    endgenerate

    // temporary implementation of the register file itself, so I don't have to 
    // spend an entire module on that for now
    generate
        for (i=0; i<NUM_REGISTERS; i++) begin

            assign {write_en[i], write_id[i]} = find_first_bit(write_req[i]);

            always_ff @(posedge clk) begin
                if (~rst_n) begin
                    register[i] <= '0;
                end else begin
                    if (write_en[i]) begin
                        register[i] <= write_data[i][write_id[i]];
                    end
                end
            end

            for (j=0; j<NUM_MASTERS; j++) begin
                assign if_reg_file[j].read_data[i] = register[i];
            end
        end
    endgenerate


    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule

