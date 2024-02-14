#!/bin/sh
#
# Copyright (c) 2024 Alexey Laurentsyeu, All rights reserved.
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

unset input output filter cset vidfmt caufmt pixfmt complex debug gstcfg lavfi

caufmt=alaw # audio format used to interpret the video
vidfmt=avi # used while converting and corrupting
pixfmt=yuv420p # yeah
gstcfg="x264enc bitrate=50000 psy-tune=grain ! mp4mux"
hsize=80120 # presumable header size

if [ "$(uname -o)" = Android ] || [ "$(uname -o)" = Toybox ] # only use quotes for uname to treat the whole output as a single string
then tmpdir=./tmp
else tmpdir=/tmp/vidcorrupt
fi

# help & licensing

case "$*" in
	"" | *-"hel"*)
		cat <<EOF
 
Files:
 -i=<input>
 -o=<output> (.mp4 will get automatically added!)

Corruption:
 -f=<filter>
 -s=<filter args>
 -c=<video color format>
 -g=<gstreamer config>
 -a=<intermediate audio format>
 -v=<intermediate video format>
 -au=<complex audio input>

Other:
 --help		Show this help message
 --license	Self-explanatory
 --debug	Debug info, Don't delete temp files.
 --lavfi	Add "-f lavfi" before second -i (only works with -au)
 
Examples:
$ ./corruptor.sh -i=input.mp4 -f=lowpass
$ ./corruptor.sh -i=input.mp4 -o=output -f=custom -s="acrusher=bits=16:samples=200:mix=0.2"
$ ./corruptor.sh -i=input.mp4 -o=/tmp/somevideo -f=custom --lavfi -au="anoisesrc=c=brown:amplitude=0.04" -s="[0:a][1:a]amix=inputs=2:duration=first"

Info:
If no output is specified, input file hash + .mp4 will be used instead.
If -au is specified, "-af" in ffcmd will get replaced with "-filter_complex"

EOF
		exit 0
		;;
	*"licens"*) sed -n '2,15{s/^#//;p}' $0;exit 0 ;;
esac

# set some variables

switches() {
local args="$*"

# loop through each arg
for arg in $args; do
	case $arg in
		-i=*) input="${arg#*=}" ;; #
		-o=*) output="${arg#*=}".mp4 ;; #
		-f=*) filter="${arg#*=}" ;; #
		-s=*) cset="${arg#*=}" ;; #
		-v=*) vidfmt="${arg#*=}" ;; #
		-a=*) caufmt="${arg#*=}" ;;
		-c=*) pixfmt="${arg#*=}" ;; #
		-g=*) gstcfg="${arg#*=}" ;;
		-au=*) complex="${arg#*=}" ;;
		--debug) debug=y ;;
		--lavfi) lavfi=y ;;
		*) ;;  # ignore any other args
	esac
done
}
switches "$*"

# functions

varset() {
hash=$(md5sum "$1"|head -c10)
ucvid=${tmpdir}/ucvid-$hash.$vidfmt
cvid=${tmpdir}/cvid-$hash.$vidfmt
inter1=${tmpdir}/inter1-$hash.raw
}

error() {
printf "%s\n" "Error: $1"
exit "$2"
}

alias cls='[ -z $debug ]&&clear'

getfile() {
[ -f "$1" ] || error "Input file doesn't exist, is a folder, or a special device." 66
varset "$1"
}

debug() {
cat <<EOF
Debug info

Internal variables:
hash>	$hash
ucvid>	$ucvid
cvid>	$cvid
inter1>	$inter1
ffcmd>	$ffcmd

User input:
input>	$input
output>	$output
filter>	$filter
vidfmt>	$vidfmt
pixfmt>	$pixfmt
cset>	$cset
gst>	$gstcfg
au> 	$complex
lavfi>	$lavfi
EOF
read nothing
}

rval() {
printf "Filter frequency: "
read fv1
}

chkapp() {
printf "Searching for $1...\n"
which $1 2>/dev/null && printf "$1 found\n\n" || error "$1 not found! Please install the $2 package." 1
}

