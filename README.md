Thanks blinkodemia and all the people from discord.gg/linux for motivating me into making this.

<p align=center>
    <img src="media/repotitle.png">
</p>

-----------

This is a simple (or not) video corruptor script that uses GStreamer and FFmpeg.

# Latest Changelog
- Added controllable intermediate audio rate
- Added the -r switch
- Added the --audio switch
- GStreamer command fixes
- Some code maintenence

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
 -r=<intermediate audio frequency>
 -v=<intermediate video format>
 -au=<complex audio input>

Other:
 --help		Show this help message
 --license	Self-explanatory
 --debug	Debug info, don't delete temp files
 --lavfi	Presume lavfi -au format
 --audio	Enable audio (DANGEROUS!)
 
Examples:
$ ./corruptor.sh -i=input.mp4 -f=lowpass
$ ./corruptor.sh -i=input.mp4 -o=output -f=custom -s="acrusher=bits=16:samples=200:mix=0.2"
$ ./corruptor.sh -i=input.mp4 -o=/tmp/somevideo -f=custom --lavfi -au="anoisesrc=c=brown:amplitude=0.04" -s="[0:a][1:a]amix=inputs=2:duration=first"

Info:
If no output is specified, input file hash + .mp4 will be used instead.
If -au is specified, "-af" in ffcmd will get replaced with "-filter_complex"
Enabling audio may cause encoder issues, VERY loud sounds and overbloated video outputs (up to 20GB)
```

# Known Bugs
- GStreamer freezes (mainly from --audio)
- ~~FFmpeg jank~~ If you have problems with ffmpeg, please doube-check the command.
- Cannot use paths like `~/Videos/video.mp4` for inputs and outputs

# TODO
- ~~SoX filters?~~ [No.](http://fqa.9front.org/tuttleglenda.png)
