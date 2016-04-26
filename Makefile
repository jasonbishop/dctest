default: dctest

CC = g++
LINKER = g++
.SUFFIXES: .S .c .cxx .o .s

C_OBJS = workqueue.o dctest.o

COPTS = -Wall -g -O3 -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native

LINKOPTS = -lpthread

dctest: $(C_OBJS)
	$(CC) $(COPTS) $(C_OBJS) $(LINKOPTS) -o dctest

clean: 
	- rm -f *.o
	- rm -f dctest

%.o: %.c
	$(CC) -c $(COPTS) $< -o $@

%.o: %.cpp
	$(CC) -c $(COPTS) $< -o $@

%.o: %.cxx
	$(CC) -c $(COPTS) $< -o $@
