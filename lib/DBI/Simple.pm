package DBI::Simple;

use base qw(Class::Accessor);

use 5.008;
use strict;
use warnings;
no strict "subs";
no strict "refs";
use DBI;
use POSIX qw(strftime ceil);
use Data::Dumper;

use constant true => (1==1);
use constant false => (1==0);

our $VERSION = '1.0';


# Preloaded methods go here.
=pod
=head1 DBI::Simple

DBI::Simple - Perlish access to DBI


=head1 DESCRIPTION

This module provides DBI::Simple which is a highly (over)simplified
interface to DBI.  The point of DBI::Simple is that end programmers
who  want to write their programs which access simple databases in
Perl, should be able to write their programs in Perl and not Perl +
SQL.  This is a different approach as compared to the Tie::DBI. 
This module is not what high end or midrange database programmers
would like or care to use.  It works great for really simple stuff,
like SADU (search, add, delete,  update) on existing tables.  It
follows a basic Keep It Simple(tm) philosophy, in that the
programmer ought to be able to use a database table with very
little effort.

=head1 SYNOPSIS

  use DBI::Simple;
  my $sice = DBI::Simple->new;
				 );
  ...
  # all methods return a hash with two possible keys. 
  # On success, the return is
  #	{ success => true }
  # On failure, the return is
  #	{ failed  => { 
  #                    error => "error_message_from_call", 
  #                    code  => "error_return_code_from_call" 
  #                  } 
  #     }
  
  # sets internal $sice->{_dbh} to open database handle
  $sice->db_open(dsn => $dsn, dbuser => $dbuser, dbpass => $dbpass);
  
  $sice->db_add(table => $table_name,columns => {field1=>$data1,...});
  $sice->db_search(table => $table_name [,search => {field=>$data1,...}]);
  $sice->db_update(table => $table_name,search => {field=>$data1,...},
                                                   columns=>
						     {field1=>$data1,...
						  }
		  );
  $sice->db_delete(table => $table_name,search => {field=>$data1,...});
  
  $sice->close; 



=head2 Methods

=over 4
 
=item db_open(dsn => $dsn, dbuser => $dbuser, dbpass => $dbpass  )

The C<db_open> function returns a database handle attached to
$self->{_dbh}.  RaiseError is set to 1.

=cut
sub db_open
    {
      my ($self,%args) = @_;
      my ($dsn,$dbuser,$dbpass,$options,%rc,$dbh,$tmp,$name);

      if ($self->{debug})
         {
	   printf "D[%s] db_open: args -> \'%s\'\n",$$,join(":",keys(%args)) if ($self->{debug});
	 }
      # quick error check    
      foreach (qw(dsn dbuser dbpass))
        {
	 if (exists($args{$_})) 
            { 
	      $dsn	= $args{$_} if ($_ eq 'dsn');
	      $dbuser	= $args{$_} if ($_ eq 'dbuser');
	      $dbpass	= $args{$_} if ($_ eq 'dbpass');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      # connect to DB
      $self->{_dbh}	= false;
        {
             $self->{_dbh}= DBI->connect(
	    				 $dsn, 
					 $dbuser, 
					 $dbpass, 
					 {'RaiseError' => 1, AutoCommit=>1 }
					);
	   };
      if (
          (defined($self->{_dbh} )) 	&& 
	  (defined($self->{_dbh}->err))	&& 
	  ($self->{_dbh}->err)
	 )
	 {
	   printf "D[%s]: SICE database error \'%s\'\n",$$,$self->{_dbh}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_dbh}->errstr , 
			      'code'	=> $self->{_dbh}->err 
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s]: SICE database connection succeeded\n",$$ if ($self->{debug});   
	 }
      %rc= ( 'success' => true );
      printf "D[%s]: SICE database connection dump = %s\n",$$,Dumper($self) if ($self->{debug});   
      return \%rc;
    }

=cut
=item db_add(table=> $tablename, columns=>{field1=>$data1,...})


=cut
sub db_add
    {
      my ($self,%args)=@_;
      my ($table,$columns,$prep,%rc,@fields,@values);
      
      # quick error check    
      foreach (qw(table columns))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $args{$_} if ($_ eq 'table');
	      $columns	= $args{$_} if ($_ eq 'columns');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @fields=(keys %{$columns});
      map { push @values,$columns->{$_} } @fields;
      
      # create the SQL for the insert
      $prep  = sprintf 'INSERT INTO %s (',$table;
      $prep .= join(",",@fields). ') VALUES (';
      foreach (0 .. $#values)
        {
	  $prep .= sprintf "\'%s\'",$values[$_];
	  $prep .= "," if ($_ < $#values);
	}
      $prep .= ')';

      # compile it
      eval { $self->{_sth} = $self->{_dbh}->prepare($prep) };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_add: prepare failed with error \'%s\'\n\n\tprepare=\'%s\'\n",
	   $$,$self->{_sth}->err,$prep  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_add: prepare succeeded\n",$$ if ($self->{debug});   
	 }
      
      # execute it ...
      eval { $self->{_sth}->execute(); };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_add: execute failed with error \'%s\'\n",
	   $$,$self->{_sth}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_add: execute succeeded\n",$$ if ($self->{debug});   
	 }
            
      %rc= ( 'success' => true );
      return \%rc;
    }   
