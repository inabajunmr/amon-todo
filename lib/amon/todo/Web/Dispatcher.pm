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
    if ( verify_access_token($c) ) {
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
    if ( verify_access_token($c) ) {
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
    if ( verify_access_token($c) ) {
        return response_401($c);
    }

    my $username = $args->{username};
    $c->db->delete( 'user' => { username => $username } );
    return $c->render_json( { status => 200, message => "$username deleted" } );
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
            expires_at_epoch_sec => time() + 10
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
        return 1;
    }
    if ( !( @split[0] eq 'bearer' || @split[0] eq 'Bearer' ) ) {
        return 1;
    }
    my $saved_token =
      $context->db->single( 'access_token', { access_token => @split[1] } );
    if ( !defined($saved_token) ) {
        return 1;
    }

    print 'save:', $saved_token->expires_at_epoch_sec, ' now:', time();
    if ( $saved_token->expires_at_epoch_sec < time() ) {
        return 1;
    }

    return 0;
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
