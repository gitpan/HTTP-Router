#line 1
package UNIVERSAL::can;

use strict;
use warnings;

use 5.006;

use vars qw( $VERSION $recursing );
$VERSION = '1.12';

use Scalar::Util 'blessed';
use warnings::register;

my $orig;
use vars '$always_warn';

BEGIN
{
	$orig = \&UNIVERSAL::can;

	no warnings 'redefine';
	*UNIVERSAL::can = \&can;
}

sub import
{
	my $class = shift;
	for my $import (@_)
	{
		$always_warn = 1 if $import eq '-always_warn';
		no strict 'refs';
		*{ caller() . '::can' } = \&can if $import eq 'can';
	}
}

sub can
{
	# can't call this on undef
	return _report_warning() unless defined $_[0];

	# don't get into a loop here
	goto &$orig if $recursing;

	# call an overridden can() if it exists
	local $@;
	my $can = eval { $_[0]->$orig('can') || 0 };

	# but not if it inherited this one
	goto &$orig if $can == \&UNIVERSAL::can;

	# make sure the invocant is useful
	unless ( _is_invocant( $_[0] ) )
	{
		_report_warning();
		goto &$orig;
	}

	# redirect to an overridden can, making sure not to recurse and warning
	local $recursing = 1;
	my $invocant = shift;

	_report_warning();
	return $invocant->can(@_);
}

sub _report_warning
{
	if ( $always_warn || warnings::enabled() )
	{
		my $calling_sub = ( caller(2) )[3] || '';
		warnings::warn("Called UNIVERSAL::can() as a function, not a method")
			if $calling_sub !~ /::can$/;
	}

	return;
}

sub _is_invocant
{
	my $potential = shift;
	return unless length $potential;
	return 1 if blessed($potential);

	my $symtable = \%::;
	my $found    = 1;

	for my $symbol ( split( /::/, $potential ) )
	{
		$symbol .= '::';
		unless ( exists $symtable->{$symbol} )
		{
			$found = 0;
			last;
		}

		$symtable = $symtable->{$symbol};
	}

	return $found;
}

1;
__END__

#line 194
