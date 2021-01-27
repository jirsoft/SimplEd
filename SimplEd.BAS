'#MMDEBUG ON
'#DEFINE "DBG ", ""
#DEFINE "DBG ", "'"

OPTION DEFAULT NONE
OPTION EXPLICIT
OPTION BASE 0

OPTION BREAK 0
DBG OPTION BREAK 3

'SimpleEd
CONST VERSION.SE = "0.32"

CONST ZERO.SE = CHR$(0)
DIM STRING CWD.SE = MM.INFO$(PATH)
CHDIR CWD.SE
DIM STRING LAST.SE = "NewFont", EXPORT.SE = CWD.SE + "SE_EXPORTED"
DIM INTEGER T_TIME.SE = 0, C_TIME.SE = 0

'#INCLUDE "TUI.INC"
#INCLUDE "../LIB/TUI.INC"

CONST NAME_CHARS.SE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_!@#%^&*-+()[]"

CONST MINH.SE = 4, MAXH.SE = 64
CONST MINW.SE = 4, MAXW.SE = 64

CONST MINC.SE = 32, MAXC.SE = 255

DIM INTEGER BEGIN.SE = MINC.SE, END.SE = MAXC.SE
DIM INTEGER CMIN.SE = MINC.SE, CMAX.SE = MINC.SE

DIM INTEGER W.SE = 8, H.SE = 8
DIM INTEGER CW.SE = W.SE * (MM.HRES \ W.SE), CD.SE = (MM.HRES - CW.SE) \ 2

DIM STRING COL.SE, ROW.SE
DIM INTEGER LIMIT.SE = 0
DIM INTEGER CHAR.SE(MAXC.SE - MINC.SE, MAXH.SE - 1), ASC.SE = MINC.SE
DIM INTEGER CLIP.SE(MAXH.SE - 1)
DIM INTEGER UNDO.SE(MAXH.SE - 1)

DIM INTEGER CX.SE = 0, CY.SE = 0, CON.SE = 0
DIM INTEGER WW.SE = 8 * MAXW.SE
DIM INTEGER PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
DIM INTEGER DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
DIM INTEGER DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
DIM STRING kk

DIM INTEGER REC.SE = 0
DIM STRING MACRO.SE = ""
DIM STRING MACRO_NAME.SE(20)
DIM STRING MACRO_CALL.SE(20)

DIM INTEGER MOU.SE = -1, MOU_X.SE = -1, MOU_Y.SE = -1, MOU_L.SE = -1, MOU_R.SE = -1, MOU_W.SE = -1

SEinit
SEinitMouse

ON KEY 157, SEscreenShot


DO 
  IF MOU.SE > -1 THEN SEtestMouse
  kk = INKEY$
  IF kk<>"" THEN 
    IF MOU.SE > -1 THEN GUI CURSOR HIDE
    SEkey(kk)
    IF MOU.SE > -1 THEN GUI CURSOR SHOW
  ENDIF
LOOP

END

SUB SEinitMouse
  'try to find mouse and set MOU.SE to it's port

  LOCAL INTEGER i
  IF MM.INFO(VERSION) >= 5.07 THEN
    MOU.SE = MM.INFO(OPTION MOUSE)
    ON ERROR SKIP
    CONTROLLER MOUSE OPEN MOU.SE
    IF MM.ERRNO <> 0 THEN
      MOU.SE = -1
    ENDIF
  ELSE
    MOU.SE = -1
  ENDIF 
  FOR i = 1 TO 3
    IF MOU.SE < 0 THEN
      ON ERROR SKIP
      CONTROLLER MOUSE OPEN i
      IF MM.ERRNO = 0 THEN
        MOU.SE = i
      ENDIF
    ENDIF
    IF MOU.SE >= 0 THEN
      IF TUIquestion("MOUSE TEST", "Mouse found on port " + STR$(MOU.SE) + ", use it?") THEN
        LOAD PNG "Mouse.PNG", 640, 50
        GUI CURSOR ON 0, MOUSE(X, MOU.SE), MOUSE(Y, MOU.SE), RGB(GREEN)
      ELSE
        MOU.SE = -1
      ENDIF
      EXIT SUB
    ENDIF
  NEXT i
END SUB

SUB SEmouseSetPix(xx AS INTEGER, yy AS INTEGER)
  SEcursorB(0)
  CX.SE = FIX((xx - DX.SE)\PIX.SE)
  CY.SE = FIX((yy - DY.SE)\PIX.SE)
  SEpixel(1)
END SUB

SUB SEmouseClrPix(xx AS INTEGER, yy AS INTEGER)
  SEcursorB(0)
  CX.SE = FIX((xx - DX.SE)\PIX.SE)
  CY.SE = FIX((yy - DY.SE)\PIX.SE)
  SEpixel(-1)
END SUB

SUB SEtestMouse
  'testing mouse for movement and buttons

  LOCAL INTEGER x = MOUSE(X. MOU.SE), y = MOUSE(Y. MOU.SE)
  LOCAL INTEGER l = MOUSE(L. MOU.SE), r = MOUSE(R. MOU.SE), w = MOUSE(W. MOU.SE)
  LOCAL INTEGER cxl = WW.SE + 4, cyu = 16, pxy = MIN(MAXW.SE \ W.SE, MAXH.SE \ H.SE), change = 0
  INC cxl, (MAXW.SE - pxy * W.SE) \ 2  
  INC cyu, (MAXH.SE - pxy * H.SE) \ 2  
  LOCAL INTEGER cxr = cxl + pxy * W.SE, cyd = cyu + pxy * H.SE

  IF MOU_X.SE <> x OR MOU_Y.SE <> y THEN 'mouse movement
    GUI CURSOR x, y
    MOU_X.SE = x
    MOU_Y.SE = y
    change = 1
  ENDIF

  IF MOU_L.SE <> l THEN 'left button change
    IF l THEN 'pressed
      SEprepareUndo
      IF y >= DY.SE AND y < DY.SE + H.SE * PIX.SE THEN
        IF x >= DX.SE AND x < DX.SE + W.SE * PIX.SE THEN
          'set pixel
          SEmouseSetPix(x, y)
        ENDIF
      ELSEIF y >= (MM.VRES - H.SE) THEN
        IF x >= CD.SE THEN
          'choose character to edit
          GUI CURSOR HIDE
          SEcursorS(0)
          SEcursorB(0)
          ASC.SE = ((x - CD.SE) \ W.SE) + CMIN.SE
          SEcursorS(1)
          SEdrawCharB
          CX.SE = 0: CY.SE = 0
          SEcursorB(1)
          GUI CURSOR SHOW
        ENDIF
      ENDIF
      IF x >= cxl THEN
        IF x < cxr THEN
          IF y >= cyu THEN
            IF y < cyd THEN
              SEtoClipboard
              SEshowClipboard
            ENDIF
          ENDIF
        ENDIF
      ENDIF
    ELSE 'released
    ENDIF
    MOU_L.SE = l
  ELSEIF l THEN 'left button hold
    IF change THEN 'move with left button
      IF y >= DY.SE AND y < DY.SE + H.SE * PIX.SE THEN
        IF x >= DX.SE AND x < DX.SE + W.SE * PIX.SE THEN
          'set pixels
          SEmouseSetPix(x, y)
        ENDIF
      ENDIF
    ENDIF
  ENDIF

  IF MOU_R.SE <> r THEN 'right button change
    IF r THEN 'pressed
      SEprepareUndo
      IF y >= DY.SE AND y < DY.SE + H.SE * PIX.SE THEN
        IF x >= DX.SE AND x < DX.SE + W.SE * PIX.SE THEN
          'erase pixels
          SEmouseClrPix(x, y)
        ENDIF
      ENDIF      
      IF x >= cxl THEN
        IF x < cxr THEN
          IF y >= cyu THEN
            IF y < cyd THEN
              SEfromClipboard
              SEcursorS(1)
              SEdrawCharB
              SEcursorB(1)
            ENDIF
          ENDIF
        ENDIF
      ENDIF
    ELSE 'released
    ENDIF
    MOU_R.SE = r
  ELSEIF r THEN 'right button hold
    IF change THEN 'move with right button
      IF y >= DY.SE AND y < DY.SE + H.SE * PIX.SE THEN
        IF x >= DX.SE AND x < DX.SE + W.SE * PIX.SE THEN
          'erase pixel
          SEmouseClrPix(x, y)
        ENDIF
      ENDIF
    ENDIF
  ENDIF

  IF MOU_W.SE <> w THEN 'middle button change
    IF w THEN 'pressed
      IF x >= cxl THEN
        IF x < cxr THEN
          IF y >= cyu THEN
            IF y < cyd THEN
              SEorFromClipboard
              SEcursorS(1)
              SEdrawCharB
              SEcursorB(1)
            ENDIF
          ENDIF
        ENDIF
      ENDIF
    ELSE 'released
    ENDIF
    MOU_W.SE = w
  ELSEIF w THEN 'middle button hold
    IF change THEN 'move with middle button
    ENDIF
  ENDIF
