package amon::todo::DB::Schema;
use strict;
use warnings;
use utf8;

use Teng::Schema::Declare;

base_row_class 'amon::todo::DB::Row';

table {
    name 'user';
    pk 'username';
    columns qw(username password);
};

table {
    name 'access_token';
    pk 'access_token';
    columns qw(access_token username);
};

1;
