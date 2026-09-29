# The HTML back end: one page holding every label, each as an inline SVG, one label per printed
# page.
#
# On screen a label is shown at the size the drawing works out to, in millimetres. On paper it
# is given the whole page instead, whatever page the printer offers, and the drawing scales
# into it keeping its proportions. That is why no page size is declared: a size the driver does
# not have is a size it reinterprets, and the three main browsers reinterpret it in three
# different ways - one rotates and shrinks, one clips and adds pages, one scales by a figure of
# its own. Asking for nothing but the page it is given, the label comes out the same everywhere,
# and the scale control in the print dialog has nothing left to do.

# The page being built: its size, the fonts to embed, and the labels collected so far.
Class htmloutput 

	clabels = ""
	nlabelw = 0
	nlabelh = 0
	nfill = 100
	afonts = []
	anotices = []
	
# Starts an empty page for labels of this pixel size, to be printed at this percentage of the
# page. Anything outside 1..100 is read as the whole page.
	Func Init nw, nh, npercent 

		nlabelw = nw 
		nlabelh = nh 
		nfill = npercent 
		If nfill < 1 Or nfill > 100 nfill = 100 Ok 
		clabels = ""
		afonts = []
		anotices = []
		
# Embeds a font file in the page, so the browser draws the text with the same face the
# measurement was made with. Without this the page would fall back to whatever the machine
# happens to have, and the widths on screen would not be the widths that were computed.
#
# The format is passed in rather than worked out here: it depends on how the font file is
# built, quadratic outlines in a .ttf and cubic ones in a .otf, and this object writes markup,
# it does not read font files.
	Func registerfont cfontfamily, cfontpath, cfontformat 

		If cfontfamily = "" Or cfontpath = "" Return Ok 
		If cfontformat = "" cfontformat = "truetype" Ok 
		If find(afonts, cfontfamily, 1) > 0 Return Ok 
		afonts+[cfontfamily, cfontpath, cfontformat]
		
# A line the reader should see before printing: something the run already knows will come out
# wrong. It is shown on screen, above the labels, and never printed - a warning on paper would be
# a defect of its own.
	Func addnotice ctext 

		If ctext = "" Return Ok 
		add(anotices, ctext)
		
# Adds one finished drawing to the page.
	Func addlabel csvg 

		clabels += '<div class="label-page">'+nl 
		clabels += csvg 
		clabels += "</div>"+nl 
		
