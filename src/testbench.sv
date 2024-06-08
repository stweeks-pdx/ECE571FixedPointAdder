module top;

	import floatingpointpkg::*;
	import fpclasspkg::*;

	localparam TRUE = 1'b1;
	localparam FALSE = 1'b0;
	localparam MAXFRAC = 23;
	localparam NORMMAX = 2**32;

	// DUT logic
	float AddendA, AddendB, Result;
	logic Go, Clock, Reset, Zero, Inf, Nan, Ready;

	// Test variables
	FpClass testclass;

	FloatingPointAdder DUT(.AddendA, .AddendB, .Go, .Clock, .Reset, .Result, .Ready, .Zero, .Inf, .Nan);

	task automatic ClearConstraints(input FpClass fpc);
		fpc.constraint_mode(0);
	endtask

	task automatic RunAdd;
		repeat (1) @(negedge Clock);
		Go = 1'b1;
		@(negedge Clock) Go = 1'b0;
		wait(Ready);
		// timeout and check need to go here somehow
	endtask

	initial
	begin
		Clock = FALSE;
		forever #50 Clock = ~Clock;
	end

	initial
	begin
		`ifdef DEBUG
			$monitor("AddendA: %p, AddendB: %p, Go: %b, Reset: %b, Result: %p, Ready: %b, Zero: %b, Inf: %b, Nan: %b, Clock: %b",
				AddendA, AddendB, Go, Reset, Result, Ready, Zero, Inf, Nan, Clock);
		`endif

		Reset = 1;
		repeat (2) @(negedge Clock);
		Reset = 0;
		/**************************/
		/**** DIRECTED TESTING ****/
		/**************************/
		// Create and add zeros of differing signs.
		repeat (1) @(negedge Clock);
		AddendA = '{1, 0, 0};
		repeat (1) @(negedge Clock);
		AddendB = '{0, 0, 0};

		RunAdd();

		// Check zero added to a number
		repeat (1) @(negedge Clock);
		AddendA = '{0, 0, 0};
		repeat (1) @(negedge Clock);
		AddendB = '{1, 110, 23'h7b_ef_19};

		RunAdd();
		
		repeat (1) @(negedge Clock);
		AddendA = '{1, 0, 0};
		repeat (1) @(negedge Clock);
		AddendB = '{1, 110, 23'h7b_ef_19};

		RunAdd();
		
		// Check two large numbers added together.
		repeat (2) @(negedge Clock);
		AddendA = '{0, 254, (2**MAXFRAC - 1)};
		repeat (1) @(negedge Clock);
		AddendB = '{0, 254, (2**MAXFRAC - 1)};

		RunAdd();

		// Check largest and smallest numbers added together.
		repeat (2) @(negedge Clock);
		AddendA = '{0, 254, (2**MAXFRAC - 1)};
		repeat (1) @(negedge Clock);
		AddendB = '{1, 254, (2**MAXFRAC - 1)};

		RunAdd();

		// Check the two smallest numbers added together.
		repeat (2) @(negedge Clock);
		AddendA = '{1, 254, (2**MAXFRAC - 1)};
		repeat (1) @(negedge Clock);
		AddendB = '{1, 254, (2**MAXFRAC - 1)};

		RunAdd();

		// Check two regular floats (opposite signs)
		repeat (2) @(negedge Clock);
		AddendA = ShortrealToFloat(-234.56);
		repeat (1) @(negedge Clock);
		AddendB = ShortrealToFloat(156.12);

		RunAdd();

		// Check two regular floats (same signs)
		repeat (2) @(negedge Clock);
		AddendA = ShortrealToFloat(15632.476);
		repeat (1) @(negedge Clock);
		AddendB = ShortrealToFloat(567.7892);

		RunAdd();

		repeat (2) @(negedge Clock);
		AddendA = ShortrealToFloat(-5678.93854);
		repeat (1) @(negedge Clock);
		AddendB = ShortrealToFloat(-323.45671);

		RunAdd();
		

		/****************************/
		/**** RANDOMIZED TESTING ****/
		/***************************/
		// Test randomized test classes of normalized numbers only
		testclass = new();
		ClearConstraints(testclass);
		testclass.onlynorm_c.constraint_mode(1);
		for(longint i = 0; i < NORMMAX; i++)
		begin
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a normalized float");
			repeat (1) @(negedge Clock);
			AddendA = testclass.createFloat();
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a normalized float");
			repeat (1) @(negedge Clock);
			AddendB = testclass.createFloat();
			RunAdd();
		end

		ClearConstraints(testclass);
		testclass.alldenorm_c.constraint_mode(1);
		for(longint i = 0; i < NORMMAX; i++)
		begin
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a denormalized float");
			repeat (1) @(negedge Clock);
			AddendA = testclass.createFloat();
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a denormalized float");
			repeat (1) @(negedge Clock);
			AddendB = testclass.createFloat();
			RunAdd();
		end

		ClearConstraints(testclass);
		for(longint i = 0; i < NORMMAX; i++)
		begin
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a float");
			repeat (1) @(negedge Clock);
			AddendA = testclass.createFloat();
			assert (testclass.randomize()) else $fatal(0, "Randomization failed to create a float");
			repeat (1) @(negedge Clock);
			AddendB = testclass.createFloat();
			RunAdd();
		end
		
		
	end

endmodule
