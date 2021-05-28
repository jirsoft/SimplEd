# SimplEd
Simple font editor for CMM2 with basic mouse support.

#### v0.41
	Keys can now be defined in SimplEd.CFG file, when this file not exists, default keys are used
	(sample SimplEd.CFG file is provided, with comments inside, WIN is replaced with other keys)
	File has 2 sections:
	1. #help-texts, here is on-screen-help for skortcuts
	2. #shortcuts, here are the actuall keys
	Keys numbers for the section 2 can be found by running included Show_Keys.BAS
	
#### v0.40
	IMPORT from image doesn't erase font, so you can import new characters from different images into same font
	moving character cursor in image scanning is faster with SHIFT (10 pixels)
	some shortcuts are changed
	1. moving character LEFT/RIGHT/TOP/BOTTOM/CENTER is now with ALT
	2. WIN+SHIFT+F marks FIRST char in font (USED for preview and export)
	3. WIN+SHIFT+L marks LAST char in font (USED for preview and export)
	4. WIN+F jumps to FIRST char
	5. WIN+L jumps to LAST char
	6. all other keys jumps directly to this char!	

#### v0.38
	WIN+0 will find minimal WIDTH and HEIGHT for all characters from FIRST to LAST. It's useful after font scanning, so you can make the font size smaller. Becareful, the size is pure size (without margins). How to use it:
 	go through font and erase random points from scanning
 	get font size with WIN+0
 	put all chars to RIGHT TOP (ERASE MACRO, RECORD MACRO, R, T, PLAY MACRO to FONT)
 	adjust WIDTH and HEIGHT (WIDTH need to be multiplication of 4)
 	put all to the CENTER (ERASE MACRO, RECORD MACRO, C, PLAY MACRO to FONT)
 	go through font and with ALT+CRSR move chars to proper position if needed
	
#### v0.35
	CTRL-S will SWPA between current character and CLIP
	WIN+I can import also images - will be scanned into font

#### v0.33
	mouse support improvements (auto search for correct port, release on ond...)
	bugfix of the bottom row of characters
	included actual copy of TUI.INC
	UNDO extended to more operations
	
#### v0.30
	mouse support:
		1. in editor: LEFT button sets pixels, RIGHT button clears pixels (both also set cursor)
		2. in character set: LEFT button chooses character from set
		3. in CLIP: LEFT button copy active char to clipboard, RIGHT button from clipboard, MIDDLE button OR from clipboard  
	
#### v0.20
	some "SPECIAL" functions like rasterize and skew
	MACRO recording and play, you can prepare it on one char and play to complete font
	(for example copy char to clip, shift left, OR from clip, shift right = make char bolder horizontal)
	bugfixes
	removed TUI.INC, see description
	
#### v0.10
	preview
	TUI improvement
	keys change (standard clipboard)
	default export directory
	screenshot to SSxxx.BMP (full screen or dialog)

#### v0.03
	new functions
	
#### v0.02
	import from BAS, INC and FNT file

#### v0.01
	first public version
	
