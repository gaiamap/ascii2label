# ascii2label - the program.
#
# Three steps, and this file is the only place that orders them: parse the template into a
# model (the boxes, lines and points of the ASCII drawing, plus the configuration that
# follows it), read the data (one CSV row per label, plus an optional free-flowing text), then
# render one drawing per row. Everything the run learns goes to the screen and to app.log.
#
# ascii2label.ring starts this file, in the folder that one lives in, and the template goes
# in that folder too: every path in the configuration - the template, the CSV, the images, a
# font file - is resolved from there, and so is everything the tool writes.
Load "stdlibcore.ring"
Load "main/model.ring"
Load "parser/grid.ring"
Load "parser/parser.ring"
Load "render/render.ring"

# Reads the template, reports what the layout analysis found - how many rectangles, lines
# and points, and where - then renders one label per data row. With no CSV, or a CSV holding
# only its header, it still produces one label with empty data and says so in the log.
Func Main 

	ctemplatepath = "template.cfg"
	clogfile = "app.log"
	write(clogfile, "")
	If Not fexists(ctemplatepath)
		# A first run in a folder with no template gets a label rather than a bare line: the
		# tool draws one from a template it carries itself, which says what is missing and
		# shows at the same time what a template turns into. Same steps as any other run.
		log("No "+ctemplatepath+" in this folder.")
		oparser = New parser 
		aresult = oparser.parsetemplatetext(startheretemplate())
		renderlabels(aresult[1], aresult[2], [["There is no template.cfg in this folder"]], 
		startheretext())
		log("Written: start-here.html - a label, drawn from a template held inside the tool.")
		log("Open it, or read README.md.")
		Return 
	Ok 
	log("Parsing template: "+ctemplatepath)
	oparser = New parser 
	aresult = oparser.parsetemplate(ctemplatepath)
	If islist(aresult) And len(aresult) = 2
		omodel = aresult[1]
		ogrid = aresult[2]
	Else 
		log("Error parsing template.")
		Return 
	Ok 
	log("--- Layout Detection Result ---")
	log("Grid: "+string(ogrid.width())+" x "+string(ogrid.height()))
	nrectscount = 0
	nlinescount = 0
	npointscount = 0
	For oblock In omodel.blocks 
		If oblock.w > 0 And oblock.h > 0
			nrectscount++
			log("  Rect  ID="+string(oblock.id)+
			" X="+string(oblock.x)+" Y="+string(oblock.y)+
			" W="+string(oblock.w)+" H="+string(oblock.h))
		Elseif oblock.w > 0 Or oblock.h > 0
			nlinescount++
			log("  Line  X="+string(oblock.x)+" Y="+string(oblock.y)+
			" W="+string(oblock.w)+" H="+string(oblock.h))
		Else 
			npointscount++
			log("  Point X="+string(oblock.x)+" Y="+string(oblock.y))
		Ok 
	Next 
	log("Summary: "+string(nrectscount)+" Rects, "+
	string(nlinescount)+" Lines, "+
	string(npointscount)+" Points")
	log("---------------------------------")
	ccsvfile = omodel.config.csv_file 
	adatarows = []
	If ccsvfile != ""
		log("Reading CSV: "+ccsvfile)
		adatarows = oparser.readcsv(ccsvfile)
	Ok 
	alabeldata = []
	If len(adatarows) > 1
		For i = 2 To len(adatarows)
			add(alabeldata, adatarows[i])
		Next 
	Else 
		log("Warning: no CSV rows. Single label with empty data.")
		add(alabeldata, [])
	Ok 
	cfixedtext = ""
	If omodel.config.text_file != ""
		log("Reading fixed text: "+omodel.config.text_file)
		cfixedtext = oparser.readtextfile(omodel.config.text_file)
	Ok 
	log("Rendering "+string(len(alabeldata))+" label(s)...")
	acanvas = renderlabels(omodel, ogrid, alabeldata, cfixedtext)
	logprintsize(omodel, acanvas)
	If len($labeltextwarnings) > 0
		log("--- Text warnings ---")
		For cwarning In $labeltextwarnings log("  "+cwarning) Next 
	Ok 
	If len($labelcodewarnings) > 0
		log("--- Code generator warnings ---")
		For cwarning In $labelcodewarnings log("  "+cwarning) Next 
	Ok 
	If omodel.config.html_output 
		log("Output: "+omodel.config.out_name+".html")
	Ok 
	If omodel.config.svg_output 
		log("Output: one .svg per label, starting at "+omodel.config.out_name+"_001.svg")
	Ok 
	If Not omodel.config.html_output And Not omodel.config.svg_output 
		log("Warning: html_output and svg_output are both off. Nothing was written.")
	Ok 
	log("Done.")
	
