# Entry point of the renderer: it decides the canvas size, opens the HTML page that will
# hold every label, and draws one label per data row. It knows nothing about SVG or HTML -
# it drives whatever drawing object it is given, so a second back end can be added.
Load "render_svg.ring"
Load "render_html.ring"
Load "render_textflow.ring"
Load "ringfm.ring"
# Loaded for StringToBase64, used to embed fonts and images in the standalone .svg. It also
# arrives with ringfm, but a file that uses a function says where it gets it from.
Load "stdlibcore.ring"

# What the run has to say about the text: a font that is not on this machine, a body that had
# to be made smaller than the template asked. Main empties it onto the log at the end, as it
# does with the warnings of the code generators.
$labeltextwarnings = []

# The face the metric reader is holding right now. Reading a font file costs time and the
# same face is asked for once per block per row, so it is read again only when the name
# changes.
$labelfontname = ""

# The files already turned into data: URIs for the standalone .svg, kept by path. The same
# mark comes back on many labels and every one of them asks for the font, so each file is
# encoded once.
$labelembedded = []

# The five characters that cannot stand for themselves in markup. Every piece of text that comes
# from the data passes through here before it reaches a drawing or a page: the apostrophe is
# escaped as well, which HTML needs inside an attribute and XML accepts.
Func escapemarkup ctext 

	ctext = substr(ctext, "&", "&amp;")
	ctext = substr(ctext, "<", "&lt;")
	ctext = substr(ctext, ">", "&gt;")
	ctext = substr(ctext, '"', "&quot;")
	ctext = substr(ctext, "'", "&#39;")
	Return ctext 
	
# A number with a fixed count of decimals, so a column of them lines up in the log and a
# millimetre in a page never comes out with sixteen digits.
Func formatfixed nvalue, ndigits 

	nscale = pow(10, ndigits)
	nrounded = floor(nvalue*nscale+0.5)
	nint = floor(nrounded/nscale)
	If ndigits = 0 Return string(nint) Ok 
	nfrac = nrounded-nint*nscale 
	cfrac = string(nfrac)
	While len(cfrac) < ndigits 
		cfrac = "0"+cfrac 
	End 
	Return string(nint)+"."+cfrac 
	
# Pixels to millimetres at 96 dpi, the resolution the browser assumes. It is what makes a
# 60 x 40 mm label come out of the printer at 60 x 40 mm.
Func pxtomm npx 

	Return npx*25.4/96
	
# One drawing per data row. The page holding them all is written when html_output is on, and
# each drawing also goes out as its own .svg file when svg_output is on.
#
# The canvas is measured from the elements themselves rather than declared, and the drawing
# is placed on the centre of the cells. Both are decided once by canvasgeometry, below, and
# used for every row.
#
# Fonts named in the configuration that are real files are loaded once and registered with
# the HTML page, so the browser shows the same face the measurement used. A font named but
# not found is left to the browser to resolve.
Func renderlabels omodel, ogrid, adatarows, cfixedtext 

	acanvas = canvasgeometry(omodel)
	ncanvasw = acanvas[1]
	ncanvash = acanvas[2]
	noffsetx = acanvas[3]
	noffsety = acanvas[4]
	ohtml = New htmloutput 
	ohtml. Init (ncanvasw, ncanvash, omodel.config.page_fill)
	afontnames = [omodel.config.font]
	For oblock In omodel.blocks 
		add(afontnames, oblock.config.font)
	Next 
	ausedfonts = []
	For cfontname In afontnames 
		If cfontname = "" Loop Ok 
		afont = usefont(cfontname)
		If afont[2] = "" Loop Ok 
		If find(ausedfonts, afont[1], 1) = 0 ausedfonts+[afont[1], afont[2]] Ok 
	Next 
	For af In ausedfonts 
		ohtml.registerfont(af[1], af[2], fontformatfor(af[2]))
	Next 
	atextsizes = planbodysizes(omodel, adatarows)
	For i = 1 To len(adatarows)
		arow = adatarows[i]
		csuffix = string(i)
		While len(csuffix) < 3
			csuffix = "0"+csuffix 
		End 
		$labelcodeareas = []
		osvg = New svgdrawing 
		osvg. Init (ncanvasw, ncanvash)
		aflowed = flowtextintoframes(omodel, ogrid, cfixedtext)
		renderrow(osvg, omodel, arow, aflowed, noffsetx, noffsety, atextsizes)
		csvgcontent = osvg.getsvg()
		ohtml.addlabel(csvgcontent)
		If omodel.config.svg_output 
			write(omodel.config.out_name+"_"+csuffix+".svg", selfcontainedsvg(csvgcontent, ausedfonts))
		Ok 
	Next 
	warnaboutcutcodes()
	warnaboutoverlappingcodes()
	For cnotice In $labeltextwarnings 
		ohtml.addnotice(cnotice)
	Next 
	For cnotice In $labelcodewarnings 
		ohtml.addnotice(cnotice)
	Next 
	If omodel.config.html_output 
		ohtml.save(omodel.config.out_name+".html")
	Ok 
	Return [ncanvasw, ncanvash]
	
