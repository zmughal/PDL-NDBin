# multidimensional binning & histogramming - flattening tests

use strict;
use warnings;
use Test::More tests => 10;
use Test::PDL;
use Test::NoWarnings;
use PDL;
use PDL::NDBin::Actions_PP;

# compatibility with non-64-bit PDL versions
BEGIN { if( ! defined &PDL::indx ) { *indx = \&PDL::long } }

###
{
	# variable declarations
	my( $x, $y, $a, $b, $idx );

	#
	$x = sequence 10;
	$y = sequence 10;
	$y->inplace->setvaltobad( 5 );

	$a = $x->_flatten_into( 0, 2,1,4 );
	is_pdl $a, indx( 0,0,0,1,1,2,2,3,3,3 ), 'start with pdl=0, clip to 4 bins';

	$a = $x->_flatten_into( zeroes($x), 2,1,4 );
	is_pdl $a, indx( 0,0,0,1,1,2,2,3,3,3 ), 'start with pdl=zeroes, clip to 4 bins';

	$a = $x->_flatten_into( zeroes($x), 2,1,5 );
	is_pdl $a, indx( 0,0,0,1,1,2,2,3,3,4 ), 'clip to 5 bins';

	$a = $x->_flatten_into( zeroes($x), 2,1,4 );
	$b = $y->_flatten_into( $a, 2,1,4 );
	is_pdl $b, indx( 0,0,0,5,5,-1,10,15,15,15 )->setvaltobad( -1 ), 'flatten into existing list';

	$idx = 0;
	$idx = $x->_flatten_into( $idx, 2,1,4 );
	is_pdl $idx, indx( 0,0,0,1,1,2,2,3,3,3 ), 'chained flattening';
	$idx = $y->_flatten_into( $idx, 2,1,4 );
	is_pdl $idx, indx( 0,0,0,5,5,-1,10,15,15,15 )->setvaltobad( -1 ), 'chained flattening';
}

###
{
	my $x = pdl( -5.1,-4.1,-3.1,-2.1,-1.1,-0.1,0.9,1.9,2.9,3.9,4.9 );
	my $a = $x->_flatten_into( 0, 1,-2,5 );
	is_pdl $a, indx( 0,0,0,0,0,1,2,3,4,4,4 ), 'clips at lowest and highest bin';
}

###
{
	#
	my $x = pdl( 0.80343195756814, 0.927874117015989, 0.629377038954896,
		0.813670019709157, 0.109892272285908, 0.909970194086767,
		0.231683873941019, 0.541144640924436, 0.109126349902372,
		0.601227261650592, 0.800708249693155, 0.562154069998975,
		0.574649518618561, 0.917305742006434, 0.204621294120894,
		0.630545449996241, 0.95674098513047, 0.5207158616968,
		0.742677003907783, 0.90018231894738, 0.0404266059139395,
		0.81040945956606, 0.386094593711871, 0.31797246027795,
		0.160611381681722, 0.0812357490052023, 0.791703099246757,
		0.298083660095962, 0.54736854337516, 0.392918865575055,
		0.651652420110448, 0.365467498065463, 0.50704056607049,
		0.488694920115989, 0.450662255075041, 0.73571525977156,
		0.41057359097859, 0.382802826524411, 0.969053606427192,
		0.48397333607064, 0.4111483677971, 0.635257945104854,
		0.329757023357541, 0.916312131413726, 0.57857076253514,
		0.508977139291247, 0.178312829836724, 0.501361601031242,
		0.676050922073447, 0.081219748071959, 0.797391552386284,
		0.64761213867417, 0.152065158646582, 0.396937791150478,
		0.885512940154765, 0.262570704819403, 0.440216327638925,
		0.110092011227096, 0.120499666242477, 0.334622882366297,
		0.295769733072508, 0.980014680296748, 0.931962327782852,
		0.308271035376769, 0.419350219432321, 0.55883701702416,
		0.527096035384044, 0.240310988842971, 0.874774908523552,
		0.42382514257973, 0.756721012661355, 0.231013706304417,
		0.975922828385283, 0.141785305298072, 0.93339052624928,
		0.413658379880623, 0.151790270396521, 0.583733192655941,
		0.983214448371424, 0.49160822643568, 0.382456913103002,
		0.284625084857254, 0.0436261302672385, 0.958944166647832,
		0.792725379467033, 0.828596950260177, 0.729599348026479,
		0.393513513220022, 0.883953760697725, 0.0639529014848108,
		0.152871185165491, 0.625774872836509, 0.245459557055302,
		0.658813284799706, 0.467741151093886, 0.859315736246053,
		0.810342266540719, 0.708226626801519, 0.261316913965867,
		0.536299754533793 ); # 100 random numbers
	my( $step, $min, $n ) = ( .1, 0, 10 );
	my $expected = indx( ($x - $min)/$step );
	$expected->inplace->clip( 0, $n-1 );
	my $got = $x->_flatten_into( 0, $step, $min, $n );
	is_pdl $got, $expected, 'cross-check with PDL implementation (old implementation)';
}

