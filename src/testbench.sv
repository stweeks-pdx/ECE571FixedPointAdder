module top;

	import floatingpointpkg::*;
	import fpclasspkg::*;

	localparam TRUE = 1'b1;
	localparam FALSE = 1'b0;
	localparam MAXFRAC = 23;
	parameter NORMMAX = 2**16; 

	// DUT logic
	float AddendA, AddendB, Result;
	logic Go, Clock, Reset, Zero, Inf, Nan, Ready;
	
	//coverage results
	static int sm_coverage,se_coverage,z_coverage,i_coverage,n_coverage;
	int NumTests;

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
		if (!(IsDenorm(AddendA) || IsDenorm(AddendB) || IsNaN(AddendA) || IsNaN(AddendB) || IsInf(AddendA) || IsInf(AddendB)))
		begin
	        	if ( (Result) != ShortrealToFloat(FloatToShortreal(AddendA) + FloatToShortreal(AddendB)) )
                    		$display("****ERORR Expected: Result = %b Received: Result = %b Inputs: AddendA = %b AddendB = %b",
                               ShortrealToFloat(FloatToShortreal(AddendA) + FloatToShortreal(AddendB)), Result, AddendA, AddendB);
		end
	endtask
	
	//coverage
	covergroup fpadd with function sample(logic[EXPBITS+FRACBITS:0]Result,logic Zero,Inf,Nan);
		option.at_least = 1;
		sign: coverpoint Result[EXPBITS+FRACBITS] iff (Ready);
		exp: coverpoint Result[EXPBITS+FRACBITS-1:FRACBITS] iff (Ready)
		{
			bins e1 = {[1:(2**EXPBITS-1)-1]};
			bins e2 = {[2**EXPBITS-1:(2**EXPBITS)-2]};
		}
		man: coverpoint Result[FRACBITS-1:0] iff (Ready)
		{
			bins m1 = {[0:2**20]};
			bins m2 = {[(2**20)+1:2**21]};
			bins m3 = {[(2**21)+1:2**22]};
			bins m4 = {[(2**22)+1:(2**23)-1]};
		}
		sgman: cross sign,man;
		sgex: cross sign,exp;
		
		zero: coverpoint Zero iff (Ready);
		inf: coverpoint Inf iff (Ready);
		nan: coverpoint Nan iff (Ready);
	endgroup
	
	fpadd fpcover = new;

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
				NumTests++;
				fpcover.sample(Result,Zero,Inf,Nan);
				sm_coverage = fpcover.sgman.get_coverage();
				se_coverage = fpcover.sgex.get_coverage();
				z_coverage = fpcover.zero.get_coverage();
				i_coverage = fpcover.inf.get_coverage();
				n_coverage = fpcover.nan.get_coverage();
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
				NumTests++;
				fpcover.sample(Result,Zero,Inf,Nan);
				sm_coverage = fpcover.sgman.get_coverage();
				se_coverage = fpcover.sgex.get_coverage();
				z_coverage = fpcover.zero.get_coverage();
				i_coverage = fpcover.inf.get_coverage();
				n_coverage = fpcover.nan.get_coverage();
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
				NumTests++;
				fpcover.sample(Result,Zero,Inf,Nan);
				sm_coverage = fpcover.sgman.get_coverage();
				se_coverage = fpcover.sgex.get_coverage();
				z_coverage = fpcover.zero.get_coverage();
				i_coverage = fpcover.inf.get_coverage();
				n_coverage = fpcover.nan.get_coverage();
			end
		
		`ifdef DEBUG
			$display("Total number of testcases = %d",NumTests);
			$display("sm_coverage = %d",sm_coverage);
			$display("se_coverage = %d",se_coverage);
			$display("z_coverage  = %d",z_coverage );
			$display("i_coverage = %d",i_coverage);
			$display("n_coverage = %d",n_coverage);
		`endif

		$finish;
	end

endmodule