# The size of the canvas and the offset that puts the drawing on the centre of the cells.
#
# The cell is the unit of the layout, and a '+' in the template names a whole cell rather
# than one corner of it: lines, borders and points are drawn through the centre of the cell
# they were written in, half a cell in from its edge.
#
# Two things follow. A drawing has a white border of half a cell on all four sides, and the
# four margins are equal, because they are the same half cell. The canvas is the furthest
# right and lowest cell any block reaches, times the size of a cell, so a template that grows
# needs no size declared anywhere.
#
# What can spill past that margin is the stroke: one wider than a cell sticks out further
# than the half cell it has to live in. Rather than clip it, the canvas grows by the worst
# overflow found, by the same amount on both sides, so the drawing stays centred.
#
# Half cells and pads are rounded to whole pixels, so on an odd cell size one side gets one
# pixel more than the other.
#
# Returns the width, the height, and the offset to add to every element of every row.
Func canvasgeometry omodel 

	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	nhalfcellw = floor(ncharw/2+0.5)
	nhalfcellh = floor(ncharh/2+0.5)
	nmaxx = 0
	nmaxy = 0
	For oblock In omodel.blocks 
		If oblock.x+oblock.w > nmaxx nmaxx = oblock.x+oblock.w Ok 
		If oblock.y+oblock.h > nmaxy nmaxy = oblock.y+oblock.h Ok 
	Next 
	ncanvasw = nmaxx*ncharw 
	ncanvash = nmaxy*ncharh 
	noverx = 0
	novery = 0
	For oblock In omodel.blocks 
		ainkbox = blockinkbox(omodel, oblock, nhalfcellw, nhalfcellh)
		If len(ainkbox) = 4
			If -ainkbox[1] > noverx noverx = -ainkbox[1] Ok 
			If -ainkbox[2] > novery novery = -ainkbox[2] Ok 
			If ainkbox[3]-ncanvasw > noverx noverx = ainkbox[3]-ncanvasw Ok 
			If ainkbox[4]-ncanvash > novery novery = ainkbox[4]-ncanvash Ok 
		Ok 
	Next 
	npadx = 0
	npady = 0
	If noverx > 0 npadx = ceil(noverx) Ok 
	If novery > 0 npady = ceil(novery) Ok 
	Return [ncanvasw+2*npadx, ncanvash+2*npady, nhalfcellw+npadx, nhalfcellh+npady]
	
