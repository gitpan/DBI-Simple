package DBI::Simple;

use XML::Simple;
use 5.008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

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

our @EXPORT = qw(
	
);

our $VERSION = '0.01';
our %dbs;
                                                                                
sub new {
        my $class = shift;
        $class = ref($class) || $class;
                                                                                
        my $conffile = shift @_;
        my ($conf, $constr, $dbh, $self);
                                                                                
        $conffile ||= '/etc/dbi.conf/simple.conf';
                                                                                
        unless ($dbh = $dbs{$conffile}){
                                                                                
                $conf = XML::Simple::XMLin($conffile, 'keyattr'=>[]);
                                                                                
                $constr = "dbi:$conf->{driver}:" || die 'No driver specified';
                my $k;
                foreach $k (keys %{$conf}){
                        $constr .= "$k=$conf->{$k};" unless (grep($k eq $_, ('driver', 'user', 'password')));
                }
                                                                                
                if ($dbh = DBI->connect($constr, $conf->{'user'}, $conf->{'password'})){
                        $dbs{$conffile} = $dbh;
                }
                else {
                        return undef;
                }
        }
                                                                                
        $self->{dbh} = $dbh;
        bless $self, $class;
        return $self;
}

sub execute {
        my ($self, $sql, @params) = @_;
        my ($dbh, $qrytype, $row, @rows, $sth);
                                                                                
        $dbh = $self->{dbh};
        $sth = $dbh->prepare($sql);
                                                                                
        unless ($sth->execute(@params)){
		$self->{errstr} = $sth->errstr;
                return;
        }
                                                                                
        ($qrytype) = split(/\s/, $sql);
        if (lc($qrytype) eq 'select'){
                while ($row = $sth->fetchrow_hashref){
                        push @rows, $row;
                }
                $sth->finish;
		$self->{errstr} = '';
                return @rows;
        }
	$self->{errstr} = '';
        return 1;
}

sub errstr {
	my $self = shift;
	return $self->{errstr};
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBI::Simple - Perl extension for very simple DBI wrapper

=head1 SYNOPSIS

  use DBI::Simple;
  $db = new DBI::Simple 'path/to/conf/file';
  @rows = $db->execute("select multiple, columns from multiple join tables using (column) where columns.column = ?", 'value');
  print $db->errstr;

=head1 ABSTRACT

  DBI::Simple provide a super-simple mechanism for accessing DBI sources. It has a simple database handle caching mechanism, but may not be well suited for environments that require query caching and other more sophisticated features.

  It provides a simple way to prepare and execute a statement, and retrieve the results of a query in a sigle command. It depends on small xml files to contain the data necessary for connecting to the DBI source.

=head1 DESCRIPTION

A configuration file might look like this:
<db>
        <driver>Pg</driver>
        <dbname>mydb</dbname>
        <user>me</user>
	<password>mypassword</password>
</db>


=head1 DEPENDENCIES

XML::Simple

=head1 SEE ALSO

DBI

=head1 AUTHOR

Sean McMurray

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Sean McMurray

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Public License (GPL).

=cut