END SUB

FUNCTION SErc(s AS STRING) AS STRING
  LOCAL INTEGER i
  
  SErc = ""
  FOR i = 1 TO len(s)
    SErc = SErc + CHR$(48 + ASC(MID$(s, i, 1)))
  NEXT i  
END FUNCTION

SUB SEkey(kk AS STRING)
  'main key seting method

  LOCAL INTEGER m = KEYDOWN(7)
  LOCAL INTEGER k = ASC(kk)
  LOCAL INTEGER hlp, hlp1, hlp2, i, j, cnt
  LOCAL STRING s
  
  IF (m AND 1) OR (m AND 16) THEN k = ASC(kk) + 1000 'ALT
  IF (m AND 2) OR (m AND 32) THEN k = ASC(kk) + 4000 'CTRL
  IF (m AND 4) OR (m AND 64) THEN k = ASC(kk) + 3000 'WIN
  IF (m AND 8) OR (m AND 128) THEN k = ASC(kk) + 2000 'SHIFT

  '''TEXT MM.HRES, 0, STR$(k),"RT",,,RGB(WHITE),RGB(NOTBLACK)'''

  SELECT CASE k
    CASE 3000 + ASC("q"), 3000 + ASC("Q")
      IF TUIquestion("QUIT", "Are you ready to leave me alone?") THEN
        CLS
        CHDIR TUIgetParent(EXPORT.SE)
        OPTION BREAK 3
        IF MOU.SE > -1 THEN CONTROLLER MOUSE CLOSE MOU.SE
        END
      ENDIF

    CASE 3000 + ASC("p"), 3000 + ASC("P") 'preview
      SEpreviewFont

    CASE 1000 + ASC("s"), 1000 + ASC("S") 'special function
      SEprepareUndo
      SEspecial
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)
      
    CASE 1000 + ASC("n"), 1000 + ASC("N") 'rotate 90` degrees
      SEprepareUndo
      SEmacroAdd(0)
      SEninety
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)      

    CASE ASC("c"), ASC("C") 'center
      SEprepareUndo
      SEmacroAdd(1)
      SEcenter
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE ASC("l"), ASC("L") 'left
      SEprepareUndo
      SEmacroAdd(2)
      SEleft
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE ASC("r"), ASC("R") 'right
      SEprepareUndo
      SEmacroAdd(3)
      SEright
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE ASC("t"), ASC("T") 'top
      SEprepareUndo
      SEmacroAdd(4)
      SEtop
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE ASC("b"), ASC("B") 'bottom
      SEprepareUndo
      SEmacroAdd(5)
      SEbottom
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 128  'cursor up
      IF CY.SE > 0 THEN
        SEcursorB(0)
        INC CY.SE, -1
        SEcursorB(1)
      ENDIF

    CASE 129  'cursor down
      IF CY.SE < H.SE - 1 THEN
        SEcursorB(0)
        INC CY.SE, 1
        SEcursorB(1)
      ENDIF

    CASE 130  'cursor left
      IF CX.SE > 0 THEN
        SEcursorB(0)
        INC CX.SE, -1
        SEcursorB(1)
      ENDIF

    CASE 2163  'fast right
      SEcursorB(0)
      IF CX.SE+W.SE\4 < W.SE THEN
        INC CX.SE, W.SE\4
      ELSE
        CX.SE = W.SE - 1
      ENDIF
      SEcursorB(1)
     

    CASE 2130  'fast left
      SEcursorB(0)
      IF CX.SE > W.SE\4 THEN
        INC CX.SE, -W.SE\4
      ELSE
        CX.SE = 0
      ENDIF
      SEcursorB(1)
     

    CASE 2128  'fast up
      SEcursorB(0)
      IF CY.SE > H.SE\4 THEN
        INC CY.SE, -H.SE\4
      ELSE
        CY.SE = 0
      ENDIF
      SEcursorB(1)
     

    CASE 2161  'fast down
      SEcursorB(0)
      IF CY.SE+H.SE\4 < H.SE THEN
        INC CY.SE, H.SE\4
      ELSE
        CY.SE = H.SE - 1
      ENDIF
      SEcursorB(1)
     

    CASE 131  'cursor right
      IF CX.SE < W.SE - 1 THEN
        SEcursorB(0)
        INC CX.SE, 1
        SEcursorB(1)
      ENDIF

    CASE 3130 'WIN left, character cursor left
      SEcharCursLeft
      SEprepareUndo
        
    CASE 3131 'WIN right, character  cursor right
      SEcharCursRight
      SEprepareUndo

    CASE 1130 'ALT left
      SEprepareUndo
      SEmacroAdd(6)
      SErotateLeft
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1128 'ALT up
      SEprepareUndo
      SEmacroAdd(8)
      SErotateUp
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1129 'ALT down, rotate down  
      SEprepareUndo
      SEmacroAdd(9)
      SErotateDown
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1131 'ALT right, rotate right
      SEprepareUndo
      SEmacroAdd(7)
      SErotateRight
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1000 + ASC("i"), 1000 + ASC("I") 'ALT i/I
      SEprepareUndo
      SEmacroAdd(10)
      SEinvert
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1000 + ASC("h"), 1000 + ASC("H") 'ALT h/H
      SEprepareUndo
      SEmacroAdd(11)
      SEhorMirror
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 1000 + ASC("v"), 1000 + ASC("V") 'ALT v/V
      SEprepareUndo
      SEmacroAdd(12)
      SEverMirror
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 3000 + ASC("e"), 3000 + ASC("E") 'WIN e/E
      SEexport
      
    CASE 3000 + ASC("i"), 3000 + ASC("I") 'WIN i/I
      SEimport

    CASE 3000 + ASC("f"), 3000 + ASC("F") 'WIN f/F
      SEmarkFirst

    CASE 3000 + ASC("l"), 3000 + ASC("L") 'WIN l/L
      SEmarkLast

    CASE 3000 + ASC("m"), 3000 + ASC("M") 'WIN m/M
      SEmacros

    CASE 1000 + ASC("f"), 1000 + ASC("F") 'ALT f/F, fill character
      SEprepareUndo
      SEfill

    CASE 4003 'CTRL-C, copy character to clipboard
      SEmacroAdd(13)
      SEtoClipboard
      SEshowClipboard

    CASE 4022 'CTRL-V, paste clipboard to character
      SEprepareUndo
      SEmacroAdd(14)
      SEfromClipboard
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 4015 'CTRL-O, OR-paste clipboard to character
      SEprepareUndo
      SEmacroAdd(15)
      SEorFromClipboard
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    CASE 4026 'CTRL-Z, undo
      SEundo

    CASE 1000 + ASC("e"), 1000 + ASC("E") 'erase character
      SEprepareUndo
      SEmacroAdd(16)
      SEerase
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)
    
    CASE 32 'SPACE, pixel ON/OFF
      SEpixel

    CASE 3000 + ASC("d"), 3000 + ASC("D") 'WIN d/D, load default font
      SEdefaultFont

    CASE 3000 + ASC("h"), 3000 + ASC("H") 'WIN h/H, enter new height
      SEnewHeight

    CASE 3000 + ASC("w"), 3000 + ASC("W") 'WIN w/W, enter new width
      SEnewWidth

    CASE 3043 'WIN +
      SEplusSize

    CASE 3045 'WIN -
      SEminusSize

  END SELECT
END SUB