# How far one element reaches, in pixels, with the drawing already on the cell centres and
# before the canvas has been grown: left, top, right, bottom, or an empty list for an element
# that draws nothing.
#
# It asks the same questions the drawing object asks, in the same order, so that what is
# measured here is what is drawn there. A border or a point with no stroke, or in no colour,
# draws nothing; a box and a point spread by half their stroke on every side; a line only
# across itself, since it is drawn as a rectangle of the length the drawing gave it, and a
# radius eats into that length instead of adding to it. A background fill is not measured: it never leaves its box.
Func blockinkbox omodel, oblock, nhalfcellw, nhalfcellh 

	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	nx = (oblock.x-1)*ncharw+nhalfcellw 
	ny = (oblock.y-1)*ncharh+nhalfcellh 
	nw = oblock.w*ncharw 
	nh = oblock.h*ncharh 
	If oblock.w > 0 And oblock.h > 0
		nstroke = oblock.config.stroke 
		cink = oblock.config.fg_color 
		If nstroke = 0 Or cink = "" Or cink = "none" Return [] Ok 
		nspread = nstroke/2
		Return [nx-nspread, ny-nspread, nx+nw+nspread, ny+nh+nspread]
	Ok 
	cink = omodel.config.fg_color 
	If oblock.w > 0 Or oblock.h > 0
		nstroke = omodel.config.stroke_line 
		If nstroke = 0 Or cink = "" Or cink = "none" Return [] Ok 
		nspreadx = nstroke/2
		nspready = nstroke/2
		If oblock.h = 0 nspreadx = 0 Ok 
		If oblock.w = 0 nspready = 0 Ok 
		Return [nx-nspreadx, ny-nspready, nx+nw+nspreadx, ny+nh+nspready]
	Ok 
	nstroke = omodel.config.stroke_point 
	If nstroke = 0 Or cink = "" Or cink = "none" Return [] Ok 
	nspread = nstroke/2
	Return [nx-nspread, ny-nspread, nx+nspread, ny+nspread]
	
# A symbol carried off the label. There is no module smaller than one pixel, so a string too long
# for the room the drawing gave it is generated at its own width, and where that runs past the
# canvas the drawing clips it: what is left on the page is part of a symbol, which no scanner
# reads back.
#
# Outgrowing its own box is not this, and is not said any more. Since the symbols are drawn last
# and paint their own ground, a symbol that spills onto its neighbours is whole and readable; what
# it covers is the drawing's business and the reader can see it. Only the edge of the label cuts.
#
# What is measured is how far past the edge it goes, and that is all the message gives. The two
# ways back are named but not counted, because which one works depends on the drawing: where the
# code box is the rightmost thing on the label, moving it left takes the edge of the canvas with
# it and gains nothing, and it is a wider box that helps; where a frame sets that edge, the
# opposite. Only the worst is named: they all come from the same field.
Func warnaboutcutcodes 

	If len($labelbarcodecut) = 0 Return Ok 
	aworst = $labelbarcodecut[1]
	For acase In $labelbarcodecut 
		If acase[2] > aworst[2] aworst = acase Ok 
	Next 
	cmessage = "BARCODE ["+aworst[1]+"] runs "+aworst[2]+" px past the edge of the label, where "+
	"the drawing cuts it and it will not scan. Give it more room in the drawing, or shorten the "+
	"data."
	If len($labelbarcodecut) > 1
		cmessage += " ("+(len($labelbarcodecut)-1)+" more like it)"
	Ok 
	add($labelcodewarnings, cmessage)
	
# A count with its noun in agreement, since these lines are read by a person.
Func countphrase ncount, cnoun 

	If ncount = 1 Return "1 "+cnoun Ok 
	Return "" + ncount + " " + cnoun + "s"
	
# One code symbol on top of another. The symbols are drawn after everything else and each paints
# its own opaque ground, so a line, a letter or a picture can no longer reach the modules; two
# symbols on the same ground still can, and there the later one wins and nothing is left of the
# earlier to read. It takes two boxes drawn one inside the other, which is rare and always a
# mistake, and it is the only overlap left worth a word.
#
# Only the first pair is named, with the count of the rest: they come from one misplaced box
# repeated on every label of the run.
Func warnaboutoverlappingcodes 

	If len($labelcodeoverlap) = 0 Return Ok 
	afirst = $labelcodeoverlap[1]
	cmessage = "CODE ["+afirst[1]+"] is covered by CODE ["+afirst[2]+"], drawn on top of it, and "+
	"nothing of it is left to read. Move the two apart in the drawing."
	If len($labelcodeoverlap) > 1
		cmessage += " ("+(len($labelcodeoverlap)-1)+" more)"
	Ok 
	add($labelcodewarnings, cmessage)
	