# What the label comes to when it is printed.
#
# The drawing has a size of its own, in pixels, and a browser reads one pixel as 1/96 inch, which
# is the size it shows. Printed, the label is given the page instead, so what it comes out at is
# the size of the paper.
#
# The modules of a symbol are drawn in whole pixels, so the narrowest one is a fixed share of the
# label and comes out as small as the paper makes it. What decides whether it is read is its width
# in millimetres on the paper, and that is a property of the label and the paper alone: no printer
# changes it, and a scanner measures nothing else. So the report is written in millimetres, which
# is the unit the whole question is asked in.
#
# The figure it is written against is a quarter of a millimetre, and it comes from two places that
# agree. The GS1 general specifications allow a minimum X-dimension of 0.250 mm (0.0098 inch)
# where a unit is physically too small to carry the minimum its application asks for - the change
# notification that set symbol specification tables 2 and 5 gives it in that form - and two dots
# of a 203 dpi print head come to the same 0.250 mm.
#
# Neither is a golden rule. The same table asks 0.495 mm for a GS1-128 on a logistic unit in
# general distribution, twice as much; a 300 dpi head lays two dots in 0.17 mm and a 180 dpi one
# in 0.28; and a symbology or a scanner may want more than any of them. That is why the
# millimetres are printed beside every figure: another floor can be applied to them without
# touching the tool. It is why the line under the floor names the printer and the scanner instead
# of giving a verdict: a 203 dpi head has printed a module of one and a half dots and a scanner
# has read it back, so below the floor a code may still read, and the tool cannot know.
#
# That gives the report two forms. With no media declared it is a condition: the paper the label
# has to be printed on for the narrowest module to reach that width, which is a figure to compare
# with the roll in the printer. With a media declared the comparison is done here.
#
# The figure is taken from the narrowest module drawn in the whole run, so meeting it meets every
# label of it. That module usually comes from the longest content, but not always: a shorter one
# in a smaller box can be tighter, which is why the line names the modules and not a symbol.
Func logprintsize omodel, acanvas 

	nlabelw = acanvas[1]
	nlabelh = acanvas[2]
	nfill = omodel.config.page_fill 
	If nfill < 1 Or nfill > 100 nfill = 100 Ok 
	aworst = []
	nmodule = 0
	For arecord In $labelcodemodules 
		If nmodule = 0 Or arecord[1] < nmodule 
			nmodule = arecord[1]
			aworst = arecord 
		Ok 
	Next 
	log("--- Print size ---")
	log("  cell     "+omodel.config.char_width+" x "+omodel.config.char_height+" px")
	log("  label    "+nlabelw+" x "+nlabelh+" px, "+
	formatfixed(pxtomm(nlabelw), 2)+" x "+formatfixed(pxtomm(nlabelh), 2)+" mm at 96 dpi")
	If nfill < 100
		log("  page     the label is printed at "+nfill+"% of it, centred")
	Else 
		log("  page     the label is printed across the whole of it")
	Ok 
	cmedia = trim(omodel.config.media)
	If cmedia != ""
		amedia = mediasize(cmedia)
		If len(amedia) = 2
			logonmedia(omodel, amedia, nlabelw, nlabelh, nfill, aworst)
		Else 
			log("  media    '"+cmedia+"' is not two millimetre figures like 62x29, and is ignored")
		Ok 
		If len(amedia) = 2 Return Ok 
	Ok 
	If nmodule = 0
		Return 
	Ok 
	# The lines above are what this run IS; this is what it WOULD need on paper nobody has named
	# yet. So it is written as a condition rather than put in the column, where a value reads as a
	# fact.
	npagewidth = 0.25*nlabelw*100/(nmodule*nfill)
	log("  codes    the narrowest module reaches 0.25 mm on paper "+
	formatfixed(npagewidth, 1)+" mm wide or wider")
	
# The two millimetre figures of a media, or an empty list for anything else. Written as one value
# because that is how a roll is named - 62x29 - and read here rather than as two keys, so that a
# label that changes paper changes one line.
Func mediasize cvalue 

	nat = substr(lower(cvalue), "x")
	If nat < 2 Return [] Ok 
	nwide = number(trim(left(cvalue, nat-1)))
	nhigh = number(trim(substr(cvalue, nat+1)))
	If nwide <= 0 Or nhigh <= 0 Return [] Ok 
	Return [nwide, nhigh]
	
# What the label and its symbols come to on a declared media.
#
# The label is fitted to the paper keeping its proportions, so one of the two sides fills it and
# the other falls short: what a module is measured against is the size the label really comes out
# at, and not the size of the paper. Where the two proportions differ the line says so by itself,
# because the figure it prints is smaller than the media on one side.
Func logonmedia omodel, amedia, nlabelw, nlabelh, nfill, aworst 

	nprintw = amedia[1]
	nprinth = nlabelh*amedia[1]/nlabelw 
	If nprinth > amedia[2]
		nprinth = amedia[2]
		nprintw = nlabelw*amedia[2]/nlabelh 
	Ok 
	nprintw = nprintw*nfill/100
	nprinth = nprinth*nfill/100
	log("  media    "+amedia[1]+" x "+amedia[2]+" mm, the label comes out "+
	formatfixed(nprintw, 1)+" x "+formatfixed(nprinth, 1)+" mm on it")
	If len(aworst) = 0 Return Ok 
	nmmperpx = nprintw/nlabelw 
	nmodulemm = aworst[1]*nmmperpx 
	log("  codes    narrowest module "+formatfixed(nmodulemm, 3)+" mm on the media")
	If nmodulemm >= 0.25 Return Ok 
	log("           under the 0.25 mm floor: below it, reading the code depends on the "+
	"printer and the scanner. "+mendingadvice(omodel, aworst, nmmperpx, nlabelw, nfill))
	
