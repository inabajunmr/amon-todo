use strict;
use warnings;
use Test::More;


use amon::todo;
use amon::todo::Web;
use amon::todo::Web::View;
use amon::todo::Web::ViewFunctions;

use amon::todo::DB::Schema;
use amon::todo::Web::Dispatcher;


pass "All modules can load.";

done_testing;
