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
    columns qw(access_token username expires_at_epoch_sec);
};

table {
    name 'todo';
    pk 'todo_id';
    columns qw(todo_id todo username create_at_epoch_sec);
};

1;