# Writes the page out: the embedded fonts, then every label in its own printable block.
	Func save cfilename 

		cmmw = formatfixed(pxtomm(nlabelw*100/nfill), 2)
		cmmh = formatfixed(pxtomm(nlabelh*100/nfill), 2)
		chtml = "<!DOCTYPE html>"+nl 
		# The page is in English because the project is. The language declared here is what a
		# screen reader and a hyphenator go by, so it has to say what the labels are in.
		chtml += '<html lang="en">'+nl 
		chtml += "<head>"+nl 
		chtml += '  <meta charset="UTF-8">'+nl 
		chtml += '  <meta name="viewport" content="width=device-width, initial-scale=1">'+nl 
		chtml += "  <title>Labels</title>"+nl 
		chtml += "  <style>"+nl 
		For afont In afonts 
			cfamily = afont[1]
			cpath = afont[2]
			chtml += "    @font-face {"+nl 
			chtml += '      font-family: "'+cfamily+'";'+nl 
			chtml += '      src: url("'+cpath+'") format("'+afont[3]+'");'+nl 
			chtml += "      font-weight: normal;"+nl 
			chtml += "      font-style: normal;"+nl 
			chtml += "    }"+nl 
		Next 
		chtml += "    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }"+nl 
		chtml += "    @page {"+nl 
		chtml += "      margin: 0;"+nl 
		chtml += "    }"+nl 
		chtml += "    body {"+nl 
		chtml += "      background: #d0d0d0;"+nl 
		chtml += "      font-family: Arial, Helvetica, sans-serif;"+nl 
		chtml += "    }"+nl 
		# The box is the PAGE the label will be given, not the label: at page_fill 80 it is a
		# quarter wider, and the drawing sits at 80% of it. So what the screen shows is what the
		# paper will show, with the label still at the size the drawing works out to.
		chtml += "    .label-page {"+nl 
		chtml += "      width: "+cmmw+"mm;"+nl 
		chtml += "      height: "+cmmh+"mm;"+nl 
		chtml += "      overflow: hidden;"+nl 
		chtml += "      background: white;"+nl 
		chtml += "      display: flex;"+nl 
		chtml += "      align-items: center;"+nl 
		chtml += "      justify-content: center;"+nl 
		chtml += "      page-break-after: always;"+nl 
		chtml += "      break-after: page;"+nl 
		chtml += "    }"+nl 
		chtml += "    .label-page:last-child {"+nl 
		chtml += "      page-break-after: auto;"+nl 
		chtml += "      break-after: auto;"+nl 
		chtml += "    }"+nl 
		# The '>' is the rule itself, not a nicety: a label carries other svg elements inside it
		# - the QR and the barcode are each a nested drawing with their own size - and a descendant
		# selector would stretch every one of them to the full label, which is how a code ends up
		# printed across the whole card and clipped at its edge.
		chtml += "    .label-page > svg {"+nl 
		chtml += "      display: block;"+nl 
		chtml += "      width: "+nfill+"%;"+nl 
		chtml += "      height: "+nfill+"%;"+nl 
		chtml += "    }"+nl 
		chtml += "    @media screen {"+nl 
		chtml += "      body {"+nl 
		chtml += "        display: flex;"+nl 
		chtml += "        flex-direction: column;"+nl 
		chtml += "        align-items: center;"+nl 
		chtml += "        gap: 28px;"+nl 
		chtml += "        padding: 28px;"+nl 
		chtml += "      }"+nl 
		chtml += "      .label-page {"+nl 
		chtml += "        box-shadow: 0 3px 14px rgba(0,0,0,0.30);"+nl 
		chtml += "      }"+nl 
		chtml += "    }"+nl 
		chtml += "    .notices {"+nl 
		chtml += "      width: 210mm;"+nl 
		chtml += "      max-width: 100%;"+nl 
		chtml += "      padding: 12px 16px;"+nl 
		chtml += "      background: #FFF8E1;"+nl 
		chtml += "      border: 1px solid #E0C060;"+nl 
		chtml += "      color: #3A3000;"+nl 
		chtml += "      font-size: 13px;"+nl 
		chtml += "      line-height: 1.5;"+nl 
		chtml += "    }"+nl 
		chtml += "    .notices b { display: block; margin-bottom: 4px; }"+nl 
		chtml += "    .notices div { margin-top: 3px; }"+nl 
		chtml += "    @media print {"+nl 
		chtml += "      .notices { display: none; }"+nl 
		chtml += "      @page { margin: 0; }"+nl 
		chtml += "      html, body { height: 100%; }"+nl 
		chtml += "      body { background: none; display: block; gap: 0; padding: 0; }"+nl 
		# The label takes the whole printed page here, and only here: on screen it keeps the
		# millimetres of the drawing, which is what makes the preview worth looking at.
		chtml += "      .label-page { width: 100%; height: 100vh; }"+nl 
		chtml += "    }"+nl 
		chtml += "  </style>"+nl 
		chtml += "</head>"+nl 
		chtml += "<body>"+nl 
		chtml += nl 
		If len(anotices) > 0
			chtml += '<div class="notices">'+nl 
			chtml += "  <b>Before printing</b>"+nl 
			For cnotice In anotices 
				chtml += "  <div>"+escapemarkup(cnotice)+"</div>"+nl 
			Next 
			chtml += "</div>"+nl 
		Ok 
		chtml += clabels 
		chtml += "</body>"+nl 
		chtml += "</html>"+nl 
		write(cfilename, chtml)
		