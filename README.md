# dctest
storage data corruption test utility

## prbs23
This utility uses [prbs23](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence) pseudorandom binary sequence method for testing for data corruption.

Each invocation of dctest operates on a set of files or devices which are destructively written to and read from.  

## usage

	$ dctest --help

	Disk Corruption Tester (dctest) version 2.2
	Copyright (C) 2003 Timothy A. Seufert (tas@mindspring.com)
	Copyright (C) 2016 Jason Bishop (jason.bishop@gmail.com)

	Usage: dctest option1 <parm1> option2 <parm2> ...

	Options:
	  --name filename  /  -n filename
	          Name of test file (default test.dat)

	  --log filename  /  -l filename
	          Name of log file (default log.txt)

	  --count N  /  -c N
	          Number of times to run test, 0 = infinite loop (default 1)

	  --verify N  /  -v N
	          Number of verification passes per test (default 1)

	  --size N  /  -s N
	          Size of test file, in megabytes (default 100)

	  --halt
	          Halt if corruption is detected, leaving test file intact

	  --help  /  -h
	          Display help

	Example: Run test 5 times, logging to a file named "foo.txt":
	  dctest --c 5 --log foo.txt


## example

	$ ./dctest --size 200 --verify 3 --count 2 --name /tmp/googoo

	Beginning test iteration #1; creating test file...
	producer regular
	................................................................ (526.5 MB/s)
	Verifying integrity of test file, pass #1
	producer regular
	................................................................ (836.9 MB/s)
	Verifying integrity of test file, pass #2
	producer regular
	................................................................ (1266.9 MB/s)
	Verifying integrity of test file, pass #3
	producer regular
	................................................................ (974.2 MB/s)

	Beginning test iteration #2; creating test file...
	producer complement
	................................................................ (561.7 MB/s)
	Verifying integrity of test file, pass #1
	producer complement
	................................................................ (1004.5 MB/s)
	Verifying integrity of test file, pass #2
	producer complement
	................................................................ (1215.4 MB/s)
	Verifying integrity of test file, pass #3
	producer complement
	................................................................ (1255.9 MB/s)

	Finished testing.


### background on prbs23

Notes on the above PRBS23 pseudorandom bit sequence generator:

PRBSn generators are serial shift registers n bits long with
feedback taps at two or more bit positions.  The initial value
of the shift register is defined to be all ones.

The taps for PRBS23 are 23, 18.  The serial equation for PRBS23 is thus:

   Bit[N] = Bit[N-23] ^ Bit[N-18]               (Eqn. 1)

where Bit[N] refers to Bit #N of the serial PRBS23 sequence.

This implementation stores a 32-bit chunk of the PRBS23 bit stream in a
register.  Each iteration through the loop calculates the next 32 bits
of the PRBS23 sequence.

The upper 18 bits of the new 32-bit shift register value are
computed in parallel:

   new = ((old >> 23) ^ (old >> 18)) << 32

This expression is simplified by merging the final left shift into
the two right shifts (avoids use of 64-bit temp registers):

   new = (old >> (23-32)) ^ (old >> (18-32))
       = (old >> -9) ^ (old >> -14)
       = (old << 9) ^ (old << 14)               (Eqn. 2)

Eqn. 2 cannot directly compute the lower 14 bits of the new value, since
they all depend on one or two bits in the upper 18 bits of the new value.
To get around this problem, we substitute Eqn. 1 into itself, and simpify:

   Bit[N] = (Bit[N-23-23] ^ Bit[N-23-18]) ^ (Bit[N-18-23] ^ Bit[N-18-18])
   Bit[N] = (Bit[N-46] ^ Bit[N-41]) ^ (Bit[N-41] ^ Bit[N-36])
   Bit[N] = Bit[N-46] ^ (Bit[N-41] ^ Bit[N-41]) ^ Bit[N-36]
   Bit[N] = Bit[N-46] ^ 0 ^ Bit[N-36]
   Bit[N] = Bit[N-46] ^ Bit[N-36]

In the 32-bit parallel world, this gives us:

   new = ((old >> 46) ^ (old >> 36)) << 32
       = (old >> 14) ^ (old >> 4)               (Eqn. 3)

Now we can calculate the upper 16 bits with Eqn. 2 and the lower 16
with Eqn. 3.
