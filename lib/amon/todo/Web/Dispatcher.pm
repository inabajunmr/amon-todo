package amon::todo::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;
use JSON;
use Data::Dumper;
use Data::UUID;

post '/user' => sub {
    print "POST /user\n";

    my ($c) = @_;
    if ( validate_content_type_json($c) ) {
        return response_415($c);
    }
    my ($u, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }

    my $body     = decode_json( $c->req->content() );
    my $username = $body->{username};
    my $password = $body->{password};

    $c->db->insert(
        user => {
            username => $username,
            password => $password,
        }
    );

    return $c->render_json($body);
};

get '/user' => sub {
    print "GET /user\n";

    my ($c) = @_;
    my ($u, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }

    my @users  = $c->db->search('user');
    my @result = ();
    foreach my $user (@users) {
        push(
            @result,
            {
                (
                    username => $user->username,
                    password => $user->password
                )
            }
        );
    }
    return $c->render_json( \@result );
};

delete_ '/user/:username' => sub {
    print "DELETE /user\n";
    my ( $c, $args ) = @_;
    my ($u, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }

    my $username = $args->{username};
    $c->db->delete( 'user' => { username => $username } );
    return $c->render_json( { status => 200, message => "$username deleted" } );
};

get '/todo' => sub {
    print "GET /todo\n";
    my ($c) = @_;
    my ($username, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }

    my @todos = $c->db->search('todo', {username => $username}, {order_by => 'create_at_epoch_sec DESC'});
    my @result = ();
    foreach my $todo (@todos) {
        push(
            @result,
            {
                (
                    todo_id => $todo->todo_id,
                    todo => $todo->todo,
                    create_at_epoch_sec => $todo->create_at_epoch_sec,
                )
            }
        );
    }
    return $c->render_json( \@result );
};

post '/todo' => sub {
    print "POST /todo\n";
    
    my ($c) = @_;
    if ( validate_content_type_json($c) ) {
        return response_415($c);
    }
    my ($username, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }

    my $body     = decode_json( $c->req->content() );
    my $todo = $body->{todo};
    my $ug    = Data::UUID->new();
    my $uuid  = $ug->create();
    my $id = $ug->to_string($uuid);

    $c->db->insert(
        todo => {
            todo_id => $id,
            username => $username,
            todo => $todo,
            create_at_epoch_sec => time(),
        }
    );
    return $c->render_json($body);
};

delete_ '/todo/:todo_id' => sub {
    print "DELETE /todo\n";
    my ( $c, $args ) = @_;
    my ($username, $err) = verify_access_token($c);
    if ( $err ) {
        return response_401($c);
    }
    my $todo_id = $args->{todo_id};
    my $todo = $c->db->single('todo', {todo_id => $todo_id});
    if(!($todo->username eq $username)) {
        return $c->render_json( { status => 403, message => "$username don't has permission" } );
    }
    $c->db->delete('todo' => {todo_id => $todo_id});
    return $c->render_json( { status => 200, message => "$todo_id deleted" } );
};

# no client authentication
post '/oauth/token' => sub {
    print "POST /oauth/token\n";
    my $c          = shift();
    my $grant_type = $c->req->parameters->{grant_type};
    my $username   = $c->req->parameters->{username};
    my $password   = $c->req->parameters->{password};

    if ( !( $grant_type eq 'password' ) ) {
        return $c->render_json(
            {
                status  => 400,
                message => "supported only resource owner password grant"
            }
        );
    }

    my $user = $c->db->single( 'user', { username => $username } );
    if ( !defined($user) ) {
        return $c->render_json(
            { status => 404, message => "$username is not found" } );
    }
    if ( !( $user->password eq $password ) ) {
        return response_401($c);
    }

    my $ug    = Data::UUID->new();
    my $uuid  = $ug->create();
    my $token = $ug->to_string($uuid);

    $c->db->insert(
        'access_token' => {
            access_token         => $token,
            username             => $username,
            expires_at_epoch_sec => time() + 3600
        }
    );

    return $c->render_json(
        { access_token => $token, token_type => 'bearer', expires_in => 10 } );
};

# invalid = 1
sub verify_access_token {
    my $context              = shift();
    my $authorization_header = $context->req->header('Authorization');
    my @split                = split( / /, $authorization_header );
    my $len                  = @split;
    if ( $len != 2 ) {
        return (undef, 1);
    }
    if ( !( $split[0] eq 'bearer' || $split[0] eq 'Bearer' ) ) {
        return (undef, 1);
    }
    my $saved_token =
      $context->db->single( 'access_token', { access_token => $split[1] } );
    if ( !defined($saved_token) ) {
        return (undef, 1);
    }

    if ( $saved_token->expires_at_epoch_sec < time() ) {
        return (undef, 1);
    }

    return ($saved_token->username, 0);
}

# invalid = 1
sub validate_content_type_json {
    my $context      = shift();
    my $content_type = $context->req->headers->content_type();

    if ( $content_type eq 'application/json' ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub response_401 {
    my $context = shift();
    return $context->render_json(
        {
            status  => 401,
            message => 'authorization failed'
        }
    );
}

sub response_415 {
    my $context = shift();
    return $context->render_json(
        {
            status  => 415,
            message => 'needs to header content-type=application/json'
        }
    );
}

1;
