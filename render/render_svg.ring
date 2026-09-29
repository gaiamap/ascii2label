# The SVG back end: the drawing surface every block is painted on. It knows how to draw a
# frame, a line, a point, a piece of text, an image and a code symbol, and nothing about
# where any of them go - the placing is decided one level up, in render.ring.
#
# Throughout this file, whether an argument was given is asked with isnull(), not with
# '= null': in Ring null is the empty string and 0 = "" is true, so '= null' would read a
# quiet zone of zero as "not given" and put the default in its place.
Load "ringqr.ring"
Load "ringbc.ring"

# One entry per symbol drawn - the bars of a linear one and the squares of a QR alike - holding
# what the print report needs to judge it and to say how to mend it: the width of one module in
# pixels, the room that width was taken from, the natural width of the symbol at one pixel per
# module, and whether it was the height of the box and not its width that decided.
#
# The narrowest module of the run is the one that has to survive, and the other three numbers are
# what turn 'too thin' into a count of cells: they say how much room a wider module would need,
# and a QR grows with its room while a linear symbol grows in whole steps of its natural width.
# The natural width is zero for a QR, which is how the report tells the two apart.
$labelcodemodules = []

# The linear symbols that ran off the label, as [data, pixels past the edge]. At one pixel per
# module there is nothing left to shrink, so a symbol too long for the room it was given is drawn
# at its own width; where that carries it past the canvas the drawing clips it and nothing can be
# read back. A symbol that only outgrows its own box is not here and is not reported: it is drawn
# after everything else and paints its own ground, so it stays whole - what it covers is the
# neighbour, and that is the drawing's business, not the scanner's.
$labelbarcodecut = []

# The code symbols drawn on the label being built, as [x, y, w, h, data], and the pairs found one
# on top of the other, as [covered, covering]. The symbols are put down after everything else on
# the label and each paints its own opaque ground, so nothing but another symbol can reach the
# modules: what is left to watch for is two of them on the same ground, where the later one wins
# and the earlier is gone under it.
$labelcodeareas = []
$labelcodeoverlap = []

$labelcodewarnings = []

# The markup built so far, and the canvas it is being built for.
Class svgdrawing 

	coutput = ""
	nwidth = 0
	nheight = 0
	
# Opens an empty drawing of this pixel size.
	Func Init nw, nh 

		nwidth = nw 
		nheight = nh 
		coutput = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'+nl 
		coutput += '<svg width="'+nwidth+'" height="'+nheight+'"'
		coutput += ' viewBox="0 0 '+nwidth+" "+nheight+'"'
		coutput += ' xmlns="http://www.w3.org/2000/svg">'+nl 
		coutput += '<rect width="100%" height="100%" fill="white"/>'+nl 
		
# The finished markup, closed and ready to be embedded or written out.
	Func getsvg 

		Return coutput+"</svg>"+nl 
		
# Writes the drawing to its own .svg file.
	Func save cfilename 

		write(cfilename, getsvg())
		
# A box: the border of a frame, or the background of a field. A stroke of zero means no
# border at all, which is how a block carries a colour without being outlined.
#
# The corner radius is capped at half the shorter side, which is as round as a rectangle gets:
# there it is a pill, and there is nothing further to ask for. Capped here rather than left to
# the renderer, because a renderer clamps the two axes separately, and on a shape much wider
# than it is tall that gives a lens instead of a pill.
	Func drawrectangle x, y, w, h, stroke, radius, fg, bg 

		nround = radius 
		nshorterside = w 
		If h < nshorterside nshorterside = h Ok 
		If nround > nshorterside/2 nround = nshorterside/2 Ok 
		coutput += '<rect x="'+x+'" y="'+y+'"'
		coutput += ' width="'+w+'" height="'+h+'"'
		If nround > 0
			coutput += ' rx="'+nround+'" ry="'+nround+'"'
		Ok 
		cstroke = fg 
		If stroke = 0 Or fg = "" Or fg = "none"
			cstroke = "none"
		Ok 
		cfill = bg 
		If bg = "" Or bg = "none"
			cfill = "none"
		Ok 
		coutput += ' stroke="'+cstroke+'" stroke-width="'+stroke+'"'
		coutput += ' fill="'+cfill+'"/>'+nl 
		
