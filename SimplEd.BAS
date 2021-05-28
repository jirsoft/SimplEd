'#MMDEBUG ON
'#DEFINE "DBG ", ""
#DEFINE "DBG ", "'"

OPTION DEFAULT NONE
OPTION EXPLICIT
OPTION BASE 0
OPTION CRLF LF

OPTION BREAK 0
DBG OPTION BREAK 3

'SimpleEd
CONST VERSION.SE = "0.41"


CONST MIN_GRF.SE = "0.11"

CONST ZERO.SE = CHR$(0)
DIM STRING CWD.SE = MM.INFO$(PATH)
CHDIR CWD.SE
DIM STRING LAST.SE = "NewFont", EXPORT.SE = CWD.SE + "SE_EXPORTED"
DIM INTEGER T_TIME.SE = 0, C_TIME.SE = 0

#INCLUDE "TUI.INC"
#INCLUDE "GRF.INC"
'#INCLUDE "../LIB/TUI.INC"
'#INCLUDE "../LIB/GRF.INC"

CONST NAME_CHARS.SE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_!@#%^&*-+()[]"

CONST MINH.SE = 4, MAXH.SE = 64
CONST MINW.SE = 4, MAXW.SE = 64

CONST MINC.SE = 32, MAXC.SE = 255

DIM INTEGER BEGIN.SE = MINC.SE, END.SE = MAXC.SE
DIM INTEGER CMIN.SE = MINC.SE, CMAX.SE = MINC.SE

DIM INTEGER W.SE = 8, H.SE = 8
DIM INTEGER CW.SE = W.SE * (MM.HRES \ W.SE), CD.SE = (MM.HRES - CW.SE) \ 2

DIM INTEGER SHORTCUT.SE(47) 'all 44 shortcuts for SimplEd
DIM STRING SHORTCUT_TXT.SE(25) 'all 26 shortcut help strings for SimplEd


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

DIM INTEGER NUN.SE = -1, NUN_X.SE = -1, NUN_Y.SE = -1, NUN_L.SE = -1, NUN_R.SE = -1, NUN_SET.SE = 0
DIM FLOAT NUNX.SE = 1, NUNY.SE = 1

DIM INTEGER MOU.SE = -1, MOU_X.SE = -1, MOU_Y.SE = -1, MOU_L.SE = -1, MOU_R.SE = -1, MOU_W.SE = -1, MOU_SET.SE = 0
DIM STRING MOU_INF.SE = CWD.SE + "MOUSE.INF"
DIM STRING NUN_INF.SE = CWD.SE + "NUNCHUK.INF"


SEinit
SEinitMouse
'SEinitNunchak

'shortcut 46
ON KEY SHORTCUT.SE(46), SEscreenShot


DO 
  IF MOU.SE > -1 THEN 
    SEtestMouse
  ELSEIF NUN.SE > -1 THEN
    'SEtestNunchuk
  ENDIF
  
  kk = INKEY$
  IF kk<>"" THEN 
    IF MOU.SE > -1 OR NUN.SE > -1 THEN GUI CURSOR HIDE
    SEkey(kk)
    IF MOU.SE > -1 OR NUN.SE > -1 THEN GUI CURSOR SHOW
  ENDIF
LOOP

END

SUB SEinitNunchak
  'try to find nunchak and set NUN.SE to it's port

  LOCAL INTEGER i
  NUN.SE = -1

  FOR i = 1 TO 3
    IF NUN.SE < 0 THEN
      ON ERROR SKIP
      WII NUNCHUK OPEN i
      IF MM.ERRNO = 0 THEN
        NUN.SE = i
      ENDIF
    ENDIF
    IF NUN.SE > 0 THEN
      IF NUN_SET.SE THEN
        LOAD PNG "Mouse.PNG", 640, 50
        GUI CURSOR ON 0, NUNX.SE*NUNCHUK(JX, NUN.SE), NUNY.SE*NUNCHUK(JY, NUN.SE), RGB(GREEN)
        
      ELSEIF TUIquestion("NUNCHUK TEST", "Nunchuk found on port " + STR$(NUN.SE) + ", use it?") THEN
        LOAD PNG "Mouse.PNG", 640, 50
        GUI CURSOR ON 0, NUNX.SE*NUNCHUK(JX, NUN.SE), NUNY.SE*NUNCHUK(JY, NUN.SE), RGB(GREEN)
        ON ERROR SKIP
        OPEN NUN_INF.SE FOR OUTPUT AS #1
        IF MM.ERRNO = 0 THEN
          CLOSE #1
        ENDIF

      ELSE
        NUN.SE = -1

      ENDIF
      EXIT SUB
    ENDIF
  NEXT i
END SUB

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
  FOR i = 0 TO 3
    IF MOU.SE < 0 THEN
      ON ERROR SKIP
      CONTROLLER MOUSE OPEN i
      IF MM.ERRNO = 0 THEN
        MOU.SE = i
      ENDIF
    ENDIF
    IF MOU.SE >= 0 THEN
      IF MOU_SET.SE THEN
        LOAD PNG "Mouse.PNG", 640, 50
        GUI CURSOR ON 0, MOUSE(X, MOU.SE), MOUSE(Y, MOU.SE), RGB(GREEN)
        
      ELSEIF TUIquestion("MOUSE TEST", "Mouse found on port " + STR$(MOU.SE) + ", use it?") THEN
        LOAD PNG "Mouse.PNG", 640, 50
        GUI CURSOR ON 0, MOUSE(X, MOU.SE), MOUSE(Y, MOU.SE), RGB(GREEN)
        ON ERROR SKIP
        OPEN MOU_INF.SE FOR OUTPUT AS #1
        IF MM.ERRNO = 0 THEN
          CLOSE #1
        ENDIF

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

