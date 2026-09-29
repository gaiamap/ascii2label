# The canvas the layout analysis works on: the ASCII drawing cropped to the smallest
# rectangle that holds every '+'. Anything outside that box is ignored, so a template may be
# indented, commented and surrounded by blank space without any of it counting. Coordinates
# everywhere in the pipeline are cells of this grid, 1-based, with (1,1) at its top left.

# The cropped drawing, its width and its height, in cells.
Class grid 

	alines = []
	nwidth = 0
	nheight = 0
	
# Finds every '+' in the raw lines, takes the bounding box of them all and keeps only that
# region. A drawing with no '+' leaves an empty grid rather than an error: there is no layout
# to analyse, and the caller reports that nothing was found.
	Func Init alayout 

		apoints = []
		For y = 1 To len(alayout)
			cline = alayout[y]
			For x = 1 To len(cline)
				If cline[x] = "+"
					apoints+[y, x]
				Ok 
			Next 
		Next 
		If len(apoints) = 0
			alines = []
			nwidth = 0
			nheight = 0
			Return 
		Ok 
		miny = apoints[1][1]
		maxy = apoints[1][1]
		minx = apoints[1][2]
		maxx = apoints[1][2]
		For i = 2 To len(apoints)
			py = apoints[i][1]
			px = apoints[i][2]
			If py < miny miny = py Ok 
			If py > maxy maxy = py Ok 
			If px < minx minx = px Ok 
			If px > maxx maxx = px Ok 
		Next 
		nheight = maxy-miny+1
		nwidth = maxx-minx+1
		alines = list(nheight)
		For i = 1 To nheight 
			origy = miny+i-1
			If origy > len(alayout)
				alines[i] = ""
				Loop 
			Ok 
			corigline = alayout[origy]
			If minx <= len(corigline)
				nend = maxx 
				If nend > len(corigline)
					nend = len(corigline)
				Ok 
				alines[i] = substr(corigline, minx, nend-minx+1)
			Else 
				alines[i] = ""
			Ok 
		Next 
		
# How many cells tall the cropped drawing is.
	Func height 

		Return nheight 
		
# How many cells wide it is.
	Func width 

		Return nwidth 
# The character at a cell, or a space. Reading outside the grid is not an error: the
# detection walks off the edges constantly, and a blank is the right answer there.
	Func char y, x 

		If y < 1 Or y > nheight 
			Return ""
		Ok 
		If x < 1 Or x > nwidth 
			Return ""
		Ok 
		cline = alines[y]
		If x <= len(cline)
			Return cline[x]
		Ok 
		Return " "
		
# Whether that cell holds a '+', which is the only character with structural meaning.
	Func isplus y, x 

		Return char(y, x) = "+"