# An independent line of the drawing - a rule, a fold, a perforation.
#
# Drawn as a rectangle as long as the run and as thick as the stroke, so that a radius rounds
# the ends by eating into that length instead of adding to it, and the ink stays inside the
# cells the drawing gave it. At half the stroke the two ends are semicircles and there is no
# more to round. With no radius the rectangle covers exactly the same pixels a line with square
# ends covers.
	Func drawline x1, y1, x2, y2, stroke, radius, fg 

		If stroke = 0 Or fg = "" Or fg = "none"
			Return 
		Ok 
		nlineleft = x1 
		nlinetop = y1 
		nlinewidth = x2-x1 
		nlineheight = y2-y1 
		If nlineheight = 0
			nlineheight = stroke 
			nlinetop = y1-stroke/2
		Else 
			nlinewidth = stroke 
			nlineleft = x1-stroke/2
		Ok 
		nround = radius 
		If nround > stroke/2 nround = stroke/2 Ok 
		coutput += '<rect x="'+nlineleft+'" y="'+nlinetop+'"'
		coutput += ' width="'+nlinewidth+'" height="'+nlineheight+'"'
		If nround > 0
			coutput += ' rx="'+nround+'" ry="'+nround+'"'
		Ok 
		coutput += ' fill="'+fg+'"/>'+nl 
		
# A lone marker: a punch hole, a registration mark, a bullet.
#
# A square of side stroke, whose corners the radius rounds as it rounds those of any other box:
# at half the side the square is a disc. The size stays the stroke's business either way, so
# asking for a rounder marker never returns a smaller one.
	Func drawpoint x, y, stroke, radius, fg 

		If stroke = 0 Or fg = "" Or fg = "none"
			Return 
		Ok 
		nhalfside = stroke/2
		nround = radius 
		If nround > nhalfside nround = nhalfside Ok 
		coutput += '<rect x="'+(x-nhalfside)+'" y="'+(y-nhalfside)+'"'
		coutput += ' width="'+stroke+'" height="'+stroke+'"'
		If nround > 0
			coutput += ' rx="'+nround+'" ry="'+nround+'"'
		Ok 
		coutput += ' fill="'+fg+'"/>'+nl 
		
# Text inside a block, anchored left, centred or right, and sitting on the middle of the box.
#
# A value that carries newlines is drawn as the several lines it is: they are stacked one line
# height apart and the whole stack is centred on the box, so two lines sit half above and half
# below the middle.
#
# Each line is hung from the middle of its own line box, and the centring is left to whoever
# draws it: 'central' means the renderer puts the middle of the letters, ascender to
# descender, on that line. Estimating the drop from the baseline as a fraction of the body is
# off by a little for every face, and a stack that exactly fills its box then pokes out of it.
#
# The text is not wrapped and not shrunk here: a value longer than its block runs past it.
# Only the free-flowing text of the anonymous frames is wrapped to fit.
	Func drawtext x, y, w, h, text, font, size, align, fg 

		If text = "" Return Ok 
		alines = str2list(text)
		nlineheight = size*1.2
		ntotalh = len(alines)*nlineheight 
		nstacktop = y+(h-ntotalh)/2
		For i = 1 To len(alines)
			cline = alines[i]
			nypos = nstacktop+(i-1)*nlineheight+nlineheight/2
			nxpos = x 
			canchor = "start"
			If align = "center"
				nxpos = x+(w/2)
				canchor = "middle"
			Elseif align = "right"
				nxpos = x+w 
				canchor = "end"
			Ok 
			coutput += '<text x="'+nxpos+'" y="'+nypos+'"'
			If font != ""
				coutput += ' font-family="'+font+'"'
			Ok 
			coutput += ' font-size="'+size+'"'
			coutput += ' fill="'+fg+'"'
			coutput += ' text-anchor="'+canchor+'"'
			coutput += ' dominant-baseline="central">'
			coutput += escapemarkup(cline)
			coutput += "</text>"+nl 
		Next 
		
# An image, referenced by path and fitted inside the block without distorting it. The file is
# never read here: what goes into the drawing is the reference, and whoever displays it
# resolves the path.
	Func drawimage x, y, w, h, path 

		If path = "" Return Ok 
		coutput += '<image href="'+path+'"'
		coutput += ' x="'+x+'" y="'+y+'"'
		coutput += ' width="'+w+'" height="'+h+'"'
		coutput += ' preserveAspectRatio="xMidYMid meet"/>'+nl 
		
# Puts a symbol on the register of what this label already carries, and notes it when it lands on
# one that is there. Only the ground a symbol really covers is registered, which on a symbol that
# was fitted into a larger box is smaller than the box on one of the two sides.
	Func _registercode x, y, w, h, cdata 

		For aarea In $labelcodeareas 
			If x < aarea[1]+aarea[3] And x+w > aarea[1] And y < aarea[2]+aarea[4] And y+h > aarea[2]
				add($labelcodeoverlap, [aarea[5], cdata])
				Exit 
			Ok 
		Next 
		add($labelcodeareas, [x, y, w, h, cdata])
		
