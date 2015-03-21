requires 'perl',        '5.008005';
requires 'Moo',         '1.006001';
requires 'Set::Scalar', '1.29';

on test => sub {
    requires 'Test::Most',         '0.34';
    requires 'Test::FailWarnings', '0.008';
};
