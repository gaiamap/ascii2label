# Every straight run between two '+' in the drawing, horizontal first and then vertical.
# From each '+' the scan walks right, and then down, for as long as the characters continue
# the line, and records a segment at every further '+' it meets: a row of three '+' gives
# three segments, not one. The rectangle search needs every pair of corners, including the
# pairs nested inside a longer run.
Func scansegments ogrid 

	asegmentsfound = []
	scanoneway(ogrid, true, "-", asegmentsfound)
	scanoneway(ogrid, false, "|", asegmentsfound)
	Return asegmentsfound 
	
# One direction of the scan. The walk is the same either way - stand on a '+', step along the
# line while the character continues it, and record a segment at every '+' met - so only the
# axis changes, and with it the character that continues a run.
Func scanoneway ogrid, bhorizontal, ccontinues, asegmentsfound 

	For y = 1 To ogrid.height()
		For x = 1 To ogrid.width()
			If Not ogrid.isplus(y, x) Loop Ok 
			nfrom = y 
			nto = ogrid.height()
			If bhorizontal 
				nfrom = x 
				nto = ogrid.width()
			Ok 
			For n = nfrom+1 To nto 
				nendy = n 
				nendx = x 
				If bhorizontal 
					nendy = y 
					nendx = n 
				Ok 
				ccharval = ogrid.char(nendy, nendx)
				If ccharval != ccontinues And ccharval != "+" Exit Ok 
				If ccharval = "+"
					oseg = New segmentdetect 
					oseg.bhorizontal = bhorizontal 
					oseg.ny1 = y oseg.nx1 = x 
					oseg.ny2 = nendy oseg.nx2 = nendx 
					asegmentsfound+oseg 
				Ok 
			Next 
		Next 
	Next 
	