use strict;
use warnings;

package OD::Prometheus::Set;

use v5.24;
use Moose;
use LWP::UserAgent;
use Data::Printer;
use Scalar::Util qw(looks_like_number);
use OD::Prometheus::Metric;

=head1 NAME

OD::Prometheus::Set - A set of Prometheus metrics

=cut

use overload
	'@{}'	=> sub { $_[0]->metrics }
;

has metrics => (
        is		=> 'ro',
        isa		=> 'ArrayRef[OD::Prometheus::Metric]',
        default		=> sub { [] },
);


sub push {
	push shift->metrics->@*, @_
}

sub size {
	scalar $_[0]->metrics->@*
}

sub is_empty {
	$_[0]->size == 0
}

sub find {
	my $self	= shift // die 'incorrect call';
	my $metric	= shift // die 'incorrect call';
	my $attrs	= shift // {};
	my $value	= shift;

	my $rs = OD::Prometheus::Set->new;
	
	LOOP:
	for my $item ( $self->metrics->@* ) {
		next LOOP unless $metric eq $item->metric_name;
		for my $attr (keys $attrs->%*) {
			next LOOP unless exists( $item->labels->{ $attr } );
			next LOOP unless $attrs->{ $attr } eq $item->labels->{ $attr }
		}
		if( defined( $value ) ) {
			#say STDERR "Comparing ".$value." with ".$item->value;
			if( looks_like_number( $value ) ) {
				#say STDERR "Comparing as numbers";
				next LOOP unless $value == $item->value
			}
			else {
				#say STDERR "Comparing as strings";
				next LOOP unless $value eq $item->value
			}
		}
		$rs->push( $item )
	}
	return $rs
}


1;