SUB SEtestNunchuk
  'testing NUNCHUK for movement and buttons

  NUNX.SE = W.SE*PIX.SE/256
  NUNY.SE = H.SE*PIX.SE/256
  LOCAL INTEGER x = DX.SE + NUNX.SE*NUNCHUK(JX, NUN.SE)
  LOCAL INTEGER y = DY.SE + NUNY.SE*(255-NUNCHUK(JY, NUN.SE))
  LOCAL INTEGER l = NUNCHUK(Z, NUN.SE), r = NUNCHUK(C, NUN.SE)
  LOCAL INTEGER cxl = WW.SE + 4, cyu = 16, pxy = MIN(MAXW.SE \ W.SE, MAXH.SE \ H.SE), change = 0
  INC cxl, (MAXW.SE - pxy * W.SE) \ 2  
  INC cyu, (MAXH.SE - pxy * H.SE) \ 2  
  LOCAL INTEGER cxr = cxl + pxy * W.SE, cyd = cyu + pxy * H.SE

  IF NUN_X.SE <> x OR NUN_Y.SE <> y THEN 'Nunchuk movement
    GUI CURSOR x, y
    NUN_X.SE = x
    NUN_Y.SE = y
    change = 1
  ENDIF

  IF NUN_L.SE <> l THEN 'left button change
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
    NUN_L.SE = l
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

  IF NUN_R.SE <> r THEN 'right button change
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
    NUN_R.SE = r
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
END SUB

SUB SEtestMouse
  'testing mouse for movement and buttons

  LOCAL INTEGER x = MOUSE(X, MOU.SE), y = MOUSE(Y, MOU.SE)
  LOCAL INTEGER l = MOUSE(L, MOU.SE), r = MOUSE(R, MOU.SE), w = MOUSE(W, MOU.SE)
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

SUB SEquit
  CLS
  CHDIR TUIgetParent(EXPORT.SE)
  OPTION BREAK 3
  IF MOU.SE > -1 THEN CONTROLLER MOUSE CLOSE MOU.SE
  END
END SUB

SUB SEkey(kk AS STRING)
  'main key seting method

  LOCAL INTEGER m = KEYDOWN(7), mm = 0
  LOCAL INTEGER k = ASC(kk)
  LOCAL INTEGER hlp, hlp1, hlp2, i, j, cnt
  LOCAL STRING s
  
  IF (m AND 1) OR (m AND 16) THEN INC mm, 1000 'ALT
  IF (m AND 2) OR (m AND 32) THEN INC mm, 4000 'CTRL
  IF (m AND 4) OR (m AND 64) THEN INC mm, 3000 'WIN
  IF (m AND 8) OR (m AND 128) THEN INC mm, 2000 'SHIFT

  INC k, mm
  DBG TEXT MM.HRES, 0, STR$(k,4)+"/"+ STR$(m,2),"RT",,,RGB(WHITE),RGB(NOTBLACK)

  SELECT CASE k
    'cursor up
    CASE SHORTCUT.SE(00) 
      IF CY.SE > 0 THEN
        SEcursorB(0)
        INC CY.SE, -1
        SEcursorB(1)
      ENDIF

    'fast cursor up
    CASE SHORTCUT.SE(01)  
      SEcursorB(0)
      IF CY.SE > H.SE\4 THEN
        INC CY.SE, -H.SE\4
      ELSE
        CY.SE = 0
      ENDIF
      SEcursorB(1)
     
    'cursor down
    CASE SHORTCUT.SE(02)
      IF CY.SE < H.SE - 1 THEN
        SEcursorB(0)
        INC CY.SE, 1
        SEcursorB(1)
      ENDIF

    'fast cursor down
    CASE SHORTCUT.SE(03)
      SEcursorB(0)
      IF CY.SE+H.SE\4 < H.SE THEN
        INC CY.SE, H.SE\4
      ELSE
        CY.SE = H.SE - 1
      ENDIF
      SEcursorB(1)
     
    'cursor left
    CASE SHORTCUT.SE(04)
      IF CX.SE > 0 THEN
        SEcursorB(0)
        INC CX.SE, -1
        SEcursorB(1)
      ENDIF

    'fast cursor left
    CASE SHORTCUT.SE(05)
      SEcursorB(0)
      IF CX.SE > W.SE\4 THEN
        INC CX.SE, -W.SE\4
      ELSE
        CX.SE = 0
      ENDIF
      SEcursorB(1)
     
    'cursor right
    CASE SHORTCUT.SE(06)
      IF CX.SE < W.SE - 1 THEN
        SEcursorB(0)
        INC CX.SE, 1
        SEcursorB(1)
      ENDIF
        
    'fast cursor right
    CASE SHORTCUT.SE(07)
      SEcursorB(0)
      IF CX.SE+W.SE\4 < W.SE THEN
        INC CX.SE, W.SE\4
      ELSE
        CX.SE = W.SE - 1
      ENDIF
      SEcursorB(1)
     
    'SPACE, pixel ON/OFF
    CASE SHORTCUT.SE(08)
      SEpixel

    'CTRL-C, copy character to clipboard
    CASE SHORTCUT.SE(09)
      SEmacroAdd(13)
      SEtoClipboard
      SEshowClipboard

    'CTRL-V, paste clipboard to character
    CASE SHORTCUT.SE(10)
      SEprepareUndo
      SEmacroAdd(14)
      SEfromClipboard
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'CTRL-S, swap character and clipboard
    CASE SHORTCUT.SE(11)
      SEswapClipboard
      SEshowClipboard
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'CTRL-O, OR-paste clipboard to character
    CASE SHORTCUT.SE(12)
      SEprepareUndo
      SEmacroAdd(15)
      SEorFromClipboard
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'CTRL-Z, undo
    CASE SHORTCUT.SE(13)
      SEundo

    'ALT up, shift (rotate) up
    CASE SHORTCUT.SE(14)
      SEprepareUndo
      SEmacroAdd(8)
      SErotateUp
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT down, shift (rotate) down
    CASE SHORTCUT.SE(15)
      SEprepareUndo
      SEmacroAdd(9)
      SErotateDown
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT left, shift (rotate) left
    CASE SHORTCUT.SE(16)
      SEprepareUndo
      SEmacroAdd(6)
      SErotateLeft
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT right, shift (rotate) right
    CASE SHORTCUT.SE(17)
      SEprepareUndo
      SEmacroAdd(7)
      SErotateRight
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT l,move total left
    CASE SHORTCUT.SE(18)
      SEprepareUndo
      SEmacroAdd(2)
      SEleft
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT r, move total right
    CASE SHORTCUT.SE(19)
      SEprepareUndo
      SEmacroAdd(3)
      SEright
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT t, move total top
    CASE SHORTCUT.SE(20)
      SEprepareUndo
      SEmacroAdd(4)
      SEtop
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT b, move total bottom
    CASE SHORTCUT.SE(21)
      SEprepareUndo
      SEmacroAdd(5)
      SEbottom
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT c, center char
    CASE SHORTCUT.SE(22)
      SEprepareUndo
      SEmacroAdd(1)
      SEcenter
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT h, mirror horizontal
    CASE SHORTCUT.SE(23)
      SEprepareUndo
      SEmacroAdd(11)
      SEhorMirror
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT v, mirror vertical
    CASE SHORTCUT.SE(24)
      SEprepareUndo
      SEmacroAdd(12)
      SEverMirror
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT f, fill character
    CASE SHORTCUT.SE(25)
      SEprepareUndo
      SEfill

    'ALT-e, erase character
    CASE SHORTCUT.SE(26)
      SEprepareUndo
      SEmacroAdd(16)
      SEerase
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)
    
    'ALT i, invert char
    CASE SHORTCUT.SE(27)
      SEprepareUndo
      SEmacroAdd(10)
      SEinvert
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)

    'ALT n,rotate 90` degrees
    CASE SHORTCUT.SE(28)
      SEprepareUndo
      SEmacroAdd(0)
      SEninety
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)      

    'ALT s, special function
    CASE SHORTCUT.SE(29)
      SEprepareUndo
      SEspecial
      SEcursorS(1)
      SEdrawCharB
      SEcursorB(1)
      
    'WIN left, character cursor left
    CASE SHORTCUT.SE(30)
      SEcharCursLeft
      SEprepareUndo
        
    'WIN right, character  cursor right
    CASE SHORTCUT.SE(31)
      SEcharCursRight
      SEprepareUndo

    'WIN f, JUMP to first
    CASE SHORTCUT.SE(32)
      SEcharCurs(BEGIN.SE)
      SEprepareUndo

    'WIN l, JUMP to last
    CASE SHORTCUT.SE(33)
      SEcharCurs(END.SE)
      SEprepareUndo

    'WIN+SHIFT F, MARK first
    CASE SHORTCUT.SE(34)
      SEmarkFirst

    'WIN+SHIFT L, MARK last
    CASE SHORTCUT.SE(35)
      SEmarkLast

    'WIN 0, find minimum font size
    CASE SHORTCUT.SE(36)
      SEminimalSize

    'WIN +, make font bigger
    CASE SHORTCUT.SE(37)
      SEplusSize

    'WIN -, make font smaller
    CASE SHORTCUT.SE(38)
      SEminusSize

    'WIN h, enter new height
    CASE SHORTCUT.SE(39)
      SEnewHeight

    'WIN w, enter new width
    CASE SHORTCUT.SE(40)
      SEnewWidth

    'WIN p, preview font (FIRST to LAS)
    CASE SHORTCUT.SE(41)
      SEpreviewFont

    'WIN d, load default font
    CASE SHORTCUT.SE(42)
      SEdefaultFont

    'WIN i, import file
    CASE SHORTCUT.SE(43)
      SEimport

    'WIN e, export font (FIRST to LAST)
    CASE SHORTCUT.SE(44)
      SEexport
      
    'WIN m, macro functions
    CASE SHORTCUT.SE(45)
      SEmacros

    'shortcut 46 is default PrintScreen (0157), set on row 78 (ON KEY...)

    'WIN q, QUIT SimplEd
    CASE SHORTCUT.SE(47)
      IF TUIquestion("QUIT", "Are you ready to leave me alone?") THEN SEquit

    CASE ELSE
      SEcharCurs(k MOD 1000)
      SEprepareUndo

  END SELECT
