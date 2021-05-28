OPTION DEFAULT NONE
OPTION EXPLICIT
OPTION BASE 0

OPTION BREAK 0

DIM STRING key = INKEY$, quit = ""
? "KEY TESTING PROGRAM FOR SimplEd"
? "Press any key for keycode, includeing CTRL, ALT, WIN, SHIFT..."
? "Press q,u,i,t to quit this program"
?
DO WHILE quit<>"quit"
  DO WHILE key = ""
    key = INKEY$
  LOOP
  ? SEkey(key)
  SELECT CASE LEN(quit)
    CASE 0
      IF LCASE$(key) = "q" THEN
        CAT quit, "q"
      ELSE
        quit = ""
      ENDIF

    CASE 1
      IF LCASE$(key) = "u" THEN
        CAT quit, "u"
      ELSE
        quit = ""
      ENDIF

    CASE 2
      IF LCASE$(key) = "i" THEN
        CAT quit, "i"
      ELSE
        quit = ""
      ENDIF

    CASE 3
      IF LCASE$(key) = "t" THEN
        CAT quit, "t"
      ELSE
        quit = ""
      ENDIF

  END SELECT
  key = ""
LOOP

END
FUNCTION SEkey(kk AS STRING) AS STRING

  LOCAL INTEGER m = KEYDOWN(7), mm = 0
  LOCAL INTEGER k = ASC(kk)

  SEkey = ""
  IF (m AND 1) OR (m AND 16) THEN INC mm, 1000:CAT SEkey, "ALT " 'ALT
  IF (m AND 2) OR (m AND 32) THEN INC mm, 4000:CAT SEkey, "CTRL " 'CTRL
  IF (m AND 4) OR (m AND 64) THEN INC mm, 3000:CAT SEkey, "WIN " 'WIN
  IF (m AND 8) OR (m AND 128) THEN INC mm, 2000:CAT SEkey, "SHIFT "'SHIFT

  SELECT CASE kk
    CASE CHR$(128)
      CAT SEkey," up = "  

    CASE CHR$(129), CHR$(161)
      CAT SEkey, " down = "  

    CASE CHR$(130)
      CAT SEkey, " left = "  

    CASE CHR$(131), CHR$(163)
      CAT SEkey, " right = "  

    CASE " "
      CAT SEkey, "SPACE = "  

    CASE ELSE
      IF (m AND 2) OR (m AND 32) THEN
        CAT SEkey, CHR$(96 + k) + " = "
      ELSE  
        CAT SEkey, LCASE$(kk) + " = "  
      ENDIF
  END SELECT

  INC k, mm
  CAT SEkey, STR$(k, 4, 0, "0")
END FUNCTION
