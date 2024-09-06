
/*
* quick doc on how the user register file parameterization works and why
*
* from the user side:
* 1. the user has to specify axi_reg_file_param.svh, which needs to define 
* `AXI_LITE_REG_FILE_NUM_REGISTERS and `AXI_LITE_REG_FILE_AXI_REG_FILE_AXI_ADDR_WIDTH
* 2. the user has to specify axi_reg_file_table.svh, which needs to specify 
* axi_lite_reg_map_table as `const reg_entry_t [REG_FILE_NUM_REGISTERS]`
* 3. the user is HIGHLY ENCOURAGED to not include axi_reg_file_table.svh 
* anywhere, and to not include axi_reg_file_param.svh without include guards. If 
* you need the register file table in the rtl code, import it from reg_file_pkg, 
    * it gets included within the package.
*
* internally/design decisions
* - foremost, of course, I want to have a clearly configurable and easy-to-use 
*   user interface, that does not require touching any other file.
* - I wanted to do that via headers, not via a user package, because it just 
*   feels more natural to specify these system parameters via headers. Plus 
*   I haven't found any spot where it really makes a difference.
* - why is it 2 header files? Because they need to be included at different 
*   points in the code. reg_entry_t must be typedef'd when the register file 
*   table is evaluated. For it to be typedef'd, you need the register axi 
*   address width.  Thus, some code needs to come in between of two chunks of 
*   user code.  Maybe with a bit of hacking one would find a solution of headers 
*   that include each other, but the solution with two headers that get included 
*   at different points felt relatively clean. Plus the parameters header 
*   contains parameters that you might as well want to pass at other points in 
*   the design, to use them as parameters, whereas you definitely do not want to 
*   have the table in the global scope (because that is exactly what you have 
*   packages for).
*   Another advantage is that, because the register file table code is only 
*   evaluated within the package, it can make use of the MEMORY_MAPPED etc 
*   constants, without having to include anything (which would further mess up 
*   the structure) or clutter the global namespace with defines.
*     - yes, as an alternative to reg_entry_t already be typedef'd, maybe it 
*     would have been ok/possible if the user just gave the array as plain code.  
    *     But first that's more error-prone, and second I think it's a good 
    *     thing if they know what exactly they are actually typing, that makes 
    *     the code understandable and better to follow/debug.
*/

`include "axi_reg_file_param.svh"

package reg_file_pkg;

    localparam          REG_FILE_TYPE_DIRECT_ACCESS = "direct_access";
    localparam          REG_FILE_TYPE_MEMORY = "memory";

    localparam          REG_FILE_MEMORY_TYPE_DUAL_PORT = "dual_port";
    localparam          REG_FILE_MEMORY_TYPE_SINGLE_PORT = "single_port";

    localparam          MEMORY_MAPPED       = 1'b1;
    localparam          NO_MEMORY_MAPPED    = 1'b0;
    localparam          TRIGGER_ON_WRITE    = 1'b1;
    localparam          NO_TRIGGER_ON_WRITE = 1'b0;
    localparam          CLEAR_ON_READ       = 1'b1;
    localparam          NO_CLEAR_ON_READ    = 1'b0;

    localparam          REG_FILE_NUM_REGISTERS  = `AXI_LITE_REG_FILE_NUM_REGISTERS;
    localparam          REG_FILE_AXI_ADDR_WIDTH          = `AXI_LITE_REG_FILE_AXI_ADDR_WIDTH;

    typedef struct packed {
        logic   [`AXI_LITE_REG_FILE_AXI_ADDR_WIDTH-1:0] addr;
        logic                                           memory_mapped;
        logic                                           trigger_on_write;
        logic                                           clear_on_read;
    } reg_entry_t;

    typedef logic [$clog2(REG_FILE_NUM_REGISTERS)-1:0]  reg_id_t;

    typedef struct packed {
        logic                                           entry_found;
        reg_id_t                                        id;
        reg_entry_t                                     entry;
    } reg_file_item_t;

    `include "axi_reg_file_table.svh"

    /*
    * be aware: the function does synthesize, but as expected, it can introduce 
    * a considerable timing problem. You are comparing a 32-bit register against 
    * a good number of values using LUTs. Already for only 3 integers in the map 
    * table, that gives 3 hierarchy levels of LUTs for the CE port. Might get 
* worse with a larger number of choices. Good thing is there is no fanout...
    */
    function automatic reg_file_item_t get_reg_item_from_addr(
        logic [REG_FILE_AXI_ADDR_WIDTH-1:0] addr
    );
        reg_file_item_t          hit;
        hit.entry_found = 1'b0;

        for (int i=0; i<REG_FILE_NUM_REGISTERS; i++) begin
            if (axi_lite_reg_map_table[i].addr == addr) begin
                hit.entry_found = 1'b1;
                hit.id = reg_id_t'(i);
                hit.entry = axi_lite_reg_map_table[i];
            end
        end

        return hit;
    endfunction

endpackage