=cut
=item db_search(table=> $tablename, search=>{field1=>$data1,...})


=cut
sub db_search
    {
      my ($self,%args)=@_;
      my ($table,$search,$prep,%rc,@fields,@values);
      
      # quick error check    
      foreach (qw(table search))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $args{$_} if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	    }
	} 
      if (!defined($table))      
	    {
	      %rc= ( 'failed' => {'error' => "no table specified" } );
	      return \%rc;
	    }
	    
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }
      
      # if search is not defined, then use simpler form of 
      # search (e.g. select * from table; )
      if (!defined($search))
         {
	  $prep  = sprintf 'SELECT * FROM %s',$table;
	 }
	else
	 {

	  # extract fields and values from the columns
	  @fields=(keys %{$search});
	  map { push @values,$search->{$_} } @fields;

	  # create the SQL for the insert
	  $prep  = sprintf 'SELECT * FROM %s WHERE ',$table;      
	  foreach (0 .. $#fields)
            {
	     $prep .= " AND " if ($_ > 0);
	     $prep .= sprintf "%s=\'%s\'",$fields[$_],$values[$_];
	    }
        }

      # compile it
      eval { $self->{_sth} = $self->{_dbh}->prepare($prep) };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_search: prepare failed with error \'%s\'\n\n\tprepare=\'%s\'\n",
	   $$,$self->{_sth}->err,$prep  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_search: prepare succeeded\nprepare: %s\n",$$,$prep if ($self->{debug});   
	 }
      
      # execute it ...
      printf "D[%s] db_search: executing search\n",$$ if ($self->{debug});
      eval { $self->{_sth}->execute(); };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_search: execute failed with error \'%s\'\n",
	   $$,$self->{_sth}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_search: execute succeeded\n",$$ if ($self->{debug});   
	 }
      
      %rc= ( 'success' => true );
      return \%rc;
    }   
=cut
=item db_update(table=> $tablename, search=>{field1=>$data1,...},columns=>{fieldN=>$dataN,...})


=cut
sub db_update
    {
      my ($self,%args)=@_;
      my ($table,$search,$columns,$prep,%rc,@sfields,@svalues,@cfields,@cvalues);
      
      # quick error check    
      foreach (qw(table search columns))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $args{$_} if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	      $columns	= $args{$_} if ($_ eq 'columns');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @sfields=(keys %{$search});
      map { push @svalues,$search->{$_} } @sfields;
      @cfields=(keys %{$columns});
      map { push @cvalues,$columns->{$_} } @cfields;
      
      # create the SQL for the insert
      $prep  = sprintf 'UPDATE %s  SET ',$table;      
      foreach (0 .. $#cfields)
        {
	 $prep .= "," if ($_ > 0);
	 $prep .= sprintf "%s=\'%s\'",$cfields[$_],$cvalues[$_];
	}
      $prep .= ' WHERE ';
      foreach (0 .. $#sfields)
        {
	 $prep .= "," if ($_ > 0);
	 $prep .= sprintf "%s=\'%s\'",$sfields[$_],$svalues[$_];
	}
      printf "D[%s] db_update: prepare = \'%s\' \n",
	   $$,$prep  if ($self->{debug});
      

      # compile it
      eval { $self->{_sth} = $self->{_dbh}->prepare($prep) };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_update: prepare failed with error \'%s\'\n\n\tprepare=\'%s\'\n",
	   $$,$self->{_sth}->err,$prep  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_update: prepare succeeded\n",$$ if ($self->{debug});   
	 }
      
      # execute it ...
      eval { $self->{_sth}->execute(); };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_update: execute failed with error \'%s\'\n",
	   $$,$self->{_sth}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_update: execute succeeded\n",$$ if ($self->{debug});   
	 }
      
      %rc= ( 'success' => true );
      return \%rc;
    }   
=cut
=item db_delete(table=> $tablename, search=>{field1=>$data1,...})

