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
    return($bitstoshortreal(f));
    endfunction: FloatToShortreal

    function automatic float ShortrealToFloat(input shortreal s);
    return($shortrealtobits(s));
    endfunction: ShortrealToFloat

    function automatic void DisplayFloatComponents(input float f);
    $write("%1b %2h %h\n",f.sign, f.exp, f.frac);
    endfunction: DisplayFloatComponents

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
