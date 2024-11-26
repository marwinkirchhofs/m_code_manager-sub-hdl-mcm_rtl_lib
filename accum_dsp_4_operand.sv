
/*
* company:
* author/engineer:
* creation date:
* project name:
* target devices:
* tool versions:
*
* DESCRIPTION:
* Add or accumulate 4 input (2's complement) operands of up to 48-bit solely 
* using 2 DSP48E2 ressources. Result accumulation can be dynamically switched on 
* and off (enables/disables the DSP's internal output feedback path)
*
* latency: 1 or 2 cycles, depending on master DSP P register 
* (1+DSP_MASTER_OUT_REG_EN, see localparam).
*
*         ______________________
* op_0 - |A:B       DSP         |
* op_1 - |C    A:B+C+PCIN(+P)  P| - result
*         ----------------------
*                     cascade ^
*         ____________________|_
* op_2 - |A:B       DSP         |
* op_3 - |C         A:B+C       |
*         ----------------------
*
* INTERNALS:
*
* DSP registers: The slave register can not have any datapath registers enabled.  
* The problem is the C path of the master register. For the P cascade from slave 
* to master, the slave's P reg needs to be enabled, so there is one compulsory 
* cycle of latency to the master's ALU, that the master's datapaths need to 
* match. The C input path only has up to one register levels, so there is only 
* one solution without external registers. Which also means: Should that not 
* pass timing, the master's C path needs an external register to match the slave 
* data path registers.
*
* * INTERFACE:
*		[port name]		- [port description]
* :i_accumulate: activates the master DSP's internal result feedback path to the 
* adder input. Remember to only activate as long as you need it, because in 
* order to reset the circuit, accumulation needs to be deactivated. 
*
* :ACCUMULATE_EN: if 1, enables circuitry for accumulating results over multiple 
* circles. Implications: If set to 1, OUT_REG has no effect (always acts as 
* OUT_REG=1 because the register is required for accumulation). If 0, 
* i_accumulate is ignored.
* :RST_EN: (NOT IMPLEMENTED) if set to 1, the output reset is available via 
* rst_n (allowing for resetting an accumulating circuit without deasserting 
* i_accumulate). Has no effect if not (OUT_REG==1 || ACCUMULATE_EN==1), because 
* in those cases the register to be reset is deactivated
* :OPMODE_REG: activates the DSP OPMODEREG, with the effect that i_accumulate 
* has a 1-cycle latency in taking effect. May help with timing, or with cycle 
* alignment of certain applications.
*/

import mcm_math_pkg::*;

