# The shared vocabulary of the pipeline: the parser fills these in, the renderers read them,
# and nothing else passes between the two. With the types here rather than on either side, a
# second renderer can be added without touching the parser.

# The [0] section of the template: the size of one character cell in pixels, which is what
# turns the ASCII grid into a drawing, plus the defaults every block inherits. These are the
# values used when the template says nothing.
Class globalconfig 

	char_width = 10
	char_height = 20
	stroke_point = 3
	stroke_line = 2
	stroke_frame = 1
	# Two keys and not one, because the two families round differently and neither inherits
	# from the other: radius_box is the corner radius of every box, radius_mark the rounding
	# of the lines and the points, which have no section of their own to be addressed in.
	radius_box = 0
	radius_mark = 0
	# Both outputs are optional and independent. The page is the usual one and is on by
	# default; the standalone files are off.
	html_output = 1
	# How much of the printed page the label takes, as a percentage. 100 fills it; a smaller
	# number leaves a border all round, the label staying centred and in proportion.
	page_fill = 100
	svg_output = 0
	# The base name of what the run writes: <out_name>.html and <out_name>_001.svg onwards.
	out_name = "labels"
	csv_file = ""
	text_file = ""
	# The label the paper is cut to, in millimetres, and the only thing here that is not used to
	# draw: it never reaches the page, and the browser is told nothing about it. It is what turns
	# the print report from a condition the reader has to check into a figure and a verdict.
	# Left empty the report keeps the condition, which needs nothing declared.
	media = ""
	font = ""
	# Zero here means no ceiling, and that is deliberate. font_size is a ceiling, not a size:
	# the body of a text grows to fill its box, and a number written here would cap every text
	# of every label that does not set its own, switching the growing off everywhere. A ceiling
	# for one job belongs in that job's template, in [0], where it can be seen.
	font_size = 0
	align = "left"
	fg_color = "#000000"
	bg_color = "#FFFFFF"
	# Written as one of the words the configuration accepts, and not as the letter the
	# generator wants: a default that the reader of the key cannot recognise is a default
	# that never arrives.
	qr_correction = "medium"
	quiet_zone = 1
	
# A [1]..[9] section: what one numbered box holds and how it is drawn. The empty string, the
# zero and the -1 all mean 'not set', and are replaced by the global default once the whole
# configuration has been read. Which of the three a key uses is not a matter of taste: a key
# whose zero is a value of its own needs another mark for 'not set', or the two become the same
# sentence. That is why radius and quiet_zone start at -1 - square corners and no quiet zone are
# legitimate requests - while a body of zero pixels is not, so font_size can use the zero. And
# why align starts empty rather than at 'left': a key that holds its own default cannot be told
# apart from one the template wrote, and what the general section says would never reach a box.
#
# font_size is a ceiling, not a size: the body of the text is chosen to fill the box, and this
# is as large as it may get. Not written at all means no ceiling.
Class blockconfig 

	type = "text"
	font = ""
	font_size = 0
	align = ""
	fg_color = ""
	bg_color = ""
	stroke = 1
	radius = -1
	format = ""
	caption = ""
	qr_correction = ""
	quiet_zone = -1
	
# One element found in the drawing, in character cells and not pixels: a rectangle has a
# width and a height, a line has one of the two, a point has neither. The id is the digit
# written inside a rectangle; 0 means an anonymous frame - a border, or a place for the free
# text.
Class block 

	id = 0
	x = 0
	y = 0
	w = 0
	h = 0
	config = New blockconfig 
	
# A marker with no size, kept as its own type for the renderers that draw it.
Class point 

	x = 0
	y = 0
	
# A segment between two points of the grid, kept as its own type for the same reason.
Class line 

	x1 = 0
	y1 = 0
	x2 = 0
	y2 = 0
	
# Everything the template said, in one object: the global configuration and the elements
# found. It is the only thing that crosses from the parser to the renderer.
Class model 

	config = New globalconfig 
	blocks = []
	lines = []
	points = []
	
# The types below belong to the detection, not to the result: they hold the raw coordinates
# while the analysis runs, and become blocks once it is done.
# A run of '-' or '|' between two '+', horizontal or vertical.
Class segmentdetect 

	bhorizontal = true 
	ny1 = 0 nx1 = 0
	ny2 = 0 nx2 = 0
	
# Four segments that close a box, with the digit found inside it.
Class rectangledetect 

	nx = 0 ny = 0
	nw = 0 nh = 0
	nid = 0
	
# A '+' that turned out to be neither a corner nor an end.
Class pointdetect 

	ny = 0 nx = 0
	
# Segments of the same row or column merged into the longest run they form.
Class linedetect 

	bhorizontal = true 
	ny1 = 0 nx1 = 0
	ny2 = 0 nx2 = 0
	