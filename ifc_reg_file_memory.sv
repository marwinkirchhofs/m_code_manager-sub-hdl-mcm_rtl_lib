`timescale 1ns/1ps

/*
* interface for a memory-based register file -> meaning there is one cycle of 
* read access latency to all registers
* write latency depends on the backend implementation
*/
interface ifc_reg_file_memory #(
    parameter           REGISTER_WIDTH = 32,
    parameter           NUM_REGISTERS = 16
) (
    input clk
);

    localparam          WIDTH_REG_ADDR = $clog2(NUM_REGISTERS);

    logic [REGISTER_WIDTH-1:0]      write_data;
    logic [WIDTH_REG_ADDR-1:0]      write_addr;
    logic                           write_en;
    logic [REGISTER_WIDTH-1:0]      read_data;
    logic [WIDTH_REG_ADDR-1:0]      read_addr;

    modport master (
        output write_data, write_addr, write_en, read_addr,
        input read_data
    );

    modport slave (
        input write_data, write_addr, write_en, read_addr,
        output read_data
    );


endinterface
