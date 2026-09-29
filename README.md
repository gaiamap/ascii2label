# ascii2label

A label layout tool written in Ring. The layout is a drawing made of `+`, `-` and `|` in a
text file, followed by a short configuration block saying what each box contains. The tool
reads one row of a CSV per label and writes an HTML file holding them all, one label per
page, and/or one standalone SVG per label.

A label carries three kinds of content: texts, images, and machine-readable codes.
Each box of the drawing holds one of them, and text that belongs to no box in particular flows
through the room the boxes leave.

Every position comes from the character cells of the drawing: one cell to a character typed, and
the configuration says how many pixels wide and tall a cell is. Pixels appear in the
configuration only as sizes.

**Note:** This document contains ASCII art inside code blocks, which require a monospaced
font to render correctly.

---

## Install

```
ringpm install ascii2label
```

Requires **Ring 1.23** or later, and three packages - `ringqr`, `ringbc` and `ringfm`, the QR,
barcode and font-metric code - which RingPM installs together with this one.

---

## Running it

```
cd <folder holding the tool>
ring ascii2label.ring
```

Everything is resolved from the folder the tool is run in: `template.cfg` is read from there,
and every path in the configuration - the CSV, the free text, the images, a font file - is
relative to it. The tool reports what it did on screen and in `app.log`.

The configuration is a list of `key = value` lines grouped in sections: `[0]` for the label as a
whole, and `[1]` to `[9]` for the numbered boxes of the drawing. Every key this document names is
listed in Configuration, further down.

Requires the Ring interpreter, its standard library (`stdlibcore.ring`) and the three packages
named in Install, above, which hold the QR, barcode and font-metric code.

### Inputs

| File | Role |
|---|---|
| `template.cfg` | the ASCII drawing plus the configuration block. The name is fixed |
| `data.csv` | one row per label. Path from `csv_file`. Left out, the tool makes a single label with empty data |
| a text file | text that flows into the frames. Path from `text_file`; optional |

### Outputs

| File | When |
|---|---|
| `labels.html` | unless `html_output = 0`. One page per label |
| `labels_001.svg`, `labels_002.svg`, … | only when `svg_output = 1`. One file per label |
| `app.log` | always. Rewritten every time the tool is used |

The `labels` in those two names is what `out_name` says: the page is `<out_name>.html`, and the
standalone files start at `<out_name>_001.svg`.

Both outputs hold the same drawing; what differs is what each one needs beside it. The HTML page
points at the images and at the font files in the folder it was written in, so it needs that
folder. A standalone `.svg` tries to embed them as `data:` URIs, and needs nothing.
Not every font is embedded: see Fonts, below. Turning both outputs off writes neither, and the
log says so.

---

## Printing

Open the output file in a browser and print it: one label to a page, and the label is given the
whole page. Two keys of the template are about printing, `page_fill` and `media`, both in its
`[0]` section.

Nothing in the file names a paper size. What it does declare is a margin of zero, and each label
is a box that takes the full width and the full height of whatever page the browser hands it,
with the drawing fitted inside, centred and in proportion. The same file therefore prints one
label per page on A4, on A5 and on a 60 x 40 mm ribbon without being told which of them is in
the printer.

That zero margin is what leaves the print dialog nothing to change: the scale, "fit to printable
area" and the margins all work on room the label has already taken. A dialog that offers several
pages to a sheet puts that many labels on one, each still whole and in proportion.

The screen cannot show the paper. The page it draws has the proportions of the drawing,
and a sheet with other proportions adds white on one pair of sides - above and below a label
wider than it is tall, and to the left and the right of a taller one.

The `page_fill` key is for a label that should not reach the edges of the paper. At
`page_fill = 90` the label is printed at 90% of the page, centred, with white left all round. On
screen that border is drawn too: the label sits inside the page it asked for, at the size the
drawing works out to.

### The measurements are relative

Nothing a template says is a measurement on paper. Sizes are given in pixels - how wide one
character of the drawing stands for, how thick a line is drawn, how large a text is set - and
the label is then scaled to the page as one picture, so those numbers survive only as
proportions between the parts. A line two pixels thick inside a ten-pixel character is a line a
fifth of a character thick, on A4 and on a ribbon alike.

