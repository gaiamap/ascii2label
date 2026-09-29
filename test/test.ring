Load "stdlibcore.ring"

Func Main 

	# The runner drives the tool, so it works in the tool's folder - and it finds that folder
	# from its own name, not from the folder the command was typed in, so it can be started from
	# anywhere. Its own folder is test, which sits beside the tool, so the tool's folder is the
	# one above its own.
	cowndir = justfilepath(filename())
	If cowndir != "" chdir(cowndir) Ok 
	chdir("..")
	croot = currentdir()
	ctestdir = croot+"/test"
	If ! direxists(ctestdir)
		See "Error: test.ring has to stay in the test folder, beside the tool."+nl 
		Return 
	Ok 
	alist = dir(ctestdir)
	For aentry In alist 
		cname = aentry[1]
		bisdir = aentry[2]
		If bisdir And cname != "." And cname != ".."
			runtest(cname, croot, ctestdir)
		Ok 
	Next 
	See "Tests execution finished."+nl 
	
Func runtest cscenario, croot, ctestdir 

	See "Processing scenario: "+cscenario+nl 
	cscenariopath = ctestdir+"/"+cscenario 
	aresultsext = [".exe", ".log", ".svg", ".html"]
	See "  Creating links for inputs..."+nl 
	afiles = dir(cscenariopath)
	alinkedfiles = []
	For afile In afiles 
		cfilename = afile[1]
		bisdir = afile[2]
		If ! bisdir 
			bisresult = false 
			For cext In aresultsext 
				If hasextension(cfilename, cext)
					bisresult = true 
					Exit 
				Ok 
			Next 
			If ! bisresult 
				ctarget = cscenariopath+"/"+cfilename 
				clink = croot+"/"+cfilename 
				# A leftover from an earlier attempt is not harmless: the link would still point at the
				# other scenario, and every label from here on would be drawn from the wrong template
				# with nothing said. On a file system that refuses deletion that is exactly what
				# happens, so the runner stops here instead.
				If fexists(clink)
					See "  Error: "+cfilename+" is already in the working directory - "+
					"an earlier attempt could not clean up after itself. Remove it by hand and try again."+nl 
					cleanuplinks(alinkedfiles, croot)
					Return 
				Ok 
				If iswindows()
					cwinlink = substr(clink, "/", "\")
					cwintarget = substr(ctarget, "/", "\")
					system("cmd /c mklink /H "+'"'+cwinlink+'" "'+cwintarget+'" >nul 2>&1')
				Else 
					system("ln -s "+'"'+ctarget+'" "'+clink+'"')
				Ok 
				If fexists(clink)
					add(alinkedfiles, cfilename)
				Else 
					See "  Error: Failed to create link for "+cfilename+nl 
					cleanuplinks(alinkedfiles, croot)
					Return 
				Ok 
			Ok 
		Ok 
	Next 
	See "  Executing ascii2label.ring..."+nl 
	# The same interpreter that is running this runner, not a "ring" that has to be on the
	# PATH: exefilename() gives its full path. The path is quoted because it may contain
	# spaces, and on Windows the whole line is wrapped in one more pair, because cmd /c eats
	# the first and the last quote.
	ccommand = char(34)+exefilename()+char(34)+" ascii2label.ring"
	If iswindows()
		system(char(34)+ccommand+char(34))
	Else 
		system(ccommand)
	Ok 
	See "  Moving results to scenario directory..."+nl 
	arootfiles = dir(croot)
	For arootfile In arootfiles 
		crootfilename = arootfile[1]
		bisdir = arootfile[2]
		If ! bisdir 
			bisresult = false 
			For cext In aresultsext 
				If hasextension(crootfilename, cext)
					bisresult = true 
					Exit 
				Ok 
			Next 
			If bisresult 
				csrc = croot+"/"+crootfilename 
				cdest = cscenariopath+"/"+crootfilename 
				If iswindows()
					system("move /Y "+'"'+substr(csrc, "/", "\")+'" "'+substr(cdest, "/", "\")+'" >nul 2>&1')
				Else 
					system("mv "+'"'+csrc+'" "'+cdest+'"')
				Ok 
			Ok 
		Ok 
	Next 
	See "  Cleaning up links..."+nl 
	cleanuplinks(alinkedfiles, croot)
	
Func cleanuplinks alinkedfiles, croot 

	For clinkedfile In alinkedfiles 
		clinkpath = croot+"/"+clinkedfile 
		If iswindows()
			system("del "+'"'+substr(clinkpath, "/", "\")+'" >nul 2>&1')
		Else 
			remove(clinkpath)
		Ok 
		# Deletion can be refused - a read-only share, a mount without the right. Saying so
		# turns the next attempt's wrong drawing into a message the user can act on.
		If fexists(clinkpath)
			See "  Warning: "+clinkedfile+" could not be removed - remove it by hand before using the tool again."+nl 
		Ok 
	Next 
	
Func hasextension cfilename, cext 

	If len(cfilename) < len(cext) Return false Ok 
	Return right(lower(cfilename), len(cext)) = lower(cext)
	