use File::Spec;
use File::Basename qw(dirname);
my $dbuser = defined($ENV{DATABASE_USERNAME}) ? $ENV{DATABASE_USERNAME} : 'root';
my $dbsecret = defined($ENV{DATABASE_SECRET}) ? $ENV{DATABASE_SECRET} : '';
my $dbhost = defined($ENV{DATABASE_HOST}) ? $ENV{DATABASE_HOST} : 'localhost';

+{
    'DBI' => ["dbi:mysql:host=$dbhost;port=3306;database=amontodo",
              $dbuser, $dbsecret,
              +{
                mysql_enable_utf8 => 1,
               }
             ],
};
