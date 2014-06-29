package DBIx::Class::Query::StackTrace;

use strict;
use warnings;

use Carp;
use Class::Method::Modifiers qw[ install_modifier ];
use Devel::StackTrace;
use namespace::autoclean;

our $ENV_VAR = "DBIC_STACKTRACE";
our $FRAME_FILTER = sub {
    my $h = shift;
    return 0 if $h->{caller}[0] =~ /^DBIx::Class/;
    return 1;
};
our $IDEMPOTENCY_CHECK = "__DBIX_CLASS_QUERY_STACKTRACE";


sub attach_to {
    my ( $class, %p ) = @_;
    my $schema = $p{schema} || confess "schema required";

    return unless $ENV{$ENV_VAR};

    my $storage = $schema->storage;

    if( !$storage->debug ) {
        warn "schema->debug is not on, DBIx::Class::Query::StackTrace will not work. Did you forget to set DBIC_TRACE=1?";
        return;
    }

    #Idempotency
    return if $storage->debugobj->can($IDEMPOTENCY_CHECK);

    my $klass = ref( $storage->debugobj );

    install_modifier(
        $klass,
        "before",
        "query_start",
        sub {
            my $trace = Devel::StackTrace->new( frame_filter => $FRAME_FILTER );
            warn "$trace";
        } );

    install_modifier( $klass, "fresh", $IDEMPOTENCY_CHECK, sub { 1 } );
    return 1;
}

1;

=head1 NAME

    DBIx::Class::Query::StackTrace - Add a stack trace onto DBIC_TRACE

=head1 SYNOPSIS

    DBIx::Class::Query::StackTrace->attach_to( schema => $schema )