# How much room one column needs at one body size: the widest line it wraps to, and the height of
# the stack. The two questions the size search asks are both this one - whether the column fits a
# box is these two against it, and by how much it misses is the same two at the smallest body
# there is.
#
# The width is asked as well as the height because the wrapper leaves a word it cannot break on a
# line of its own, so a line can come out wider than the width it was wrapped to.
Func columnextent oblock, adatarows, nsize, nboxw 

	nwidest = 0
	ntallest = 0
	For arow In adatarows 
		ctext = ""
		If oblock.id <= len(arow) ctext = arow[oblock.id] Ok 
		If ctext = "" Loop Ok 
		alines = fm_wraptext(ctext, nsize, nboxw)
		If len(alines)*(nsize*1.2) > ntallest ntallest = len(alines)*(nsize*1.2) Ok 
		For cline In alines 
			nlinew = fm_measureline(cline, nsize)
			If nlinew > nwidest nwidest = nlinew Ok 
		Next 
	Next 
	Return [nwidest, ntallest]
	
# Whether this block actually draws a line around itself.
#
# It decides who gets the inset: the half cell of white is there to keep the content off the
# border, so a block that draws no border is given the whole box. Asking it here, once, keeps
# the measuring and the drawing agreed on how much room there is.
Func hasborder oblock 

	If oblock.config.stroke = 0 Return false Ok 
	If oblock.config.fg_color = "" Or oblock.config.fg_color = "none" Return false Ok 
	Return true 
	
# The room a block's content gets, in pixels: the whole box where no border is drawn, and the
# interior - one cell in from each side - where one is. The origin is the caller's, so the same
# answer serves the drawing, which has an offset, and the measuring, which has none.
Func blockinnerbox omodel, oblock, nx, ny 

	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	If Not (hasborder(oblock) And oblock.w > 1 And oblock.h > 1)
		Return [nx, ny, oblock.w*ncharw, oblock.h*ncharh]
	Ok 
	nhalfcellw = floor(ncharw/2+0.5)
	nhalfcellh = floor(ncharh/2+0.5)
	Return [nx-nhalfcellw+ncharw, ny-nhalfcellh+ncharh, 
	(oblock.w-1)*ncharw, (oblock.h-1)*ncharh]
	
# Says a thing once. The same warning would otherwise come out per block and per row.
Func addtextwarning cmessage 

	If find($labeltextwarnings, cmessage) > 0 Return Ok 
	add($labeltextwarnings, cmessage)
	
# The face to measure with, and the name to ask the browser for.
#
# A font written as a file is read for its metrics and registered with the page under the
# family name kept inside it, so the browser shows the face that was measured. A font written
# by name - Arial, Times, Courier - is handed to the library all the same: it knows where
# those families live on Windows, macOS and Linux and resolves the name to a real file, which
# makes the measurement exact rather than estimated. In that case the drawing keeps asking for
# the name, because the browser on this machine reaches the same file by that name, and a page
# is not allowed to load an absolute system path.
#
# When the library has to fall back on a family it does not know, it says so and so do we: the
# measurement is then made with a stand-in and the page may show something else.
#
# Returns the family to write in the drawing, and the file to register with the page, or an
# empty file name when there is nothing to register.
Func usefont cfontname 

	If cfontname = "" Return ["", ""] Ok 
	bisfile = fexists(cfontname)
	If cfontname != $labelfontname 
		$labelfontname = cfontname 
		If Not fm_init(cfontname)
			$labelfontname = ""
			addtextwarning("font '"+cfontname+
			"' could not be read: the widths are a built-in estimate and the fit is approximate")
			Return [cfontname, ""]
		Ok 
		If $fmfallback 
			addtextwarning("font '"+cfontname+
			"' is not on this machine: measured with "+$fmfamily+
			", the page may show another face")
		Ok 
	Ok 
	If bisfile 
		cfamily = $fmfamily 
		If cfamily = "" cfamily = cfontname Ok 
		Return [cfamily, cfontname]
	Ok 
	Return [cfontname, ""]
	