###
{
	#
	my $x = pdl( 0.431571966576488, 0.496883088580461, 0.538516671202284,
		0.0682823640262953, 0.148652836575895, 0.250695924260057,
		0.600853331756607, 0.452168677741689, 0.533622053443114,
		0.560363504628867, 0.810273810771644, 0.0684447321013764,
		0.561010417791284, 0.0432483699057826, 0.741183214428471,
		0.707101926760622, 0.794649229822259, 0.686304563771984,
		0.309164732525868, 0.164776474311118, 0.536863998111489,
		0.87766162892926, 0.0890104251808701, 0.546956938207721,
		0.644192871565085, 0.529947556844775, 0.88988926340981,
		0.648254677556487, 0.332636662911501, 0.585008522874276,
		0.900956609457179, 0.848857325488261, 0.42809580010783,
		0.990163126871806, 0.228876589585308, 0.244189389023695,
		0.783415685839561, 0.515185408466195, 0.915502035914837,
		0.410507335923477, 0.534103577372694, 0.178445677913146,
		0.983906167314142, 0.169823190511671, 0.630180031878457,
		0.227277760316511, 0.851781254775343, 0.461969758360503,
		0.619794008493447, 0.494537155553331, 0.663732486685216,
		0.359206201531499, 0.00729569030183441, 0.968943430934516,
		0.0221454264012912, 0.909553854280851, 0.0286827996313583,
		0.775263450986529, 0.987163151076611, 0.79971296625596,
		0.32309744104116, 0.681416371249227, 0.520069689241094,
		0.358230548735541, 0.50085913064709, 0.21851824315101,
		0.164360047743127, 0.636481741897292, 0.865008470478944,
		0.517710157344695, 0.301429248781997, 0.811531179935024,
		0.711262714894165, 0.800930655866068, 0.842703697419932,
		0.9442207685913, 0.465532065183869, 0.893827231611809,
		0.489863181652023, 0.831675168822009, 0.00172173089965,
		0.205604669424503, 0.425381183332956, 0.840240163365941,
		0.476582424603425, 0.90625632901974, 0.40589026151147,
		0.857711032455335, 0.912128823197666, 0.855419788593792,
		0.0929283725066448, 0.918232143272498, 0.117004446229704,
		0.543767121710133, 0.144636425874577, 0.325744227532986,
		0.761640182081354, 0.507734031479089, 0.136277454759703,
		0.819236345257487 ); # 100 random numbers
	my $y = pdl( 0.681040852869959, 0.667749076007993, 0.207083018302125,
		0.330435733400869, 0.446327232651203, 0.840597182497717,
		0.580853247453287, 0.412068756105405, 0.395506760096769,
		0.363994218933613, 0.754501417761087, 0.0860952292473272,
		0.183442419657684, 0.970495138864649, 0.387702563385115,
		0.130288077140101, 0.618323574279945, 0.0848172000833358,
		0.610277087258918, 0.980249119064872, 0.944648736689391,
		0.938431772684041, 0.888073110290545, 0.247436919697201,
		0.683358063848775, 0.854020101307754, 0.661611074443595,
		0.518382546395095, 0.60212244294944, 0.239450852765302,
		0.320794785566076, 0.123213360072604, 0.521444505317621,
		0.631417169147056, 0.587160348680083, 0.840508927564834,
		0.927993048414198, 0.407927495599424, 0.641907672322272,
		0.191216420978172, 0.31723397818681, 0.188079223676937,
		0.797908711933285, 0.93501952601364, 0.952820816894576,
		0.114183748063525, 0.304707697733757, 0.126973979151664,
		0.268373867668235, 0.0882074389975571, 0.0880415624952313,
		0.0198084553932247, 0.484342098992347, 0.0501218474325213,
		0.153558961616252, 0.748080696465216, 0.532863522501291,
		0.744219747318709, 0.775273974447128, 0.0350395665169927,
		0.0193010984670998, 0.340477941901057, 0.893051104371292,
		0.692863210860473, 0.470939827624765, 0.24698468109429,
		0.763401868246898, 0.903835735737808, 0.379819488029472,
		0.467275617318805, 0.450525395939248, 0.776528885938511,
		0.714604263970305, 0.689739030159217, 0.269416360332837,
		0.4603351348321, 0.41063810307627, 0.727285138342282,
		0.56268853990127, 0.807543480532665, 0.430910840143103,
		0.00207725332191444, 0.923341692133999, 0.71897312496845,
		0.984697754383109, 0.0557708747062833, 0.0859784993707784,
		0.562022162092397, 0.384392093255403, 0.889502146365487,
		0.571027451377955, 0.464512479838767, 0.381909013270207,
		0.644535945818077, 0.855541963815138, 0.560207350206319,
		0.0495081686784751, 0.334377830910711, 0.388446111086534,
		0.979258705530192 ); # yet more random numbers :-)
	my( $step, $min, $n ) = ( .1, 0, 10 );
	my $expected = 0;
	for my $axis ( $x, $y ) {
		my $binned = indx( ($axis - $min)/$step );
		$binned->inplace->clip( 0, $n-1 );
		$expected = $expected * $n + $binned;
	}
	my $got = $x->_flatten_into( 0, $step, $min, $n );
	$got = $y->_flatten_into( $got, $step, $min, $n );
	is_pdl $got, $expected, 'cross-check with PDL implementation for two axes (old implementation)';
}
