package DBI::Simple::Recordset;

use 5.008;
use strict;
use warnings;

use Carp;

require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBI::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

sub new
{
	my ($class, $sth, $dbh) = @_;
	my $self = {};

	die "DBI::Simple::Recordset->new should not be called outside of DBI::Simple" if !$sth or !$dbh;

	bless $self, $class;
	$self->{_sth} = $sth;
	$self->{_dbh} = $dbh;
	$self->{data} = {};

	$self->move_next;

	return $self;
}

sub sth
{
	$_[0]->{_sth};
}

sub dbh
{
	$_[0]->{_dbh};
}

sub move_next
{
	my ($self) = @_;

	return if $self->{_eof};

	my $hashref = $self->{_sth}->fetchrow_hashref;

	if(!$hashref)
	{
		$self->{_eof} = 1;
		return;
	}

	$self->{data}->{$_} = $hashref->{$_} for(keys(%$hashref));
}

sub has_records
{
	my ($self) = @_;
	!$self->{_eof};
}

sub eof
{
	my ($self) = @_;
	$self->{_eof};
}

sub insert
{

}

sub delete
{
}

sub AUTOLOAD
{
	my $self = shift;

	croak "$self not an object" unless(ref($self));
	my $name = our $AUTOLOAD;
	return if $name =~ /::DESTROY$/ or $name =~ /::_/;

	croak "can't access $name in $self" unless exists $self->{$name};

	if(@_)
	{
		$self->{data}->{$name} = shift;
	}
	else
	{
		return $self->{data}->{$name};
	}
}

1;
__END__

=head1 NAME

DBI::Simple::Recordset - Stores the results of a query executed with DBI::Simple

=head1 SYNOPSIS

  use DBI::Simple;
  $dbi = DBI::Simple->connect('mysql:hostname=localhost;database=main', 'user', 'pass');
  $rs = $dbi->query('SELECT * FROM Users');
  while($rs->has_records)
  {
	  print @{$rs->row};
	  $rs->move_next;
  }
  $rs->insert(name => 'jdoe', pass => 'password');
  $rs->commit;

=head1 ABSTRACT

  DBI::Simple::Recordset allows navigation of a resultset returned by the L<DBI::Simple> C<query> function.

=head1 DESCRIPTION

DBI::Simple::Recordset objects are returned by the C<query> method of L<DBI::Simple>.  Recordsets provide
the following functions:

=item C<dbh>

The C<dbh> method returns the underlying DBI database handle.

=item C<sth>

The C<sth> method returns the underlying DBI statement handle.

=over

=item C<move_next

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<DBI::Simple>, L<DBI>, DBD::*

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