SUB SEinit
  'init routine

  LOCAL INTEGER i

  MODE 1,8
  CLS RGB(NOTBLACK) 
  LOAD PNG "Logo.PNG", 584, 0
  'LOAD PNG "Mouse1.PNG", 640, 50
  LOAD FONT "SimplEd.FNT"
  FONT #8
  TEXT WW.SE + MAXW.SE + 16, MAXH.SE - 8, SEdigital(VERSION.SE), "LT",,,RGB(RED), RGB(NOTBLACK)

  RESTORE macro_def
  FOR i = 0 TO BOUND(MACRO_NAME.SE())
    READ MACRO_NAME.SE(i), MACRO_CALL.SE(i)
  NEXT i
  SEhelp
  SEdefaultChars(1)
  SEdrawCharSet
  ASC.SE = MINC.SE + 1
  SEdrawCharB
  SEcursorS(1)   
  SEcursorB(1)
  SEshowClipboard

  macro_def:
  DATA "Rotate 90 degrees", "SEninety"
  DATA "Center char", "SEcenter"
  DATA "Char to left", "SEleft"
  DATA "Char to right", "SEright"
  DATA "Char to top", "SEtop"
  DATA "Char to bottom", "SEbottom"
  DATA "Shift/rotate left", "SErotateLeft"
  DATA "Shift/rotate right", "SErotateRight"
  DATA "Shift/rotate up", "SErotateUp"
  DATA "Shift/rotate down", "SErotateDown"
  DATA "Invert char", "SEinvert"
  DATA "Horizontal mirror", "SEhorMirror"
  DATA "Vertical mirror", "SEverMirror"
  DATA "COPY to CLIP", "SEtoClipboard"
  DATA "PASTE from CLIP", "SEfromClipboard"
  DATA "OR from CLIP", "SEorFromClipboard"
  DATA "Erase char", "SEerase"
  DATA "Rasterize HOR", "SErasterHor"
  DATA "Rasterize VER", "SErasterVer"
  DATA "Skew char left", "SEskewLeft"
  DATA "Skew char right", "SEskewRight"  
END SUB

SUB SEcursorS(onOff AS INTEGER)
  'SMALL cursor (red box begind selected character for edit)

  LOCAL INTEGER dx = W.SE * (ASC.SE - CMIN.SE) + CD.SE
  LOCAL INTEGER dy = MM.VRES - H.SE

  CON.SE = onOff
  IF onOff THEN
    BOX dx, dy, W.SE, H.SE, 0, RGB(NOTBLACK), RGB(RED)
  ELSE
    BOX dx, dy, W.SE, H.SE, 0, RGB(NOTBLACK), RGB(NOTBLACK)
  END IF
  SEdrawCharS(ASC.SE, dx, dy)
END SUB

SUB SEcursorB(onOff AS INTEGER)
  'BIG cursor

  LOCAL INTEGER dx = WW.SE + W.SE * ((ASC.SE - MINC.SE) MOD 16)
  LOCAL INTEGER dy = H.SE * ((ASC.SE - MINC.SE) \ 16)

  CON.SE = onOff
  IF onOff THEN
    BOX DX.SE + CX.SE * PIX.SE, DY.SE + CY.SE * PIX.SE, PIX.SE, PIX.SE, 1, RGB(RED)
    SEdrawNum(CY.SE)
  ELSE
    BOX DX.SE + CX.SE * PIX.SE, DY.SE + CY.SE * PIX.SE, PIX.SE, PIX.SE, 1, RGB(GRAY)
  END IF
END SUB

SUB SEdrawCharS(ch AS INTEGER, dx AS INTEGER, dy AS INTEGER, col AS INTEGER)
  'draw SMALL (edited) character

  LOCAL INTEGER x, y, r

  IF dx => 0 AND dx < MM.HRES THEN
    IF col = 0 THEN col = RGB(WHITE)
    FOR y = 0 TO H.SE - 1
      r = CHAR.SE(ch - MINC.SE, y)
      FOR x = 0 TO W.SE - 1
        IF r AND (1<<(W.SE - x - 1)) THEN
          PIXEL dx + x, dy + y, col
        ENDIF
      NEXT x
    NEXT y
  ENDIF
END SUB

SUB SEdrawNum(yy AS INTEGER)
  'HEX number of actual row of BIG cursor position

  LOCAL STRING txt = HEX$(CHAR.SE(ASC.SE - MINC.SE, yy) AND ((1 << W.SE) - 1), CINT(W.SE / 4 + 0.49)))

  TEXT 0, WW.SE, txt, "LT",,,, RGB(WHITE), RGB(NOTBLACK)
END SUB

SUB SEdrawCharB
  'draw BIG character

  LOCAL INTEGER x, y

  PAGE WRITE 1
  BOX 0, 0, WW.SE, WW.SE, 0, RGB(NOTBLACK), RGB(GRAY) 'big char
  FOR y = 0 TO H.SE - 1
    FOR x = 0 TO W.SE - 1
      IF CHAR.SE(ASC.SE - MINC.SE, y) AND (1<<(W.SE-x-1)) THEN
        BOX DX.SE + x * PIX.SE, DY.SE + y * PIX.SE, PIX.SE, PIX.SE, 1, RGB(GRAY), RGB(WHITE)
      ELSE
        BOX DX.SE + x * PIX.SE, DY.SE + y * PIX.SE, PIX.SE, PIX.SE, 1, RGB(GRAY), RGB(NOTBLACK)
      ENDIF
    NEXT x
  NEXT y
  PAGE WRITE 0
  BLIT 0, 0, 0, 0, WW.SE, WW.SE, 1
  LOCAL STRING txt = "CHR$(" + STR$(ASC.SE, 3) + ") = " + CHR$(ASC.SE)
  TEXT WW.SE - 8 * LEN(txt), WW.SE, txt, "LT",,,RGB(WHITE), RGB(NOTBLACK)
  IF ASC.SE = BEGIN.SE THEN
    IF BEGIN.SE = END.SE THEN
      TEXT WW.SE - 16 * 8, WW.SE, " BOTH", "RT",,,RGB(RED), RGB(NOTBLACK)
    ELSE
      TEXT WW.SE - 16 * 8, WW.SE, "FIRST", "RT",,,RGB(RED), RGB(NOTBLACK)
    ENDIF
  ELSEIF ASC.SE = END.SE THEN
    TEXT WW.SE - 16 * 8, WW.SE, " LAST", "RT",,,RGB(RED), RGB(NOTBLACK)
  ELSE
    TEXT WW.SE - 16 * 8, WW.SE, "     ", "RT",,,RGB(RED), RGB(NOTBLACK)
  ENDIF
  SEsetLimits
END SUB

SUB SEdrawCharSet
  'draw line of all SMALL characters on bottom of the screen

  LOCAL INTEGER i, dx = CD.SE, dy = MM.VRES - H.SE

  BOX 0, MM.VRES - MAXH.SE, MM.HRES, MAXH.SE, 0, RGB(NOTBLACK), RGB(NOTBLACK)
  FOR i = CMIN.SE TO CMAX.SE
    SEdrawCharS(i, dx, dy)
    INC dx, W.SE
  NEXT i     
  BOX 0, WW.SE, WW.SE, 16, 0, RGB(NOTBLACK), RGB(NOTBLACK)
  TEXT WW.SE \ 2, WW.SE, STR$(W.SE) + "x" + STR$(H.SE),"CT",,,RGB(WHITE), RGB(NOTBLACK)
END SUB

SUB SEdefaultChars(f AS INTEGER)
  'load default font (1-7) or SimplEd font(8)
  LOCAL INTEGER x, y, i

  IF f THEN 
    FONT f
  ELSE
    EXIT SUB
  ENDIF

  SELECT CASE f
    CASE 1, 4, 8
      BEGIN.SE = 32
      END.SE = 255

    CASE 2,3,5,7
      BEGIN.SE = 32
      END.SE = 127

    CASE 6
      BEGIN.SE = 43
      END.SE = 96

  END SELECT
  IF f < 8 THEN
    LAST.SE = "Default" + STR$(f)
  ELSE
    LAST.SE = "SimplEd"
  ENDIF
  W.SE = MM.INFO(FONTWIDTH)
  H.SE = MM.INFO(FONTHEIGHT)
  CW.SE = W.SE * (MM.HRES \ W.SE)
  CD.SE = (MM.HRES - CW.SE) \ 2
  CMIN.SE = MINC.SE
  CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
  PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
  DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
  DY.SE = (WW.SE - PIX.SE * H.SE) \ 2

  FONT 8
  LOCAL STRING dialog = TUIwaitingON("GENERATE CHARACTERS")
  FOR i = MINC.SE TO MAXC.SE
    FONT 8
    TUIwaitingProgress(dialog, 100 * (i - MINC.SE) / (MAXC.SE - MINC.SE))
    IF f THEN FONT f
    PAGE WRITE 1
    TEXT 0,0,CHR$(i),"LT",,,RGB(WHITE), RGB(BLACK)

    FOR y = 0 TO H.SE - 1
      CHAR.SE(i - MINC.SE, y) = 0
      FOR x = 0 TO W.SE - 1
        IF PIXEL(x, y) <> RGB(BLACK) THEN
          CHAR.SE(i - MINC.SE, y) = CHAR.SE(i - MINC.SE, y) OR (1 << (W.SE - x - 1))
        ENDIF
      NEXT x
    NEXT y
    PAGE WRITE 0
  NEXT i   
  TUIwaitingOFF(dialog)
  IF f THEN FONT 8