=cut
sub db_delete
    {
      my ($self,%args)=@_;
      my ($table,$search,$prep,%rc,@fields,@values);
      
      # quick error check    
      foreach (qw(table search))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $args{$_} if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @fields=(keys %{$search});
      map { push @values,$search->{$_} } @fields;
      
      # create the SQL for the insert
      $prep  = sprintf 'DELETE FROM %s WHERE ',$table;      
      foreach (0 .. $#fields)
        {
	 $prep .= "," if ($_ > 0);
	 $prep .= sprintf "%s=\'%s\'",$fields[$_],$values[$_];
	}
     

      # compile it
      eval { $self->{_sth} = $self->{_dbh}->prepare($prep) };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_delete: prepare failed with error \'%s\'\n\n\tprepare=\'%s\'\n",
	   $$,$self->{_sth}->err,$prep  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_delete: prepare succeeded\n",$$ if ($self->{debug});   
	 }
      
      # execute it ...
      eval { $self->{_sth}->execute(); };
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf "D[%s] db_delete: execute failed with error \'%s\'\n",
	   $$,$self->{_sth}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err,
			      'prepare'	=> $prep
			     } 
		);
           return \%rc;
	 }
	else
	 {
	   printf "D[%s] db_delete: execute succeeded\n",$$ if ($self->{debug});   
	 }
      
      
      %rc= ( 'success' => true );
      return \%rc;
    }   
=cut
=item db_close

=cut
sub db_close
    {
      my ($self )=shift;
      if (defined($self->{_sth})) { undef $self->{_sth} ; }
      $self->{_dbh}->disconnect();      
    } 
=cut
=pod
=back

=head1 EXAMPLE

Suppose you have a nice database, a SQLite in this case, though it
will work perfectly well with Mysql, Postgres, and anything else
DBI supports.  This database has a list of host names and MAC
addresses, and you want to list them from the database.  

The table has been created using:


 CREATE TABLE hosts (
        mac_address      text,
        ip_address       text,
        dhcp_ipaddress   text,
        host_name        text,
        host_domain      text,
        net_device       text,
        gateway          text,
        netmask          text,
        mtu              text,
        options          text
        );


and the script looks like this


 #!/usr/bin/perl

 use strict;
 use DBI::Simple;
 my ($dbh,$err,$sice);
 my ($rc,$debug,$q);

 $debug	= 1;
 $sice   = SICE->new( { debug=>$debug } );
 $sice->db_open(
                 'dsn'           => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                 'dbuser'        => "",
                 'dbpass'        => ""
               );

 printf "Machines in cluster.db\n" ;
 $rc     = $sice->db_search('table' => 'hosts');
 if (defined($rc->{success}))
    {
       printf "mac\t\t\tip\t\thostname\n" ;
       $q=($sice->{_sth}->fetchall_hashref('mac_address'));
       foreach (sort keys %{$q})
	{
         printf "%s\t%s\t%s\n", $_,
	 			$q->{$_}->{ip_address},
				$q->{$_}->{host_name} ;
	}
    }
   else
    {
       printf "WARNING: the search did not succeed.\n
       	       DB returned the following error:\n\n%s\n\n",
	       $rc->{failed};
    }
 $sice->db_close;

The db_search does the query, and stores the result in a session
handle stored  as $object_name->{_sth}.  You can then use your
favorite DBI method to pull  out the records.  What DBI Simple
saves you is writing SQL.  It will do that portion for you.  If you
turn debugging by creating the object with  debug=>1, then you can
watch the SQL that is generated.

=head1 WHY

Why hide SQL?  That question should answer itself, especially in
programs not requiring the full firepower of a Class::DBI or most
of the DBI methods.   It is fairly easy to make a mistake in the
SQL you generate, and debugging  it can be annoying.  This was the
driving force behind this particular  module.  The SQL that is
generated is fairly simple minded.  It is executed,  and results
returned.  If it fails, this is also caught and what DBI thinks is
the reason it failed is returned as the $object->{failed} message.

This module is not for the folks who need the full firepower of
most of the rest of DBI.  This module is for simple programs.  If
you exceed the  capabilities of this module, then please look to
one of the other modules that do DBs.  

The approach to this module is simplicity.  It is intended to be
robust  for basic applications, and it is used in a commercial
product.

=head1 AUTHOR

Joe Landman (landman@scalableinformatics.com)


=head1 COPYRIGHT

Copyright (c) 2003-2005 Scalable Informatics LLC.  All rights
reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version
5.8.6 or, at your option, any later version of Perl 5 you may have
available.

=head1 SEE ALSO

perl(1), DBI, Class::Accessor

=head1 BUGS

Well, quite likely.  SQL is a standard, and standards are open to
interpretation.  This means that some things may not work as
expected. We have run into issues in quoting fields and values,
where DBD::Mysql happily accepted input that DBD::Pg croaked on.  

=cut

1;
__END__
