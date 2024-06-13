package fpclasspkg;

let EXPBIT = 8;
let FRACBIT = 23;
let BIAS = 8'h7F;
let MAXEXPVALUE = 8'h7F;
let MINEXPVALUE = 8'hFF;

import floatingpointpkg::*;


class FpClass;
    /*** Class Variables ***/
    rand logic sign;
    rand logic [EXPBIT-1:0] exp;
    rand logic [FRACBIT-1:0] significand;
    logic signed [EXPBIT-1:0] minexp, maxexp;

    /*** Function Definitions ***/
    extern function float createFloat();
    extern function void setSign(input logic newSign);
    extern function logic getSign();
    extern function void setExp(input logic [EXPBIT-1:0] newExp);
    extern function logic [EXPBIT-1:0] getExp();
    extern function void setSignificand(input logic [FRACBIT-1:0] newSignificand);
    extern function logic [FRACBIT-1:0] getSignificand();
    extern function logic signed [EXPBIT-1:0] getMinExp();
    extern function logic signed [EXPBIT-1:0] getMaxExp();
    extern function void setMinExp(input logic signed [EXPBIT-1:0] newMin);
    extern function void setMaxExp(input logic signed [EXPBIT-1:0] newMax);
    extern function void display();

    /*** Constraints ***/
    constraint nodenorm_c {
        if (this.significand != 0) this.exp != 0;
    }

    constraint alldenorm_c {
        this.exp == 0;
        this.significand inside {[1:2**FRACBIT-1]};
    }

    constraint nonan_c {
        if (this.significand != 0) this.exp != (2**EXPBIT - 1); 
    }

    constraint noinf_c {
        if (this.significand == 0) this.exp != (2**EXPBIT - 1);
    }

    constraint exprange_c {
        this.exp inside {[this.minexp + BIAS:this.maxexp + BIAS]};
    }

    constraint onlynorm_c {
        this.exp inside {[1:254]};
        this.significand != 0;
    }

    /*** Class Constructor ***/
    function new(); // new constructor defaults to 0 fraction
        this.sign = 0;
        this.exp = '0;
        this.significand = '0;
        this.minexp = MINEXPVALUE;
        this.maxexp = MAXEXPVALUE;
    endfunction
endclass;


/*** Function Definitions ***/
function automatic float FpClass::createFloat();
    float newFloat = '{this.sign, this.exp, this.significand};
    return newFloat;
endfunction

function automatic void FpClass::setSign(input logic newSign);
    this.sign = newSign;
endfunction

function automatic logic FpClass::getSign();
    return this.sign;
endfunction

function automatic void FpClass::setExp(input logic [EXPBIT-1:0] newExp);
    this.exp = newExp;
endfunction

function automatic logic [EXPBIT-1:0] FpClass::getExp();
    return this.exp;
endfunction

function automatic void FpClass::setSignificand(input logic [FRACBIT-1:0] newSignificand);
    this.significand = newSignificand;
endfunction

function automatic logic [FRACBIT-1:0] FpClass::getSignificand();
    return this.significand;
endfunction

function automatic logic signed [EXPBIT-1:0] FpClass::getMinExp();
    return this.minexp;
endfunction

function automatic logic signed [EXPBIT-1:0] FpClass::getMaxExp();
    return this.maxexp;
endfunction

function automatic void FpClass::setMinExp(input logic signed [EXPBIT-1:0] newMin);
    this.minexp = newMin;
endfunction

function automatic void FpClass::setMaxExp(input logic signed [EXPBIT-1:0] newMax);
    this.maxexp = newMax;
endfunction

function automatic void FpClass::display();
    $display("sign:%b  exponent:%b   significand:%b  minexp:%d  maxexp:%d", this.sign, this.exp, this.significand, this.minexp, this.maxexp);
endfunction

endpackage