END SUB

SUB SEincRC(s AS STRING, i AS INTEGER)
  'add 1 to number in string

  MID$(s, i, 1) = CHR$(ASC(MID$(s, i, 1)) + 1)
END SUB

SUB SEdecRC(s AS STRING, i AS INTEGER)
  'sub 1 to number in string

  ON ERROR SKIP
  MID$(s, i, 1) = CHR$(ASC(MID$(s, i, 1)) - 1)
  IF MM.ERRNO THEN MMDEBUG BREAK
END SUB

SUB SEsetLimits
  'find character boundary

  LOCAL INTEGER x, y
  LOCAL STRING bbb

  COL.SE = STRING$(W.SE, 0)
  ROW.SE = STRING$(H.SE, 0)
  LIMIT.SE = 0
  FOR y = 0 TO H.SE - 1
    bbb = BIN$(CHAR.SE(ASC.SE - MINC.SE, y), W.SE)
    FOR x = 0 TO W.SE - 1
      IF MID$(bbb, x + 1, 1) = "1"  THEN
        SEincRC(COL.SE, x + 1)
        SEincRC(ROW.SE, y + 1)
        INC LIMIT.SE
      ENDIF
    NEXT x
  NEXT y
END SUB

SUB SErotateLeft
  'shift char left with rotation

  LOCAL INTEGER hlp1 = (1 << (W.SE - 1)), i
  LOCAL STRING hlp2

  FOR i = 0 TO H.SE - 1
    hlp2 = BIN$(CHAR.SE(ASC.SE - MINC.SE, i), W.SE)
    hlp2 = MID$(hlp2, 2) + LEFT$(hlp2, 1)   
    CHAR.SE(ASC.SE - MINC.SE, i) = VAL("&b" + hlp2)
  NEXT i
END SUB

SUB SErotateUp
  'shift char up with rotation

  LOCAL INTEGER hlp1 = CHAR.SE(ASC.SE - MINC.SE, 0), i

  FOR i = 1 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, i - 1) = CHAR.SE(ASC.SE - MINC.SE, i)
  NEXT i
  CHAR.SE(ASC.SE - MINC.SE, H.SE - 1) = hlp1
END SUB

SUB SEinvert
  'invert char

  LOCAL INTEGER hlp = (1 << W.SE) - 1, i

  FOR i = 0 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, i) XOR hlp
  NEXT i
END SUB

SUB SEverMirror
  'mirror char vertical

  LOCAL INTEGER i, hlp

  FOR i = 0 TO H.SE \ 2 - 1
    hlp = CHAR.SE(ASC.SE - MINC.SE, i)
    CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, H.SE - i - 1)
    CHAR.SE(ASC.SE - MINC.SE, H.SE - i - 1) = hlp
  NEXT i
END SUB

SUB SEhorMirror
  'mirror char horizontal

  LOCAL INTEGER i, j, hlp, hlp2

  FOR i = 0 TO H.SE - 1
    hlp = CHAR.SE(ASC.SE - MINC.SE, i)
    hlp2 = 0
    FOR j = 0 TO W.SE - 1
      IF (hlp AND (1 << j)) > 0 THEN INC hlp2, 1 << (W.SE - j - 1)
    NEXT j 
    CHAR.SE(ASC.SE - MINC.SE, i) = hlp2
  NEXT i
END SUB

SUB SEmarkFirst
  'mark FIRST char (for EXPORT)

  IF ASC.SE > END.SE THEN
    BEGIN.SE = END.SE
    END.SE = ASC.SE
  ELSE
    BEGIN.SE = ASC.SE
  ENDIF
  IF ASC.SE = BEGIN.SE THEN
    IF BEGIN.SE = END.SE THEN
      TEXT WW.SE - 16 * 8, WW.SE, " BOTH", "RT",,,RGB(RED), RGB(NOTBLACK)
    ELSE   
      TEXT WW.SE - 16 * 8, WW.SE, "FIRST", "RT",,,RGB(RED), RGB(NOTBLACK)
    ENDIF
  ELSE
    TEXT WW.SE - 16 * 8, WW.SE, " LAST", "RT",,,RGB(RED), RGB(NOTBLACK)
  ENDIF
END SUB

SUB SEmarkLast
  'mark LAST char (for EXPORT)

  IF ASC.SE < BEGIN.SE THEN
    END.SE = BEGIN.SE
    BEGIN.SE = ASC.SE
  ELSE
    END.SE = ASC.SE
  ENDIF
  IF ASC.SE = BEGIN.SE THEN
    IF BEGIN.SE = END.SE THEN
      TEXT WW.SE - 16 * 8, WW.SE, " BOTH", "RT",,,RGB(RED), RGB(NOTBLACK)
    ELSE   
      TEXT WW.SE - 16 * 8, WW.SE, "FIRST", "RT",,,RGB(RED), RGB(NOTBLACK)
    ENDIF
  ELSE
    TEXT WW.SE - 16 * 8, WW.SE, " LAST", "RT",,,RGB(RED), RGB(NOTBLACK)
  ENDIF
END SUB

SUB SEcharCursLeft
  'move SMALL cursor left

  IF ASC.SE > CMIN.SE THEN
    SEcursorS(0)
    SEcursorB(0)
    INC ASC.SE, - 1
    SEcursorS(1)
    SEdrawCharB
    CX.SE = 0: CY.SE = 0
    SEcursorB(1)
  ELSE
    IF ASC.SE > MINC.SE THEN
      SEcursorS(0)
      SEcursorB(0)
      INC ASC.SE, -1
      INC CMIN.SE, -1
      INC CMAX.SE, -1
      BLIT CD.SE, MM.VRES - H.SE, CD.SE + W.SE, MM.VRES - H.SE, CW.SE - W.SE, H.SE
      SEcursorS(1)
      SEdrawCharB
      CX.SE = 0: CY.SE = 0
      SEcursorB(1)
    ENDIF
  ENDIF
END SUB

SUB SEcharCursRight
  'move SMALL cursor right

  IF ASC.SE < CMAX.SE  THEN
    SEcursorS(0)
    SEcursorB(0)
    INC ASC.SE, 1
    SEcursorS(1)
    SEdrawCharB
    CX.SE = 0: CY.SE = 0
    SEcursorB(1)
  ELSE
    IF ASC.SE < MAXC.SE THEN
      SEcursorS(0)
      SEcursorB(0)
      INC ASC.SE
      INC CMIN.SE
      INC CMAX.SE
      BLIT CD.SE + W.SE, MM.VRES - H.SE, CD.SE, MM.VRES - H.SE, CW.SE, H.SE
      SEcursorS(1)
      SEdrawCharB
      CX.SE = 0: CY.SE = 0
      SEcursorB(1)
    ENDIF
  ENDIF
END SUB

SUB SEerase
  'erase char

  LOCAL INTEGER i

  FOR i = 0 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, i) = 0
  NEXT i
END SUB

SUB SEtoClipboard
  'copy char TO CLIP

  LOCAL INTEGER i

  FOR i = 0 TO H.SE - 1
     CLIP.SE(i) = CHAR.SE(ASC.SE - MINC.SE, i)
  NEXT i
END SUB

SUB SEfromClipboard
  'copy char FROM CLIP

  LOCAL INTEGER i

  FOR i = 0 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, i) = CLIP.SE(i)
  NEXT i
END SUB

