
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* * DESCRIPTION:
* Read-only memory for mapping register file addreses to register IDs in an 
* addressable (non-CAM) way.
* Why is that module even here? Because I thought it would be nice for the user 
* to be able to set up an addressing scheme with empty addresses (for reserved 
* addresses, for example). While not having physical registers taking up 
* hardware space for all the unused intermediary addresses, just to make the 
* addresses match with the physical ID of the register in the register file 
* (array). Of course, there is no problem if the register file itself is 
* implemented as BRAM (or whatever RAM). But this lib also offers a register 
* file with full parallel simultaneous hardware access to all registers, which 
* means the register file must be implemented in bare FFs because no addressable 
* RAM has simultaneous instant access to all addresses.
* But not having all register physically implemented makes the register file 
* content-accessed (with the addresses as keys), instead of simply 
* address-accessed, thus terrible for timing. The in-between solution: Implement 
* a physical structure that does have entries for the ENTIRE register file 
* address space (determined by `reg_file_pkg::REG_FILE_AXI_ADDR_WIDTH`), but 
* that only holds the IDs to the physical register file (or some "address not 
* assigned" indicator). The advantages:
* 1. The IDs need logarithmically less space than a register itself
* 2. That makes the ID-lookup an addressable ROM, meaning no CAM at all anymore
*
* So, to resolve a register file address:
* 1. look up the corresponding physical register ID in the full-size ROM (aka 
* this module)
* 2. access the register with the ID
*
* latency can be adjusted between 0 (LUTRAM) and 1 (BRAM). don't know if I'll 
* ever need the BRAM option, but now it's here
*
* OPERATION:
* simple ROM lookup
*
* undefined behavior if an address is supplied that is not aligned with 
* REGISTER_WIDTH (in fact, lower bits simply get truncated, but it's marked as 
* undefined here)
*
* PARAMETERS:
* :REGISTER_WIDTH: (value in bits, must be a power of 2 and >=8) required to 
* determine the address step from one register to the next one
* :NO_LATENCY: set to 1 (default) for a 0-latency (LUTRAM) implementation. Any 
* other value means latency=1 (!!! UNTESTED for 0 !!!)
*
*/

import reg_file_pkg::*;

module reg_file_rom_map_addr_id #(
    parameter                       REGISTER_WIDTH = 32,
    parameter                       NO_LATENCY = 1
) (
    input logic                             clk,
    input logic                             rst_n,

    input reg_file_addr_t                   i_addr,
    output reg_file_id_t                    o_id
);

    localparam REGISTER_WIDTH_BYTES = (REGISTER_WIDTH>>3);
    localparam NUM_REG_FILE_ADDRESSES = (1<<REG_FILE_AXI_ADDR_WIDTH) / REGISTER_WIDTH_BYTES;

    typedef logic [$clog2(NUM_REG_FILE_ADDRESSES)-1:0] rom_reg_file_addr_t;

    genvar i;

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    reg_file_id_t                               rom_reg_file_ids [NUM_REG_FILE_ADDRESSES-1:0];
    reg_file_id_t                               id;

    logic [$clog2(NUM_REG_FILE_ADDRESSES)-1:0]  rom_reg_file_addr;

    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    //----------------------------
    // ROM SETUP
    //----------------------------

    generate
    begin: gen_rom_data
        for (i=0; i<$size(rom_reg_file_ids); i++) begin
            assign rom_reg_file_ids[i] =
                            reg_file_addr2id(i*REGISTER_WIDTH_BYTES, AXI_LITE_REG_MAP_TABLE);
        end
    end
    endgenerate

    //----------------------------
    // ROM ACCESS
    //----------------------------

    // right-shift the register address to register id rom steps
    // example: REGISTER_WIDTH=32, i_addr=00111000 -> rom_reg_file_addr=001110
    assign rom_reg_file_addr = (i_addr>>($clog2(REGISTER_WIDTH_BYTES)));

    generate
    begin: gen_rom_access
        if (NO_LATENCY == 1) begin
            always_comb begin
                id = rom_reg_file_ids[rom_reg_file_addr];
            end
        end else begin
            always_ff @(posedge clk) begin
                id <= rom_reg_file_ids[rom_reg_file_addr];
            end
        end
    end
    endgenerate

    assign o_id = id;

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

endmodule