Two things survive the scaling, and the tool reports both. The shape of the
drawing is kept when the label is fitted to the paper, so it decides how much of that paper the
label can cover. And the thinnest bar of a barcode, or the smallest square of a QR code, keeps
its share of the label, so what it measures on the sheet depends on the label and the paper
alone.

### What the tool reports

The tool writes a block like this one, on screen and in `app.log`, every time it is used. This
is `test/scenario-1`:

```
--- Print size ---
  cell     10 x 20 px
  label    480 x 340 px, 127.00 x 89.96 mm at 96 dpi
  page     the label is printed across the whole of it
  codes    the narrowest module reaches 0.25 mm on paper 120.0 mm wide or wider
```

The word at the start of each line says what that line is about, and the four of them read like
this.

The `cell` line is the character cell of the drawing, at the size the template asked for. The
`label` line is the drawing in pixels, and what those pixels come to in millimetres at 96 dpi,
the resolution a browser assumes: the size the drawing works out to, and the size it prints at
only when the sheet happens to be that size.

The `page` line says how much of the paper the label takes: the whole of it, or the percentage the
`page_fill` key asked for.

The `codes` line is about the paper rather than the drawing, and it uses two words. A
machine-readable code is drawn with bars of a few set widths, or with little squares; the printed
code is called a symbol, and the smallest unit it is drawn with is called a module. The module is
the part a scanner has the most trouble with: it keeps its share of the label, so on the sheet it
comes out as small as the sheet makes it, and its width in millimetres there is what decides
whether the code can be read at all.

Where the template writes no `media` key, this line is a condition: the paper the label has to be
printed on for that module to reach a quarter of a millimetre. That width is the floor: below it a
scanner starts to have trouble. The tool takes the figure from the thinnest module anywhere in the
set of labels, so paper that suits it suits every one of them.

`media` is a key of the `[0]` section, and it names the paper: the label the paper is cut to, in
millimetres, written as `62x29`. It never reaches the page - the report reads it and nothing else
does, so the print dialog is left with exactly as little to do as before - and what it changes is
that the comparison is made here rather than left to the reader. A fifth line appears, carrying
the same name as the key. This is `test/scenario-3-badge` with `media = 62x29` added to its `[0]`
section:

```
  label    350 x 210 px, 92.60 x 55.56 mm at 96 dpi
  page     the label is printed across the whole of it
  media    62 x 29 mm, the label comes out 48.3 x 29.0 mm on it
  codes    narrowest module 0.262 mm on the media
```

The `media` line says one more thing. The label keeps its proportions, so a
drawing whose proportions are not the paper's comes out smaller than the paper on one side: the
A6 shipping label of `test/scenario-4-shipping` on that same roll prints 21.2 x 29.0 mm, using a
third of the width.

Under the floor, the `codes` line says what a code would want to reach it, in the two quantities
a template can check: the cells of room it would take against the cells it has, and the printed
width at which the module it already has would reach the floor. It gives no verdict, because
below the floor a code may still read: that depends on the printer and the scanner, and the tool
knows neither. This is `test/scenario-2-shelf`, which is printed at `page_fill = 80`, on the same
roll:

```
  codes    narrowest module 0.151 mm on the media
           under the 0.25 mm floor: below it, reading the code depends on the printer and the scanner. To reach it the symbol would want 22 cells of room in width where it has 20, or the label printed 56.3 mm wide instead of 33.9, or shorter data. page_fill back at 100 would give 0.188 mm, still under
```

The line does not say what the module would become after a change to the drawing. A wider box
makes a wider label, and a wider label fitted to the same paper is scaled down further, so a
code given more cells can come out with a narrower module than before. The `page_fill` key is the
exception, since it shrinks the label without touching the drawing: where it is set below 100 the
line says what putting it back at 100 would give. Where that figure reaches the floor, the line
offers it as one of the ways; where it does not, the line gives it after them.

Anything the tool has to say before the page goes to the printer - a value that did not fit its
box, a code that does not fit on the label - is repeated at the top of the page under **Before
printing**, and is left out of the print itself.

### Why a quarter of a millimetre

Two places agree on that figure. GS1, the body behind the barcode standards used in retail and
distribution, allows a module of 0.250 mm where a unit is too small to carry anything larger. And
a label printer of 203 dots per inch, which is a common enough resolution, lays two of its dots
in the same 0.250 mm - and two dots is about as thin as a bar can be printed and still come out
with clean edges.