END SUB

SUB SEinit
  'init routine

  LOCAL INTEGER i

  MOU_SET.SE = (MM.INFO(FILESIZE MOU_INF.SE) >= 0)
  NUN_SET.SE = (MM.INFO(FILESIZE NUN_INF.SE) >= 0)
  
  MODE 1
  CLS RGB(NOTBLACK) 
  LOAD PNG CWD.SE + "Logo.PNG", 584, 0, 2
  LOAD FONT CWD.SE + "SimplEd.FNT"
  FONT #8
  TEXT WW.SE + MAXW.SE + 16, MAXH.SE - 8, SEdigital(VERSION.SE), "LT",,,RGB(RED), RGB(NOTBLACK)

  IF VAL(VERSION.GRF) < VAL(MIN_GRF.SE) THEN
    TUIwarning("GRF.INC VERSION TOO OLD", "GRF.INC v" + MIN_GRF.SE + " or newer needed, you have v" + VERSION.GRF)
    SEquit
  ENDIF

  RESTORE macro_def
  FOR i = 0 TO BOUND(MACRO_NAME.SE())
    READ MACRO_NAME.SE(i), MACRO_CALL.SE(i)
  NEXT i
  SEreadDefaults
  SEreadConfig("SimplEd.CFG")
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

SUB SEdrawCharSet(start AS INTEGER)
  'draw line of all SMALL characters on bottom of the screen

  LOCAL INTEGER i, dx = CD.SE, dy = MM.VRES - H.SE

  BOX 0, MM.VRES - MAXH.SE, MM.HRES, MAXH.SE, 0, RGB(NOTBLACK), RGB(NOTBLACK)
  IF start <> 0 THEN CMIN.SE = start
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

