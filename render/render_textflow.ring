# The free-flowing text engine: takes one text and flows it into the anonymous frames of the
# layout - the boxes with no digit - as many lines as each of them can hold. It fills the
# background of a label with a description while the numbered boxes carry the data.
Load "ringfm.ring"

# Lays the text out into every anonymous frame, in reading order, and returns one entry per
# line placed: which frame it belongs to, where it sits inside it, and how it is drawn.
# The frames are taken in the order they were found, and the text continues from one to the
# next, so the same paragraph can run across several boxes of the drawing.
Func flowtextintoframes omodel, ogrid, ctext 

	aanonblocks = []
	For oblock In omodel.blocks 
		If oblock.id = 0 And oblock.w > 0 And oblock.h > 0
			add(aanonblocks, oblock)
		Ok 
	Next 
	If len(aanonblocks) = 0 Or ctext = ""
		Return []
	Ok 
	For i = 1 To len(aanonblocks)-1
		For j = i+1 To len(aanonblocks)
			If aanonblocks[j].y < aanonblocks[i].y Or 
				(aanonblocks[j].y = aanonblocks[i].y And aanonblocks[j].x < aanonblocks[i].x)
				temp = aanonblocks[i]
				aanonblocks[i] = aanonblocks[j]
				aanonblocks[j] = temp 
			Ok 
		Next 
	Next 
	ngridh = ogrid.height()
	ngridw = ogrid.width()
	aoccupied = list(ngridh+1)
	For y = 1 To ngridh 
		aoccupied[y] = list(ngridw+1)
		For x = 1 To ngridw 
			aoccupied[y][x] = false 
		Next 
	Next 
	For y = 1 To ngridh 
		For x = 1 To ngridw 
			If ogrid.char(y, x) != " "
				aoccupied[y][x] = true 
			Ok 
		Next 
	Next 
	For oblock In omodel.blocks 
		If oblock.id > 0 And oblock.w > 0 And oblock.h > 0
			For y = oblock.y To oblock.y+oblock.h-1
				For x = oblock.x To oblock.x+oblock.w-1
					If y >= 1 And y <= ngridh And x >= 1 And x <= ngridw 
						aoccupied[y][x] = true 
					Ok 
				Next 
			Next 
		Ok 
	Next 
	aallslots = []
	For oblock In aanonblocks 
		For nrow = 0 To oblock.h-1
			ngridy = oblock.y+nrow 
			nstartx = 0
			nconsecutive = 0
			For ncol = 0 To oblock.w-1
				ngridx = oblock.x+ncol 
				If Not aoccupied[ngridy][ngridx]
					If nconsecutive = 0
						nstartx = ngridx 
					Ok 
					nconsecutive++
				Else 
					If nconsecutive >= 3
						add(aallslots, [oblock, nrow, nstartx, nconsecutive])
					Ok 
					nconsecutive = 0
				Ok 
			Next 
			If nconsecutive >= 3
				add(aallslots, [oblock, nrow, nstartx, nconsecutive])
			Ok 
		Next 
	Next 
	If len(aallslots) = 0
		Return []
	Ok 
	cglobalfont = omodel.config.font 
	# The text keeps its own lines: a line break written in the text is a line break on the
	# label. A line too long for the slot it lands in is broken to fit, and what is left of it
	# stays at the head of the text, so the next slot carries on that same line and the line
	# after it starts on a slot of its own. A line left empty in the text takes its slot and
	# draws nothing, which is the blank row it asks for.
	atextlines = []
	If ctext != "" atextlines = str2list(ctext) Ok 
	aflowresult = []
	For slotidx = 1 To len(aallslots)
		If len(atextlines) = 0 Exit Ok 
		oslot = aallslots[slotidx]
		oblock = oslot[1]
		nrow = oslot[2]
		nslotx = oslot[3]
		nslotw = oslot[4]
		ngridy = oblock.y+nrow 
		cfont = oblock.config.font 
		If cfont = "" cfont = cglobalfont Ok 
		afont = usefont(cfont)
		cfontfamily = afont[1]
		# Free text has no box to grow into: one of its lines is laid on one cell row, which is a
		# fact of the layout. So a font_size that was written is the body - a larger one lets the
		# lines run into one another, which is the template's business, and is how a long passage
		# is made to run across the frames instead of ending in the first one. Only when nothing
		# was asked for does the cell decide, and then it gives the largest body it can hold.
		nsize = oblock.config.font_size 
		If nsize = 0 nsize = omodel.config.font_size Ok 
		If nsize = 0
			nsize = floor(omodel.config.char_height/1.2)
			If nsize < 1 nsize = 1 Ok 
		Ok 
		around = roundingtrim(omodel, oblock, ngridy, nslotx, nslotw)
		nslotwidthpx = nslotw*omodel.config.char_width-around[1]-around[2]
		If nslotwidthpx < 1 Loop Ok 
		If atextlines[1] = ""
			del(atextlines, 1)
			Loop 
		Ok 
		alines = fm_wraptext(atextlines[1], nsize, nslotwidthpx)
		If len(alines) = 0
			del(atextlines, 1)
			Loop 
		Ok 
		clinetext = alines[1]
		crest = ""
		For i = 2 To len(alines)
			If i > 2 crest += " " Ok 
			crest += alines[i]
		Next 
		If crest = ""
			del(atextlines, 1)
		Else 
			atextlines[1] = crest 
		Ok 
		If len(clinetext) > 0
			oresult = New flowresult 
			oresult.block = oblock 
			oresult.text = clinetext 
			oresult.slotx = nslotx 
			oresult.slotw = nslotw 
			oresult.roundleft = around[1]
			oresult.roundright = around[2]
			oresult.sloty = ngridy 
			oresult.font = cfontfamily 
			oresult.size = nsize 
			oresult.color = oblock.config.fg_color 
			oresult.align = oblock.config.align 
			add(aflowresult, oresult)
		Ok 
	Next 
	Return aflowresult 