It is a floor and not a promise. The same GS1 tables ask for twice as much on a parcel going
through general distribution; a printer with more dots to the inch can hold a thinner module; and
one kind of code, or one make of scanner, may want more than any of them. The figure is fixed and
there is no key for it. Every line gives the millimetres it measured instead, so anyone working
to a stricter figure can compare the two.

---

## The template

One file, two parts. The drawing comes first, and the configuration follows it, starting at
its first section heading. A line beginning with `#` is a comment.

### The drawing

Four characters carry meaning:

| Character | Meaning |
|---|---|
| `+` | corner, junction, or a point marker on its own |
| `-` | horizontal run between two `+` |
| `\|` | vertical run between two `+` |
| a digit `1`-`9` | written in the first cell inside a box, it gives that box its data column |

A run is an unbroken stretch of `-` or `|`, taken whole from its first `+` to its last.

The canvas is the smallest area that holds every `+`. Anything outside it is ignored, so
the drawing may be indented and surrounded by comments and blank lines without any of it
counting. Coordinates are cells of that canvas, counted from 1 at its top left.

**Rectangles.** Every closed box in the drawing is a rectangle, including the ones that appear
where other boxes meet. The first character inside the box is its id: a digit means the box takes
that column of the CSV, anything else makes it an anonymous frame - a border, or a place for the
free-flowing text. Two boxes cannot share a digit: the first of them takes the column and the
other is read as a frame.

**Lines.** A run that is not the side of a rectangle is a line.

**Points.** A `+` that is neither a corner nor the end of a line is a point marker, drawn as a
small square that `radius_mark` can round, up to a disc. A `+` with a neighbour on all four sides
is a crossing inside the drawing and is dropped.

Three rules decide what the drawing adds up to.

**Inclusion.** Shapes may contain one another. A shared side, or an
overlap, does not merge two of them: each is still read on its own.

**Junction.** Wherever two runs meet - at a corner, at a T, or crossing one another - the
character there is a `+`. A `-` or a `|` left in its place is not a junction, and the drawing
that gets read is a different one.

**Division.** A run that goes from one side of a rectangle to the opposite side deletes that
rectangle and leaves the parts it divides, and it does so even when the run is itself the side of
other rectangles. That is how a drawing splits a frame in two. Stopping one cell short of either
side leaves the frame whole.

**Examples.** Every count below is what the tool reports for that drawing.

The smallest shapes. Two `+` make a line, one on its own makes a point, and a `+` that ends up
inside a longer run becomes a point too:

```
   +              +---+          ++             +              +---           +-+-+
                                                +

   a point        a line         the shortest   the same       not a line:    a line and
                                 line           vertically     a point        a point
```

Rectangles, and what a divider does to the frame it meets:

```
   +---+          +--+--+        +--+--+        +--+--+
   |   |          |  |  |        |  |  |        |  |  |
   +---+          +--+--+        +--+  |        +-----+
                                 |     |
                                 +-----+

   one            two            two            one rectangle
   rectangle      rectangles:    rectangles:    and a point:
                  the divider    the divider    the divider
                  cuts the       closes a       reaches
                  frame in two   smaller one    no `+`
```

Rectangles that meet. A blank row between them keeps them apart, touching borders close a
third one, and a box laid across the side of another is cut by it:

```
   +---+          +---+            +---+
   |   |          |   |            |   |
   +---+          +---+          +-+-+ |
                  +---+          | | | |
   +---+          |   |          +-+-+ |
   |   |          +---+            |   |
   +---+                           +---+

   two            three            three
   rectangles     rectangles:      rectangles:
                  the meeting      the small box
                  borders          is cut in two
                  close a third    by the side
                                   it lies across
```

Junctions. The same picture twice: with `+` where the runs meet, and with `-` left in their
place:

```
    +---+          +---+
    |   |          |   |
   ++---++        +-----+
    |   |          |   |
    +---+          +---+

   two            three lines,
   rectangles     no rectangle
   and a line
```

Nesting, ids, and characters that join nothing:

```
   +-----+         +-----+         +-----+          +---+---+
   | +-+ |         | +-+ |         | - | |          |1  |2  |
   | | | |         |     |         | | | |          |   |   |
   | +-+ |         |  +  |         |     |          +---+---+
   +-----+         +-----+         +-----+

   two             one rectangle,  one rectangle:   two rectangles,
   rectangles      one line,       `-` and `|`      taking columns
                   one point       count only       1 and 2
                                   between two `+`
```