SUB SEcharCurs(char AS INTEGER)
  'move SMALL cursor to specific char

  IF char>=MINC.SE AND char<= MAXC.SE THEN
    SEcursorS(0)
    SEcursorB(0)
    ASC.SE = char
    IF ASC.SE<CMIN.SE THEN
      DO WHILE CMIN.SE>ASC.SE
        INC CMAX.SE, -1
        INC CMIN.SE, -1
      LOOP
      SEdrawCharSet(CMIN.SE)
    ELSEIF ASC.SE>CMAX.SE THEN
      DO WHILE CMAX.SE<ASC.SE
        INC CMAX.SE
        INC CMIN.SE
      LOOP
      SEdrawCharSet(CMIN.SE)
    ENDIF
    SEdrawCharB
    CX.SE = 0: CY.SE = 0
    SEcursorB(1)
    SEcursorS(1)
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

SUB SEswapClipboard
  'swap char and CLIP

  LOCAL INTEGER i, hh

  FOR i = 0 TO H.SE - 1
    hh = CLIP.SE(i)
    CLIP.SE(i) = CHAR.SE(ASC.SE - MINC.SE, i)
    CHAR.SE(ASC.SE - MINC.SE, i) = hh
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

    LOCAL STRING dialog = TUIwaitingON("EXPORT FONT")
    OPEN EXPORT.SE + "/" + fname FOR OUTPUT AS #1
          
    ?#1,"DefineFont #8"
    ?#1,"  " HEX$(END.SE - BEGIN.SE + 1, 2) HEX$(BEGIN.SE, 2) HEX$(H.SE, 2) HEX$(W.SE, 2)
          
    ?#1,"  ";
    dword = ""
    octaCount = 0
    hexDigits = CINT(W.SE / 4 + 0.49)
    FOR i = BEGIN.SE TO END.SE
      TUIwaitingProgress(dialog, 100*i/(END.SE - BEGIN.SE + 1))
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
    TUIwaitingOFF(dialog)
    'TUIwarning("EXPORT FONT", "File '" + EXPORT.SE + "/" + fname + "' saved")
  ENDIF
END SUB