# The size of every text on the label, chosen once for the whole run, one value per block.
#
# Once rather than per label: a size decided row by row would print the same field large on
# one label and small on the next. The size kept is the one at which every row of the data
# still fits its box, so the worst row decides for all of them.
#
# The body of a text and the caption of a code are both here, and are chosen the same way: what
# differs is that a text may wrap and grow to fill its box, while a caption is one line in a band
# the symbol has to give up. Blocks with no text of their own get a zero.
Func planbodysizes omodel, adatarows 

	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	asizes = []
	For oblock In omodel.blocks 
		nchosen = 0
		If oblock.id > 0 And oblock.w > 0 And oblock.h > 0
			ainner = blockinnerbox(omodel, oblock, 0, 0)
			If oblock.config.type = "text"
				usefont(oblock.config.font)
				nchosen = fitbodysize(oblock, adatarows, ainner[3], oblock.h*ncharh, ncharw, ncharh)
			Elseif oblock.config.type = "code" And oblock.config.caption != ""
				usefont(oblock.config.font)
				nchosen = fitcaptionsize(oblock, adatarows, ainner[3], ainner[4], ncharw, ncharh)
			Ok 
		Ok 
		add(asizes, nchosen)
	Next 
	Return asizes 
	
# The largest body at which the whole column still fits the box.
#
# font_size is a ceiling and not a size: written, it is as large as the text may ever get; not
# written, there is no ceiling and the text grows until the box is full. The other ceiling is
# the box itself - no body taller than the height it has to live in.
#
# The search is by halving: once a body fits, every smaller one fits too, so the boundary is
# found in a handful of tries.
#
# Going below the ceiling the template asked for goes in the log: a text is never allowed to run
# past its box, but the reader has to be told that what he asked for did not fit. It stays a
# notice and not a verdict - one pixel of drawing on a sheet printed large, at a resolution the
# tool knows nothing about, can still come out perfectly readable.
Func fitbodysize oblock, adatarows, nboxw, nboxh, ncharw, ncharh 

	nceiling = oblock.config.font_size 
	nupper = floor(nboxh/1.2)
	If nceiling > 0 And nceiling < nupper nupper = nceiling Ok 
	If nupper < 1 nupper = 1 Ok 
	nlower = 1
	nbest = 0
	While nlower <= nupper 
		nmiddle = floor((nlower+nupper)/2)
		If bodyfits(oblock, adatarows, nmiddle, nboxw, nboxh)
			nbest = nmiddle 
			nlower = nmiddle+1
		Else 
			nupper = nmiddle-1
		Ok 
	End 
	If nbest = 0
		nbest = 1
		aextent = columnextent(oblock, adatarows, 1, nboxw)
		ashort = [aextent[1]-nboxw, aextent[2]-nboxh]
		cadvice = "shorten the value"
		If ashort[1] > 0
			cadvice = "widen the box by "+countphrase(ceil(ashort[1]/ncharw), "cell")+", or shorten the value"
		Elseif ashort[2] > 0
			cadvice = "make the box "+countphrase(ceil(ashort[2]/ncharh), "cell")+" taller, or shorten the value"
		Ok 
		addtextwarning("block ["+oblock.id+
		"]: the text does not fit its box at any size and is drawn at 1 px, the smallest "+
		"there is - "+cadvice)
	Elseif nceiling > 0 And nbest < nceiling 
		addtextwarning("block ["+oblock.id+
		"]: text size reduced from "+nceiling+" to "+nbest+" px so the longest value fits")
	Ok 
	Return nbest 
	
