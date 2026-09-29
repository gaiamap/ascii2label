aPackageInfo = [
	:name = "The ascii2label Package",
	:description = "Label layout tool written in Ring - an ASCII drawing and a CSV in, labels out as HTML and SVG; a possible use of ringqr, ringbc and ringfm",
	:folder = "ascii2label",
	:developer = "Gaiamap",
	:email = "",
	:license = "MIT License",
	:version = "1.0.0",
	:ringversion = "1.23",
	:versions = 	[
		[
			:version = "1.0.0",
			:branch = "master"
		]
	],
	:libs = 	[
		[
			:name = "ringqr",
			:version = "1.0.0",
			:providerusername = "gaiamap"
		],
		[
			:name = "ringbc",
			:version = "1.0.0",
			:providerusername = "gaiamap"
		],
		[
			:name = "ringfm",
			:version = "1.0.0",
			:providerusername = "gaiamap"
		]
	],
	:files = 	[
		"main.ring",
		"README.md",
		"LICENSE",
		"ascii2label.ring",
		"main/main.ring",
		"main/model.ring",
		"parser/grid.ring",
		"parser/lines.ring",
		"parser/parser.ring",
		"parser/points.ring",
		"parser/rectangles.ring",
		"parser/scanner.ring",
		"render/render.ring",
		"render/render_html.ring",
		"render/render_svg.ring",
		"render/render_textflow.ring",
		"test/scenario-1/data.csv",
		"test/scenario-1/fixed-text.txt",
		"test/scenario-1/logo_alpha.png",
		"test/scenario-1/logo_beta.png",
		"test/scenario-1/logo_delta.png",
		"test/scenario-1/logo_gamma.png",
		"test/scenario-1/template.cfg",
		"test/scenario-1/testfont-OFL.txt",
		"test/scenario-1/testfont.ttf",
		"test/scenario-2-shelf/data.csv",
		"test/scenario-2-shelf/mk_bag.jpg",
		"test/scenario-2-shelf/mk_bean.png",
		"test/scenario-2-shelf/mk_decaf.gif",
		"test/scenario-2-shelf/mk_pods.webp",
		"test/scenario-2-shelf/template.cfg",
		"test/scenario-3-badge/DancingScript-OFL.txt",
		"test/scenario-3-badge/DancingScript-Regular.otf",
		"test/scenario-3-badge/data.csv",
		"test/scenario-3-badge/mk_attendee.gif",
		"test/scenario-3-badge/mk_chair.png",
		"test/scenario-3-badge/mk_org.png",
		"test/scenario-3-badge/mk_speaker.webp",
		"test/scenario-3-badge/template.cfg",
		"test/scenario-4-shipping/data.csv",
		"test/scenario-4-shipping/mk_express.jpg",
		"test/scenario-4-shipping/mk_fragile.gif",
		"test/scenario-4-shipping/mk_parcel.png",
		"test/scenario-4-shipping/template.cfg",
		"test/scenario-5-jar/data.csv",
		"test/scenario-5-jar/fixed-text.txt",
		"test/scenario-5-jar/mk_bee.gif",
		"test/scenario-5-jar/mk_honey.png",
		"test/scenario-5-jar/mk_leaf.webp",
		"test/scenario-5-jar/template.cfg",
		"test/scenario-6-ticket/data.csv",
		"test/scenario-6-ticket/mk_star.jpg",
		"test/scenario-6-ticket/mk_stub.png",
		"test/scenario-6-ticket/template.cfg",
		"test/test.ring"
	],
	:ringfolderfiles = 	[

	],
	:windowsfiles = 	[

	],
	:linuxfiles = 	[

	],
	:ubuntufiles = 	[

	],
	:fedorafiles = 	[

	],
	:freebsdfiles = 	[

	],
	:macosfiles = 	[

	],
	:windowsringfolderfiles = 	[

	],
	:linuxringfolderfiles = 	[

	],
	:ubunturingfolderfiles = 	[

	],
	:fedoraringfolderfiles = 	[

	],
	:freebsdringfolderfiles = 	[

	],
	:macosringfolderfiles = 	[

	],
	:run = "ring main.ring",
	:windowsrun = "",
	:linuxrun = "",
	:macosrun = "",
	:ubunturun = "",
	:fedorarun = "",
	:setup = "",
	:windowssetup = "",
	:linuxsetup = "",
	:macossetup = "",
	:ubuntusetup = "",
	:fedorasetup = "",
	:remove = "",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = ""
]