SUB SEimport
  'import FONT file (from .FNT, .BAS or .INC)

  LOCAL STRING fileName, ext = ".FNT,.BAS,.INC,.PNG,.BMP,.GIF,.JPG"

  fileName = TUIfileSelect(CWD.SE, ext)  
  IF fileName <> "" THEN
    LAST.SE = fileName
    IF INSTR(LAST.SE, ".") THEN
      DO WHILE RIGHT$(LAST.SE, 1) <> "."
        LAST.SE = LEFT$(LAST.SE, LEN(LAST.SE) - 1)
      LOOP
      LAST.SE = LEFT$(LAST.SE, LEN(LAST.SE) - 1)
    ENDIF
    IF INSTR(".BMP.PNG.JPG.GIF", UCASE$(RIGHT$(fileName, 4))) > 0 THEN
      SEimageScan(fileName)
    ELSE
      SEimportFont(fileName)
    ENDIF
    ASC.SE = BEGIN.SE
    CMIN.SE = BEGIN.SE
    CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1 
    SEdrawCharSet
    SEdrawCharB
    SEcursorS(1)   
    SEcursorB(1)
    SEshowClipboard
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
  LOCAL INTEGER m = 0, first, cnt, hexDigits, y, size, pnt = 1
  LOCAL STRING dialog = TUIwaitingON("IMPORT FONT")

  FOR first = MINC.SE TO MAXc.SE
    FOR cnt = 0 TO MAXH.SE - 1
      CHAR.SE(first - MINC.SE, cnt) = 0
    NEXT cnt
  NEXT first
  OPEN f FOR INPUT AS #1
  size = LOF(#1)
  DO WHILE NOT EOF(#1)
    LINE INPUT #1, lin
    INC pnt, LEN(lin)
    TUIwaitingProgress(dialog, 100*pnt/size)
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
  TUIwaitingOFF(dialog)
  CW.SE = W.SE * (MM.HRES \ W.SE)
  CD.SE = (MM.HRES - CW.SE) \ 2
  CMIN.SE = MINC.SE
  CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
  PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
  DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
  DY.SE = (WW.SE - PIX.SE * H.SE) \ 2

  CX.SE = 0
  CY.SE = 0
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
      IF f <> l THEN TUIwaitingProgress(dialog, 100*(j - f)/(l - f))
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

SUB SEimageScan(filePath AS STRING)
  'scan image in filePath for characters

  LOCAL STRING info = GRF.getImgInfo(filePath)
  IF info <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(info, 1, ",")), h = VAL(FIELD$(info, 2, ",")), x, y
    IF w <= MM.HRES AND h <= MM.VRES THEN  
      PAGE WRITE 1
      CLS RGB(NOTBLACK)
      PAGE WRITE 0
      IF GRF.loadImg(filePath, 0, 0, 1, 1) THEN
        PAGE COPY 0 TO 2 'save current page
        PAGE WRITE 1
        LOCAL INTEGER bc = GRF.getLuma(0, 0, 1), luma, fc = 0

        PAGE WRITE 0
        LOCAL STRING dialog = TUIwaitingON("IMAGE SCANNER - B/W CONVERSION")
        PAGE WRITE 1

        FOR y = 0 TO h - 1
          PAGE WRITE 0
          TUIwaitingProgress(dialog, 100 * y / h)
          PAGE WRITE 1
          FOR x = 0 TO w - 1
            luma = GRF.getLuma(x, y, 1)
            IF bc < 128 THEN 'font on dark ?
              IF luma > bc THEN
                PIXEL x, y, RGB(WHITE)
              ELSE
                PIXEL x, y, RGB(NOTBLACK)
              ENDIF            

            ELSE 'font on light ?
              IF luma < bc THEN
                PIXEL x, y, RGB(NOTBLACK)
              ELSE
                PIXEL x, y, RGB(WHITE)
              ENDIF            
            ENDIF
          NEXT x
        NEXT y
        
        IF bc < 128 THEN
          bc = 0 
          fc = 255
        ELSE 
          bc = 255
          fc = 0
        ENDIF
        PAGE WRITE 0
        TUIwaitingOFF(dialog)
        PAGE COPY 1 TO 0 'show B/W image
       
        LOCAL INTEGER nx = VAL(TUIinput("IMAGE SCANNER", "Characters in row:", "", "0123456789"))
        IF nx > 0 AND nx < w THEN
         LOCAL INTEGER ny = VAL(TUIinput("IMAGE SCANNER", "Rows count:", "", "0123456789"))
          IF ny > 0 AND ny < w THEN
            LOCAL INTEGER dx = MIN(MAXW.SE, w \ nx), dy = MIN(MAXH.SE, h \ ny), xx = 0, yy = 0, hlp = 1, alt, m, shft
            LOCAL STRING k = ""
            
            LOCAL STRING inf(7)
            inf(0) = "You should adjust red grid to every character"
            inf(1) = "KEYS:"
            inf(2) = "CRSR      move grid left, right, top or bottom (offset), faster with SHIFT"
            inf(3) = "ALT+CRSR  make characters wider, narrower, higher or smaller"
            inf(4) = "r/R/c/C   more/less character in row/column (extend/reduce grid)"
            inf(5) = "?         this HELP"
            inf(6) = "ENTER     PROCEED to next step"
            inf(7) = "ESC       CANCEL and exit"
            DO 
              PAGE COPY 1 TO 0 'show B/W image
              FOR x = 0 TO nx
                LINE xx + x*dx, yy, xx + x*dx, yy + ny*dy, 1, RGB(RED)
              NEXT x
              FOR y = 0 TO ny
                LINE xx, yy + y*dy, xx + nx*dx, yy + y*dy, 1, RGB(RED)
              NEXT y

              TEXT MM.HRES, 0, STR$(dx)+"x"+STR$(dy), "RT",8,,RGB(RED),RGB(NOTBLACK)
              TEXT MM.HRES, 16, "R"+STR$(ny)+"x C"+STR$(nx), "RT",8,,RGB(RED),RGB(NOTBLACK)
              TEXT MM.HRES, 32, "X"+STR$(xx), "RT",8,,RGB(RED),RGB(NOTBLACK)
              TEXT MM.HRES, 48, "Y"+STR$(yy), "RT",8,,RGB(RED),RGB(NOTBLACK)
              IF hlp THEN
                TUIinfo("SET CHARACTER SIZE", inf())
                hlp = 0
              ENDIF
              DO WHILE k = ""
                k = INKEY$
              LOOP
              
              m = KEYDOWN(7)
              IF (m AND 1) OR (m AND 16) THEN 
                alt = 1
              ELSE
                alt = 0
              ENDIF
              IF (m AND 8) OR (m AND 128) THEN 
                shft = 1
              ELSE
                shft = 0
              ENDIF


              SELECT CASE k
                CASE CHR$(131) 'RIGHT
                  IF alt THEN
                    IF dx < MAXW.SE AND xx + nx*dx < w THEN INC dx  
                  ELSE
                    IF xx + nx*dx < w THEN INC xx
                  ENDIF

                CASE CHR$(163) 'SHIFT RIGHT
                  IF xx + 10 + nx*dx < w THEN INC xx, 10

                CASE CHR$(130) 'LEFT
                  IF alt THEN
                    IF dx > MINW.SE THEN INC dx, -1
                  ELSEIF shft THEN
                    IF xx-10 > 0 THEN INC xx, -10
                  ELSE
                    IF xx > 0 THEN INC xx, -1
                  ENDIF

                CASE CHR$(129) 'DOWN
                  IF alt THEN
                    IF dy < MAXH.SE AND yy + ny*dy < h THEN INC dy
                  ELSE
                    IF yy + ny*dy < h  THEN INC yy
                  ENDIF

                CASE CHR$(161) 'SHIFT DOWN
                  IF yy + 10 + ny*dy < h  THEN INC yy, 10

                CASE CHR$(128) 'UP
                  IF alt THEN
                    IF dy > MINH.SE THEN INC dy, -1
                  ELSEIF shft THEN
                    IF yy-10 > 0 THEN INC yy, -10
                  ELSE
                    IF yy > 0 THEN INC yy, -1
                  ENDIF

                CASE "r"
                  IF (ny + 1)*dy + yy <= h THEN INC ny
                  'dy = MIN(MAXW.SE, h \ ny)

                CASE "R"
                  IF ny > 1 THEN INC ny, -1
                  'dy = MIN(MAXW.SE, h \ ny)

                CASE "c"
                  IF (nx + 1)*dx + xx <= w THEN INC nx
                  'dx = MIN(MAXW.SE, w \ nx)

                CASE "C"
                  IF nx > 1 THEN INC nx, -1
                  'dx = MIN(MAXW.SE, w \ nx)
                
                'CASE "i"
                '  bc = 255 - bc
                '  fc = 255 - fc

                CASE "?"
                  TUIinfo("SET CHARACTER SIZE", inf())

                CASE CHR$(10) 'proceed
                  EXIT DO 

                CASE CHR$(27)
                  PAGE COPY 2 TO 0 'exit
                  PAGE WRITE 0
                  EXIT SUB
                  
              END SELECT
              k = ""  
            LOOP

            LOCAL INTEGER px, py
            LOCAL STRING enabled = "abcdefghijklmnopqrstuvwxyz", mapping = ""
            CAT enabled,           "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            CAT enabled,           " 0123456789,.+-*/!@#$%^&()_={[}]:;<>?\|'~`" + CHR$(34)
            'selection made
            inf(0) = "Now is needed to map every symbol to proper character, so enter"
            inf(1) = "for every symbol keyboard char it should be mapped to."
            inf(2) = "For example press 'A' for symbol that looks like 'A'."
            inf(3) = "Process is case sensitive, so 'a' and 'A' are different!"
            inf(4) = "If you map less than complete set, not mapped symbols will follow."
            inf(5) = "Enabled keys " + LEFT$(enabled, 46)
            inf(6) = "             " + MID$(enabled, 47)
            inf(7) = "BACKSPACE remove last, ENTER finish the process, ESC to cancel"
            TUIinfo("SET CHRACTER MAP",  inf())

            k = ""
            x = 0
            y = 0           
            TEXT x + xx, y + yy, "_", "LT", 7,,RGB(GREEN), RGB(BLACK)
            DO
              DO WHILE k = ""
                k = INKEY$
              LOOP
              IF INSTR(enabled, k) > 0 THEN
                px = x: py = y
                TEXT x + xx, y + yy, k, "LT", 7,,RGB(GREEN), RGB(BLACK)
                INC x, dx
                IF x >= nx*dx THEN
                  x = 0
                  IF y + dy < ny*dy THEN
                    INC y, dy
                  ENDIF
                ENDIF 
                IF x <> px OR y <> py THEN
                  TEXT x + xx, y + yy, "_", "LT", 7,,RGB(GREEN), RGB(BLACK)
                  px = x: py = y
                ENDIF
                IF LEN(mapping) < 128 THEN CAT mapping, k

              ELSE IF k = CHR$(27) THEN
                PAGE COPY 2 TO 0 'exit
                PAGE WRITE 0
                EXIT SUB

              ELSEIF k = CHR$(8) THEN
                IF LEN(mapping) > 0 THEN
                  mapping = LEFT$(mapping, LEN(mapping) - 1)
                  px = x: py = y
                  IF x > 0 THEN
                    INC x, -dx
                  ELSE
                    IF y > 0 THEN
                      x = (nx - 1) * dx
                      INC y, -dy
                    ENDIF
                  ENDIF
                  IF x <> px OR y <> py THEN
                    TEXT x + xx, y + yy, " ", "LT", 7,,RGB(RED), RGB(NOTBLACK)
                    px = x: py = y
                  ENDIF
                ENDIF

              ELSEIF k = CHR$(10) THEN
                EXIT DO
              ENDIF
              k = ""
            LOOP

      
            PAGE WRITE 0
            CLS RGB(NOTBLACK)
            PAGE COPY 2 TO 0 'show SE image

            END.SE = nx * ny + MINC.SE - 1
            H.SE = dy
            W.SE = dx
            IF W.SE MOD 4 <> 0 THEN INC W.SE, 4 - (W.SE MOD 4) 'width should be multiply of 4 
            CW.SE = W.SE * (MM.HRES \ W.SE)
            CD.SE = (MM.HRES - CW.SE) \ 2
            CMIN.SE = MINC.SE
            CMAX.SE = MM.HRES \ W.SE + CMIN.SE - 1   
            PIX.SE = MIN(WW.SE \ W.SE, WW.SE \ H.SE)  
            DX.SE = (WW.SE - PIX.SE * W.SE) \ 2
            DY.SE = (WW.SE - PIX.SE * H.SE) \ 2
            BEGIN.SE = MINC.SE
            dialog = TUIwaitingON("IMAGE SCANNER - CREATE FONT")
            'let the old characters to be here
            'FOR x = MINC.SE TO MAXC.SE
            '  FOR y = 0 TO MAXH.SE - 1
            '    CHAR.SE(x - MINC.SE, y) = 0
            '  NEXT y
            'NEXT x
            LOCAL INTEGER i, rx = xx, ry = yy

            ASC.SE = MINC.SE
            px = ASC.SE: py = MAXC.SE
            FOR i = MINC.SE TO END.SE
              TUIwaitingProgress(dialog, 100 * (i - MINC.SE) / (END.SE - MINC.SE))
              IF LEN(mapping) > 0 THEN
                ASC.SE = ASC(LEFT$(mapping, 1))
                mapping = MID$(mapping, 2)
              ELSE
                IF ASC.SE < MAXC.SE THEN INC ASC.SE
              ENDIF
              px = MAX(px, ASC.SE)
              py = MIN(py, ASC.SE)
              FOR y = 0 TO H.SE - 1
                CHAR.SE(ASC.SE - MINC.SE, y) = 0
                FOR x = 0 TO dx - 1
                  IF x < W.SE THEN
                    IF (GRF.getLuma(rx+x, ry+y, 1)>128 AND fc) OR (GRF.getLuma(rx+x, ry+y, 1)<128 AND bc) THEN
                      CHAR.SE(ASC.SE - MINC.SE, y) = CHAR.SE(ASC.SE - MINC.SE, y) OR (1 << (W.SE - x - 1))
                    ENDIF
                  ENDIF
                NEXT x
              NEXT y
              INC rx, dx
              IF (rx - xx) / dx >= nx THEN
                rx = xx
                INC ry, dy
              ENDIF
            NEXT i   

            END.SE = px
            BEGIN.SE = py            
            TUIwaitingOFF(dialog)
          ENDIF
        ENDIF
        PAGE COPY 2 TO 0
        PAGE WRITE 0
      ELSE

        TUIwarning("IMAGE SCANNER", "Loading error")
      ENDIF
    ENDIF
  ELSE
    TUIwarning("IMAGE SCANNER", "This image can't be scanned")
  ENDIF
END SUB

FUNCTION SEgetMinSize(ch AS INTEGER) AS INTEGER
  'find minimum width and height for given character and return in as MIN_W * 100 + MIN_H

  LOCAL INTEGER w, h, r, c
  LOCAL STRING b

  h = H.SE
  r = 0
  DO WHILE h > 0 AND CHAR.SE(ch - MINC.SE, r) = 0
    INC r
    INC h, -1
  LOOP
  r = H.SE - 1
  DO WHILE h > 0 AND CHAR.SE(ch - MINC.SE, r) = 0
    INC r, -1
    INC h, -1
  LOOP
  w = CHAR.SE(ch - MINC.SE, 0) 
  FOR r = 1 TO H,SE - 1
    w = w OR CHAR.SE(ch - MINC.SE, r)
  NEXT r
  IF w <> 0 THEN
    b = BIN$(w, W.SE)
    w = W.SE
    DO WHILE w > 0 AND LEFT$(b, 1) = "0"
      b = MID$(b, 2)
      INC w, -1
    LOOP
    DO WHILE w > 0 AND RIGHT$(b, 1) = "0"
      b = LEFT$(b, LEN(b) - 1)
      INC w, -1
    LOOP
  ENDIF 
  SEgetMinSize = h + 100 * w
END FUNCTION

SUB SEminimalSize
  'finds minimum size for given font (wihout margins)

  LOCAL INTEGER i, mh = 0, mw = 0

  IF BEGIN.SE <> END.SE THEN LOCAL STRING dialog = TUIwaitingON("FIND FONT MINIMAL SIZE")
  FOR i = BEGIN.SE TO END.SE
    IF BEGIN.SE <> END.SE THEN TUIwaitingProgress(dialog, 100*(i - BEGIN.SE)/(END.SE - BEGIN.SE))
    mh = MAX(mh, SEgetMinSize(i) MOD 100)
    mw = MAX(mw, SEgetMinSize(i) \ 100)
  NEXT i
  IF BEGIN.SE <> END.SE THEN TUIwaitingOFF(dialog)
  TUIwarning("FIND FONT MINIMAL SIZE", "Characters on TOP-RIGHT: " + STR$(mw) + "x" + STR$(mh))
END SUB

FUNCTION SEskipBlank(s AS STRING) AS STRING
  'remove spaces and tabs from left and right

  SEskipBlank = s
  DO WHILE LEFT$(SEskipBlank,1)=" ") OR LEFT$(SEskipBlank,1)=CHR$(9) OR RIGHT$(SEskipBlank,1)=" " OR RIGHT$(SEskipBlank,1)=CHR$(9))
    IF LEFT$(SEskipBlank,1)=" " OR LEFT$(SEskipBlank,1)=CHR$(9) THEN
      SEskipBlank = MID$(SEskipBlank,2)
    ENDIF
    IF RIGHT$(SEskipBlank,1)=" " OR RIGHT$(SEskipBlank,1)=CHR$(9) THEN
      SEskipBlank = LEFT$(SEskipBlank,LEN(SEskipBlank)-1)
    ENDIF
  LOOP
