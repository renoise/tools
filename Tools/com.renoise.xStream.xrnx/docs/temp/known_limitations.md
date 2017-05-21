# Known limitations

**Single track:** xStream is designed to produce output for a single pattern or automation track only. Also, you can only run a single model at a time. Both are deliberate decisions, to give the tool a certain focus and simplicity. 

**Tempo:** Due to the nature of Lua scripting in Renoise, there is an upper limit to how fast a tempo you can reliably use when streaming in real-time (180 BPM / 8 LPB should be no problem, but twice the tempo might cause small gaps in the output). Precisely how high you can push the tempo depends on your system performance. If you have plenty of CPU power, you could try decrease the `writeahead` amount (accessed in Options > Streaming), to increase the number of lines being written.

**Modal Dialogs:** A modal dialog is a specific type of dialogs which prevent you from accessing the program until you have chosen an action, with a common example being the "Are you sure you want to XX" prompt. Triggering this type of dialog should be avoided while streaming, as it will produce a gap in the output while it is visible.  