# A code symbol, with the raw string optionally printed above or below it as a caption. The
# format decides which of the two generators is used: anything containing 'qr' goes to the QR
# one, everything else to the linear one. The caption is reserved first, so the symbol is
# drawn into what is left rather than over the text.
#
# The size of the caption is chosen one level up, once for the whole run and against this box, so
# a zero here is not a value left out: it says the box has no room for a caption, and the band is
# not taken out at all. That is also why nothing is capped here - a band as tall as the box would
# leave the symbol a negative height, which is not valid markup, and the size that arrives can no
# longer be that large.
	Func drawcode x, y, w, h, data, format, fg, caption, font, size, quietzone, qrcorrection 

		If data = "" Return Ok 
		If font = "" font = "Arial,sans-serif" Ok 
		If isnull(quietzone) quietzone = 1 Ok 
		ncaptionh = 0
		If caption != "" And size > 0
			ncaptionh = size*1.15
		Else 
			caption = ""
		Ok 
		ncodey = y 
		ncodeh = h 
		If caption = "above"
			ncodey = y+ncaptionh 
			ncodeh = h-ncaptionh 
		Elseif caption != ""
			ncodeh = h-ncaptionh 
		Ok 
		cfmt = lower(format)
		If substr(cfmt, "qr") > 0
			drawqrplaceholder(x, ncodey, w, ncodeh, data, quietzone, qrcorrection)
		Else 
			drawbarcodeplaceholder(x, ncodey, w, ncodeh, data, format, quietzone)
		Ok 
		If caption != ""
			If caption = "above"
				ncy = y+(ncaptionh/2)
			Else 
				ncy = ncodey+ncodeh+(ncaptionh/2)
			Ok 
			coutput += '<text x="'+(x+w/2)+'" y="'+ncy+'"'
			coutput += ' font-family="'+font+'"'
			coutput += ' font-size="'+size+'"'
			coutput += ' fill="'+fg+'" text-anchor="middle"'
			coutput += ' dominant-baseline="central">'
			coutput += escapemarkup(data)
			coutput += "</text>"+nl 
		Ok 
		
# A QR symbol, asked of the library and dropped into the block.
#
# The mode is not a template key and is not the user's to choose: 'AUTO' hands the decision
# to the library, which picks the mode that packs the whole text most tightly. Passing nothing
# would inherit the library's own default, which is Numeric, and every label holding a URL
# would then report a mode change that is not a fault.
#
# The correction level the template asked for is translated here into the letter the library
# expects, since reading a configuration key and then not using it is worse than not offering
# it at all.
#
# The opening tag is rebuilt rather than patched: the library already writes its own width,
# height and viewBox, and inserting ours in front of them would leave the tag with two of
# each. A browser forgives that and draws the first, but the file is then invalid XML, and
# this same markup is also written out as a standalone .svg.
	Func drawqrplaceholder nx, ny, nw, nh, cdata, nquietzone, cqrcorrection 

		If isnull(nquietzone) nquietzone = 1 Ok 
		cec = null 
		Switch lower(cqrcorrection)
		On "low" cec = "L"
		On "medium" cec = "M"
		On "high" cec = "Q"
		On "highest" cec = "H"
		Off 
		ares = qr_generate(cdata, "AUTO", cec, null, nquietzone, ["svg", "info"])
		For cwarning In ares[:info][:warnings]
			add($labelcodewarnings, "QR ["+cdata+"] "+cwarning)
		Next 
		aparts = _symbolparts(ares[:svg], nw, nh)
		nnativew = aparts[1]
		nnativeh = aparts[2]
		csvgbody = aparts[3]
		# The symbol is fitted inside the box and centred, so the ground it really covers is
		# smaller than the box on one of the two sides, and it is that ground that goes on the
		# register.
		nscale = nw/nnativew 
		If nh/nnativeh < nscale nscale = nh/nnativeh Ok 
		# The module of a QR, on the same register as the bars of a linear symbol: the symbol's
		# own side less the quiet zone the library put around it, over the count of modules it
		# reported, and then scaled as the whole drawing is. A QR is where this matters most,
		# since a small one carrying a lot of data has many modules to fit in the same box.
		nmodules = ares[:info][:modules]
		If nmodules > 0
			# Which side of the box decided the fit is what the mending advice needs: a symbol
			# fitted to the height grows by a taller box and not by a wider one.
			bbyheight = (nh/nnativeh < nw/nnativew)
			nroom = nw 
			If bbyheight nroom = nh Ok 
			add($labelcodemodules, [(nnativew-2*nquietzone)*nscale/nmodules, nroom, 0, bbyheight])
		Ok 
		_registercode(nx+(nw-nnativew*nscale)/2, ny+(nh-nnativeh*nscale)/2,
		nnativew*nscale, nnativeh*nscale, cdata)
		cnewsvg = '<svg x="'+nx+'" y="'+ny+'" width="'+nw+'" height="'+nh+'"'
		cnewsvg += ' viewBox="0 0 '+nnativew+" "+nnativeh+'"'
		cnewsvg += ' preserveAspectRatio="xMidYMid meet"'
		cnewsvg += ' xmlns="http://www.w3.org/2000/svg">'+nl 
		coutput += cnewsvg+csvgbody+nl 
		