ffwrong() {
printf "FFmpeg exited with a non-0 code!\nContinue? (may be risky) [Y/n]: "
read ans;echo $ans|grep -E [nN]>/dev/null&&exit 1
}

# checks

## check for deps
cls && printf "First checks\n"
chkapp ffmpeg ffmpeg
chkapp gst-launch-1.0 gstreamer

## check if the input file is too big
if [ $(wc -c<"$input") -gt 32428800 ]
then printf "The input video is too big!\nFrom my tests 10 seconds of 720p30fps footage need at least 1 Gigabyte of free storage at /tmp to get corrupted!\nAre you sure you want to continue? [y/N]"
	 read ans;echo $ans|grep -E [yY]>/dev/null||exit 1
fi

## check for and create a temporary directory
[ -d "$tmpdir" ] || mkdir "$tmpdir" || error "Can't create a temporary directory!" 1

printf "Done.\n"
[ -z $debug ]&&cls

# 0wO
ffset() {
fv1="$cset"
if [ -z $complex ]
then basecmd="ffmpeg -y -f $caufmt -i $ucvid -threads $(nproc) -af"
elif [ -z $lavfi ]
then basecmd="ffmpeg -y -f $caufmt -i $ucvid -i $complex -threads $(nproc) -filter_complex"
else basecmd="ffmpeg -y -f $caufmt -i $ucvid -f lavfi -i $complex -threads $(nproc) -filter_complex" 
fi

[ -z "$fv1" ] && ! [ "$filter" = custom ] && rval

case "$filter" in
	"highpass") ffcmd="$basecmd volume=-0.15dB,highpass=f=$fv1 -f $caufmt $inter1"
		;;
	"lowpass") ffcmd="$basecmd volume=-0.15dB,lowpass=f=$fv1 -f $caufmt $inter1"
		;;
	"custom") [ -z "$cset" ] && error 'https://ffmpeg.org/ffmpeg-filters.html' 78 ||
	ffcmd="$basecmd $cset -f $caufmt $inter1"
		;;
		*) error "I don't know this filter!" 76
	;;
esac
}
## setting the ffcmd (checks included)
if [ -z "$input" ]; then
	error "I need an input video!" 66
elif [ -z "$filter" ]; then
	error "Please choose a filter as the -f= option. Available filters:
highpass, lowpass, custom." 78
else
	getfile "$input"
	[ -z "$output" ] && output=$hash.mp4 &&
	printf "Output not specified! Defaulting to $(pwd)/${output}\n"
	ffset
fi

# corruption
[ ! -z $debug ] && printf "Everything correct here?\n" && debug

ffmpeg -y -i "$input" -c:v rawvideo -pix_fmt $pixfmt -an -threads $(nproc) $ucvid || ffwrong && cls
$ffcmd || ffwrong && cls

# restoring the header
vidsize=$(wc -c<$ucvid) # get the video size in bytes
printf "Got the raw video size as $vidsize bytes.\n\n"

printf "Putting the first $hsize bytes as cvid header... "
head -c$hsize "$ucvid" > "$cvid" &&
printf "Done\n" || error "Something went wrong!" 1

printf "Transferring corrupted data to cvid... "
tail -c$(($vidsize-$hsize)) "$inter1" | head -c$(($vidsize-$hsize*2)) >> "$cvid" &&
printf "Done\n" || error "Something went wrong!" 1

printf "Restoring the end data portion... "
tail -c$(($(wc -c<"$ucvid")-$(wc -c<"$cvid"))) "$ucvid" >> "$cvid" &&
printf "Done\n" || error "Something went wrong!" 1

# [ -z $debug ] && printf "Removing inter1..." && rm "$inter1" && printf "Done\n" # why did i add this

printf "\nArming GStreamer...\n"
gst-launch-1.0 filesrc location=$cvid ! decodebin ! videoconvert ! $gstcfg ! filesink location="$output" &&
printf "Everything Done!\n\n" || error "Something went wrong!" 1

if [ ! -z $debug ]
then debug
else printf "Cleaning up...\n"
	 rm -rv "$tmpdir" && printf "Done\n\n"
fi