SUB SEorFromClipboard
  'copy char FROM CLIP with LOGICAL OR (combine char and CLIP)

  LOCAL INTEGER i

  FOR i = 0 TO H.SE - 1
     CHAR.SE(ASC.SE - MINC.SE, i) = CLIP.SE(i) OR CHAR.SE(ASC.SE - MINC.SE, i)
  NEXT i
END SUB

SUB SErotateDown
  'shift char DOWN with rotation

  LOCAL INTEGER i, hlp1 = CHAR.SE(ASC.SE - MINC.SE, H.SE - 1) 

  FOR i = H.SE - 2 TO 0 STEP -1
    CHAR.SE(ASC.SE - MINC.SE, i + 1) = CHAR.SE(ASC.SE - MINC.SE, i)
  NEXT i
  CHAR.SE(ASC.SE - MINC.SE, 0) = hlp1
END SUB

SUB SErotateRight
  'shift char RIGHT with rotation

  LOCAL INTEGER i
  LOCAL STRING hlp2

  FOR i = 0 TO H.SE - 1
    hlp2 = BIN$(CHAR.SE(ASC.SE - MINC.SE, i), W.SE)
    hlp2 = RIGHT$(hlp2, 1) + LEFT$(hlp2, LEN(hlp2) - 1)   
    CHAR.SE(ASC.SE - MINC.SE, i) = VAL("&b" + hlp2) 
  NEXT i
END SUB

SUB SEdefaultFont
  'selection of DEFAULT or SimplEd FONT

  LOCAL INTEGER hlp = TUIchoice("LOAD DEFAULT FONT","ASCII 8x12,ASCII 12x20,ASCII 16x24,ASCII 10x16,ASCII 24x32,ASCII 32x50,ASCII 6x8,SimpleEd 8x16")
 
  IF hlp >= 0 THEN
    SEdefaultChars(hlp + 1)
    SEdrawCharSet
    ASC.SE = MINC.SE
    SEdrawCharB
    SEcursorS(1)   
    SEcursorB(1)
    SEshowClipboard
  ENDIF
END SUB

SUB SEnewHeight
  'change FONT HEIGHT

  LOCAL INTEGER hlp = VAL(TUIinput("NEW FONT HEIGHT", "Enter height ("+STR$(MINH.SE)+"-"+STR$(MAXH.SE)+"):",STR$(H.SE),"0123456789"))

  IF hlp <= MAXH.SE THEN
    IF hlp >= MINH.SE THEN
      IF H.SE <> hlp THEN 
        IF TUIquestion("NEW FONT HEIGHT", "Really set height to "+STR$(hlp)+"?") THEN
          H.SE = hlp
          SEcursorB(0)
          PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
          DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
          DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
          CW.SE = W.SE * (MM.HRES \ W.SE)
          CD.SE = (MM.HRES - CW.SE) \ 2
          CMIN.SE = MINC.SE
          CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
          ASC.SE = CMIN.SE
          SEdrawCharSet
          SEdrawCharB
          SEcursorB(1)
          SEcursorS(1)
          SEshowClipboard
        ENDIF
      ENDIF
    ENDIF
  ENDIF
END SUB

SUB SEnewWidth
  'change FONT WIDTH

  LOCAL INTEGER hlp = VAL(TUIinput("NEW FONT WIDTH", "Enter width ("+STR$(MINW.SE)+"-"+STR$(MAXW.SE)+", multiple of 4):",STR$(W.SE),"0123456789"))

  IF hlp <= MAXW.SE THEN
    IF hlp >= MINW.SE THEN
      IF hlp MOD 4 <> 0 THEN hlp = 4 * FIX(hlp / 4)
      IF W.SE <> hlp THEN 
        IF TUIquestion("NEW FONT WIDTH", "Really set width to "+STR$(hlp)+"?") THEN
          W.SE = hlp
          SEcursorB(0)
          PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
          DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
          DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
          CW.SE = W.SE * (MM.HRES \ W.SE)
          CD.SE = (MM.HRES - CW.SE) \ 2
          CMIN.SE = MINC.SE
          CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
          ASC.SE = CMIN.SE
          SEdrawCharSet
          SEdrawCharB
          SEcursorB(1)
          SEcursorS(1)
          SEshowClipboard
        ENDIF
      ENDIF
    ENDIF
  ENDIF
END SUB

SUB SEplusSize
  'make char BIGGER (WIDTH with multiple of 4, HEIGHT loosely)

  IF W.SE + 4 <= MAXW.SE OR H.SE < MAXH.SE THEN
    SEcursorB(0)    
    IF W.SE + 4 =< MAXW.SE THEN INC W.SE, 4
    IF H.SE < MAXH.SE THEN INC H.SE, 1
    PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
    DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
    DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
    CW.SE = W.SE * (MM.HRES \ W.SE)
    CD.SE = (MM.HRES - CW.SE) \ 2
    CMIN.SE = MINC.SE
    CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
    ASC.SE = CMIN.SE
    SEdrawCharSet
    SEdrawCharB
    SEcursorB(1)
    SEcursorS(1)
    SEshowClipboard
  ENDIF
END SUB

SUB SEminusSize
  'make char SMALLER (WIDTH with multiple of 4, HEIGHT loosely)

  IF W.SE - 4 => MINW.SE OR H.SE > MINH.SE THEN
    SEcursorB(0)
    IF W.SE - 4 => MINW.SE THEN INC W.SE, -4
    IF H.SE > MINH.SE THEN INC H.SE, -1
    PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
    DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
    DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
    CW.SE = W.SE * (MM.HRES \ W.SE)
    CD.SE = (MM.HRES - CW.SE) \ 2
    CMIN.SE = MINC.SE
    CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
    ASC.SE = CMIN.SE
    SEdrawCharSet
    SEdrawCharB
    SEcursorB(1)
    SEcursorS(1)
    SEshowClipboard
  ENDIF
END SUB

SUB SEshowClipboard
  'draw CLIP on the screen

  LOCAL INTEGER x, y, dx = WW.SE + 4, dy = 0, pxy = MIN(MAXW.SE \ W.SE, MAXH.SE \ H.SE)

  TEXT dx + MAXW.SE \ 2, dy, "CLIP", "CT",,, RGB(YELLOW), RGB(NOTBLACK)
  INC dy, 16
  BOX dx, dy, MAXW.SE, MAXH.SE, 0, RGB(NOTBLACK), RGB(GRAY)

  dx = dx + (MAXW.SE - pxy * W.SE) \ 2  
  dy = dy + (MAXH.SE - pxy * H.SE) \ 2  
  FOR y = 0 TO H.SE - 1
    FOR x = 0 TO W.SE - 1
      IF CLIP.SE(y) AND (1<<(W.SE-x-1)) THEN
        BOX dx + pxy * x, dy + pxy * y, pxy, pxy, 0, RGB(WHITE), RGB(WHITE)
      ELSE
        BOX dx + pxy * x, dy + pxy * y, pxy, pxy, 0, RGB(NOTBLACK), RGB(NOTBLACK)
      ENDIF
    NEXT x
  NEXT y
END SUB

FUNCTION SEdigital(s AS STRING) AS STRING
  'get LCD version of number (from SimplEd font)

  SEdigital = ""
  LOCAL INTEGER i

  FOR i = 1 TO LEN(s)
    IF INSTR("0123456789", MID$(s, i, 1)) > 0 THEN
      CAT SEdigital, CHR$(240 + ASC(MID$(s, i, 1)) - 48)
    ELSE
      CAT SEdigital, MID$(s, i, 1)
    ENDIF
  NEXT i
END FUNCTION

SUB SEfill
  'flood fill in char

  LOCAL INTEGER x, y, hlp

  PAGE WRITE 1
  FOR y = 0 TO H.SE - 1
    hlp = CHAR.SE(ASC.SE - MINC.SE, y)
    FOR x = 0 TO W.SE - 1
      IF hlp AND (1 << (W.SE - x - 1)) THEN
        PIXEL x, y, RGB(WHITE)
      ELSE
        PIXEL x, y, RGB(BLACK)
      ENDIF
    NEXT x
  NEXT y
  BOX -1, -1, W.SE + 2, H.SE + 2, 1, RGB(WHITE)
  PIXEL FILL CX.SE, CY.SE, RGB(WHITE) 

  FOR y = 0 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, y) = 0
    FOR x = 0 TO W.SE - 1
      IF PIXEL(x, y) <> RGB(BLACK) THEN
        CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y) OR (1 << (W.SE - x - 1))
      ENDIF
    NEXT x
  NEXT y
  PAGE WRITE 0
  SEcursorS(1)
  SEdrawCharB
  SEcursorB(1)