module accum_dsp_4_operand #(
    parameter                                       DATA_WIDTH = DSP48E2_P_WIDTH,
    parameter                                       RST_EN = 0,
    parameter                                       ACCUMULATE_EN = 1,
    parameter                                       OUT_REG = 1,
    parameter                                       OPMODE_REG = 0
) (
    input logic                                     clk,
    input logic                                     rst_n,
    input logic                                     i_accumulate,
    input logic [DATA_WIDTH-1:0]                    i_operands  [4],
    output logic [DATA_WIDTH-1:0]                   o_result
);

    localparam DSP_MASTER_OUT_REG_EN = ((ACCUMULATE_EN == 1) || (OUT_REG == 1)) ? 1 : 0;

    genvar i;

    //----------------------------------------------------------
    // INTERNAL SIGNALS
    //----------------------------------------------------------

    logic [DSP48E2_P_WIDTH-1:0]             operands_full_width [4];

    logic [DSP48E2_P_WIDTH-1:0]             dsp_cascade;
    logic                                   dsp_mult_sign;
    logic [DSP48E2_P_WIDTH-1:0]             dsp_result;
    logic [DSP48E2_P_WIDTH-1:0]             dummy_dsp_result;
    logic [DSP48E2_A_WIDTH-1:0]             dsp_op_a    [2];
    logic [DSP48E2_B_WIDTH-1:0]             dsp_op_b    [2];

    logic                                   dsp_master_accumulate_en;

    // set up OPMODE (ALU input) to
    // * W mux: P feedback (master-only)
    // * X mux: A:B operand
    // * Y mux: C operand
    // * Z mux: cascade in (master-only)
    // * everything else 0
    logic [1:0] bits_opmode_w_dsp_master;
    assign bits_opmode_w_dsp_master = {1'b0, dsp_master_accumulate_en};
    const logic [1:0] bits_opmode_w_dsp_slave = 2'b00;
    const logic [1:0] bits_opmode_x_dsp = 2'b11; // necessary for the Y mux
    const logic [1:0] bits_opmode_y_dsp = 2'b11; // select the M (multiplier) register
    const logic [2:0] bits_opmode_z_dsp_master = 3'b001; // select C
    const logic [2:0] bits_opmode_z_dsp_slave = 3'b000; // select C
    logic [8:0] bits_opmode_dsp_master;
    assign bits_opmode_dsp_master =
        {bits_opmode_w_dsp_master, bits_opmode_z_dsp_master, bits_opmode_y_dsp, bits_opmode_x_dsp};
    const logic [8:0] bits_opmode_dsp_slave =
        {bits_opmode_w_dsp_slave, bits_opmode_z_dsp_slave, bits_opmode_y_dsp, bits_opmode_x_dsp};

    // set up inmode to take from A2 and B2 (but it is direct input connection 
    // since we disable the registers by parameters
    const logic [4:0] bits_inmode = 5'b0;


    // DUMMY DSP CONNECTIONS
    logic [DSP48E2_P_WIDTH-1:0]             dummy_dsp_slave_result;
    logic [DSP48E2_P_WIDTH-1:0]             dummy_dsp_cascade;
    logic                                   dsp_master_overflow;
    logic                                   dsp_master_underflow;
    logic                                   dsp_master_patterndetect;
    logic                                   dsp_master_patternbdetect;
    logic                                   dsp_slave_overflow;
    logic                                   dsp_slave_underflow;
    logic                                   dsp_slave_patterndetect;
    logic                                   dsp_slave_patternbdetect;

    logic [3:0]                             dummy_dsp_master_carryout;
    logic [7:0]                             dummy_dsp_master_xorout;
    logic [29:0]                            dummy_dsp_master_acout;
    logic [17:0]                            dummy_dsp_master_bcout;
    logic                                   dummy_dsp_master_carrycascout;
    logic                                   dummy_dsp_master_multsignout;
    logic [DSP48E2_P_WIDTH-1:0]             dummy_dsp_master_cascadeout;
    logic [3:0]                             dummy_dsp_slave_carryout;
    logic [7:0]                             dummy_dsp_slave_xorout;
    logic [29:0]                            dummy_dsp_slave_acout;
    logic [17:0]                            dummy_dsp_slave_bcout;
    logic                                   dummy_dsp_slave_carrycascout;
    logic                                   dummy_dsp_slave_multsignout;
    logic [DSP48E2_P_WIDTH-1:0]             dummy_dsp_slave_cascadeout;


    //----------------------------------------------------------
    // OPERATION
    //----------------------------------------------------------

    generate begin: gen_operand_padding
        for (i=0; i<4; i++) begin
            assign operands_full_width[i] =
                {{(DSP48E2_P_WIDTH-DATA_WIDTH){i_operands[i][DATA_WIDTH-1]}}, i_operands[i]};
        end
    end endgenerate

    assign dsp_master_accumulate_en = (ACCUMULATE_EN == 1) & i_accumulate;

    // I know, hard-coded, the signal widths only work with DSP48E2. You have to 
        // adjust the signal widths should this code ever get in contact with 
        // a non-Ultrascale DSP.
    assign dsp_op_a[0] = operands_full_width[0][DSP48E2_P_WIDTH-1 -: 30];
    assign dsp_op_b[0] = operands_full_width[0][17:0];
    assign dsp_op_a[1] = operands_full_width[2][DSP48E2_P_WIDTH-1 -: 30];
    assign dsp_op_b[1] = operands_full_width[2][17:0];

    assign o_result = dsp_result[DATA_WIDTH-1:0];

    //----------------------------------------------------------
    // SUBMODULES
    //----------------------------------------------------------

    // MASTER DSP
    DSP48E2 #(
        // Feature Control Attributes: Data Path Selection
        .AMULTSEL("A"),
        .A_INPUT("DIRECT"),
        .BMULTSEL("B"),
        .B_INPUT("DIRECT"),
        .PREADDINSEL("A"), // dummy
        .RND(48'h000000000000), // dummy
        .USE_MULT("NONE"), // deactivate multiplier
        .USE_SIMD("ONE48"), // run single full-width adder
        .USE_WIDEXOR("FALSE"), // dummy
        .XORSIMD("XOR24_48_96"), // dummy
        // Pattern Detector Attributes: Pattern Detection Configuration
        .AUTORESET_PATDET("NO_RESET"), // dummy
        .AUTORESET_PRIORITY("RESET"), // dummy
        .MASK(48'h3fffffffffff), // dummy
        .PATTERN(48'h000000000000), // dummy
        .SEL_MASK("MASK"), // dummy
        .SEL_PATTERN("PATTERN"), // dummy
        .USE_PATTERN_DETECT("NO_PATDET"), // dummy
        // PROGRAMMABLE INVERSION ATTRIBUTES
        // no inputs inverted
        .IS_ALUMODE_INVERTED(4'b0000),
        .IS_CARRYIN_INVERTED(1'b0),
        .IS_CLK_INVERTED(1'b0),
        .IS_INMODE_INVERTED(5'b00000),
        .IS_OPMODE_INVERTED(9'b000000000),
        .IS_RSTALLCARRYIN_INVERTED(1'b0),
        .IS_RSTALUMODE_INVERTED(1'b0),
        .IS_RSTA_INVERTED(1'b0),
        .IS_RSTB_INVERTED(1'b0),
        .IS_RSTCTRL_INVERTED(1'b0),
        .IS_RSTC_INVERTED(1'b0),
        .IS_RSTD_INVERTED(1'b0),
        .IS_RSTINMODE_INVERTED(1'b0),
        .IS_RSTM_INVERTED(1'b0), // dummy
        .IS_RSTP_INVERTED(1'b1),
        // REGISTER CONTROL ATTRIBUTES
        .ACASCREG(1), // (match AREG)
        .ADREG(0), // dummy
        .ALUMODEREG(0), // hard-coded
        .AREG(1), // match slave DSP P REG
        .BCASCREG(1), // (match BREG)
        .BREG(1), // match slave DSP P REG
        .CARRYINREG(0), // hard-coded signal
        .CARRYINSELREG(0), // hard-coded signal
        .CREG(1), // match slave DSP P REG
        .DREG(1), // dummy
        .INMODEREG(0), // hard-coded input
        .MREG(0),
        .OPMODEREG(OPMODE_REG), // hard-coded input
        .PREG(DSP_MASTER_OUT_REG_EN)
    ) inst_dsp48e2_accum_master (
        .CLK(clk),

        // DATA INPUTS
        .A(dsp_op_a[0]), // operand 0 upper
        .B(dsp_op_b[0]), // operand 0 lower
        // (why 5 leading int bits? 3 from the DSP ALU, 2 from r_in)
        .C(operands_full_width[1]),
        .CARRYIN(1'b0), // necessary because you can't fully disable the ALU carry logic
        .D({DSP48E2_D_WIDTH{1'b1}}), // dummy
        // DATA OUTPUTS
        .CARRYOUT(dummy_dsp_master_carryout),
        .P(dsp_result),
        .XOROUT(dummy_dsp_master_xorout),
        // CASCADE INPUTS
        .ACIN({DSP48E2_A_WIDTH{1'b1}}), // dummy
        .BCIN({DSP48E2_B_WIDTH{1'b1}}), // dummy
        .CARRYCASCIN('1), // dummy
        .MULTSIGNIN(dsp_mult_sign), // dummy
        .PCIN(dsp_cascade), // dummy
        // CASCADE OUTPUTS
        .ACOUT(dummy_dsp_master_acout),
        .BCOUT(dummy_dsp_master_bcout),
        .CARRYCASCOUT(dummy_dsp_master_carrycascout),
        .MULTSIGNOUT(dsp_mult_sign),
        .PCOUT(dummy_dsp_cascade),

        // CONTROL INPUTS
        .CARRYINSEL(3'b0), // select carryin (which has to be 0)
        // set up inmode for performing A*B, and routing the input pipeline 
        // according to parameter FULL_INPUT_PIPELINE
        .INMODE(bits_inmode),
        .OPMODE(bits_opmode_dsp_master),
        .ALUMODE(4'b0), // Z+W+X+Y+CIN
        // CONTROL OUTPUTS
        .OVERFLOW(dsp_master_overflow),
        .PATTERNBDETECT(dsp_master_patternbdetect),
        .PATTERNDETECT(dsp_master_patterndetect),
        .UNDERFLOW(dsp_master_underflow),

        // RESET/CLOCK ENABLE INPUTS
        .CEA1(1'b0),
        .CEA2(1'b1), // note that A2 is activated if AREG=1
        .CEAD(1'b0),
        .CEC(1'b1),
        .CEB1(1'b0),
        .CEB2(1'b1),
        .CED(1'b0),
        .CEM(1'b0), // (internal multiplier register)
        .CEP(DSP_MASTER_OUT_REG_EN ? 1'b1 : 1'b0),
        .CECARRYIN(1'b0), // hard-wire
        .CECTRL(OPMODE_REG ? 1'b1 : 1'b0), // enable if OPMODEREG is activated
        .CEALUMODE(1'b0), // hard-coded without reg in-between
        .CEINMODE(1'b0), // allow to propagate
        // all resets deactivated, because the core doesn't use any resets
        .RSTA(1'b0),
        .RSTALLCARRYIN(1'b0),
        .RSTALUMODE(1'b0),
        .RSTB(1'b0),
        .RSTC(1'b0),
        .RSTCTRL(1'b0),
        .RSTD(1'b0),
        .RSTINMODE(1'b0),
        .RSTM(1'b0),
        .RSTP(rst_n)
    );

    // SLAVE DSP
    DSP48E2 #(
        // Feature Control Attributes: Data Path Selection
        .AMULTSEL("A"),
        .A_INPUT("DIRECT"),
        .BMULTSEL("B"),
        .B_INPUT("DIRECT"),
        .PREADDINSEL("A"), // dummy
        .RND(48'h000000000000), // dummy
        .USE_MULT("NONE"), // deactivate multiplier
        .USE_SIMD("ONE48"), // run single full-width adder
        .USE_WIDEXOR("FALSE"), // dummy
        .XORSIMD("XOR24_48_96"), // dummy
        // Pattern Detector Attributes: Pattern Detection Configuration
        .AUTORESET_PATDET("NO_RESET"), // dummy
        .AUTORESET_PRIORITY("RESET"), // dummy
        .MASK(48'h3fffffffffff), // dummy
        .PATTERN(48'h000000000000), // dummy
        .SEL_MASK("MASK"), // dummy
        .SEL_PATTERN("PATTERN"), // dummy
        .USE_PATTERN_DETECT("NO_PATDET"), // dummy
        // PROGRAMMABLE INVERSION ATTRIBUTES
        // no inputs inverted
        .IS_ALUMODE_INVERTED(4'b0000),
        .IS_CARRYIN_INVERTED(1'b0),
        .IS_CLK_INVERTED(1'b0),
        .IS_INMODE_INVERTED(5'b00000),
        .IS_OPMODE_INVERTED(9'b000000000),
        .IS_RSTALLCARRYIN_INVERTED(1'b0),
        .IS_RSTALUMODE_INVERTED(1'b0),
        .IS_RSTA_INVERTED(1'b0),
        .IS_RSTB_INVERTED(1'b0),
        .IS_RSTCTRL_INVERTED(1'b0),
        .IS_RSTC_INVERTED(1'b0),
        .IS_RSTD_INVERTED(1'b0),
        .IS_RSTINMODE_INVERTED(1'b0),
        .IS_RSTM_INVERTED(1'b0), // dummy
        .IS_RSTP_INVERTED(1'b0),
        // REGISTER CONTROL ATTRIBUTES
        .ACASCREG(0), // (dummy)
        .ADREG(0), // dummy
        .ALUMODEREG(0), // hard-coded
        .AREG(0),
        .BCASCREG(0), // (dummy)
        .BREG(0),
        .CARRYINREG(0), // hard-coded signal
        .CARRYINSELREG(0), // hard-coded signal
        .CREG(0),
        .DREG(1), // dummy
        .INMODEREG(0), // hard-coded input
        .MREG(0),
        .OPMODEREG(0), // hard-coded input
        .PREG(1) // required for cascade out
    ) inst_dsp48e2_accum_slave (
        .CLK(clk),

        // DATA INPUTS
        .A(dsp_op_a[1]), // operand 0 upper
        .B(dsp_op_b[1]), // operand 0 lower
        // (why 5 leading int bits? 3 from the DSP ALU, 2 from r_in)
        .C(operands_full_width[3]),
        .CARRYIN(1'b0), // necessary because you can't fully disable the ALU carry logic
        .D({DSP48E2_D_WIDTH{1'b1}}), // dummy
        // DATA OUTPUTS
        .CARRYOUT(dummy_dsp_slave_carryout),
        .P(dummy_dsp_result),
        .XOROUT(dummy_dsp_slave_xorout),
        // CASCADE INPUTS
        .ACIN({DSP48E2_A_WIDTH{1'b1}}), // dummy
        .BCIN({DSP48E2_B_WIDTH{1'b1}}), // dummy
        .CARRYCASCIN('1), // dummy
        .MULTSIGNIN(1'b1), // dummy
        .PCIN({DSP48E2_P_WIDTH{1'b1}}), // dummy
        // CASCADE OUTPUTS
        .ACOUT(dummy_dsp_slave_acout),
        .BCOUT(dummy_dsp_slave_bcout),
        .CARRYCASCOUT(dummy_dsp_slave_carrycascout),
        .MULTSIGNOUT(o_mult_sign),
        .PCOUT(dsp_cascade),

        // CONTROL INPUTS
        .CARRYINSEL(3'b0), // select carryin (which has to be 0)
        // set up inmode for performing A*B, and routing the input pipeline 
        // according to parameter FULL_INPUT_PIPELINE
        .INMODE(bits_inmode),
        .OPMODE(bits_opmode_dsp_slave),
        .ALUMODE(4'b0), // Z+W+X+Y+CIN
        // CONTROL OUTPUTS
        .OVERFLOW(dsp_slave_overflow),
        .PATTERNBDETECT(dsp_slave_patternbdetect),
        .PATTERNDETECT(dsp_slave_patterndetect),
        .UNDERFLOW(dsp_slave_underflow),

        // RESET/CLOCK ENABLE INPUTS
        .CEA1(1'b0),
        .CEA2(1'b0),
        .CEAD(1'b0),
        .CEC(1'b0),
        .CEB1(1'b0),
        .CEB2(1'b0),
        .CED(1'b0),
        .CEM(1'b0), // (internal multiplier register)
        .CEP(1'b1),
        .CECARRYIN(1'b0), // hard-wired
        .CECTRL(1'b0), // hard-wired
        .CEALUMODE(1'b0), // hard-coded without reg in-between
        .CEINMODE(1'b0), // allow to propagate
        // all resets deactivated, because the core doesn't use any resets
        .RSTA(1'b0),
        .RSTALLCARRYIN(1'b0),
        .RSTALUMODE(1'b0),
        .RSTB(1'b0),
        .RSTC(1'b0),
        .RSTCTRL(1'b0),
        .RSTD(1'b0),
        .RSTINMODE(1'b0),
        .RSTM(1'b0),
        .RSTP(1'b0)
    );

endmodule