END FUNCTION

FUNCTION SEreplaceChr(s AS STRING) AS STRING
  'replace all {charcode} for CHR$(charcode)
 
  SEreplaceChr = s
  LOCAL INTEGER p=INSTR(1,SEreplaceChr,"{"), p1
  DO WHILE p>0
    p1=INSTR(p,SEreplaceChr,"}")
    IF p1>0 THEN
      SEreplaceChr = LEFT$(SEreplaceChr,p-1) + CHR$(MIN(MAX(VAL(MID$(SEreplaceChr,p+1,p1-p-1)),0),255)) + MID$(SEreplaceChr,p1+1)
      p=INSTR(1,SEreplaceChr,"{")
    ELSE
      p=0
    ENDIF
  LOOP
END FUNCTION

SUB SEhelp
  'print HELP

  LOCAL INTEGER dx = WW.SE + 8, dy = MAXH.SE + 16 + 5
  TEXT dx, dy, SHORTCUT_TXT.SE(00), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(01), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21  
  TEXT dx, dy, SHORTCUT_TXT.SE(02), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(03), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(04), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(05), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21  
  TEXT dx, dy, SHORTCUT_TXT.SE(06), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(07), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(08), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(09), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(10), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(11), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(12), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(13), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21  
  TEXT dx, dy, SHORTCUT_TXT.SE(14), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(15), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(16), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(17), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(18), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(19), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(20), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(21), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(22), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 15  
  TEXT dx, dy, SHORTCUT_TXT.SE(23), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21  
  TEXT dx, dy, SHORTCUT_TXT.SE(24), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21
  TEXT dx, dy, SHORTCUT_TXT.SE(25), "LT",,,RGB(CYAN), RGB(NOTBLACK):INC dy, 21
  TEXT dx, dy, " Any other key jumps to this char", "LT",,,RGB(CYAN), RGB(NOTBLACK)
