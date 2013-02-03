package PDL::NDBin::Iterator;
# ABSTRACT: Iterator object for PDL::NDBin

use strict;
use warnings;
use Carp;
use List::Util qw( reduce );

sub new
{
	my $class = shift;
	my( $bins, $array, $idx ) = @_;
	grep { ! ($_ > 0) } @$bins and croak 'new: need at least one bin along every dimension';
	@$array or croak 'new: need at least one element in the array';
	defined $idx or croak 'new: need a list of flattened bin numbers';
	my $self = {
		bins   => $bins,
		array  => $array,
		idx    => $idx,
		active => [ (1) x @$array ],
		bin    => 0,
		var    => -1,
	};
	return bless $self, $class;
}

sub next1
{
	my $self = shift;
	return if $self->done;
	$self->{var}++;
	undef $self->{selection};		# we're switching to a new var!
	if( $self->{var} >= $self->nvars ) {
		$self->{var} = 0;
		$self->{bin}++;
		undef $self->{want};		# we're switching to a new bin!
		undef $self->{unflattened};
		return if $self->done;
	}
	return $self->{bin}, $self->{var};
}

sub next
{
	my $self = shift;
	my( $bin, $var );
	do {
		( $bin, $var ) = $self->next1;
		return if $self->done;
	} until $self->var_active;
	return wantarray ? ($bin, $var) : !$self->done;
}

sub bin   { $_[0]->{bin} }
sub done  { $_[0]->{bin} >= $_[0]->nbins }
sub bins  { @{ $_[0]->{bins} } }
sub nbins { $_[0]->{nbins} ||= reduce { $a * $b } $_[0]->bins }
sub nvars { $_[0]->{nvars} ||= scalar @{ $_[0]->{array} } }
sub data  { $_[0]->{array}->[ $_[0]->{var} ] }
sub idx   { $_[0]->{idx} }

# whether the current variable is still active, i.e., whether any bins remain
# to be computed (if all bins have been computed, the variable is considered to
# be inactive)
#
# this method is either a getter or a setter, depending on whether an argument
# is supplied
sub var_active
{
	my $self = shift;
	my $i = $self->{var};
	if( @_ ) { $self->{active}->[ $i ] = shift }
	else { $self->{active}->[ $i ] }
}

sub want
{
	my $self = shift;
	unless( defined $self->{want} ) {
		$self->{want} = PDL::which $self->idx == $self->{bin};
	}
	return $self->{want};
}

sub selection
{
	my $self = shift;
	unless( defined $self->{selection} ) {
		$self->{selection} = $self->data->index( $self->want );
	}
	return $self->{selection};
}

# unflatten bin number: yields bin number along each axis
sub unflatten
{
	my $self = shift;
	unless( defined $self->{unflattened} ) {
		my $q = $self->{bin}; # quotient
		$self->{unflattened} =
			[ map {
				( $q, my $r ) = do { use integer; ( $q / $_, $q % $_ ) };
				$r
			      } $self->bins
			];
	}
	return @{ $self->{unflattened} };
}

1;
