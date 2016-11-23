requires 'Moo',         '>= 1.006001';
requires 'Parse::Lex',  '>= 2.21';
requires 'Set::Scalar', '>= 1.29';
requires 'Try::Tiny',   '>= 0.19';
requires 'indirect',    '>= 0.37';

on test => sub {
    requires 'Test::More',                      '>= 0.98';
    requires 'Test::Most',                      '>= 0.34';
    requires 'Test::FailWarnings',              '>= 0.008';
};

on develop => sub {
    requires 'Devel::Cover',                    '>= 1.23';
    requires 'Devel::Cover::Report::Codecov',   '>= 0.14';
};