END SUB

'DIM STRING SHORTCUT.SE(43) 'all 44 shortcuts for SimplEd
SUB SEreadDefaults
  SHORTCUT_TXT.SE(00) = SEreplaceChr("{225} {226} {228} {227}   EDITOR cursor (SHFT fast)")
  SHORTCUT.SE(00) = 0128  'up
  SHORTCUT.SE(01) = 2128  'SHIFT up
  SHORTCUT.SE(02) = 0129  'down
  SHORTCUT.SE(03) = 2161  'SHIFT down
  SHORTCUT.SE(04) = 0130  'left
  SHORTCUT.SE(05) = 2130  'SHIFT left
  SHORTCUT.SE(06) = 0131  'right
  SHORTCUT.SE(07) = 2163  'SHIFT right

  SHORTCUT_TXT.SE(01) = SEreplaceChr("SPACE     INVERT pixel")
  SHORTCUT.SE(08) = 0032  'space

  SHORTCUT_TXT.SE(02) = SEreplaceChr("CTRL c/v  COPY/PASTE to/from CLIP")
  SHORTCUT.SE(09) = 4003  'CTRL c
  SHORTCUT.SE(10) = 4022  'CTRL v

  SHORTCUT_TXT.SE(03) = SEreplaceChr("CTRL s    SWAP char and CLIP")
  SHORTCUT.SE(11) = 4019  'CTRL s

  SHORTCUT_TXT.SE(04) = SEreplaceChr("CTRL o    OR from CLIP (COMBINE)")
  SHORTCUT.SE(12) = 4015  'CTRL o

  SHORTCUT_TXT.SE(05) = SEreplaceChr("CTRL z    UNDO/REDO last change")
  SHORTCUT.SE(13) = 4026  'CTRL z

  SHORTCUT_TXT.SE(06) = SEreplaceChr("ALT {225} {226} {228} {227}  SHIFT character")
  SHORTCUT.SE(14) = 1128  'ALT up
  SHORTCUT.SE(15) = 1129  'ALT down
  SHORTCUT.SE(16) = 1130  'ALT left
  SHORTCUT.SE(17) = 1131  'ALT right

  SHORTCUT_TXT.SE(07) = SEreplaceChr("ALT lrtbc    SHIFT to L/R/T/B/CTR")
  SHORTCUT.SE(18) = 1108  'ALT l
  SHORTCUT.SE(19) = 1114  'ALT r
  SHORTCUT.SE(20) = 1116  'ALT t
  SHORTCUT.SE(21) = 1098  'ALT b
  SHORTCUT.SE(22) = 1099  'ALT c

  SHORTCUT_TXT.SE(08) = SEreplaceChr("ALT h/v      MIRROR horiz/vert")
  SHORTCUT.SE(23) = 1104  'ALT h
  SHORTCUT.SE(24) = 1118  'ALT v

  SHORTCUT_TXT.SE(09) = SEreplaceChr("ALT f        FLOOD FILL char")
  SHORTCUT.SE(25) = 1102  'ALT f

  SHORTCUT_TXT.SE(10) = SEreplaceChr("ALT e        ERASE char")
  SHORTCUT.SE(26) = 1101  'ALT e

  SHORTCUT_TXT.SE(11) = SEreplaceChr("ALT i        INVERT char")
  SHORTCUT.SE(27) = 1105  'ALT i

  SHORTCUT_TXT.SE(12) = SEreplaceChr("ALT n        ROTATE char 90{216}")
  SHORTCUT.SE(28) = 1110  'ALT n

  SHORTCUT_TXT.SE(13) = SEreplaceChr("ALT s        SPECIAL functions")
  SHORTCUT.SE(29) = 1115  'ALT s

  SHORTCUT_TXT.SE(14) = SEreplaceChr("{213} {228} {227}  Choose char to EDIT")
  SHORTCUT.SE(30) = 3130  'WIN left
  SHORTCUT.SE(31) = 3131  'WIN right

  SHORTCUT_TXT.SE(15) = SEreplaceChr("{213} flFL JUMP to/MARK FIRST/LAST char")
  SHORTCUT.SE(32) = 3102  'WIN f
  SHORTCUT.SE(33) = 3108  'WIN l
  SHORTCUT.SE(34) = 5070  'WIN SHIFT F
  SHORTCUT.SE(35) = 5076  'WIN SHIFT L

  SHORTCUT_TXT.SE(16) = SEreplaceChr("{213} 0    Find font's minimal SIZE")
  SHORTCUT.SE(36) = 3048  'WIN 0

  SHORTCUT_TXT.SE(17) = SEreplaceChr("{213} +/-  Make font BIGGER/SMALLER")
  SHORTCUT.SE(37) = 3043  'WIN +
  SHORTCUT.SE(38) = 3045  'WIN -

  SHORTCUT_TXT.SE(18) = SEreplaceChr("{213} h/w  Set font HEIGHT/WIDTH")
  SHORTCUT.SE(39) = 3104  'WIN h
  SHORTCUT.SE(40) = 3119  'WIN w

  SHORTCUT_TXT.SE(19) = SEreplaceChr("{213} p    Preview font")
  SHORTCUT.SE(41) = 3112  'WIN p

  SHORTCUT_TXT.SE(20) = SEreplaceChr("{213} d    Choose default font")
  SHORTCUT.SE(42) = 3100  'WIN d

  SHORTCUT_TXT.SE(21) = SEreplaceChr("{213} i    Import FNT,BAS,INC or IMAGE")
  SHORTCUT.SE(43) = 3105  'WIN i

  SHORTCUT_TXT.SE(22) = SEreplaceChr("{213} e    Export FNT, FIRST to LAST")
  SHORTCUT.SE(44) = 3101  'WIN e

  SHORTCUT_TXT.SE(23) = SEreplaceChr("{213} m    MACRO functions")
  SHORTCUT.SE(45) = 3109  'WIN m

  SHORTCUT_TXT.SE(24) = SEreplaceChr("PrtScr Screenshot to 'SSxxx.BMP'")
  SHORTCUT.SE(46) = 0157  'PrintScreen

  SHORTCUT_TXT.SE(25) = SEreplaceChr("{213} Q    QUIT SimplEd")
  SHORTCUT.SE(47) = 5081  'WIN SHIFT Q
