;
; Procedure to print the entire game board, which is
; 80x25 characters in side.
printBoard PROC
  push si ;X value tracker
  push di ;Y value tracker
  push dx
  call resetCursor
printLp: call getBoardSD ;si/di-->dx
  cmp si, brdMinX ;Check if the current X is left of the dynamic area
  jbe printStd ;Go to the printStandard label
  cmp si, brdMaxX ;check X to the right
  ja printStd
  cmp di, brdMinY ;check Y above top of dynamic
  jbe printStd
  cmp di, brdMaxY ;check Y below bottom
  ja printStd
  jmp brdPuts ;If it's not on some outside of the gameplay area
    ;it must be in the dynamic Board. Jump to the special printer
;
printStd: call printDirect  ;Takes si, di, prints one character
  jmp nextPos ;Go to the next board position finder
;
brdPuts: mov inLoS, 0 ;set the "in line of sight" flag false
  call checkVision  ;Checks the current x/y to the dwarves
  cmp inLoS, 0  ;checkVision may set this to 1, true
  je noLoS  ;if false, use the no line of sight printer
  call visionPrint ;else must be true, use the inLoS printer
  jmp nextPos ;go to the next board position
;
noLoS:  call invisPrint ;print as though the currentLoc is invisible
  jmp nextPos ;go to the next board position
;
nextPos: inc si ;increase X
  cmp si, 80  ;if X would wrap, go to the nextLine label
  jae nextLine
  jmp printLp ;if X is still valid, reloop
;
nextLine: mov si, 0 ;reset X if it's 80+
  inc di  ;increase Y because X wrapped
  cmp di, 25  ;if Y is further than the possible row values
  jae printBX ;jump out of the method
  jmp printLp ;else reloop
;
printBX: pop dx
  pop di
  pop si
  ret
printBoard ENDP
;
; Procedure to get the value of board(si,di) and leave it in dx
; Method is nondestructive to all but cx, leaving the board value in ch
; Starts by conversion of (si,di) to dx as a pair for use in getBoardValue
getBoardSD PROC
  push si ;Input X
  push di ;Input Y
  push dx
  mov dx, di  ;move the Y into dl
  mov cl, 8 ;rotate by 8
  SHL dx, cl  ;move dl into dh
  add dx, si  ;add in the X to dl
  call getBoardValue  ;dh:Y, dl: X
  pop dx
  pop di
  pop si
  ret
getBoardSD ENDP
;
; Procedure to print ch to screen, in the 'normal' color
normColo equ dgrey
printDirect PROC
  push ax
  push bx
  push cx
  mov ah, 9 ;int version
  mov al, ch		;char to print
  mov cx, 1		;number of chars to print
  mov bh, 0			;video page
  mov bl, normColo ;BG/FG color
  int 10h ;print value out
  call incrementCursor
  pop cx
  pop bx
  pop ax
  ret
printDirect ENDP
;
; Procedure to check if either dwarf is within two squares of the
; current character to print. Sets inLoS to 1 if yes.
inLoS db 0
checkVision PROC
  push ax
  push bx
  mov ax, si ;Grab the X value
  sub al, dwarf1[0] ;subtract the first dwarven X value
  add al, 2 ;Adjust by 2 such that a range of -2 is still valid
  cmp al, 4 ;Check if the distance is in the set [0-4]
  ja chDwarf2 ;No means out of sight, check dwarf 2
  mov bx, di  ;Grab the Y value
  sub bl, dwarf1[1] ;subtract the first dwarven Y value
  add bl, 2 ;readjust
  cmp bl, 4 ;check if 0-4
  ja chDwarf2 ;again, out of dwarf1's sight
  call checkCornersLoS  ;check if the location to print is still too far from d1
  cmp inLoS, 1  ;checkCorners will set it to 1 if in sight
  je trueLoS  ;jump to the return segment for inLoS is true
  jmp chDwarf2  ;else check dwarf2
;  
chDwarf2: mov ax, si  ;Repeated documentation skipped
  sub al, dwarf2[0] ;dwarf 2's X
  add al, 2
  cmp al, 4
  ja falseLoS ;if in neither LoS, must be false, exit
  mov bx, di
  sub bl, dwarf2[1] ;dwarf 2's Y
  add bl, 2
  cmp bl, 4
  ja falseLoS
  call checkCornersLoS
  cmp inLoS, 1
  je trueLoS
  jmp falseLoS  ;Jump to false if not in sight
;
trueLoS:  mov inLoS, 1  ;Unnecessary but done for errorchecking
  jmp exitLoS
