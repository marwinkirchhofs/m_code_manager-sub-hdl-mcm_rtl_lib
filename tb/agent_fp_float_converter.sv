
package fp_float_converter_sim_pkg;

    import util_pkg::*;

    class cls_agent_fp_float_converter;

        /*
        * contains an exemplary event setup for clk posedges and for changes on
        * a 4-button vector
        */

        virtual ifc_fp_float_converter if_dut;
        event ev_clk;

        function new(virtual ifc_fp_float_converter if_dut);
            this.if_dut = if_dut;
            this.init();

            // SIGNAL -> EVENT
            fork
                this.clk_event();
            join_none

        endfunction

        function void init();
            if_dut.num_dut_in = 0.0;
        endfunction

        //----------------------------
        // SIGNAL -> EVENT
        //----------------------------
        // (necessary for older vivado/xsim versions which don't handle const 
        // ref properly)
        
        task clk_event();
            forever begin
                @(posedge if_dut.clk);
                ->ev_clk;
            end
        endtask

        //----------------------------
        // TEST OPERATION
        //----------------------------

        task run();
            test();
            $stop;
        endtask

        /*
        */
        task test_number(
            input real number,
            output bit test_passed,
            ref int num_passed, ref int num_failed
        );
            real result;
            const real epsilon = 1e-3;
            real_bool_t numbers_equal;

            // test is implemented to take one cycle, such that signals can be 
            // examined and traced in a waveform if necessary. For pure testing 
            // wouldn't be necessary, both converters are completely 
            // combinational (as of now)
            if_dut.cb.num_dut_in <= number;
            @(posedge if_dut.cb);
            result = if_dut.cb.num_dut_out;
            numbers_equal = real_equals(result, number, epsilon);
            test_passed = numbers_equal.equals;

            if (test_passed) begin
                if (`VERBOSITY >= VERBOSITY_DEBUG) begin
                    $display("[%0t] number passed: %0f (result: %0f - delta: %0f)",
                        $time, number, result, numbers_equal.delta);
                end
                num_passed++;
            end else begin
                if (`VERBOSITY >= VERBOSITY_INFO) begin
                    $display("[%0t] number failed: %0f (result: %0f - delta: %0f)",
                        $time, number, result, numbers_equal.delta);
                end
                num_failed++;
            end
        endtask

        task test();
            bit single_number_passed;
            bit test_passed;
            int passed = 0;
            int failed = 0;

            string test_name = "manual_numbers";

            print_test_start(test_name);

            @(posedge if_dut.cb);
            test_number(0.5, single_number_passed, passed, failed);
            // designed to fail, precision is too high for default floating 
            // point representation
            test_number(-5.324, single_number_passed, passed, failed);
            test_number(3.2, single_number_passed, passed, failed);
            // last case designed to fail, number is out of the default floating 
            // point representation range
            test_number(228.645, single_number_passed, passed, failed);

            test_passed = (failed == 0);

            print_test_result(test_name, test_passed);
            print_tests_stats(passed, failed);

        endtask

    endclass

endpackage