#### The coordinate system

The drawing is the layout. What a thing is, and where it goes, was decided when it was typed; the
configuration adds one thing only, how big a cell is - `char_width` by `char_height` pixels.

The number of cells and the size of a cell together decide the label's orientation: a drawing with
as many columns as rows comes out landscape when the cell is wider than it is tall, and portrait
when it is taller than it is wide. The `label` line of the report says what it comes to.

The count of cells decides how fine the placing can be, and how much of a box its content gets:
the inset that keeps a value off its border is one cell, so a box drawn two cells tall gives its
content half its height, and one drawn ten cells tall gives it nine tenths. The same holds for the
free-flowing text, which is laid one line to a cell row.

A size the configuration states in pixels does not follow the cell. The sizes the tool
chooses itself come from the box and grow with it, but a key that states a size in pixels -
a `stroke`, a `radius`, a `quiet_zone`, a written `font_size` - stays the number it was: halve the
cell and the same stroke comes out twice as heavy against the label.

The content of a numbered box does not get the whole box. Where a border is drawn, the
content is kept clear of it, which costs it one cell of width and one cell of height in all. A
thick border takes part of that clearance, and one thick enough reaches the content. Where no
border is drawn, and `stroke = 0` is how a box asks for that, the content takes the whole box. An
image therefore gets its full box.

Where a border is drawn, a text is the exception, and only up and down: it keeps the full height
of the box, and is inset at the sides alone.

### Configuration

`[0]` holds the defaults for the whole label. `[1]`-`[9]` describe one box each - the box
carrying that digit - and a key written there overrides the default for that box alone. A key
left out of a box keeps whatever `[0]` says.

#### `[0]` - the defaults

| Key | Meaning | Default |
|---|---|---|
| `char_width` | width of one character cell, in pixels | `10` |
| `char_height` | height of one character cell, in pixels | `20` |
| `stroke_frame` | line width of the frames - the boxes with no digit, the outer one included. `0` draws no line, which with a `bg_color` gives a coloured card with no border | `1` |
| `stroke_line` | line width of the independent lines | `2` |
| `stroke_point` | side of a point marker, in pixels | `3` |
| `radius_box` | corner radius of the boxes, in pixels, inherited by every box that does not set its own | `0` |
| `radius_mark` | how much the lines and the points are rounded, in pixels | `0` |
| `csv_file` | the data file. Omitted or empty: one label with empty data | *(none)* |
| `media` | the label the paper is cut to, as `62x29` in millimetres. Used by the print report and nowhere else | *(none)* |
| `out_name` | base name of what the tool writes | `labels` |
| `html_output` | `0` skips the HTML page | `1` |
| `page_fill` | how much of the printed page one label takes, in percent. Less than 100 leaves a border all round | `100` |
| `svg_output` | `1` writes one standalone `.svg` per label | `0` |
| `text_file` | file holding the free-flowing text | *(none)* |
| `font` | a family name (`Arial`, `Times`, `Courier`, `Helvetica`) or the path of a font file | *(the system default)* |
| `font_size` | the size asked for every text, in pixels. `0` lets each text fill its box | `0` |
| `align` | `left` \| `center` \| `right` | `left` |
| `fg_color` | the colour of the texts and of every line of the drawing, as `#RRGGBB` or a colour name | `#000000` |
| `bg_color` | background colour, as `#RRGGBB` or a colour name | `#FFFFFF` |
| `quiet_zone` | blank margin around a code symbol, in pixels | `1` |
| `qr_correction` | `low` \| `medium` \| `high` \| `highest` | `medium` |

`radius_box` rounds the corners of the boxes, `radius_mark` the lines and the points: the ends of
a line, and the corners of a point marker, which at half its side is a disc. Neither is honoured
beyond half the shorter side of the shape it is given, where the shape is already as round as it
gets.

Where the border is thick the corner comes out rounder than the number asks, because the rounding
follows the middle of the line: the outside of the stroke is rounded by half a stroke more than
the number, and the inside stays square until the number passes that half.