# How much the rounded corners of a frame take off one line, on the left and on the right, in
# pixels.
#
# A frame with square corners takes nothing, and that is the usual answer. Where the corners are
# rounded the border curves inward, and a line laid in the cell rows nearest the top or the
# bottom would cross it: the room a line has there is the width of the frame less what the curve
# has eaten at the height of that line, which is what a circle gives - the corner is a quarter of
# one, of the radius the box was drawn with.
#
# The worst point of the line's own cell row decides, so the whole row stays inside, and the
# radius is capped as the drawing caps it, at half the shorter side, where the shape is already as
# round as it gets.
Func roundingtrim omodel, oblock, ngridy, nslotx, nslotw 

	nradius = oblock.config.radius 
	If nradius <= 0 Return [0, 0] Ok 
	ncharw = omodel.config.char_width 
	ncharh = omodel.config.char_height 
	nboxw = oblock.w*ncharw 
	nboxh = oblock.h*ncharh 
	nshorter = nboxw 
	If nboxh < nshorter nshorter = nboxh Ok 
	If nradius > nshorter/2 nradius = nshorter/2 Ok 
	# The line's cell row against the box, both taken from the drawing: a box is measured from the
	# middle of its border cells and a row from the edge of its own, so the first row of a frame
	# begins half a cell above the border it holds.
	ntop = (ngridy-oblock.y)*ncharh-floor(ncharh/2+0.5)
	nfromtop = ntop 
	If nfromtop < 0 nfromtop = 0 Ok 
	nfrombottom = nboxh-ntop-ncharh 
	If nfrombottom < 0 nfrombottom = 0 Ok 
	neaten = arcinset(nradius, nfromtop)
	nother = arcinset(nradius, nfrombottom)
	If nother > neaten neaten = nother Ok 
	If neaten <= 0 Return [0, 0] Ok 
	# From the room the curve leaves to what this line loses: a slot that does not reach the side
	# of the frame loses nothing on that side.
	nslotleft = (nslotx-oblock.x)*ncharw-floor(ncharw/2+0.5)
	nleft = neaten-nslotleft 
	If nleft < 0 nleft = 0 Ok 
	nright = nslotleft+nslotw*ncharw-(nboxw-neaten)
	If nright < 0 nright = 0 Ok 
	Return [nleft, nright]
	
# How far a quarter circle of this radius has come in, at a distance from the end of the side it
# rounds: the whole radius at the corner itself, nothing where the straight part begins. Whole
# pixels, rounded up, so that a line never asks for more room than the curve leaves.
Func arcinset nradius, ndistance 

	If ndistance >= nradius Return 0 Ok 
	nreach = nradius-ndistance 
	Return ceil(nradius-sqrt(nradius*nradius-nreach*nreach))
	
# One line of text after the layout: which frame it landed in, what it says, where inside the
# frame it sits and how wide the slot is, what the rounded corners take off it, plus the face and
# size it is to be drawn with. The renderer only places these - all the measuring has already
# happened.
Class flowresult 

	block 
	text 
	slotx 
	slotw 
	sloty 
	font 
	size 
	color 
	align 
	roundleft 
	roundright 
	