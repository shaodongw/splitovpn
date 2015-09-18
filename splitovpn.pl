#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Cwd;
# use YAML;
# use Data::Dumper;


binmode STDOUT, ":utf8";

if ( scalar @ARGV != 1 ) {
    die "Usage: $0 <opvn-file>\n";
}
elsif ( ! -f $ARGV[0] ) {
    die "File does not exist: [$ARGV[0]] !\n";
}
else {
    process( $ARGV[0] );
}

sub process {
    my $opvn = shift;
    open OPVNFILE, "<", $opvn
            or die "Open $opvn error !\n";
    binmode(OPVNFILE, ":utf8");
    local $/;
    $_ = <OPVNFILE>;
    
    # delete all comment lines
    s/^  \# [^\r\n]* //gxms;
    
    # delete all blank lines
    s/^ \s* //gmxs;

    # extract ca of VPN server and delete it
    my $ca_regex = qr{
            <ca> \s*
            (
            ---+
            BEGIN \s+ CERTIFICATE
            ---+\s*
            [^-]*
            ---+
            END \s+ CERTIFICATE
            ---+\s*
            )
            </ca> \s*
            }xms;

    my $server_cert = $1 if (s/$ca_regex//);

    # extract cert of client and delete it
    my $cert_regex = qr{
            <cert> \s*
            (
            ---+
            BEGIN \s+ CERTIFICATE
            ---+\s*
            [^-]*
            ---+
            END \s+ CERTIFICATE
            ---+\s*
            )
            </cert> \s*
            }xms;


    my $client_cert = $1 if (s/$cert_regex//);

    # extract key of client and delete it
    my $key_regex = qr{
            <key> \s*
            (
            ---+
            BEGIN \s+ RSA \s+ PRIVATE \s+ KEY
            ---+\s*
            [^-]*
            ---+
            END \s+ RSA \s+ PRIVATE \s+ KEY
            ---+\s*
            )
            </key> \s*
            }xms;


    my $client_key = $1 if (s/$key_regex//);

    my $dir = cwd();
    $_ .= "ca " . $dir . "/" . $opvn . ".ca.crt\n";
    $_ .= "cert " . $dir . "/" . $opvn . ".client.crt\n";
    $_ .= "key " . $dir . "/" . $opvn . ".client.key\n";

    open CA_CRT,        ">", $opvn . ".ca.crt";
    open CLIENT_CRT,    ">", $opvn . ".client.crt";
    open CLIENT_KEY,    ">", $opvn . ".client.key";
    open PROFILE,       ">", $opvn . ".conf";

    print CA_CRT         $server_cert;
    print CLIENT_CRT     $client_cert;
    print CLIENT_KEY     $client_key;
    print PROFILE        $_;
    
    close CA_CRT      ;
    close CLIENT_CRT  ;
    close CLIENT_KEY  ;
    close PROFILE     ;
}