# The size of a caption, chosen once for the whole run as the body of a text is.
#
# A caption is one line and prints the string as it stands, so what decides is its width: the
# largest size at which the longest value of the column still fits between the borders. Two other
# things cap it. font_size, where the template wrote one, is the size it may not pass, as
# everywhere else. And the symbol has to keep a cell: the caption is a band taken out of the box
# before the symbol is fitted into what is left, and a symbol left less than the smallest thing
# the drawing can say is not a symbol worth printing.
#
# No wrapping and no growing to fill: a second line would be taken out of the symbol, and a
# caption is there to be read off the label rather than to fill it. Small is not the same as
# unreadable, since the label is measured against the page: on a sheet the size of a stamp four
# pixels are four pixels, and on A4 the same four are millimetres.
#
# A width is measured once at a thousand pixels and divided, because an advance scales with the
# size exactly - the search by halving that a wrapped text needs is not needed here.
#
# Returns zero for a box with no room for a caption at all, where none is drawn.
Func fitcaptionsize oblock, adatarows, nboxw, nboxh, ncharw, ncharh 

	nupper = floor((nboxh-ncharh)/1.15)
	If nupper < 1
		add($labelcodewarnings, "CODE BOX ["+oblock.id+"] is "+nboxh+
		" px high inside its borders and a cell is "+ncharh+
		" px: there is no room for a caption and none is drawn. Make the box "+
		countphrase(ceil((ncharh+1.15-nboxh)/ncharh), "cell")+" taller.")
		Return 0
	Ok 
	nceiling = oblock.config.font_size 
	If nceiling > 0 And nceiling < nupper nupper = nceiling Ok 
	nwidest = 0
	For arow In adatarows 
		ctext = ""
		If oblock.id <= len(arow) ctext = arow[oblock.id] Ok 
		If ctext = "" Loop Ok 
		nlinew = fm_measureline(ctext, 1000)
		If nlinew > nwidest nwidest = nlinew Ok 
	Next 
	If nwidest = 0 Return nupper Ok 
	nfitswidth = floor(nboxw*1000/nwidest)
	If nfitswidth >= nupper Return nupper Ok 
	If nfitswidth < 1
		add($labelcodewarnings, "CODE BOX ["+oblock.id+
		"]: the caption does not fit its box at any size and is drawn at 1 px, the smallest there "+
		"is - widen the box by "+countphrase(ceil((nwidest/1000-nboxw)/ncharw), "cell")+
		", or shorten the data.")
		Return 1
	Ok 
	If nceiling > 0
		add($labelcodewarnings, "CODE BOX ["+oblock.id+"]: caption size reduced from "+nceiling+
		" to "+nfitswidth+" px so the longest value fits its box.")
	Ok 
	Return nfitswidth 
	
# Whether every value of one column fits one box at one body size, wrapped.
Func bodyfits oblock, adatarows, nsize, nboxw, nboxh 

	aextent = columnextent(oblock, adatarows, nsize, nboxw)
	Return aextent[1] <= nboxw And aextent[2] <= nboxh 
	
