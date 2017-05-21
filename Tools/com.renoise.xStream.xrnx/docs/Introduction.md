# Introduction

xStream is a [Renoise tool](http://www.renoise.com/tools/xstream) that facilitates _live coding_ in Renoise, using a subset of the lua language. 

So you can pick up the tool, start typing some commands, and soon enough, output starts to appear in the pattern editor. 

...illustration...

Any such code represents a 'program' that, in xStream terminology, is referred to as a _model_. These models can easily be saved and exchanged with with others, as they are entirely text-based.

If this all sounds rather nerdy - well, it is! But don't worry: the tool comes with 'batteries included': there is a built-in selection of models to choose from - not just basic examples, but also more advanced ones that aim to be genuinely useful.

Once you learn what can be achieved with just a few lines of code, you'll probably want to create new scripts (models) from scratch. This is what the later chapter, [Live Coding with xStream](), is all about. 

## Features at a glance

* **Safe syntax**: the code is running in a sandboxed environment (errors are reported, exploits not possible)
* **Works online and offline**: the tool is designed for real-time streaming, but works offline too. 
* **Seamless streaming**: output can flow across pattern boundaries, wrap around block-loops etc. 
* **Open Format**: models are stored as plain text (import a model simply via copy/paste)
* **Favourites & Presets**: every model can be mapped to a color-coded grid (provides overview)

