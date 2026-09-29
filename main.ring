# The Main File - shown by: ringpm run ascii2label
# ascii2label is a tool that works on the folder it lives in. This file only says where the
# tool is, how to call it, and how to run the six scenarios that come with it.

func main

	cLine = copy("=", 78)
	# ringpm run starts this file in the package folder, which is the tool's own folder
	cFolder = currentdir()

	? cLine
	? "The ascii2label Package"
	? cLine
	? "A label layout tool written in Ring: an ASCII drawing and a CSV in, labels out"
	? "as HTML and SVG. It shows one possible use of three libraries, which RingPM"
	? "installed with it: ringqr for the QR symbols, ringbc for the barcodes, ringfm"
	? "for the font metrics."
	? ""
	? "THE TOOL reads template.cfg from its own folder and writes the labels there:"
	? char(9) + "ring " + cFolder + "/ascii2label.ring"
	? ""
	? "THE SIX SCENARIOS in test/ each leave their labels in their own folder:"
	? char(9) + "ring " + cFolder + "/test/test.ring"
	? ""
	? "Tool    : " + cFolder
	? "Readme  : " + cFolder + "/README.md"
	? cLine
