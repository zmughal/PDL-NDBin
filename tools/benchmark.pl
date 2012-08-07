# benchmark PDL::NDBin

use strict;
use warnings;
use blib;				# prefer development version of PDL::NDBin
use Benchmark qw( cmpthese timethese );
use Fcntl;
use PDL;
use PDL::NetCDF;
use PDL::NDBin;
use Path::Class;
use Getopt::Long qw( :config bundling );
use Text::TabularDisplay;

my $iter = 1;
my @functions;
my $n = 25;
my $output;
my $usage = <<EOF;
Usage:  $0  [ options ]  input_file

Options:
  --bins <n>         | -n <n>   use <n> bins along every dimension (default: $n)
  --function <func>             select <func> to benchmark; may be specified more than once
                                and may use comma-separated values (default: @functions)
  --iters <n>        | -i <n>   perform <n> iterations for better accuracy (default: $iter)
  --output           | -o       do output actual return value from functions

EOF
GetOptions( 'bins|n=i'    => \$n,
	    'function=s'  => \@functions,
	    'iter|i=i'    => \$iter,
	    'output|o'    => \$output ) or die $usage;
my $file = shift;
$file or die $usage;
@ARGV and die $usage;
unless( @functions ) { @functions = qw( histogram want count ) }
@functions = split /,/ => join ',' => @functions;
my %selected = map { $_ => 1 } @functions;

# we're going to bin latitude and longitude from -70 .. 70
my( $min, $max, $step ) = ( -70, 70, 140/$n );

print "Reading $file ... ";
my $nc = PDL::NetCDF->new( $file, { MODE => O_RDONLY } );
my( $lat, $lon, $flux ) = map $nc->get( $_ ), qw( latitude longitude gerb_flux );
undef $nc;
print "done\n";

# shortcuts
my @axis = ( $step, $min, $n );
my %data = ( lat => $lat, lon => $lon, flux => $flux );
my $want = sub { shift->want->nelem };
my $selection = sub { shift->selection->nelem };
my $avg = sub { $_[0]->want->nelem ? shift->selection->avg : undef };
my %functions = (
	# one-dimensional histograms
	hist         => sub { hist $lat, $min, $max, $step },
	histogram    => sub { histogram $lat, $step, $min, $n },
	want         => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ]],
					vars => [[ lat => $want ]] );
				$binner->process( %data )->output
			},
	# $iter->selection->nelem is bound to be slower than $iter->want->nelem, but the purpose here is to compare
	selection    => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ]],
					vars => [[ lat => $selection ]] );
				$binner->process( %data )->output
			},
	count        => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ]],
					vars => [[ lat => 'Count' ]] );
				$binner->process( %data )->output
			},

	# two-dimensional histograms
	histogram2d  => sub { histogram2d $lat, $lon, $step, $min, $n, $step, $min, $n },
	want2d       => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ], [ lon => @axis ]],
					vars => [[ lat => $want ]] );
				$binner->process( %data )->output
			},
	count2d      => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ], [ lon => @axis ]],
					vars => [[ lat => 'Count' ]] );
				$binner->process( %data )->output
			},

	# average flux using either a coderef or a class (XS-optimized)
	coderef      => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ], [ lon => @axis ]],
					vars => [[ flux => $avg ]] );
				$binner->process( %data )->output
			},
	class        => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => @axis ], [ lon => @axis ]],
					vars => [[ flux => 'Avg' ]] );
				$binner->process( %data )->output
			},
);

my %output;
my $results = timethese( $iter,
			 { map  { my $f = $_; $_ => sub { $output{ $f } = $functions{ $f }->() } }
			   grep { $selected{ $_ } }
			   keys  %functions
			 } );
print "\nRelative performance:\n";
cmpthese( $results );
print "\n";
if( $output ) {
	print "Actual output:\n";
	while( my( $func, $out ) = each %output ) { printf "%20s: %s\n", $func, $out }
	print "\n";
}
print "Norm of difference between output piddles:\n";
my $table = Text::TabularDisplay->new( '', keys %output );
for my $row ( keys %output ) {
	$table->add( $row, map { my $diff = $output{ $row } - $_; $diff->abs->max } values %output );
}
print $table->render, "\n\n";