`font_size` left at `0` is what lets a text grow to fill its box. A number is the size asked for:
a text is set at it where the box has the room, comes out smaller where it has not, and stops
growing there. Written in `[0]` it is asked for every text of every label that does not set its
own. A caption - the raw string printed above or below a code - is chosen the same way, and
limited by the room the code needs.

#### `[1]`-`[9]` - one box, overriding the defaults

| Key | Meaning | If left out |
|---|---|---|
| `type` | `text` \| `image` \| `code` | `text` |
| `font` | face for this box | from `[0]` |
| `font_size` | the size asked for this box's text, or for its caption where `type = code` | from `[0]` |
| `align` | `left` \| `center` \| `right` | from `[0]` |
| `fg_color` | the colour of this box's text and of its border: one key for both | from `[0]` |
| `bg_color` | the colour behind them | from `[0]` |
| `stroke` | border width; `0` draws none, which is how a box carries a colour without an outline | `1` |
| `radius` | corner radius | from `radius_box` |
| `format` | for `type = code`: `ean13` \| `code128` \| `code128a` \| `code128b` \| `code128c` \| `qr` \| `AUTO` | `code128`, the set chosen from the data |
| `caption` | for `type = code`: `above` \| `below` prints the raw string | *(none)* |
| `quiet_zone` | blank margin for this symbol, in pixels | from `[0]` |
| `qr_correction` | for a QR: `low` \| `medium` \| `high` \| `highest` | from `[0]` |

Leaving a key out of a box, or leaving it empty, is how the box asks for the `[0]` value. Where
`0` is a value in its own right, though, writing it means it: `radius = 0` on a box asks for
square corners even under a rounded default, and `quiet_zone = 0` for no quiet zone at all. The
frames, the lines and the points have no section of their own, so for them what `[0]` says is
final.

`fg_color` is one key for two things, the text of a box and the border around it, so a box cannot
have one colour for its border and another for its text. A border in the colour of the paper
takes the text with it.

---

## The data file

One row per label. The tool works out the separator from the header row: it tries cutting that
row on a comma, on a semicolon and on a tab, and keeps whichever gives the most fields; where two
give the same, the first of the three wins. A file separated by semicolons can then hold commas
inside its values, which is what an address needs.

The first row is the header and is skipped. Every other row makes one label: column 1 goes to
the box carrying digit `1`, column 2 to digit `2`, and so on. A row with fewer columns than a
digit leaves that box empty.

Quotation marks are not part of the syntax. A value is taken as it stands, quotes included, so
it cannot hold the character its file is separated by.

| Box `type` | What the column holds |
|---|---|
| `text` | the text to set in the box |
| `image` | the path of an image file, or a URL; it is fitted inside the box without being stretched |
| `code` | the string to encode |

An image given as a URL is usually fetched by the browser that opens the page, and is not
embedded in a standalone `.svg`.

With no `csv_file`, or a file that is missing or holds only its header, the tool still writes one
label with empty data, and the log says so.

## The free-flowing text

`text_file` names a file whose content flows into the anonymous frames - the boxes with no
digit - in reading order, as many lines as each will hold, carrying on from one frame to the
next. The same text appears on every label of the set.

The outer frame of a label is an anonymous frame like the others, so the text fills the free
cells around the inner boxes as readily as those inside them. A text that has to stay in one
place belongs in a numbered box.

The value must be a local path. An `http://` or `https://` address is accepted but yields no
text: this tool reads from disk and does not fetch.

---

## Fonts

`font` takes either a family name or the path of a font file, and the two behave differently.

**A family name** - `arial`, `times`, `courier`, `helvetica` (or the open Liberation form of the
same face, drawn to the same letter widths) - is looked for in the font folders of Windows, macOS
and Linux. The measurement is then made on the file that was found, and is exact. On macOS
`helvetica` finds a collection, so what is measured there is the first face in it. If nothing is
found, the tool falls back to a built-in estimate and says so in the log.

**A path to a `.ttf`, `.otf` or `.ttc` file** is read directly, and it is the only form that gets
embedded: the HTML page declares it in an `@font-face` rule pointing at the file, and a
standalone `.svg` carries the file inside itself. A label set in that face keeps it on a
machine where the font was never installed. The family the page asks for is the one written
inside the file, so what the file is called does not matter. A collection - one file holding
several faces, `.ttc` - gives its first face, and there is no way to ask for another.

A family name is never embedded. The drawing asks for the name, and whichever machine opens
the file supplies what it has under that name - so a label measured here may be printed
elsewhere in another face.

