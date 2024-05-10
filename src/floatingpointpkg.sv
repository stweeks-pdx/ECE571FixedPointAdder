package floatingpointpkg;

localparam EXPONENT_BITS = 8;	// number of exponent bits
localparam FRACTION_BITS = 23;	// number of significand bits

typedef
  struct packed {
    bit sign;					// sign
    bit [EXPONENT_BITS-1:0] exponent;		// exponent
    bit [FRACTION_BITS-1:0] fraction;		// significand
  } float;


// construct floating point number from components

function float fpnumberfromcomponents(input bit sign, bit [EXPONENT_BITS-1:0] exp, bit [FRACTION_BITS-1:0] frac);
	fpnumberfromcomponents.sign = sign;
	fpnumberfromcomponents.exponent = exp;
	fpnumberfromcomponents.fraction = frac;
endfunction: fpnumberfromcomponents

// return shortreal representation of floating point number

function automatic shortreal FloatToShortreal(input float f);
	return($bitstoshortreal(f));
endfunction: FloatToShortreal


// construct floating point number from short real

function automatic float ShortrealToFloat(input shortreal s);
	return($shortrealtobits(s));
endfunction: ShortrealToFloat

//Display a floating point number's components
function automatic void DisplayFloatComponents(input float f);
    $display("sign : %1b exponent: %2h fraction: %h\n",f.sign, f.exponent, f.fraction);
endfunction: DisplayFloatComponents

//**********************************ALL FLAGS***********************************//
function bit isZero(float f);
	return((f.exponent === '0) && (f.fraction === '0));
endfunction: isZero


function bit isDenorm(float f);
	return((f.exponent === '0) && (f.fraction !== '0));
endfunction: isDenorm


function bit isNaN(float f);
	return((f.exponent === '1) && f.fraction !== '0);
endfunction: isNaN


function bit isInf(float f);
return((f.exponent === '1) && (f.fraction === '0));
endfunction: isInf

//************************************************************************************//

endpackage
