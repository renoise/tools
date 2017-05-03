# Renoise tool boilerplate - 

A simple renoise boilerplate - using cLib + vLib as the foundation.  
You can use this code as the foundation for writing your own tool. 

Demonstrates the following features: 

* How to configure vLib (extended UI library for Renoise)
* How to launch a basic dialog
* How to implement autostart (dialog+preferences) 

## Installation

**Via Renoise tools page**  
This example comes with _batteries included_, since the necessary components (vLib, cLib) are part of the distribution. In other words, install it like any other tool.

**Via Github**  
If you've got the code from github, you need to obtain the most recent version of vLib and cLib. 

## A few notes 

In this boilerplate, ui and preferences are implemented as separate classes. Whether you like classes or not is a matter of taste - vLib doesn't force a specific programming pattern on you (it's modelled over the viewbuilder API. If you are not familiar with that, I highly recommend studying the [docs][1] before you start using vLib) 

That said, I prefer to follow this kind of programming pattern as all my tools are generally of a medium-to-large size. I have no plans of creating an additional example using a different approach. 

[1]: https://github.com/renoise/xrnx/blob/master/Documentation/Renoise.ViewBuilder.API.lua