One limit, even with an embedded file: some renderers outside a browser ignore `@font-face`
altogether and substitute the face regardless.

---

## How the size of a text is chosen

A template does not have to say how big a text should be. Leave `font_size` out and the tool
sets the text as large as the numbered box will take, much as it takes the position of that box
from the drawing rather than from the configuration. But `font_size`, where it is written, is
the size the text is set at: where a numbered box has too little room the tool reduces the size
until it fits, and in the free flow it is used as it stands.

The second half of the idea is that a label is rarely printed alone. The tool chooses the size
once for the whole set of labels and uses it on every one of them, so that a field is not set
large on one label and small on the next.

### Text in a numbered box

The tool tries sizes in the box and keeps the largest at which every row of that column still
fits. Two things cap the search: the height of the box, and `font_size` if it is written. Wrapping
comes before shrinking, so a value too long for one line becomes two lines before it becomes
smaller type.

An example. This drawing and this configuration:

```
+--------------------+
|1                   |
|                    |
+--------------------+

[1]
type = text
font_size = 24
```

with a column holding `Alpha`, `Beta Ltd` and `Highland Valley Trading Company Limited`,
prints all three labels at 18 px: the largest size at which the longest of the three still
fits its box. `Alpha` and `Beta Ltd` are set at 18 px as well, although on their own they
would have taken the full 24. The tool says which value decided, and why:

```
--- Text warnings ---
  block [1]: text size reduced from 24 to 18 px so the longest value fits
```

A text that fits its box at no size at all is drawn at 1 px, with its own line in the log,
rather than dropped without a word.

### Text in the free flow

The free-flowing text has no box of its own to fill: it runs through whatever cells the frames
leave empty. Nothing has to hold it, so a `font_size` written in `[0]` is used as it stands. Left
out, the cell decides, and gives the largest size one cell row can hold.

That is also why a size larger than the cell is allowed rather than cut back to fit: its lines
run into one another, and the passage carries on into the next frame instead of ending in the
first.

### The caption of a code

The tool chooses the caption of a code box as it chooses the body of a text: once for the whole
set of labels, and as large as the longest value of that column allows. Two things cap it. A
caption is one line and never wraps, so its width against the width of the box decides. And the
band it sits in comes out of the box before the code is fitted into what is left, so the band may
not take so much that the code has less than one cell.

In `test/scenario-1` box 3 asks for 16 px and is given it. Raised to 34 the same caption comes
out at 26 - the largest size at which the longest of the four values still fits between the
borders - and the tool says which value decided:

```
--- Code generator warnings ---
  CODE BOX [3]: caption size reduced from 34 to 26 px so the longest value fits its box.
```

Left out altogether it comes out at 26 as well, and nothing is said, because nothing was asked
for. A box with no room for the band gets no caption, and the line says so and how much taller to
make the box.

---

## Worked example

This is `test/scenario-1`, the first of the six templates in `test/`. Its `template.cfg`:

```
# Layout ASCII
+
 +--------------------------------------------+
 | +------------------+  +------------------+ |
 | |1                 |  |2                 | |
 | |                  |  |                  | |
 | |                  |  |                  | |
 | +------------------+  +------------------+ |
 |  +                                         |
 +--------------------------------------------+
 |                                            |
 | +----------------------------------------+ |
 | |3                                       | |
 | |                                        | |
 | |                                        | |
 | +----------------------------------------+ |
 +--------------------------------------------+
                  +-------+                    +

# Configuration

[0]
char_width = 10
char_height = 20
stroke_point = 10
stroke_line = 6
stroke_frame = 1
radius_box = 2
radius_mark = 2
html_output = 1
csv_file = data.csv
out_name = labels
svg_output = 1
text_file = fixed-text.txt
font = testfont.ttf
font_size = 26
align = left
fg_color = Black

[1]
type = text
font = Arial
font_size = 24
align = center
stroke = 2
radius = 8
bg_color = Yellow
fg_color = Red

[2]
type = image
stroke = 0

[3]
type = code
format = code128
caption = below
font = courier
font_size = 16
stroke = 4
radius = 18
quiet_zone = 2
```

With `data.csv`