;
falseLoS: mov inLoS, 0  ;Unnecessary, but made for explicit coverage
  jmp exitLoS
;
exitLoS:  pop bx
  pop ax
  ret
checkVision ENDP
;
; Sub-procedure to checkVision to check if a spot is just out of sight
; NNYNN :Diagram
; NYYYN case 2  (see below)
; YYYYY case 3 (all true)
; NYYYN case 2 again
; NNYNN case 1
checkCornersLoS PROC
  cmp al, 0
  je cornerC1 ;If true, then go to case one
  cmp al, 1
  je cornerC2 ;True--> case two
  cmp al, 2
  je isInSite ;True --> the point is in vision
  cmp al, 3
  je cornerC2 ;Symmetrical about al==2, thus Case 2 again
  cmp al, 4
  je cornerC1 ;Case one again
  jmp noInSite  ;If it's not 0-4 there's something wrong
;
cornerC1: cmp bl, 2 ;check if bl is in the middle
  je isInSite ;if so, true
  jmp noInSite;else not true, then set to false
;
cornerC2: cmp bl, 1 ;check if bl is below 1
  jb noInSite
  cmp bl, 3 ;check if bl is above 3
  ja noInSite
  jmp isInSite  ;if it falls through, it must be true
;
isInSite: mov inLoS, 1
  jmp cornerX
;
noInSite: mov inLoS, 0
  jmp cornerX
;
cornerX:  ret
checkCornersLoS ENDP
;
; Procedure to print dh to screen, in the 'normal' color
; given CH as the value of the board at the current position
; method should be completely nondestructive
visionPrint PROC
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  mov dh, 0 ;Set to 0 for safety in using dx and cx
  mov cl, ch
  mov ch, 0
  mov dl, cl  ;Duplicate the board value
  AND cl, 00001111b ;Grab only the value bits
  AND dl, 11110000b ;Grab only the hp bits
  push cx
  mov cl, 4 ;rotation of 4
  SHR dl, cl  ;shift the left four bits to the right in dl
  pop cx
  mov di, cx  ;add cl to di : this gives the material array values
  mov si, dx  ;add dl to si : this gives the hp array value
  mov dh, hpColors[si]
  mov dl, tileColo[di]
  call colorPairToEGA ;convert the HP and Tile colors into a single color in dh
  mov ah, 9 ;int version
  mov al, gameTile[di]		;char to print
  mov cx, 1		;number of chars to print
  mov bh, 0			;video page
  mov bl, dh ;BG/FG color
  int 10h ;print value out
  call incrementCursor
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
visionPrint ENDP
;
; Print a darkened vision box to the screen instead of what is actually on the tile
brwblack equ 60h
invisPrint PROC
  push ax
  push bx
  push cx
  mov ah, 9 ;int version
  mov al, 178		;char to print, a darkened box
  mov cx, 1		;number of chars to print
  mov bh, 0			;video page
  mov bl, brwblack ;BG/FG color
  int 10h ;print value out
  call incrementCursor
  pop cx
  pop bx
  pop ax
  ret
invisPrint ENDP
;
; Procedure to move the cursor to location dh,dl
; Takes dh, dl as row, col
setCursor	PROC
	push ax
	push bx
	mov ah, 2
	mov bh, 0
	int 10h
	pop bx
	pop ax
  ret
setCursor		ENDP
;
; Procedure to find the location of the cursor and
; save it into dh, dl as row, col.
getCursor	PROC
	push ax
	push bx
	push cx
	mov ah, 3
	mov bh, 0
	int 10h
	pop cx
	pop bx
	pop ax
	ret
getCursor	ENDP
;
; Procedure to increment the location of the cursor,
; wrapping at the edge of the screen. This will go
; past row 24 (the 25th row) if called improperly
incrementCursor	PROC
	push dx
	call getCursor
	inc dl
	cmp dl, 80
	jae wrapCurs
	jmp cursSet
;
wrapCurs: mov dl, 0
	inc dh
;
cursSet: call setCursor
	pop dx
	ret
incrementCursor ENDP
;
;
; Procedure the wraps setCursor, passing 0,0 to DH,DL so that
; the cursor can be set to position 0 when necessary
resetCursor PROC
  push dx
  mov dx, 0
  call setCursor
  pop dx
  ret
resetCursor ENDP
;
; Moves the cursor offscreen for better game presentation/feel
; Uses setCursor with the passed values 25 deci, 0
offScreenCursor PROC
  push dx
  mov dx, 1900h  ;Cursor is set to 26 rows down, 0 places over.
  call setCursor  ;Aka offscreen
  pop dx
;
  end
  