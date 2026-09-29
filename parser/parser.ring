# From the template file to the model: the ASCII drawing becomes boxes, lines and points, and
# the INI section that follows it becomes the configuration they are drawn with. This file
# also reads the two data inputs, the CSV and the free-flowing text.
Load "stdlibcore.ring"
Load "scanner.ring"
Load "rectangles.ring"
Load "lines.ring"
Load "points.ring"

# Holds no state: every method takes what it needs and gives back what it made.
Class parser 

	
# Splits the file in two at the first line that opens with '[' - everything before it is the
# drawing, everything after is the configuration - then runs the layout analysis and applies
# the configuration to what it found. Blank lines and lines opening with '#' are dropped from
# the drawing but kept inside the configuration, where a '#' may be part of a colour.
	Func parsetemplate cfile 

		Return parsetemplatetext(read(cfile))
		
# The same, from the text of a template rather than from a file, so that a template held inside
# a program can be drawn by the same steps as one on disk.
	Func parsetemplatetext cfilecontent 

		aalllines = str2list(cfilecontent)
		alayoutlines = []
		aconfiglines = []
		binconfigmode = false 
		For i = 1 To len(aalllines)
			clinevalue = aalllines[i]
			ctrimmedline = trim(clinevalue)
			# A comment is dropped from the drawing, a blank line is not. The layout section is a
			# picture and an empty row is part of it: two boxes with a blank row between them are two
			# boxes, while dropping that row pushes them together, and two boxes sharing a span with
			# no gap make a third rectangle that is then drawn like any other frame. In the
			# configuration section nothing is dropped here: the reader of the keys skips what it
			# does not recognise.
			If left(ctrimmedline, 1) = "#" And Not binconfigmode 
				Loop 
			Ok 
			If left(ctrimmedline, 1) = "["
				binconfigmode = true 
			Ok 
			If binconfigmode 
				add(aconfiglines, clinevalue)
			Else 
				add(alayoutlines, clinevalue)
			Ok 
		Next 
		ogridobj = New grid 
		ogridobj. Init (alayoutlines)
		aextracteddata = extractlayout(ogridobj)
		ofinalmodel = aextracteddata[1]
		ofinalmodel.config = applyconfig(ofinalmodel.blocks, aconfiglines)
		Return [ofinalmodel, ogridobj]
		
# Runs the analysis in the order the rules require: the segments first, then the rectangles
# (which claim their corners), then the lines (which may delete a rectangle they cross), and
# last the points, which are whatever '+' nobody else claimed. Rectangles, lines and points
# all become blocks: a line is a block with one dimension at zero, a point one with both at
# zero, and that is how the renderer tells them apart.
	Func extractlayout ogrid 

		asegs = scansegments(ogrid)
		arectsdata = findrectangles(ogrid, asegs)
		arectslist = arectsdata[1]
		acornerslist = arectsdata[2]
		alinesdata = findlines(asegs, arectslist)
		alineslist = alinesdata[1]
		aendslist = alinesdata[2]
		apointslist = findpoints(ogrid, acornerslist, aendslist)
		omodelobj = New model 
		For orectitem In arectslist 
			oblock = New block 
			oblock.id = orectitem.nid 
			oblock.x = orectitem.nx 
			oblock.y = orectitem.ny 
			oblock.w = orectitem.nw 
			oblock.h = orectitem.nh 
			add(omodelobj.blocks, oblock)
		Next 
		For olineitem In alineslist 
			oblock = New block 
			oblock.id = 0
			oblock.x = olineitem.nx1 
			oblock.y = olineitem.ny1 
			If olineitem.bhorizontal 
				oblock.w = olineitem.nx2-olineitem.nx1 
				oblock.h = 0
			Else 
				oblock.w = 0
				oblock.h = olineitem.ny2-olineitem.ny1 
			Ok 
			add(omodelobj.blocks, oblock)
		Next 
		For opointitem In apointslist 
			oblock = New block 
			oblock.id = 0
			oblock.x = opointitem.nx 
			oblock.y = opointitem.ny 
			oblock.w = 0
			oblock.h = 0
			add(omodelobj.blocks, oblock)
		Next 
		Return [omodelobj, ogrid]
		