```
title,logo,qr
Alpha Corp,logo_alpha.png,http://a.com
Beta Ltd,logo_beta.png,https://example.com/beta
Gamma Inc,logo_gamma.png,https://example.com/gamma
Delta Co,logo_delta.png,https://example.com/delta
```

and `fixed-text.txt`

```
The quick brown fox jumps over the lazy dog.
```

the tool writes `labels.html` and, because `svg_output = 1`, `labels_001.svg` to
`labels_004.svg`, one per data row.

The drawing gives five rectangles - the two frames and the three numbered boxes - one line, and
three `+` that nothing else claims, drawn as 10 px point markers, their corners and the ends of
the line rounded by `radius_mark`. Box 1 sets the `title` column
centred in Arial, red on yellow with rounded corners, at the 24 px it asks for. Box 2 fits the
logo with no border of its own. Box 3 encodes the third column as a Code 128 symbol with the
raw string printed below it in Courier. The two frames take the text of `fixed-text.txt`, which
runs across both of them.

The log reports what the label comes to on paper, and what its codes need from the printer.
Printing, above, works through the block line by line:

```
--- Print size ---
  cell     10 x 20 px
  label    480 x 340 px, 127.00 x 89.96 mm at 96 dpi
  page     the label is printed across the whole of it
  codes    the narrowest module reaches 0.25 mm on paper 120.0 mm wide or wider
```

---

## What is in the project

| Path | Holds |
|---|---|
| `ascii2label.ring` | starts the program |
| `main.ring` | what `ringpm run ascii2label` prints: where the tool is and how to start it |
| `main/main.ring` | runs the three steps in order: read the template, read the data, draw one label per row |
| `main/model.ring` | the vocabulary the two halves exchange, and the value every key has when the template says nothing |
| `parser/grid.ring` | holds the drawing and answers what character sits in a given cell |
| `parser/scanner.ring` | finds every straight run of `-` or `\|` between two `+` |
| `parser/rectangles.ring` | closes those runs into boxes and reads the digit inside each one |
| `parser/lines.ring` | keeps the runs that are no box's side, and applies the rule that a run across a box deletes it |
| `parser/points.ring` | keeps the `+` that neither a box nor a line has claimed |
| `parser/parser.ring` | splits the template in two, reads the configuration into the boxes, and reads the CSV and the text file |
| `render/render.ring` | works out how big the canvas and every text have to be, then draws one label per data row |
| `render/render_svg.ring` | draws the shapes: boxes, lines, points, text, images and code symbols |
| `render/render_html.ring` | writes the page that holds every label, one to a printed page |
| `render/render_textflow.ring` | fills the anonymous frames with the free-flowing text |
| `test/` | the six worked scenarios, and the runner that goes through them |

The three libraries - `ringqr`, `ringbc` and `ringfm` - are packages of their own, each with its
own command line and its own test; the renderer is one of their callers.

### The scenarios

`test/` holds six templates that between them exercise the whole surface - a poster-like sheet,
a shelf label, a conference badge, a shipping label, a food jar and an event ticket - with
captions above and below, all three alignments, colours in the foreground and the background,
rounded and square corners, frames and a card with no frame at all, and images in PNG, JPEG,
GIF and WEBP. The script `test.ring` runs them all one after the other and leaves each result
in its own folder.

The runner links each scenario's inputs into the project root, runs the tool there and then
removes the links. If a link from an earlier attempt is still in place it stops rather than
start.

---

## Third-party components

- **Ring standard library** (`stdlibcore.ring`), for `StringToBase64` and the usual helpers.
- **Dancing Script**, in `test/scenario-3-badge/`, used for the name on the badge. Copyright
  2010 Pablo Impallari and Igino Marini, under the SIL Open Font License 1.1; the licence text
  sits beside the font in `DancingScript-OFL.txt`.
- **Nunito**, in `test/scenario-1/` as `testfont.ttf`: the ExtraBold weight of the variable font,
  cut down to the Latin ranges and renamed, all of which the licence permits. Copyright 2014 The
  Nunito Project Authors, under the SIL Open Font License 1.1; the text sits beside the font in
  `testfont-OFL.txt`.

Everything else - the drawing, the parsers, the images in the scenarios
and the sample data - belongs to the project. The sample texts are lorem ipsum, the addresses
are on `example.com` and `example.org`, which IANA reserves for documentation, and the images
were drawn for it.

## Licence

MIT - see `LICENSE`.
