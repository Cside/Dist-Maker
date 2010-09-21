#!perl -w
use strict;
use Test::More;

use Dist::Maker::Config;
use Dist::Maker::Scatter;
use Dist::Maker::Util qw(slurp);
use File::Path qw(rmtree);

END{ rmtree '.test/scatter/', { verbose => 0 } }

my $config = Dist::Maker::Config->new(
    user_data => {
        user => {
            name  => 'foo',
            email => 'bar at example.com',
        },
    },
);

my @files = qw(
    Makefile.PL lib/Foo/Bar.pm
    README Changes author/requires.cpanm
    .gitignore .shipit MANIFEST.SKIP
    t/000_load.t t/001_basic.t
    xt/pod.t xt/podcoverage.t xt/podspell.t xt/podsynopsis.t
    xt/perlcritic.t
);

foreach my $template(qw(Default XS Moose Mouse Any::Moose)) {
    note "Template: $template";

    my $x = Dist::Maker::Scatter->new(
        dist      => 'Foo::Bar',
        template  => $template,
        config    => $config,
        cache_dir => '.test_cache',
    );

    my $map = $x->content_map();
    ok $map, 'content_map';

    foreach my $file(@files) {
        ok exists $map->{$file}, "$file built successfully";
        cmp_ok length($map->{$file}), '>', 0, '... with some contents';
    }

    like $map->{README}, qr/Foo::Bar/;
    like $map->{README}, qr/\b foo \b/xms,
        'README must include $user.name';

    like $map->{README}, qr/ [^\n] \n \z/xms, 'ends with a newline';

    like $map->{'lib/Foo/Bar.pm'}, qr/\b foo \b/xms,
        'main module must include $user.name';
    like $map->{'lib/Foo/Bar.pm'}, qr/\Qbar at example.com\E/xms,
        'main module must include $user.email';

    my $d = ".test/scatter/" . $x->template;
    note "Scatter to $d";
    rmtree $d, { verbose => 0 } if -e $d;
    $x->scatter($d);

    foreach my $file(@files) {
        ok -e File::Spec->catfile($d, $file),
            "$file exists in the file system";
    }

    ok !exists $map->{EXTRA_FILES}; # meta file
}

pass 'done';

done_testing;
