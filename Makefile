# following examples from (outdated version):  
# https://cdn.netbsd.org/pub/pkgsrc/distfiles/SPTKexamples-3.9.pdf
#
# relationship between all commands: https://raw.githubusercontent.com/sp-nitech/SPTK/master/asset/diagram.png

# convert wave to 16kHz 16-bit short
%.s: %.wav
	sox $< -c 1 -r 16k -t s16 $@

# convert wave to 16kHz 64-bit double-precision float
%.d: %.wav
	sox $< -b 64 -e float -r 16k -t raw $@

# render waveform from a short integer waveform
%.png: %.s
	gwave +s $< $@

# input short integer 16kHz audio and convert to single-precision float
# frame length 400 points
# frame period 80 points
# blackman window input of length 400 points, output of length 512
# mel cepstrum with fft size of 512, analysis order (dimension) 24 and frequency warping alpha 0.42
%.mgc: %.s
	x2x +sd $< | frame -l 400 -p 80 | window -w 0 -l 400 -L 512 | \
		mgcep -l 512 -m 24 -a 0.6 > $@

# extract pitch using RAPT
# frame period of 80 points
# lower frequency of 60Hz
# higher frequency of 200Hz
# assuming signal is at 16kHz sampling rate
# output 1/F0 values
%.pit: %.s
	x2x +sd $< | pitch -a 0 -p 80 -L 60 -H 200 -s 16 -o 0 > $@

# make a codebook of size 128 using Linde-Buzo-Gray on vectors with hidden dimension 24
%.codebook: %.mgc
	lbg -n 24 -e 128 -i 1000 -d 1e-6 -r 1e-8 < $< > $@

# quantize mgc using a codebook
%.vq: %.codebook %.mgc
	msvq -l 24 -s $^ > $@

# dequantize mgc using a codebook
%.ivq: %.codebook %.vq
	imsvq -l 24 -s $^ > $@

# run MLSA filter to synthesize speech
%-mlsa.wav: %.pit %.mgc
	echo $^ | (read pit mgc; sopr -m 2 $$pit | \
	    excite -p 80 | \
	    mglsadf -p 80 -m 24 -a 0.6 $$mgc | \
	    x2x +ds -r -e 1 | \
	    sox -c 1 -t s16 -r 16000 - -t wav $@)


.DELETE_ON_ERROR:
