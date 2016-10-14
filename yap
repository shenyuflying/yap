#!/bin/bash


usage () {
	echo "================================================================"
	echo "                          YAP    ver0.1                         "
	echo "================================================================"
	echo "  yap -- yet another profiling tool based on poor man's profiler"
	echo "         to generate stack rank of your program.                "
	echo "                                                                "
	echo "                             yshen 2016 see http://shenyu.wiki  "
	echo "================================================================"
	echo "                                                         "
	echo "usage: yap options=values"
	echo "        -s | --samples=n      how many samples to collect"
	echo "        -t | --sleeptime=n    how many time to sleep during each sample"
	echo "        -f | --stackframe=n   how deep the stack frame to output"
	echo "        -p | --pid=pid        which pid to analyze"
	echo "        -n | --progname=name  which program to analyze, good for multi-process profiling "
	echo "        -h | --help           show this help"
	exit 1
}

#default values
nsamples=100
sleeptime=0
deep=5
pid=0
progname=""

GETOPT_ARGS=`getopt -o s:t:f:p:n:h -l samples:,sleeptime:,stackframe:,pid:,progname:,help -- "$@"`

#getopt report an error better show the help
if [ $? != "0" ] ; then
	usage
	exit 1
fi

eval set -- "$GETOPT_ARGS"
while [ -n "$1" ]
do
	case "$1" in
		-s|--samples) nsamples=$2; shift 2;;
		-t|--sleeptime) sleeptime=$2; shift 2;;
		-f|--stackframe) deep=$2; shift 2;;
		-p|--pid) pid=$2; shift 2;;
		-n|--progname) progname=$2; shift 2;;
		-h|--help) usage ; shift 2;;
		--) break ;;
		*) echo "invalid parameter:" $1,$2; usage; exit 1; break ;;
	esac
done


if [ "x"$progname = "x" ]  && [ "x"$pid = "x0" ] ; then
	echo "either --progname or --pid should be specified"
	exit 1
fi  


for x in $(seq 1 $nsamples)
  do
    # find all pid of progname for mlti-process program
    if [ "x"$progname != "x" ] ; then
	pids=$(pidof $progname)
        for pid_i in $pids ; do
    	    gdb -ex "set pagination 0" -ex "thread apply all bt $deep" -batch -p $pid_i    2>/dev/null  
        done
    fi
    # just look the program of a pid
    if [ "x"$pid != "x0" ] ; then
    	gdb -ex "set pagination 0" -ex "thread apply all bt $deep" -batch -p $pid  2>/dev/null  
    fi

    sleep $sleeptime

    # show the progress
    echo "$x/$nsamples completed." >&2
  done | \
awk '
  BEGIN { s = ""; } 
  /^Thread/ { print s; s = ""; } 
  /^\#/ { if (s != "" ) { s = s "\t" $4} else { s = $4 } } 
  END { print s }' | \
sort |\
uniq -c |\
sort -r -n -k 1,1 


