import floatingpointpkg::*;

module top;

float inf;
float nan;
float f,S_T_F,nf;
float zero;
float denorm;
bit [31:0] b;
shortreal s, ns;
bit error;

initial
begin

//******Verification of  fpnumberfromcomponents verified with 263.30 Float number**************//
$display("***********************************************************************************\n");
$display("Verification of  fpnumberfromcomponents verified with 263.30 Float number\n\n");

f	=	fpnumberfromcomponents(0,135,239206);
$display("f = %b\n", f);

nf	=	fpnumberfromcomponents(1,135,239206);
$display("nf = %b\n", nf);



$display("***********************************************************************************\n\n\n");
//***********************************************************************************************//


//***************************************Verification of FloatToShortreal************************//
$display("***********************************************************************************\n");
$display("Verification of FloatToShortreal\n\n");


s	=	FloatToShortreal(f);
$display("s = %f\n",s);


ns	=	FloatToShortreal(nf);
$display("ns = %f\n",ns);

$display("***********************************************************************************\n\n\n");


//***************************************Verification of ShortrealToFloat************************//
$display("***********************************************************************************\n");
$display("Verification of ShortrealToFloat\n\n");

S_T_F	=	ShortrealToFloat(263.30);
$display("ShortrealToFloat = %b\n",S_T_F);

$display("***********************************************************************************\n\n\n");
//***********************************************************************************************//


//****************************VERIFICATION OF THE fpnumberfromcomponents and ShortrealToFloat**************************************//
$display("***********************************************************************************\n");
$display("SELF CHECKING!!   Verification of fpnumberfromcomponents and ShortrealToFloat\n\n");

if(S_T_F === f)
	$display("Both the fpnumberfromcomponents and ShortrealToFloat MATCHED!! for same input value\n");
else
	$error("Both the fpnumberfromcomponents and ShortrealToFloat NOT_MATCHED!! for same input value\n");

$display("***********************************************************************************\n\n\n");
//*************************************************************************************************************************************//


//******************************************create and test + and-inf********************************************************************//
$display("***********************************************************************************\n");
$display("Verification of isINFINITY\n\n");

inf = fpnumberfromcomponents('0,'1,'0);
if (!isInf(inf))
	begin
	$display("*** error *** \n isinfinity +inf broken");
	error = '1;
	end
DisplayFloatComponents(inf);
$display("%f",FloatToShortreal(inf));

inf = fpnumberfromcomponents('1,'1,'0);
if (!isInf(inf))
	begin
	$display("*** error *** \n isinfinity -inf broken");
	error = '1;	
	end
DisplayFloatComponents(inf);
$display("%f",FloatToShortreal(inf));



$display("***********************************************************************************\n\n\n");
//********************************************************************************************************************************************//


//********************************************create and test nan*********************************//
$display("***********************************************************************************\n");
$display("Verification of NAN\n\n");


nan = fpnumberfromcomponents('0,'1,'1);
if (!isNaN(nan))
	begin
	$display("*** error *** \n isnan +NaN broken");
	error = '1;	
	end
DisplayFloatComponents(nan);
$display("%f",FloatToShortreal(nan));

nan = fpnumberfromcomponents('1,'1,'1);
if (!isNaN(nan))
	begin
	$display("*** error *** \n isnan -NaN broken");
	error = '1;	
	end
DisplayFloatComponents(nan);
$display("%f",FloatToShortreal(nan));

$display("***********************************************************************************\n\n\n");
//********************************************************************************************************************************************//

//********************************************create and test ZERO*********************************//
$display("***********************************************************************************\n");
$display("Verification of isZERO\n\n");

zero = fpnumberfromcomponents('0,'0,'0);
if (!isZero(zero))
	begin
	$display("*** error *** \n iszero +0 broken");	
	error = '1;		
	end
DisplayFloatComponents(zero);
$display("%f",FloatToShortreal(zero));

$display("***********************************************************************************\n\n\n");
//********************************************************************************************************************************************//

$finish ();
end
endmodule