END SUB

SUB SEexport
  'export font file into EXPORT.SE directory
  
  LOCAL STRING fname = "NewFont (" + STR$(W.SE) + "x" + STR$(H.SE) + ")"
  LOCAL INTEGER row, octaCount, i, j, hexDigits, act
  LOCAL STRING dword, byte

  IF LAST.SE <> "" THEN
    fname = LAST.SE + "(" + STR$(W.SE) + "x" + STR$(H.SE) + ")"
  ELSE
    fname = "NewFont(" + STR$(W.SE) + "x" + STR$(H.SE) + ")"
  ENDIF
  fname  = TUIinput("EXPORT FONT", "Enter name:", fname, NAME_CHARS.SE)
  IF fname <> "" THEN
    fname = fname + ".FNT"
    IF NOT SEexist(EXPORT.SE) THEN
      MKDIR EXPORT.SE
    ENDIF
    IF SEexist(EXPORT.SE + "/" + fname) THEN
      IF NOT TUIquestion("EXPORT FONT", "File '" + fname +"' exists, replace it?") THEN
        EXIT SUB
      ENDIF
    ENDIF

    OPEN EXPORT.SE + "/" + fname FOR OUTPUT AS #1
          
    ?#1,"DefineFont #8"
    ?#1,"  " HEX$(END.SE - BEGIN.SE + 1, 2) HEX$(BEGIN.SE, 2) HEX$(H.SE, 2) HEX$(W.SE, 2)
          
    ?#1,"  ";
    dword = ""
    octaCount = 0
    hexDigits = CINT(W.SE / 4 + 0.49)
    FOR i = BEGIN.SE TO END.SE
      act = i - MINC.SE
      FOR j = 0 TO H.SE - 1

        row = CHAR.SE(act, j) AND ((1 << W.SE) - 1)
        byte = byte + HEX$(row, hexDigits)
        DO WHILE LEN(byte) >= 2
          dword = LEFT$(byte, 2) + dword
          byte = MID$(byte, 3)
        LOOP

        DO WHILE LEN(dword) >= 8
          ?#1, RIGHT$(dword, 8)"  ";
          dword = LEFT$(dword, LEN(dword) - 8)
          INC octaCount
          IF octaCount = 8 THEN
            octaCount = 0
            ?#1,""
            IF j < (H.SE - 1) OR i < END.SE OR dword <> "" THEN
              ?#1,"  ";
            ENDIF
          ENDIF
        LOOP
      NEXT j
    NEXT i
    IF dword <> "" THEN
      ?#1, RIGHT$("00000000" + dword, 8)      
      INC octaCount
      IF octaCount = 8 THEN
        octaCount = 0
        ?#1,""
      ENDIF
    ENDIF
    IF octaCount <> 0 THEN ?#1, ""

    ?#1,"END DefineFont"
    CLOSE #1
    TUIwarning("EXPORT FONT", "File '" + EXPORT.SE + "/" + fname + "' saved")
  ENDIF
END SUB

SUB SEimport
  'import FONT file (from .FNT, .BAS or .INC)

  LOCAL STRING fileName, ext = ".FNT,.BAS,.INC"

  fileName = TUIfileSelect(CWD.SE, ext)  
  IF fileName <> "" THEN
    LAST.SE = fileName
    IF INSTR(LAST.SE, ".") THEN
      DO WHILE RIGHT$(LAST.SE, 1) <> "."
        LAST.SE = LEFT$(LAST.SE, LEN(LAST.SE) - 1)
      LOOP
      LAST.SE = LEFT$(LAST.SE, LEN(LAST.SE) - 1)
    ENDIF
    SEimportFont(fileName)
  ENDIF
END SUB

FUNCTION SElTrim(s AS STRING) AS STRING
  'TRIM from LEFT

  SElTrim = s
  DO WHILE SElTrim <> "" AND LEFT$(SElTrim, 1) < CHR$(33)
    SElTrim = MID$(SElTrim, 2)
  LOOP
END FUNCTION

SUB SEimportFont(f AS STRING)
  'load imported FONT

  LOCAL STRING lin, dword, row
  LOCAL INTEGER m = 0, first, cnt, hexDigits, y

  FOR first = MINC.SE TO MAXc.SE
    FOR cnt = 0 TO MAXH.SE - 1
      CHAR.SE(first - MINC.SE, cnt) = 0
    NEXT cnt
  NEXT first
  OPEN f FOR INPUT AS #1
  DO WHILE NOT EOF(#1)
    LINE INPUT #1, lin
    lin = SElTrim(lin)
    IF lin <> "" THEN
      IF LEFT$(lin, 1) <> "'" THEN
        DO WHILE lin <> ""
          lin = SElTrim(lin)

          IF lin <> "" THEN
            IF m = 0 THEN
              IF LCASE$(LEFT$(lin, 10)) = "definefont" THEN
                lin = ""
                m = 1                
              ELSE
                lin = ""
              ENDIF
       
            ELSEIF m = 1 THEN
              cnt = VAL("&h" + LEFT$(lin, 2))         
              first = VAL("&h" + MID$(lin, 3, 2)) - MINC.SE
              H.SE = VAL("&h" + MID$(lin, 5, 2))
              W.SE = VAL("&h" + MID$(lin, 7, 2))
              hexDigits = CINT(W.SE / 4 + 0.49)
              lin = MID$(lin, 9)
              BEGIN.SE = first + MINC.SE
              END.SE = BEGIN.SE + cnt - 1
              y = 0
              row = ""
              m = 2      

            ELSEIF m = 2 THEN
              IF LCASE$(LEFT$(lin, 3)) <> "end" THEN
                dword = LEFT$(lin, 8)
                lin = MID$(lin, 9)
                DO WHILE dword <> ""
                  row = row + RIGHT$(dword, 2)
                  dword = LEFT$(dword, LEN(dword) - 2)
                  DO WHILE LEN(row) >= hexDigits 
                    CHAR.SE(first, y) = VAL("&h" + LEFT$(row, hexDigits))
                    row = MID$(row, hexDigits + 1)
                    INC y   
                    IF y = H.SE THEN
                      y = 0
                      INC first
                    ENDIF               
                  LOOP            
                LOOP              
              ELSE
                lin = ""
              ENDIF
            
            ENDIF
          ENDIF
        LOOP
      ENDIF
    ENDIF
  LOOP
  CLOSE #1
  CW.SE = W.SE * (MM.HRES \ W.SE)
  CD.SE = (MM.HRES - CW.SE) \ 2
  CMIN.SE = MINC.SE
  CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
  PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
  DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
  DY.SE = (WW.SE - PIX.SE * H.SE) \ 2

  SEdrawCharSet
  ASC.SE = MINC.SE
  SEdrawCharB
  SEcursorS(1)   
  SEcursorB(1)
  SEshowClipboard
END SUB

SUB SEtop
  'MOVE character to TOP side

  IF LIMIT.SE = 0 THEN EXIT SUB
  LOCAL INTEGER y

  DO WHILE CHAR.SE(ASC.SE - MINC.SE, 0) = 0
    FOR y = 1 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, y - 1) = CHAR.SE(ASC.SE - MINC.SE, y)
    NEXT y
    CHAR.SE(ASC.SE - MINC.SE, H.SE - 1) = 0
  LOOP
END SUB

SUB SEbottom
  'MOVE character to BOTTOM side

  IF LIMIT.SE = 0 THEN EXIT SUB
  LOCAL INTEGER y

  DO WHILE CHAR.SE(ASC.SE - MINC.SE, H.SE - 1) = 0
    FOR y = H.SE - 1 TO 1 STEP -1
      CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y - 1)
    NEXT y
    CHAR.SE(ASC.SE - MINC.SE, 0) = 0
  LOOP
END SUB

SUB SEright
  'MOVE character to RIGHT side

  IF LIMIT.SE = 0 THEN EXIT SUB
  LOCAL INTEGER x

  DO WHILE RIGHT$(COL.SE, 1) = ZERO.SE
    FOR x = 0 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, x) = CHAR.SE(ASC.SE - MINC.SE, x) >> 1
    NEXT x
    COL.SE = ZERO.SE + LEFT$(COL.SE, LEN(COL.SE) - 1)
  LOOP
