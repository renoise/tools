# Introduction


    ██╗  ██╗███████╗████████╗██████╗ ███████╗ █████╗ ███╗   ███╗
    ╚██╗██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║
     ╚███╔╝ ███████╗   ██║   ██████╔╝█████╗  ███████║██╔████╔██║
     ██╔██╗ ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
    ██╔╝ ██╗███████║   ██║   ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
    ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝

Welcome to the xStream documentation. 
Written for v1.9. 

## How does works xStreaming work?

xStream works by using _live evaluated code_ to "program" the pattern editor and automation in Renoise. 
This is done, using a subset of the lua language with some xStream additions on top. 

So you can pick up the tool, start typing some commands, and soon enough, output starts to appear in the pattern editor. 

...illustration...

Such a thing is called a [model](about_models.md). Essential a model is a small program, and xStream comes with 'batteries included' - demonstration models that range from basic examples to very advanced ones.

Models can easily be saved and exchanged with with others, as they are entirely text-based. Read about the file formats [here](file_formats.md).

## Learning more

Once you learn what can be achieved with just a few lines of code, you'll probably want to create new scripts (models) from scratch. This is what the later chapter, [Live Coding with xStream](), is about. 


## Features at a glance

* **Safe syntax**: the code is running in a sandboxed environment (errors are reported, exploits not possible)
* **Works online and offline**: the tool is designed for real-time streaming, but works offline too. 
* **Seamless streaming**: output can flow across pattern boundaries, wrap around block-loops etc. 
* **Open Format**: models are stored as plain text (import a model simply via copy/paste)
* **Favourites & Presets**: every model can be mapped to a color-coded grid (provides overview)

