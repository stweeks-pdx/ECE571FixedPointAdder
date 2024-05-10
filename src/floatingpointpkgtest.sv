import floatingpointpkg::*;
module top;
	int error;

	task automatic TestFunc(input float_t float);	
		logic Zero,Denorm,Nan,Inf;
		logic FZero,FDenorm,FNan,FInf;

		{Zero,Denorm,Nan,Inf} = '0;
		if (float.exp === 0)
		begin
			if (float.frac === 0)
				Zero = '1;
			else
				Denorm = '1;
		end
		else if (float.exp === '1)
		begin
			if (float.frac === 0)
				Inf = '1;
			else
				Nan = '1;
		end

		FZero = IsZero(float); FDenorm = IsDenorm(float); FNan = IsNaN(float); FInf = IsInf(float);

		if ({Zero,Denorm,Nan,Inf} !== {FZero,FDenorm,FNan,FInf})
		begin
			error = 1;
			$display("Input: %h",float);
			$display("Expected Output: IsZero = %b, IsDenorm = %b, IsNaN = %b, IsInf = %b",Zero,Denorm,Nan,Inf);
			$display("Actual Output: IsZero = %b, IsDenorm = %b, IsNaN = %b, IsInf = %b",FZero,FDenorm,FNan,FInf);
		end
	endtask


	initial
	begin
		error = 0;
		//Zero
		TestFunc('0);
		TestFunc('1);

		//denorm
		TestFunc(32'h00484444);
		TestFunc(32'h807C67E7);

		//NaN
		TestFunc(32'hFFD5E7E7);
		TestFunc(32'h7FAAD998);

		//Inf
		TestFunc(32'hFF800000);
		TestFunc(32'h7F800000);

		if (error === 1)
			$display("TESTS FAILED");
		else
			$display("TESTS PASSED");
		$finish;
	end
endmodule