END SUB

SUB SEleft
  'MOVE character to LEFT side

  IF LIMIT.SE = 0 THEN EXIT SUB
  LOCAL INTEGER x

  DO WHILE LEFT$(COL.SE, 1) = ZERO.SE
    FOR x = 0 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, x) = CHAR.SE(ASC.SE - MINC.SE, x) << 1
    NEXT x
    COL.SE = MID$(COL.SE, 2) + ZERO.SE
  LOOP
END SUB

SUB SEcenter
  'CENTER character

  IF LIMIT.SE = 0 THEN EXIT SUB
  LOCAL INTEGER t = 0, b = 0, l = 0, r = 0, i, diff

  FOR i = 0 TO H.SE - 1
    IF MID$(ROW.SE, i + 1, 1) <> ZERO.SE THEN
      EXIT FOR
    ELSE
      INC t
    ENDIF
  NEXT i
  FOR i = H.SE - 1 TO 0 STEP -1
    IF MID$(ROW.SE, i + 1, 1) <> ZERO.SE THEN
      EXIT FOR
    ELSE
      INC b
    ENDIF
  NEXT i
  diff = (t - b) \ 2
  IF diff > 0 THEN
    FOR i = 0 TO H.SE - 1 - diff
      CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, i + diff)
      CHAR.SE(ASC.SE - MINC.SE, i + diff) = 0
    NEXT i
  ENDIF
  diff = (b - t) \ 2
  IF diff > 0 THEN
    FOR i = H.SE - 1 TO diff STEP -1
      CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, i - diff)
      CHAR.SE(ASC.SE - MINC.SE, i - diff) = 0
    NEXT i
  ENDIF
  FOR i = 0 TO W.SE - 1
    IF MID$(COL.SE, i + 1, 1) <> ZERO.SE THEN
      EXIT FOR
    ELSE
      INC l
    ENDIF
  NEXT i
  FOR i = W.SE - 1 TO 0 STEP -1
    IF MID$(COL.SE, i + 1, 1) <> ZERO.SE THEN
      EXIT FOR
    ELSE
      INC r
    ENDIF
  NEXT i
  IF l - r > 1 THEN
    FOR i = 0 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, i) << ((l - r) \ 2)
    NEXT i
  ENDIF
  IF r - l > 1 THEN
    FOR i = 0 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, i) = CHAR.SE(ASC.SE - MINC.SE, i) >> ((r - l) \ 2)
    NEXT i
  ENDIF
END SUB

SUB SEninety
  'ROTATE character

  LOCAL INTEGER x, y, diff
  LOCAL STRING hlp(W.SE - 1) LENGTH W.SE 

  IF H.SE > W.SE THEN
    diff = (H.SE - W.SE) \ 2
    FOR x = 0 TO W.SE - 1
      FOR y = 0 TO W.SE - 1
        IF MID$(BIN$(CHAR.SE(ASC.SE - MINC.SE, y + diff), W.SE), x + 1, 1) = "1" THEN
          hlp(x) = "1" + hlp(x)
        ELSE
          hlp(x) = "0" + hlp(x)
        ENDIF
      NEXT y
    NEXT x      
    FOR y = 0 TO H.SE - 1
      IF y < diff THEN
        CHAR.SE(ASC.SE - MINC.SE, y) = 0
      ELSEIF y - diff < W.SE THEN
        CHAR.SE(ASC.SE - MINC.SE, y) = VAL("&b" + hlp(y - diff))
      ELSE
        CHAR.SE(ASC.SE - MINC.SE, y) = 0
      ENDIF
    NEXT y
  ELSE
    diff = (W.SE - H.SE) \ 2
    FOR y = 0 TO H.SE - 1
      FOR x = 0 TO H.SE - 1
        IF MID$(BIN$(CHAR.SE(ASC.SE - MINC.SE, x + diff), W.SE), y + 1 + diff, 1) = "1" THEN
          hlp(y) = "1" + hlp(y)
        ELSE
          hlp(y) = "0" + hlp(y)
        ENDIF
      NEXT x
    NEXT y      
    FOR y = 0 TO H.SE - 1
      CHAR.SE(ASC.SE - MINC.SE, y) = VAL("&b" + hlp(y) + STRING$(diff, "0"))
    NEXT y
  ENDIF
END SUB

SUB SEprepareUndo
  'store last operation into UNDO

  LOCAL INTEGER i

  FOR i = 0 TO H.SE - 1
     UNDO.SE(i) = CHAR.SE(ASC.SE - MINC.SE, i)
  NEXT i
END SUB

SUB SEundo
  'UNDO last change

  LOCAL INTEGER i, hlp

  FOR i = 0 TO H.SE - 1
    hlp = CHAR.SE(ASC.SE - MINC.SE, i)
    CHAR.SE(ASC.SE - MINC.SE, i) = UNDO.SE(i)
    UNDO.SE(i) = hlp
  NEXT i
  SEcursorS(1)
  SEdrawCharB
  SEcursorB(1)    
END SUB

FUNCTION SEexist(filePath AS STRING) AS INTEGER
  'test FILE existence

  SEexist = DIR$(filePath, ALL) <> ""
END FUNCTION

SUB SEscreenShot
  'make SCREENSHOT of dialog or screen

  LOCAL STRING ss = "SS", path = TUIgetParent(EXPORT.SE) + "/"
  LOCAL INTEGER num = 0
 
  DO WHILE SEexist(path + ss + STR$(num, 3, 0, "0") + ".BMP")
    INC num
  LOOP
  ss = path + ss + STR$(num, 3, 0, "0") + ".BMP"
  IF ON.TUI THEN
    SAVE IMAGE ss, X.TUI, Y.TUI, W.TUI, H.TUI
  ELSE
    SAVE IMAGE ss
  ENDIF
END SUB

SUB SEpreviewFont
  'complete FONT preview

  LOCAL STRING txt = LAST.SE + ", " + STR$(W.SE) + "x" + STR$(H.SE)
  LOCAL STRING dialog
  LOCAL INTEGER ww = MIN((800 - 16) \ W.SE, 16)
  LOCAL INTEGER w = END.SE - BEGIN.SE + 1, x, y
  LOCAL INTEGER h = ((w \ ww) + 1) * H.SE + 16, i, xx, yy, hlp
  w = MAX(ww * W.SE, 8 * LEN(txt))

  PAGE COPY 0 TO 1
  dialog = TUIemptyON("PREVIEW FONT", w, h)
  x = VAL(FIELD$(dialog, 3, ","))
  y = VAL(FIELD$(dialog, 4, ","))
  TEXT x, y, txt, "LT",8,,RGB(NOTBLACK), RGB(YELLOW)
  xx = x
  yy = y + 16
  hlp = 0
  FOR i = BEGIN.SE TO END.SE
    SEdrawCharS(i, xx, yy, RGB(NOTBLACK))
    INC hlp
    IF hlp < ww THEN
      INC xx, W.SE
    ELSE
      xx = x
      hlp = 0
      INC yy, H.SE
    ENDIF
  NEXT i
  TUIwaitForKey
  TUIemptyOFF(dialog)
  PAGE COPY 1 TO 0
END SUB

SUB SEhelp
  'print HELP

  LOCAL INTEGER dx = WW.SE + 8, dy = MAXH.SE + 16 + 8
  TEXT dx, dy, CHR$(225)+" "+CHR$(226)+" "+CHR$(228)+" "+CHR$(227)+"  EDITOR cursor (SHIFT fast)", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "SPACE  INVERT pixel", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "LRTBC  LEFT/RIGHT/TOP/BOTTOM/CENTER", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 24  
  TEXT dx, dy, "CTRL-C/V  COPY/PASTE to/from CLIP", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "CTRL-O    OR from CLIP (COMBINE)", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "CTRL-Z    UNDO/REDO last change", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 24  
  TEXT dx, dy, "Alt " + CHR$(225)+" "+CHR$(226)+" "+CHR$(228)+" "+CHR$(227)+"  SHIFT character", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt H/V      MIRROR horiz/vert", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt F        FLOOD FILL char", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt E        ERASE char", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt I        INVERT char", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt N        ROTATE char 90" + CHR$(216), "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, "Alt S        SPECIAL functions", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 24  
  TEXT dx, dy, CHR$(213)+" "+CHR$(228)+" "+CHR$(227)+"  Choose char to EDIT", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" F/L  MARK FIRST/LAST char", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" +/-  Make font BIGGER/SMALLER", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" H/W  Set font HEIGHT/WIDTH", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" P    Preview font", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" D    Choose default font", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" I    Import FNT, BAS or INC file", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" E    Export FNT, FIRST to LAST", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 16  
  TEXT dx, dy, CHR$(213)+" M    MACRO functions", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 24  
  TEXT dx, dy, "PrtScr Screenshot to 'SSxxx.BMP'", "LT",,,RGB(CYAN), RGB(NOTBLACK)
  INC dy, 24
  TEXT dx, dy, CHR$(213)+" Q    QUIT SimplEd", "LT",,,RGB(CYAN), RGB(NOTBLACK)
