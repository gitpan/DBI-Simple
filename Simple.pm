package DBI::Simple;

use DBI::Simple::Recordset;

use 5.008;
use strict;
use warnings;

use DBI;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (  );

our @EXPORT_OK = ( );

our @EXPORT = qw( );

our $VERSION = '0.01';


# Preloaded methods go here.

sub connect
{
	my ($class, $conn_string, @args) = @_;
	my $self = { };

	bless $self, $class;

	if($conn_string !~ /^dbi:/)
	{
		$conn_string = "dbi:" . $conn_string;
	}

	$self->{_dbh} = DBI->connect($conn_string, @args);

	return $self;
}

sub query
{
	my ($self, $query, @args) = @_;

	my $sth = $self->{_dbh}->prepare($query);
	$sth->execute(@args);
	DBI::Simple::Recordset->new($sth, $self->{_dbh});
}

sub commit
{
	my ($self) = @_;
	$self->{_dbh}->commit;
}

sub dbh
{
	$_[0]->{_dbh};
}

sub disconnect
{
	my $self = shift;
	$self->{_dbh}->disconnect;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

DBI::Simple - Perl extension to allow easy DBI access

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

  DBI::Simple abstracts the internals of the DBI module.  It inherits from DBI, so you retain all the functionality
  of the DBI when using DBI::Simple.

=head1 DESCRIPTION

DBI::Simple inherits all the methods of DBI.  The following functions are new or operate differently than their 
DBI counterparts.

=over

=item C<connect>

The C<connect> function takes the same parameters as the corresponding DBI function.  However, it is not necessary to 
specify "dbi:" in the string.  That is, the strings C<"dbi:mysql:...."> and C<"mysql:..."> are equivalent.

=item C<dbh>

The C<dbh> method returns the underlying DBI database handle.

=item C<query($statement)>

The C<query> function returns the L<DBI::Simple::Recordset> object that results from executing $statement.

=back

=head2 DEPENDENCIES

Requires the DBI module and any necessary DBD drivers.

=head2 EXPORT

None by default.  All functions are object-oriented.

=head1 TODO

=over

=item *

Update database when members of hash are changed

=item *

Cache prepared statements for better performance

=item *

Enable transaction-based updating

=back

=head1 SEE ALSO

L<DBI::Simple::Recordset>, L<DBI>, DBD::*

=head1 AUTHOR

Bill Atkins, E<lt>cpanNOSPAM@batkins.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bill Atkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