END SUB

SUB SEreadConfig(file AS STRING)
  ON ERROR SKIP
  OPEN CWD.SE+file FOR INPUT AS #1
  IF MM.ERRNO<>0 THEN EXIT SUB

  LOCAL STRING cmd, r, hlp
  LOCAL INTEGER ind
  DO WHILE NOT EOF(#1)
    LINE INPUT #1,r
    r = SEskipBlank(r)
    IF r <> "" THEN
      IF LEFT$(r,1)<>"'" THEN 'comment
        IF LEFT$(r,1)="#" THEN 'command
          cmd = LCASE$(MID$(r,2))
        ELSE
          SELECT CASE cmd
            CASE "help-texts"
              'index|text
              ind = VAL(FIELD$(r, 1, "|"))      'row index (0-25)
              hlp = LEFT$(SEreplaceChr(FIELD$(r, 2, "|")), 35) 'maximum row length to fit on the screen
              IF hlp <> "" THEN
                IF ind>=0 THEN
                  IF ind<=25 THEN
                    SHORTCUT_TXT.SE(ind) = hlp
                  ENDIF
                ENDIF
              ENDIF

            CASE "shortcuts"
              'index|shortcut
              ind = VAL(FIELD$(r, 1, "|"))  'row index (0-47)
              hlp = FIELD$(r, 2, "|")       'special key code
              IF VAL(hlp)<>0 THEN
                IF ind>=0 THEN
                  IF ind<=47 THEN
                    SHORTCUT.SE(ind) = VAL(hlp)
                  ENDIF
                ENDIF
              ENDIF

          END SELECT 
        ENDIF
      ENDIF
    ENDIF
  LOOP
  CLOSE #1      
END SUB