# Reads the INI section into the global configuration and into the numbered blocks, then
# fills every unset value from the global default, which is why a block may state only what
# it wants to change. Anonymous frames take the frame stroke rather than the block one, since
# they are borders and not fields.
	Func applyconfig ablocks, aconfiglines 

		oglobcfg = New globalconfig 
		ncurid = -1
		For i = 1 To len(aconfiglines)
			clinetxt = trim(aconfiglines[i])
			If len(clinetxt) = 0 Loop Ok 
			If left(clinetxt, 1) = "["
				cidpart = substr(clinetxt, 2, len(clinetxt)-2)
				ncurid = number(cidpart)
				Loop 
			Ok 
			nequalsidx = substr(clinetxt, "=")
			If nequalsidx = 0 Loop Ok 
			ckeyname = trim(left(clinetxt, nequalsidx-1))
			cvaluetxt = trim(substr(clinetxt, nequalsidx+1))
			If ncurid = 0
				If ckeyname = "char_width" oglobcfg.char_width = number(cvaluetxt)
				Elseif ckeyname = "char_height" oglobcfg.char_height = number(cvaluetxt)
				Elseif ckeyname = "stroke_point" oglobcfg.stroke_point = number(cvaluetxt)
				Elseif ckeyname = "stroke_line" oglobcfg.stroke_line = number(cvaluetxt)
				Elseif ckeyname = "stroke_frame" oglobcfg.stroke_frame = number(cvaluetxt)
				Elseif ckeyname = "radius_box" oglobcfg.radius_box = number(cvaluetxt)
				Elseif ckeyname = "radius_mark" oglobcfg.radius_mark = number(cvaluetxt)
				Elseif ckeyname = "html_output" oglobcfg.html_output = (cvaluetxt = "1")
				Elseif ckeyname = "page_fill" oglobcfg.page_fill = number(cvaluetxt)
				Elseif ckeyname = "svg_output" oglobcfg.svg_output = (cvaluetxt = "1")
				Elseif ckeyname = "out_name" oglobcfg.out_name = cvaluetxt 
				Elseif ckeyname = "csv_file" oglobcfg.csv_file = cvaluetxt 
				Elseif ckeyname = "text_file" oglobcfg.text_file = cvaluetxt 
				Elseif ckeyname = "media" oglobcfg.media = cvaluetxt 
				Elseif ckeyname = "font" oglobcfg.font = cvaluetxt 
				Elseif ckeyname = "font_size" oglobcfg.font_size = number(cvaluetxt)
				Elseif ckeyname = "align" oglobcfg.align = cvaluetxt 
				Elseif ckeyname = "fg_color" oglobcfg.fg_color = cvaluetxt 
				Elseif ckeyname = "bg_color" oglobcfg.bg_color = cvaluetxt 
				Elseif ckeyname = "qr_correction" oglobcfg.qr_correction = cvaluetxt 
				Elseif ckeyname = "quiet_zone" oglobcfg.quiet_zone = number(cvaluetxt)
				Ok 
				Loop 
			Ok 
			For ob In ablocks 
				If ob.id = ncurid 
					If ckeyname = "type" ob.config.type = cvaluetxt 
					Elseif ckeyname = "font" ob.config.font = cvaluetxt 
					Elseif ckeyname = "font_size" ob.config.font_size = number(cvaluetxt)
					Elseif ckeyname = "align" ob.config.align = cvaluetxt 
					Elseif ckeyname = "fg_color" ob.config.fg_color = cvaluetxt 
					Elseif ckeyname = "bg_color" ob.config.bg_color = cvaluetxt 
					Elseif ckeyname = "stroke" ob.config.stroke = number(cvaluetxt)
					Elseif ckeyname = "radius" ob.config.radius = number(cvaluetxt)
					Elseif ckeyname = "format" ob.config.format = cvaluetxt 
					Elseif ckeyname = "caption" ob.config.caption = cvaluetxt 
					Elseif ckeyname = "qr_correction" ob.config.qr_correction = cvaluetxt 
					Elseif ckeyname = "quiet_zone" ob.config.quiet_zone = number(cvaluetxt)
					Ok 
				Ok 
			Next 
		Next 
		For ob In ablocks 
			If ob.config.font = "" ob.config.font = oglobcfg.font Ok 
			If ob.config.font_size = 0 ob.config.font_size = oglobcfg.font_size Ok 
			If ob.config.align = "" ob.config.align = oglobcfg.align Ok 
			If ob.config.fg_color = "" ob.config.fg_color = oglobcfg.fg_color Ok 
			If ob.config.bg_color = "" ob.config.bg_color = oglobcfg.bg_color Ok 
			If ob.config.quiet_zone = -1 ob.config.quiet_zone = oglobcfg.quiet_zone Ok 
			If ob.config.qr_correction = "" ob.config.qr_correction = oglobcfg.qr_correction Ok 
			# The rounding is a default like the others and has to be applied here, or the global
			# keys would be read and then dropped. A box takes radius_box when it has not set its
			# own, and -1 is what 'not set' looks like: that is what leaves a written zero free to
			# mean zero, so one box can ask for square corners under a rounded default.
			#
			# A line and a point are not boxes and do not inherit from them: they take radius_mark,
			# which is theirs. They also have no section to be addressed in, so their own value is
			# always -1 and the key of the general section is the only thing that decides.
			If ob.w > 0 And ob.h > 0
				If ob.config.radius = -1 ob.config.radius = oglobcfg.radius_box Ok 
			Else 
				ob.config.radius = oglobcfg.radius_mark 
			Ok 
			If ob.w > 0 And ob.h > 0 And ob.id = 0
				ob.config.stroke = oglobcfg.stroke_frame 
			Ok 
		Next 
		Return oglobcfg 
		
# The data rows. The separator is settled once on the header line - comma, semicolon or tab,
# whichever cuts it into the most fields, with a tie going to the comma. The other two are then
# ordinary characters, so a file written with semicolons holds commas in its values. A missing
# file is not an error here - the caller decides what to do with no rows, and prints one empty
# label.
	Func readcsv cfile 

		If Not fexists(cfile) Return [] Ok 
		crawcontent = read(cfile)
		acontentlines = str2list(crawcontent)
		If len(acontentlines) = 0 Return [] Ok 
		acandidates = [",", ";", char(9)]
		cseparator = ","
		nbestcount = 1
		For ccandidate In acandidates 
			nfields = len(str2list(substr(acontentlines[1], ccandidate, nl)))
			If nfields > nbestcount 
				nbestcount = nfields 
				cseparator = ccandidate 
			Ok 
		Next 
		acsvrowslist = []
		For nline = 1 To len(acontentlines)
			add(acsvrowslist, str2list(substr(acontentlines[nline], cseparator, nl)))
		Next 
		Return acsvrowslist 
		
# The free-flowing text. An http or https address is accepted by the configuration but not
# fetched: this file reads from disk only, and a URL yields no text.
	Func readtextfile cpath 

		If left(cpath, 7) = "http://" Or left(cpath, 8) = "https://"
			Return ""
		Ok 
		If fexists(cpath) Return read(cpath) Ok 
		Return ""
		