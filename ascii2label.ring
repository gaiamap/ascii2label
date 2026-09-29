# ascii2label - the launcher.
#
# The program is main/main.ring, and this file starts it. It is here because of a rule of the
# language: in the main file of a Ring program a relative path in a Load is resolved from the
# folder the command was typed in, and not from the folder the file itself is in, and a Load
# that does not find its file is an error of compilation. The program loads four files of its
# own, so it has to be started from the folder it lives in: a start from anywhere else would
# end before one line of it could run, with nothing said but the compiler's own list.
#
# This file has no Load of its own to resolve, so it does get to run. It moves into the folder
# it is in, which it reads from its own name, and starts the program there. That folder is the
# one the program reads its template from and writes its labels to, so the tool works on the
# folder it lives in, wherever it is called from.
Load "stdlibcore.ring"

Func Main 

	cowndir = justfilepath(filename())
	If cowndir != "" chdir(cowndir) Ok 
	# The same interpreter that is running this file, not a "ring" that has to be on the PATH:
	# exefilename() gives its full path. The path is quoted because it may contain spaces, and
	# on Windows the whole line is wrapped in one more pair, because cmd /c eats the first and
	# the last quote.
	ccommand = char(34)+exefilename()+char(34)+" main/main.ring"
	If iswindows()
		system(char(34)+ccommand+char(34))
	Else 
		system(ccommand)
	Ok 
