
# Every closed box in the drawing, and the corners they occupy.
#
# A rectangle is a pair of horizontal segments with the same left and right ends, joined by
# two vertical segments at exactly those ends. The search runs over all pairs, so three
# horizontal lines on the same span give three rectangles and not two, and the extra one is
# drawn like any other frame.
#
# The id is the character just inside the top left corner, and only for a box bigger than one
# cell each way. A digit already taken by an earlier box does not count twice: the first
# rectangle found keeps it and the others become anonymous frames, so a duplicate digit turns
# a data box into a border without any message.
Func findrectangles ogrid, asegments 

	ahorizlist = []
	avertlist = []
	For i = 1 To len(asegments)
		osegitem = asegments[i]
		If osegitem.bhorizontal 
			ahorizlist+osegitem 
		Else 
			avertlist+osegitem 
		Ok 
	Next 
	ausedidlist = []
	arectanglesfound = []
	acornersfound = []
	For i = 1 To len(ahorizlist)
		otopline = ahorizlist[i]
		For j = 1 To len(ahorizlist)
			obottomline = ahorizlist[j]
			If obottomline.ny1 <= otopline.ny1 Loop Ok 
			If obottomline.nx1 != otopline.nx1 Or obottomline.nx2 != otopline.nx2 Loop Ok 
			bleftedge = false 
			brightedge = false 
			For k = 1 To len(avertlist)
				ov = avertlist[k]
				If ov.nx1 = otopline.nx1 And ov.ny1 = otopline.ny1 And ov.ny2 = obottomline.ny1 
					bleftedge = true 
				Ok 
				If ov.nx1 = otopline.nx2 And ov.ny1 = otopline.ny1 And ov.ny2 = obottomline.ny1 
					brightedge = true 
				Ok 
			Next 
			If Not (bleftedge And brightedge) Loop Ok 
			nrectxpos = otopline.nx1 
			nrectypos = otopline.ny1 
			nrectwidth = otopline.nx2-otopline.nx1 
			nrectheight = obottomline.ny1-otopline.ny1 
			nrawidvalue = 0
			If nrectwidth > 1 And nrectheight > 1
				cidcharval = ogrid.char(nrectypos+1, nrectxpos+1)
				If ascii(cidcharval) >= ascii("1") And ascii(cidcharval) <= ascii("9")
					nrawidvalue = number(cidcharval)
				Ok 
			Ok 
			nfinalid = 0
			If nrawidvalue > 0 And find(ausedidlist, nrawidvalue) = 0
				nfinalid = nrawidvalue 
				ausedidlist+nrawidvalue 
			Ok 
			orectobj = New rectangledetect 
			orectobj.nx = nrectxpos orectobj.ny = nrectypos 
			orectobj.nw = nrectwidth orectobj.nh = nrectheight 
			orectobj.nid = nfinalid 
			arectanglesfound+orectobj 
			acornersfound+(string(nrectypos)+","+string(nrectxpos))
			acornersfound+(string(nrectypos)+","+string(nrectxpos+nrectwidth))
			acornersfound+(string(nrectypos+nrectheight)+","+string(nrectxpos))
			acornersfound+(string(nrectypos+nrectheight)+","+string(nrectxpos+nrectwidth))
		Next 
	Next 
	Return [arectanglesfound, acornersfound]
	
# A name for one side of a rectangle, written so that the two ends always appear in the same
# order. The line search uses it to tell a segment it has just merged from an independent
# line lying on top of a box side.
Func sidekey bishoriz, nposa, nposb, nposc 

	If bishoriz 
		If nposb < nposc Return "H "+string(nposa)+" "+string(nposb)+" "+string(nposc) Ok 
		Return "H "+string(nposa)+" "+string(nposc)+" "+string(nposb)
	Ok 
	If nposb < nposc Return "V "+string(nposa)+" "+string(nposb)+" "+string(nposc) Ok 
	Return "V "+string(nposa)+" "+string(nposc)+" "+string(nposb)
	