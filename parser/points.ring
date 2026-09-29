
# The '+' that are decoration rather than structure: what is left once the corners of the
# rectangles and the ends of the lines have been taken away. A '+' with a neighbour on all
# four sides is dropped as well: that is a crossing inside the drawing, not a mark.
Func findpoints ogrid, acorners, aends 

	apointsfound = []
	For y = 1 To ogrid.height()
		For x = 1 To ogrid.width()
			If Not ogrid.isplus(y, x) Loop Ok 
			cposstr = string(y)+","+string(x)
			If find(acorners, cposstr) > 0 Loop Ok 
			If find(aends, cposstr) > 0 Loop Ok 
			bhasleft = (x > 1) And (ogrid.char(y, x-1) = "-" Or ogrid.char(y, x-1) = "+")
			bhasright = (x < ogrid.width()) And (ogrid.char(y, x+1) = "-" Or ogrid.char(y, x+1) = "+")
			bhasup = (y > 1) And (ogrid.char(y-1, x) = "|" Or ogrid.char(y-1, x) = "+")
			bhasdown = (y < ogrid.height()) And (ogrid.char(y+1, x) = "|" Or ogrid.char(y+1, x) = "+")
			If bhasleft And bhasright And bhasup And bhasdown Loop Ok 
			op = New pointdetect 
			op.ny = y op.nx = x 
			apointsfound+op 
		Next 
	Next 
	Return apointsfound 
	