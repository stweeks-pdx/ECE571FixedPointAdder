import floatingpointpkg::*;
module top;

	task automatic test(input float_t float);
	$display("IsZero = %b, IsDenorm = %b, IsNaN = %b, IsInf = %b",IsZero(float),IsDenorm(float), IsNaN(float), IsInf(float));
	endtask

	initial
	begin
	test('0);
	//denorm
	test(32'h00484444);
	test(32'h807C67E7);
	#10;
	//NaN
	test(32'hFFD5E7E7);
	test(32'h7FAAD998);
	//Inf
	test(32'hFF800000);
	test(32'h7F800000);
	$finish;
	end
endmodule
