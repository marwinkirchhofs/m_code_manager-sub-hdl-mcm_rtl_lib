`timescale 1ns/1ps

/*
* interface for directly mapped register file -> meaning there is zero-latency 
* read access to all registers
* write latency depends on the backend implementation
*/
interface ifc_reg_file_direct_access #(
    parameter           REGISTER_WIDTH = 32,
    parameter           NUM_REGISTERS = 16
) (
    input clk
);

    logic [NUM_REGISTERS-1:0][REGISTER_WIDTH-1:0]   write_data;
    logic [NUM_REGISTERS-1:0]                       write_req;
    logic [NUM_REGISTERS-1:0][REGISTER_WIDTH-1:0]   read_data;

    modport master (
        output write_data, write_req,
        input read_data
    );

    modport slave (
        input write_data, write_req,
        output read_data
    );

endinterface
