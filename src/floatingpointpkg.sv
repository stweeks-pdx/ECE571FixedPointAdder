package floatingpointpkg;
    parameter VERSION = "0.1";

    typedef struct packed {
    } float_t;

    typedef float_t float;

    function automatic shortreal FloatToShortreal(input float f);
    endfunction

    function automatic float ShortrealToFloat(input shortreal s);
    endfunction

    function automatic void DisplayFloatComponents(input float f);
    endfunction

    function automatic bit IsZero(input float f);
    endfunction

    function automatic bit IsDenorm(input float f);
    endfunction

    function automatic bit IsNaN(input float f);
    endfunction

    function automatic bit IsInf(input float f);
    endfunction


endpackage