# How to widen the narrowest module, said in quantities a template can check: the cells of the
# drawing, the size the label has to be printed at, and the keys.
#
# What it does NOT do is promise millimetres after a change. Widening a box widens the label too,
# and a wider label fitted to the same paper is scaled down further, so the module can come out
# narrower than before: measured on one case, five cells more took it from 0.150 to 0.119 mm. A
# figure that comes from arithmetic on the old scale would be a lie, so what is given instead is
# the room the symbol needs, which is a fact about the symbol, and the printed size at which the
# module it already has reaches the floor, which is a fact about the label.
#
# page_fill is the exception, because it is the one key that shrinks the label without touching
# the drawing: taken back to 100 it scales the module by exactly that much, so that figure is
# given. It is one of the ways only where it reaches the floor. Below the floor it is still worth
# printing, since it says that the largest free move is not enough, but a figure that does not
# reach the floor is not a way to reach it, and in a list joined by 'or' it reads as one.
Func mendingadvice omodel, aworst, nmmperpx, nlabelw, nfill 

	nmodule = aworst[1]
	nroom = aworst[2]
	nnative = aworst[3]
	ncellsize = omodel.config.char_width 
	cway = "width"
	If aworst[4]
		ncellsize = omodel.config.char_height 
		cway = "height"
	Ok 
	nwanted = 0.25/nmmperpx 
	If nnative > 0
		nwantroom = ceil(nwanted)*nnative 
	Else 
		nwantroom = nroom*nwanted/nmodule 
	Ok 
	nat100 = nmodule*nmmperpx*100/nfill 
	cadvice = "To reach it the symbol would want "+countphrase(ceil(nwantroom/ncellsize), "cell")+
	" of room in "+cway+" where it has "+(nroom/ncellsize)+", or the label printed "+
	formatfixed(0.25*nlabelw/nmodule, 1)+" mm wide instead of "+
	formatfixed(nmmperpx*nlabelw, 1)
	If nfill < 100 And nat100 >= 0.25
		cadvice += ", or page_fill back at 100, which alone takes the module to "+
		formatfixed(nat100, 3)+" mm"
	Ok 
	cadvice += ", or shorter data"
	If nfill < 100 And nat100 < 0.25
		cadvice += ". page_fill back at 100 would give "+formatfixed(nat100, 3)+
		" mm, still under"
	Ok 
	Return cadvice 
	
# Says it once in two places: on screen, and appended to app.log. The file is opened and
# closed at every line, so a run that dies halfway still leaves everything it had said.
Func log ctext 

	clogfile = "app.log"
	cmsg = string(ctext)+nl 
	See cmsg 
	fp = fopen(clogfile, "a")
	If fp != -1
		fputs(fp, cmsg)
		fclose(fp)
	Ok
	
# The template the tool falls back on, in the format a user writes: an ASCII drawing of the
# layout, then the configuration. Held here rather than on disk so that it is there when
# nothing else is, and written as an example worth reading, since it is the first template
# most people will see.
#
# Two things in the drawing are worth a word. The frame asks for a radius of 999, which is not
# a size but a way of asking for as much as it can have: no radius is honoured beyond half the
# shorter side of the shape it is given, so the frame comes out as round as it gets, and the
# title box with it. The dots keep the flowing text out of the two strips that the round corners
# leave unusable beside the title box: a cell holding anything but a space is a filled cell, and
# a filled cell is not offered to the text. Nothing is drawn for it, since a drawing draws its
# boxes, its lines and its points and nothing else.
Func startheretemplate 

	Return "+----------------------------------------------------------------------------------+
|........+----------------------------------------------------------------+........|
|........|1                                                               |........|
|........|                                                                |........|
|........+----------------------------------------------------------------+........|
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
|                                                                                  |
+----------------------------------------------------------------------------------+

[0]
char_width = 9
char_height = 22
out_name = start-here
font = arial
fg_color = #202020
stroke_frame = 2
radius_box = 999
align = center

[1]
type = text
font_size = 20
bg_color = #FFF8E1
fg_color = #3A3000
stroke = 1
radius = 999
"
	
# The text that flows into the frame of that template, which is where the three things a first
# run needs to know are said.
Func startheretext 

	Return "A template is an ASCII drawing of the layout, followed by a short configuration "+
	"block that says what each box holds."+nl+
	nl+
	"Run  ring test/test.ring  to go through the six worked examples in test/. Each one leaves "+
	"its result in its own folder, and copying the contents of one of them beside "+
	"ascii2label.ring is the quickest way to start your own."+nl+
	nl+
	"README.md describes the drawing and every key of the configuration."
	