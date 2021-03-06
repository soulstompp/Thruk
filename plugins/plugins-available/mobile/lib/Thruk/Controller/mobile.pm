package Thruk::Controller::mobile;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use parent 'Catalyst::Controller';

=head1 NAME

Thruk::Controller::mobile - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

# enable statusmap if this plugin is loaded
Thruk->config->{'use_feature_mobile'} = 1;

######################################

=head2 mobile_cgi

page: /thruk/cgi-bin/mobile.cgi

=cut
sub mobile_cgi : Path('/thruk/cgi-bin/mobile.cgi') {
    my ( $self, $c ) = @_;
    return $c->detach('/mobile/index');
}


##########################################################

=head2 index

=cut
sub index :Path :Args(0) :MyAction('AddDefaults') {
    my ( $self, $c ) = @_;
    
    if(defined $c->{'request'}->{'parameters'}->{'data'}) {
        my $type  = $c->{'request'}->{'parameters'}->{'data'};
        my $limit = $c->{'request'}->{'parameters'}->{'limit'} || 10;
        if($type eq 'host_notifications') {
            my $query = "GET log\n";
            $query   .= "Columns: type host_name service_description state time\n";
            $query   .= "Filter: class = 3\n";
            $query   .= "Limit: ".$limit."\n";
            $query   .= Thruk::Utils::Auth::get_auth_filter($c, 'log');
            my $notifications = $c->{'live'}->selectall_arrayref($query, { Slice => 1, AddPeer => 1});
    
            if(defined $limit and scalar @{$notifications} > $limit) { @{$notifications} = @{$notifications}[0..$limit]; }
    
            $c->stash->{'json'} = Thruk::Utils::sort($c, $notifications, 'time', 'DESC');
            $c->forward('Thruk::View::JSON');
            return;
        }
        else {
            $c->log->error("unknown type: ".$type);
            return;
        }
    }

    my $host_stats    = $c->{'live'}->selectrow_hashref("GET hosts\n".Thruk::Utils::Auth::get_auth_filter($c, 'hosts')."
Stats: has_been_checked = 1
Stats: state = 0
StatsAnd: 2 as up

Stats: has_been_checked = 1
Stats: state = 1
StatsAnd: 2 as down

Stats: has_been_checked = 1
Stats: state = 2
StatsAnd: 2 as unreachable

Stats: has_been_checked = 0 as pending
",
    { Slice => {}});
    my $service_stats = $c->{'live'}->selectrow_hashref("GET services\n".Thruk::Utils::Auth::get_auth_filter($c, 'services')."
Stats: has_been_checked = 1
Stats: state = 0
StatsAnd: 2 as ok

Stats: has_been_checked = 1
Stats: state = 1
StatsAnd: 2 as warning

Stats: has_been_checked = 1
Stats: state = 2
StatsAnd: 2 as critical

Stats: has_been_checked = 1
Stats: state = 3
StatsAnd: 2 as unknown

Stats: has_been_checked = 0 as pending
",
    { Slice => {} } );

    $c->stash->{hosts}     = $host_stats;
    $c->stash->{services}  = $service_stats;
    $c->stash->{template}  = 'mobile.tt';

    return 1;
}


=head1 AUTHOR

Sven Nierlein, 2010, <nierlein@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
