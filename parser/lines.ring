
# Whether a line runs right through a rectangle, from one side to the other. Touching it or
# stopping inside does not count: only a line that enters on one side and leaves by the
# opposite one is crossing.
Func iscrossingrect olineobj, orectobj 

	If olineobj.bhorizontal 
		If olineobj.ny1 <= orectobj.ny Or olineobj.ny1 >= orectobj.ny+orectobj.nh 
			Return false 
		Ok 
		If olineobj.nx1 <= orectobj.nx And olineobj.nx2 >= orectobj.nx+orectobj.nw 
			Return true 
		Ok 
	Else 
		If olineobj.nx1 <= orectobj.nx Or olineobj.nx1 >= orectobj.nx+orectobj.nw 
			Return false 
		Ok 
		If olineobj.ny1 <= orectobj.ny And olineobj.ny2 >= orectobj.ny+orectobj.nh 
			Return true 
		Ok 
	Ok 
	Return false 
	
# The independent lines of the drawing: the segments merged into the longest runs they form,
# minus those that turned out to be sides of a rectangle.
#
# A line that crosses a rectangle deletes it. That is how a drawing splits a frame in two by
# striking through it, and it is also the rule that surprises: a perforation drawn from edge
# to edge of the outer frame removes the outer frame. Stopping one cell short of each side
# keeps both.
Func findlines asegmentspool, arectangleslist 

	arectsideslistfound = []
	For orectitem In arectangleslist 
		arectsideslistfound+sidekey(true, orectitem.ny, orectitem.nx, orectitem.nx+orectitem.nw)
		arectsideslistfound+sidekey(true, orectitem.ny+orectitem.nh, orectitem.nx, orectitem.nx+orectitem.nw)
		arectsideslistfound+sidekey(false, orectitem.nx, orectitem.ny, orectitem.ny+orectitem.nh)
		arectsideslistfound+sidekey(false, orectitem.nx+orectitem.nw, orectitem.ny, orectitem.ny+orectitem.nh)
	Next 
	alineslistfound = []
	aendslistfound = []
	mergeoneway(asegmentspool, true, arectangleslist, arectsideslistfound, alineslistfound, aendslistfound)
	mergeoneway(asegmentspool, false, arectangleslist, arectsideslistfound, alineslistfound, aendslistfound)
	Return [alineslistfound, aendslistfound]
	
# One axis of that search: the runs of this axis merged into the longest stretches they form,
# each one measured against the rectangles and against their sides.
#
# The two axes are the same walk with the coordinates exchanged, so the merge is done on a pair
# of numbers - the line ACROSS the axis, which every run of one stretch shares, and its two ends
# ALONG it - and only the reading of a segment and the writing of a line know which coordinate
# is which. A run is merged into the stretch when it lies on the same across and its ends touch
# or overlap; the stretch grows until no run in the pool reaches it any more.
Func mergeoneway asegmentspool, bhorizontal, arectangleslist, arectsideslist, alineslistfound, aendslistfound 

	apool = []
	For osegitem In asegmentspool 
		If osegitem.bhorizontal != bhorizontal Loop Ok 
		If bhorizontal 
			apool+[osegitem.ny1, osegitem.nx1, osegitem.nx2]
		Else 
			apool+[osegitem.nx1, osegitem.ny1, osegitem.ny2]
		Ok 
	Next 
	While len(apool) > 0
		amerged = apool[1]
		del(apool, 1)
		bhaschangedflag = true 
		While bhaschangedflag 
			bhaschangedflag = false 
			anewpool = []
			For arun In apool 
				If arun[1] != amerged[1] Or arun[2] > amerged[3] Or arun[3] < amerged[2]
					anewpool+arun 
					Loop 
				Ok 
				If arun[2] < amerged[2] amerged[2] = arun[2] Ok 
				If arun[3] > amerged[3] amerged[3] = arun[3] Ok 
				bhaschangedflag = true 
			Next 
			apool = anewpool 
		End 
		odetectedline = New linedetect 
		odetectedline.bhorizontal = bhorizontal 
		If bhorizontal 
			odetectedline.ny1 = amerged[1] odetectedline.nx1 = amerged[2]
			odetectedline.ny2 = amerged[1] odetectedline.nx2 = amerged[3]
		Else 
			odetectedline.nx1 = amerged[1] odetectedline.ny1 = amerged[2]
			odetectedline.nx2 = amerged[1] odetectedline.ny2 = amerged[3]
		Ok 
		nidxval = 1
		While nidxval <= len(arectangleslist)
			If iscrossingrect(odetectedline, arectangleslist[nidxval])
				del(arectangleslist, nidxval)
			Else 
				nidxval++
			Ok 
		End 
		If find(arectsideslist, sidekey(bhorizontal, amerged[1], amerged[2], amerged[3])) = 0
			alineslistfound+odetectedline 
			If bhorizontal 
				aendslistfound+(string(amerged[1])+","+string(amerged[2]))
				aendslistfound+(string(amerged[1])+","+string(amerged[3]))
			Else 
				aendslistfound+(string(amerged[2])+","+string(amerged[1]))
				aendslistfound+(string(amerged[3])+","+string(amerged[1]))
			Ok 
		Ok 
	End 
	