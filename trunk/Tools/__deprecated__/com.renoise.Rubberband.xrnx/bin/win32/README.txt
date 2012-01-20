
Rubber Band
===========

An audio time-stretching and pitch-shifting library and utility program.

Copyright 2007-2010 Chris Cannam, cannam@all-day-breakfast.com.

Distributed under the GNU General Public License.

Rubber Band is a library and utility program that permits you to
change the tempo and pitch of an audio recording independently of one
another.


Attractive features
~~~~~~~~~~~~~~~~~~~

  * High quality results suitable for musical use

    Rubber Band is a phase-vocoder-based frequency domain time
    stretcher with phase resynchronisation at noisy transients and a
    phase lamination technique to reduce phasiness.  It is suitable for
    most musical uses with its default settings, and has a range of
    options for fine tuning.

  * Real-time capable

    In addition to the offline mode (for use in situations where all
    audio data is available beforehand), Rubber Band supports a true
    real-time, lock-free streaming mode, in which the time and pitch
    scaling ratios may be dynamically adjusted during use.

  * Sample-accurate duration adjustment

    In offline mode, Rubber Band ensures that the output has exactly
    the right number of samples for the given stretch ratio.  (In
    real-time mode Rubber Band aims to keep as closely as possible to
    the exact ratio, although this depends on the audio material
    itself.)

  * Multiprocessor/multi-core support

    Rubber Band's offline mode can take advantage of more than one
    processor core if available, when processing data with two or more
    audio channels.

  * No job too big, or too small

    Rubber Band is tuned so as to work well with the default settings
    for any stretch ratio, from tiny deviations from the original
    speed to very extreme stretches.

  * Handy utilities included

    The Rubber Band code includes a useful command-line time-stretch
    and pitch shift utility (called simply rubberband), two LADSPA
    pitch shifter plugins (Rubber Band Mono Pitch Shifter and Rubber
    Band Stereo Pitch Shifter), and a Vamp audio analysis plugin which
    may be used to inspect the stretch profile decisions Rubber Band
    is taking.

  * Free Software

    Rubber Band is Free Software published under the GNU General
    Public License.


Limitations
~~~~~~~~~~~

  * Not especially fast

    The algorithm used by Rubber Band is very processor intensive, and
    Rubber Band is not the fastest implementation on earth.

  * Not especially state of the art

    Rubber Band employs well known algorithms which work well in many
    situations, but it isn't "cutting edge" in any interesting sense.

  * Relatively complex

    While the fundamental algorithms in Rubber Band are not especially
    complex, the implementation is complicated by the support for
    multiple processing modes, exact sample precision, threading, and
    other features that add to the flexibility of the API.


Compiling Rubber Band
---------------------

Rubber Band is supplied with build scripts that have been tested on
Linux platforms.  It is also possible to build Rubber Band on other
platforms, including both POSIX platforms such as OS/X and non-POSIX
platforms such as Win32.  There are some example Makefiles in the misc
directory, but if you're using a proprietary platform and you get
stuck I'm afraid you're on your own, unless you want to pay us...

To build Rubber Band you will also need libsndfile, libsamplerate,
FFTW3, the Vamp plugin SDK, the LADSPA plugin header, the pthread
library (except on Win32), and a C++ compiler.  The code has been
tested with GCC 4.x and with the Intel C++ compiler.

Rubber Band comes with a simple autoconf script.  Run 

  $ ./configure
  $ make

to compile, and optionally

  # make install

to install.


Using the Rubber Band utility
-----------------------------

The Rubber Band command-line utility builds as bin/rubberband.  The
basic incantation is

  $ rubberband -t <timeratio> -p <pitchratio> <infile.wav> <outfile.wav>

For example,

  $ rubberband -t 1.5 -p 2.0 test.wav output.wav

stretches the file test.wav to 50% longer than its original duration,
shifts it up in pitch by one octave, and writes the output to output.wav.

Several further options are available: run "rubberband -h" for help.
In particular, different types of music may benefit from different
"crispness" options (-c <n> where <n> is from 0 to 6).


Using the Rubber Band library
-----------------------------

The Rubber Band library has a public API that consists of one C++
class, called RubberBandStretcher in the RubberBand namespace.  You
should #include <rubberband/RubberBandStretcher.h> to use this class.
There is extensive documentation in the class header.

A header with C language bindings is also provided in
<rubberband/rubberband-c.h>.  This is a wrapper around the C++
implementation, and as the implementation is the same, it also
requires linkage against the C++ standard libraries.  It is not yet
documented separately from the C++ header.  You should include only
one of the two headers, not both.

The source code for the command-line utility (src/main.cpp) provides a
good example of how to use Rubber Band in offline mode; the LADSPA
pitch shifter plugin (src/ladspa/RubberBandPitchShifter.cpp) may be
used as an example of Rubber Band in real-time mode.

IMPORTANT: Please ensure you have read and understood the licensing
terms for Rubber Band before using it in another application.  This
library is provided under the GNU General Public License, which means
that any application that uses it must also be published under the GPL
or a compatible license (i.e. with its full source code also available
for modification and redistribution).  See the file COPYING for more
details.  Alternative commercial and proprietary licensing terms are
available; please contact the author if you are interested.

