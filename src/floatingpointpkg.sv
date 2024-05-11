package floatingpointpkg;
    parameter VERSION = "0.1";
    parameter EXPBITS = 8;
    parameter FRACBITS = 23;
    parameter EXPONENT = 255;	

    typedef struct packed {
	logic sign;
	logic [EXPBITS-1:0] exp;
	logic [FRACBITS-1:0] frac;	
    } float_t;

    typedef float_t float;

    function float fpnumberfromcomponents(input bit sign, bit [EXPBITS-1:0] exponent, bit [FRACBITS-1:0] fraction);
		fpnumberfromcomponents.sign = sign;
		fpnumberfromcomponents.exp = exponent;
		fpnumberfromcomponents.frac = fraction;
    endfunction: fpnumberfromcomponents

    function automatic shortreal FloatToShortreal(input float f);
	    return($bitstoshortreal(f));
    endfunction

    function automatic float ShortrealToFloat(input shortreal s);
	    return($shortrealtobits(s));
    endfunction

    function automatic void DisplayFloatComponents(input float f);
	    $display("sign : %1b exponent: %2h fraction: %h\n",f.sign, f.exp, f.frac);
    endfunction

    function automatic bit IsZero(input float f);
	return ((f.exp === '0) && (f.frac === '0));
    endfunction

    function automatic bit IsDenorm(input float f);
	return ((f.exp === '0) && (f.frac !== '0));
    endfunction

    function automatic bit IsNaN(input float f);
	return ((f.exp === EXPONENT) && (f.frac !== '0));
    endfunction

    function automatic bit IsInf(input float f);
	return ((f.exp === EXPONENT) && (f.frac === '0));
    endfunction


endpackage
