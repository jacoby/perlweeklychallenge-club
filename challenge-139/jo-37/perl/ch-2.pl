#!/usr/bin/perl -s

use v5.16;
use Test2::V0;
use Math::Prime::Util qw(next_prime znorder is_square);
use Coro::Generator;
use experimental qw(signatures smartmatch);

our ($tests, $examples, $base);

run_tests() if $tests || $examples;	# does not return

die <<EOS unless @ARGV;
usage: $0 [-examples] [-tests] [-base B] [N]

-examples
    run the examples from the challenge
 
-tests
    run some tests

-base B
    use base B. Default: 10

N
    Print the first N long primes in base B.

EOS


### Input and Output

main: {
    my $long_primes = gen_long_primes($base // 10);
    say $long_primes->() for 1 .. shift;
}


### Implementation

# Create a generator for long primes. See the MAPLE implementation in
# https://oeis.org/A001913.
# There are no (or only a finite number of) long primes in bases that
# are perfect squares.
# When performing a long division of 1/p in base b, the remainders are
# generated by the sequence b**k mod p. Thus the length of the repetend
# and the order of b in the multiplicative group modulo p are the same.
sub gen_long_primes ($base=10) {
    die "cannot generate long primes in base $base" if is_square $base;
    generator {
        for (my $p = 2;; $p = next_prime($p)) {
            # znorder may return 'undef'.
            yield $p if znorder($base, $p) ~~ $p - 1;
        }
    }
}


### Examples and tests

sub run_tests {
    SKIP: {
        skip "examples" unless $examples;

        my $long_primes = gen_long_primes();
        is [map $long_primes->(), 1 .. 5], 
            [7, 17, 19, 23, 29], 'task 2';
    }

    SKIP: {
        skip "tests" unless $tests;

        {
            my $long_primes = gen_long_primes();
            # fast-forward:
            $long_primes->() for 1 .. 9999;

            # See https://oeis.org/A001913/b001913.txt
            is $long_primes->(), 308927, '# 10000';
        }
        # See https://en.wikipedia.org/wiki/Full_reptend_prime#Full_reptend_primes_in_various_bases
        {
            my $long_primes = gen_long_primes(2);
            is [map $long_primes->(), 1 .. 10],
                [3, 5, 11, 13, 19, 29, 37, 53, 59, 61],
                'long primes in base 2';
        }
        {
            my $long_primes = gen_long_primes(30);
            is [map $long_primes->(), 1 .. 10],
                [11, 23, 41, 43, 47, 59, 61, 79, 89, 109],
                'long primes in base 30';
        }
        like dies {gen_long_primes(4)}, qr/cannot generate/, 'square base';
	}

    done_testing;
    exit;
}