# Draws one label: every block goes from cells to pixels, inherits whatever it did not set
# from the global configuration, and is drawn according to its type - text, image or code. A
# block with an id takes its content from that column of the data row; a block without one is
# a frame, and receives instead the piece of free-flowing text that flowed into it.
#
# The border of a block and its content do not sit in the same place. The border passes
# through the centre of its cells, as every line of the drawing does; what goes inside is
# given the interior, from where the border cell ends to where the opposite border cell
# begins - the same ground the free-flowing text is laid into. That is where the half cell of
# white on either side of the line comes from, and there is no option to set it.
#
# Two things narrow that rule. A text keeps the full height between the two lines: sideways it
# needs the inset, because its first letter begins exactly at the edge of the box and would
# otherwise be printed on the border, but up and down it does not, since a line of text
# already carries its own air - the line height is a fifth taller than the letters - and
# taking a whole cell from a box two cells tall would halve the body for nothing.
#
# And a block that draws no border gets no inset on any side: the white was there to keep the
# content off the line. That is what gives an image block its full box back, since most of
# them are drawn without a frame.
Func renderrow osvg, omodel, arow, aflowed, noffsetx, noffsety, atextsizes 

	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	nhalfcellw = floor(ncharw/2+0.5)
	nhalfcellh = floor(ncharh/2+0.5)
	acodecalls = []
	For nblockidx = 1 To len(omodel.blocks)
		oblock = omodel.blocks[nblockidx]
		nx = (oblock.x-1)*ncharw+noffsetx 
		ny = (oblock.y-1)*ncharh+noffsety 
		nw = oblock.w*ncharw 
		nh = oblock.h*ncharh 
		ainner = blockinnerbox(omodel, oblock, nx, ny)
		ninx = ainner[1]
		niny = ainner[2]
		ninw = ainner[3]
		ninh = ainner[4]
		afont = usefont(oblock.config.font)
		cfontfamily = afont[1]
		nsize = atextsizes[nblockidx]
		If oblock.w > 0 And oblock.h > 0
			osvg.drawrectangle(nx, ny, nw, nh, 
			oblock.config.stroke, 
			oblock.config.radius, 
			oblock.config.fg_color, 
			oblock.config.bg_color)
			If oblock.id > 0
				cdata = ""
				If oblock.id <= len(arow)
					cdata = arow[oblock.id]
				Ok 
				If oblock.config.type = "text"
					# Wrapped here and not inside the drawing object: the lines are decided by the
					# same measurement that chose the body, so what is drawn is what was measured
					# to fit. The drawing object keeps its one job, which is putting marks down.
					cshown = cdata 
					If cdata != ""
						alines = fm_wraptext(cdata, nsize, ninw)
						cshown = ""
						For nlineidx = 1 To len(alines)
							If nlineidx > 1 cshown += nl Ok 
							cshown += alines[nlineidx]
						Next 
					Ok 
					osvg.drawtext(ninx, ny, ninw, nh, 
					cshown, 
					cfontfamily, 
					nsize, 
					oblock.config.align, 
					oblock.config.fg_color)
				Elseif oblock.config.type = "image"
					osvg.drawimage(ninx, niny, ninw, ninh, cdata)
				Elseif oblock.config.type = "code"
					# Kept back rather than drawn here. The symbols go down at the foot of this
					# function, after every other mark on the label, because a scanner needs the
					# modules clean and a symbol paints its own opaque ground: last means nothing
					# can reach them.
					add(acodecalls, [ninx, niny, ninw, ninh, cdata, 
					oblock.config.format, 
					oblock.config.fg_color, 
					oblock.config.caption, 
					cfontfamily, 
					nsize, 
					oblock.config.quiet_zone, 
					oblock.config.qr_correction])
				Ok 
			Ok 
		Elseif oblock.w > 0 Or oblock.h > 0
			nx2 = nx+oblock.w*ncharw 
			ny2 = ny+oblock.h*ncharh 
			osvg.drawline(nx, ny, nx2, ny2, 
			omodel.config.stroke_line, 
			oblock.config.radius, 
			omodel.config.fg_color)
		Else 
			osvg.drawpoint(nx, ny, 
			omodel.config.stroke_point, 
			oblock.config.radius, 
			omodel.config.fg_color)
		Ok 
	Next 
	For oflow In aflowed 
		# Cell boxes, not cell centres: the offset less the half cell. Without it the flowed
		# text would stay where it is while the drawing moves, on a canvas that has grown.
		nslotx = (oflow.slotx-1)*ncharw+noffsetx-nhalfcellw 
		nsloty = (oflow.sloty-1)*ncharh+noffsety-nhalfcellh 
		nslotx += oflow.roundleft 
		nslotw_px = oflow.slotw*ncharw-oflow.roundleft-oflow.roundright 
		nsloth_px = ncharh 
		osvg.drawtext(nslotx, nsloty, nslotw_px, nsloth_px, 
		oflow.text, 
		oflow.font, 
		oflow.size, 
		oflow.align, 
		oflow.color)
	Next 
	# The codes, last of all and in the order the drawing found them. Their captions travel with
	# them: drawcode writes the caption after its own symbol, so a caption is never covered by the
	# symbol it belongs to, and neither of the two can now be reached by anything else.
	For acall In acodecalls 
		osvg.drawcode(acall[1], acall[2], acall[3], acall[4], acall[5], acall[6], 
		acall[7], acall[8], acall[9], acall[10], acall[11], acall[12])
	Next 
	

