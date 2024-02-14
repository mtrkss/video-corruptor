Thanks blinkodemia and all the people from discord.gg/linux for motivating me into making this.

<p align=center>
    <img src="images/repotitle.png">
</p>

-----------

This is a simple (or not) video corruptor script that uses GStreamer and FFmpeg.

# Latest Changelog
- First commit! Woohoo!!!

# How 2 use dis? (yep, this is just the help message.)
```
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
```

# Known Bugs
- Sometimes GStreamer refuses to convert the video and freezes
- FFmpeg being janky
- Cannot use paths like `~/Videos/video.mp4` for inputs and outputs

# TODO
- ~~SoX filters?~~ [No.](http://fqa.9front.org/tuttleglenda.png)
- ~~Different raw video formats?~~ You can use mkv but it's not advised, just change the colorspace/pixfmt