# A generated symbol taken apart: its natural width and height, and its markup without the XML
# declaration and without its own opening tag.
#
# The tag is dropped rather than patched because the library already writes its own width, height
# and viewBox, and inserting ours in front of them would leave the tag with two of each. A browser
# forgives that and draws the first, but the file is then invalid XML, and this same markup is also
# written out as a standalone .svg.
	Func _symbolparts csvg, ndefaultw, ndefaulth 

		csvg = substr(csvg, '<?xml version="1.0" encoding="UTF-8" standalone="no"?>', "")
		Return [_svgattr(csvg, "width", ndefaultw), 
		_svgattr(csvg, "height", ndefaulth), 
		substr(csvg, substr(csvg, ">")+1)]
		
# Reads one numeric attribute out of a piece of markup, with a fallback when it is missing or
# not a number. It is how this file learns the natural size of a symbol the library produced.
	Func _svgattr csvg, cname, ndefault 

		csearch = cname+'="'
		npos = substr(csvg, csearch)
		If npos > 0
			nstart = npos+len(csearch)
			cval = ""
			For i = nstart To len(csvg)
				If csvg[i] = '"' Exit Ok 
				cval += csvg[i]
			Next 
			nval = number(cval)
			If nval > 0 Return nval Ok 
		Ok 
		Return ndefault 
		
# A linear barcode, asked of the library and fitted to the block.
#
# The fitting is done by measuring, not by scaling: the symbol is generated once at one pixel
# per module to learn its natural width, then regenerated at the largest whole multiple that
# still fits the block. Whole multiples matter, because a bar stretched by a fraction of a
# pixel is a bar a scanner may misread, and if the multiple turns out one too many it steps
# back down by one.
#
# The warnings are collected from the first call only: that is the one that decides the
# barcode type, and the others merely repeat the same choice at another size.
	Func drawbarcodeplaceholder nx, ny, nw, nh, cdata, cformat, nquietzone 

		If cformat = "" cformat = "CODE128" Ok 
		If isnull(nquietzone) nquietzone = 1 Ok 
		ares1 = bc_generate(cdata, cformat, 1, nh, nquietzone, ["svg", "info"])
		For cwarning In ares1[:info][:warnings]
			add($labelcodewarnings, "BARCODE ["+cdata+"] "+cwarning)
		Next 
		csvg1 = ares1[:svg]
		nnativew1 = _svgattr(csvg1, "width", nw)
		nmult = floor(nw/nnativew1)
		If nmult < 1 nmult = 1 Ok 
		If nmult > 1
			ares = bc_generate(cdata, cformat, nmult, nh, nquietzone, ["svg"])
			csvg = ares[:svg]
		Else 
			csvg = ares1[:svg]
		Ok 
		aparts = _symbolparts(csvg, nnativew1*nmult, nh)
		nnativew = aparts[1]
		nnativeh = aparts[2]
		csvgbody = aparts[3]
		If nnativew > nw And nmult > 1
			nmult = nmult-1
			ares = bc_generate(cdata, cformat, nmult, nh, nquietzone, ["svg"])
			aparts = _symbolparts(ares[:svg], nw, nh)
			nnativew = aparts[1]
			nnativeh = aparts[2]
			csvgbody = aparts[3]
		Ok 
		add($labelcodemodules, [nmult, nw, nnativew1, false])
		ncenterx = nx+floor((nw-nnativew)/2)
		If ncenterx < nx ncenterx = nx Ok 
		_registercode(ncenterx, ny, nnativew, nh, cdata)
		If ncenterx+nnativew > nwidth 
			add($labelbarcodecut, [cdata, ncenterx+nnativew-nwidth])
		Ok 
		cnewsvg = '<svg x="'+ncenterx+'" y="'+ny+'"'
		cnewsvg += ' width="'+nnativew+'" height="'+nh+'"'
		cnewsvg += ' viewBox="0 0 '+nnativew+" "+nnativeh+'"'
		cnewsvg += ' preserveAspectRatio="none"'
		cnewsvg += ' style="shape-rendering: crispEdges; image-rendering: pixelated;"'
		cnewsvg += ' xmlns="http://www.w3.org/2000/svg">'+nl 
		coutput += cnewsvg+csvgbody+nl 
		
