package floatingpointpkg;
    parameter VERSION = "0.1";
    parameter EXPBITS = 8;
    parameter FRACBITS = 23;	

    typedef struct packed {
	logic sign;
	logic [EXPBITS-1:0] exp;
	logic [FRACBITS-1:0] frac;	
    } float_t;

    typedef float_t float;

    function automatic shortreal FloatToShortreal(input float f);
    endfunction

    function automatic float ShortrealToFloat(input shortreal s);
    endfunction

    function automatic void DisplayFloatComponents(input float f);
    endfunction

    function automatic bit IsZero(input float f);
	return ((f.exp === '0) && (f.frac === 0));
    endfunction

    function automatic bit IsDenorm(input float f);
	return ((f.exp === '0) && (f.frac !== '0));
    endfunction

    function automatic bit IsNaN(input float f);
	return ((f.exp === '1) && (f.frac !== '0));
    endfunction

    function automatic bit IsInf(input float f);
	return ((f.exp === '1) && (f.frac === '0));
    endfunction


endpackage
