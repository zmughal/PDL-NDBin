package PDL::NDBin::Action::Sum;
# ABSTRACT: Action for PDL::NDBin that computes sum

=head1 DESCRIPTION

This class implements an action for PDL::NDBin.

=cut

use strict;
use warnings;
use PDL::Lite;		# do not import any functions into this namespace
use PDL::NDBin::Actions_PP;
use Params::Validate qw( validate OBJECT SCALAR UNDEF );

=head1 METHODS

=head2 new()

	my $instance = PDL::NDBin::Action::Sum->new(
		N    => $N,
		type => double,   # optional
	);

Construct an instance for this action. Requires the number of bins $N as input.
Optionally allows the type of the output piddle to be set (defaults to the type
of the variable this instance is associated with, or at least I<long>).

=cut

sub new
{
	my $class = shift;
	my $self = validate( @_, {
			N    => { type => SCALAR, regex => qr/^\d+$/ },
			type => { type => OBJECT | UNDEF, isa => 'PDL::Type', optional => 1 }
		} );
	return bless $self, $class;
}

=head2 process()

	$instance->process( $iter );

Run the action with the given iterator $iter. This action will compute all bins
during the first call and will subsequently deactivate the variable.

=cut

sub process
{
	my $self = shift;
	my $iter = shift;
	if( ! defined $self->{out} ) {
		my $type = $self->{type};
		if( ! defined $type ) {
			$type = $iter->data->type < PDL::long() ? PDL::long : $iter->data->type;
		}
		$self->{out} = PDL->zeroes( $type, $self->{N} );
	}
	$self->{count} = PDL->zeroes( PDL::indx, $self->{N} ) unless defined $self->{count};
	PDL::NDBin::Actions_PP::_isum_loop( $iter->data, $iter->idx, $self->{out}, $self->{count}, $self->{N} );
	# as the plugin processes all bins at once, every variable
	# needs to be visited only once
	$iter->var_active( 0 );
	return $self;
}

=head2 result()

	my $result = $instance->result;

Return the result of the computation.

=cut

sub result
{
	my $self = shift;
	$self->{out}->inplace->_setnulltobad( $self->{count} );
	return $self->{out};
}

1;