# The same drawing, made self-contained.
#
# The .svg written beside the page holds exactly the markup the page holds, but not what the
# page carries around it: the @font-face rules that give the drawing its real face, and the
# images the page fetches from the folder it was opened in. So every font file and every
# image is embedded here as a data: URI, and the file then needs nothing but itself.
#
# Embedded rather than referenced, although a relative path is lighter and was tried first: a
# relative path holds in one case only. A browser opening the file directly does honour a
# relative url() and a relative <image>; the same file placed in a page as
# <img src="label.svg"> loads no external resource at all, neither the font nor the images,
# because that is the rule for SVG inside an <img>; and a renderer outside a browser may
# fetch the images and ignore the @font-face. Embedding is the only form that survives all
# three.
#
# What it still does not buy: a renderer that ignores @font-face ignores it embedded as well,
# and substitutes the face. Only text turned into outlines would survive that, and it would
# no longer be text.
Func selfcontainedsvg ccontent, ausedfonts 

	cresult = ccontent 
	For cpath In imagepathsin(ccontent)
		cresult = substr(cresult, 'href="'+cpath+'"', 'href="'+filedatauri(cpath)+'"')
	Next 
	cstyle = ""
	For afont In ausedfonts 
		cstyle += '@font-face { font-family: "'+afont[1]+'";'
		cstyle += ' src: url("'+filedatauri(afont[2])+'") format("'+fontformatfor(afont[2])+'");'
		cstyle += " font-weight: normal; font-style: normal; }"+nl 
	Next 
	If cstyle = "" Return cresult Ok 
	nsvgat = substr(cresult, "<svg")
	If nsvgat = 0 Return cresult Ok 
	ntagend = substr(substr(cresult, nsvgat), ">")
	If ntagend = 0 Return cresult Ok 
	cdefs = "<defs><style type="+char(34)+"text/css"+char(34)+">"+nl+cstyle+"</style></defs>"+nl 
	Return left(cresult, nsvgat+ntagend-1)+nl+cdefs+substr(cresult, nsvgat+ntagend)
	
# The image files a drawing points at, each one once. A reference that is already a data: URI
# is left alone, and so is one naming a file that is not there: a missing mark is the
# template's business, and an error raised here would help nobody.
Func imagepathsin ccontent 

	apaths = []
	crest = ccontent 
	nfoundat = substr(crest, 'href="')
	While nfoundat > 0
		crest = substr(crest, nfoundat+6)
		nquoteat = substr(crest, char(34))
		If nquoteat > 1
			cpath = left(crest, nquoteat-1)
			If left(cpath, 5) != "data:" And fexists(cpath) And find(apaths, cpath) = 0
				add(apaths, cpath)
			Ok 
		Ok 
		nfoundat = substr(crest, 'href="')
	End 
	Return apaths 
	
# One file as a data: URI, encoded once per run and kept.
Func filedatauri cpath 

	nknown = find($labelembedded, cpath, 1)
	If nknown > 0 Return $labelembedded[nknown][2] Ok 
	curi = "data:"+mimeforfile(cpath)+";base64,"+StringToBase64(read(cpath))
	add($labelembedded, [cpath, curi])
	Return curi 
	
# The media type a data: URI has to declare, taken from the extension. Anything unrecognised
# is declared as plain bytes, which is what a viewer falls back to anyway.
Func mimeforfile cpath 

	cname = lower(cpath)
	If right(cname, 4) = ".png" Return "image/png" Ok 
	If right(cname, 4) = ".jpg" Or right(cname, 5) = ".jpeg" Return "image/jpeg" Ok 
	If right(cname, 4) = ".gif" Return "image/gif" Ok 
	If right(cname, 5) = ".webp" Return "image/webp" Ok 
	If right(cname, 4) = ".bmp" Return "image/bmp" Ok 
	If right(cname, 4) = ".svg" Return "image/svg+xml" Ok 
	If right(cname, 4) = ".ttf" Return "font/ttf" Ok 
	If right(cname, 4) = ".otf" Return "font/otf" Ok 
	If right(cname, 4) = ".ttc" Return "font/collection" Ok 
	Return "application/octet-stream"
	
# The format a @font-face rule has to declare for this file. It is not the media type: it
# says how the outlines are built, quadratic in a .ttf and cubic in a .otf, and a browser
# uses it to skip a source it cannot read without downloading it first.
Func fontformatfor cpath 

	cname = lower(cpath)
	If right(cname, 4) = ".otf" Return "opentype" Ok 
	If right(cname, 4) = ".ttc" Return "collection" Ok 
	If right(cname, 5) = ".woff" Return "woff" Ok 
	Return "truetype"
	