END SUB

SUB SEspecial
  'SPECIAL functions

  LOCAL STRING spec(4)
  spec(1) = "Rasterize horizontal"
  spec(2) = "Rasterize vertical"
  spec(3) = "Skew right"
  spec(4) = "Skew left"

  LOCAL STRING f = TUIgetItem("SPECIAL FUNCTIONS", "Select function:", spec())
  IF f = "" THEN EXIT SUB

  SELECT CASE f
    CASE spec(1)
      SEmacroAdd(17)
      SErasterHor

    CASE spec(2)
      SEmacroAdd(18)
      SErasterVer

    CASE spec(3)
      SEmacroAdd(19)
      SEskewRight

    CASE spec(4)
      SEmacroAdd(20)
      SEskewLeft
  END SELECT
END SUB

SUB SErasterHor
  'HORIZONTAL rasterizing

  LOCAL INTEGER y, stp

  IF H.SE < 16 THEN
    stp = 4

  ELSEIF H.SE < 32 THEN
    stp = 3

  ELSE
    stp = 2

  ENDIF
  
  FOR y = 0 TO H.SE - 1
    IF NOT(y MOD stp) THEN
      CHAR.SE(ASC.SE - MINC.SE, y) = 0
    ENDIF
  NEXT y
END SUB

SUB SErasterVer
  'VERTICAL rasterizing

  LOCAL INTEGER y, stp

  IF W.SE < 16 THEN
    stp = &b1101110111011101

  ELSEIF W.SE < 32 THEN
    stp = &b110110110110110110110110110110110
  ELSE
    stp = &b1010101010101010101010101010101010101010101010101010101010101010

  ENDIF
  
  FOR y = 0 TO H.SE - 1
    CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y) AND stp
  NEXT y
END SUB

SUB SEskewRight
  'SKEW character to RIGHT

  LOCAL INTEGER y, skw = 0
  
  FOR y =0 TO H.SE - 1
    IF NOT((y + 1) MOD 8) THEN INC skw
    CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y) >> skw
  NEXT y
END SUB

SUB SEskewLeft
  'SKEW character to LEFT

  LOCAL INTEGER y, skw = 0
  
  FOR y = 0 TO H.SE - 1
    IF NOT((y + 1) MOD 8) THEN INC skw
    CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y) << skw
  NEXT y
END SUB

SUB SEmacros
  'macro functions

  LOCAL INTEGER m = TUIchoice("MACRO functions", "Record START,Record STOP,Play to CHAR, Play to FONT,Erase macro,Show macro")

  SELECT CASE m
    CASE 0
      SEmacroRecON
    
    CASE 1
      SEmacroRecOFF

    CASE 2
      SEmacroRecOFF
      SEmacroPlay(ASC.SE, ASC.SE)

    CASE 3
      SEmacroRecOFF
      SEmacroPlay(BEGIN.SE, END.SE)

    CASE 4
      MACRO.SE = ""
      SEmacroRecOFF
      
    CASE 5
      SEmacroShow
  END SELECT
END SUB

SUB SEmacroRecON
  'START macro RECORD

  REC.SE = 1
  SETTICK 500, SEblinkRec  
END SUB

SUB SEmacroRecOFF
  'STOP macro RECORD

  REC.SE = 0
  SETTICK 0, 0
  IF MACRO.SE <> "" THEN
    TEXT WW.SE + 4, 0, CHR$(233), "LT",,, RGB(RED), RGB(NOTBLACK)
  ELSE
    TEXT WW.SE + 4, 0, " ", "LT",,, RGB(NOTBLACK), RGB(NOTBLACK) 
  ENDIF
END SUB

SUB SEblinkRec
  'blink with RECORD sign

  IF REC.SE = 1 THEN
    CIRCLE WW.SE + 8, 8, 3, ,,RGB(RED), RGB(RED)
  ELSE
    TEXT WW.SE + 4, 0, " ", "LT",,, RGB(NOTBLACK), RGB(NOTBLACK) 
  ENDIF
  REC.SE = 3 - REC.SE  
END SUB

SUB SEmacroAdd(f AS INTEGER)
  'add macro "f" into MACRO.SE

  IF REC.SE THEN
    IF LEN(MACRO.SE) < 255 THEN
      CAT MACRO.SE, CHR$(f)
    ELSE
      SEmacroRecOFF
    ENDIF
  ENDIF
END SUB

SUB SEmacroShow
  'list MACRO.SE

  IF MACRO.SE <> "" THEN
    LOCAL STRING txt(LEN(MACRO.SE)), s
    LOCAL INTEGER i

    FOR i = 1 TO LEN(MACRO.SE)
      txt(i) = STR$(i, 3) + ": " + MACRO_NAME.SE(ASC(MID$(MACRO.SE, i, 1)))
    NEXT i
    s = TUIgetItem("SHOW MACRO", STR$(LEN(MACRO.SE)) + " steps", txt())
  ENDIF
END SUB

SUB SEmacroPlay(f AS INTEGER, l AS INTEGER)
  'playback of MACRO.SE for character "f" to character "l"
 
  IF MACRO.SE <> "" THEN
    LOCAL INTEGER old = ASC.SE, i, j
    LOCAL STRING func, dialog

    SEcursorS(0)

    IF f <> l THEN dialog = TUIwaitingON("MACRO PLAY")
    FOR j = f TO l
      IF f <> l THEN TUIwaitingProgress(dialog, 100*(ASC.SE - f)/(l - f))
      ASC.SE = j
      SEcursorS(1)
      FOR i = 1 TO LEN(MACRO.SE)
        SEsetLimits
        func = MACRO_CALL.SE(ASC(MID$(MACRO.SE, i, 1)))
        CALL func
      NEXT i
      SEcursorS(0)
    NEXT j
    
    IF f <> l THEN TUIwaitingOFF(dialog)
    ASC.SE = old
    SEcursorS(1)
    SEdrawCharB
    SEcursorB(1)
  ENDIF
END SUB

SUB SEpixel(setCol AS INTEGER)
  'make pixel in BIG on/off

  LOCAL INTEGER hlp = (1 << (W.SE - CX.SE - 1)), nhlp = INV hlp
 
  IF MOU.SE > -1 THEN GUI CURSOR HIDE
  SEcursorB(0)
  IF ((CHAR.SE(ASC.SE - MINC.SE, CY.SE) AND hlp) = 0) AND (setCol >= 0) THEN
    CHAR.SE(ASC.SE - MINC.SE, CY.SE) = CHAR.SE(ASC.SE - MINC.SE, CY.SE) OR hlp
    SEincRC(ROW.SE, CY.SE + 1)
    SEincRC(COL.SE, CX.SE + 1)
    BOX DX.SE + CX.SE * PIX.SE, DY.SE + CY.SE * PIX.SE, PIX.SE, PIX.SE, 1, RGB(GRAY), RGB(WHITE)
  ELSEIF ((CHAR.SE(ASC.SE - MINC.SE, CY.SE) AND hlp) > 0) AND (setCol <= 0) THEN
    CHAR.SE(ASC.SE - MINC.SE, CY.SE) = CHAR.SE(ASC.SE - MINC.SE, CY.SE) AND nhlp
    SEdecRC(ROW.SE, CY.SE + 1)
    SEdecRC(COL.SE, CX.SE + 1)
    BOX DX.SE + CX.SE * PIX.SE, DY.SE + CY.SE * PIX.SE, PIX.SE, PIX.SE, 1, RGB(GRAY), RGB(NOTBLACK)
  ENDIF
  SEcursorS(1)     
  SEcursorB(1)
  IF MOU.SE > -1 THEN GUI CURSOR SHOW
END SUB

