	jmp start ;Skip opening constants
;
; Every nonspecial material in the game, given with HP|Character reference
; divided by the first 4bits for HP, the last for the character reference
; (Character reference is the ascii value at #### in gametile)
; (HP reference is the FG color value at #### in hpcolors)
; To look at any material, you must mask out one half or the other
dirt equ 00000000b
special equ 11110001b
water equ 11110010b
loam equ 00110011b
rhyolite equ 01010100b
lignite equ 01100101b
microcline equ 01110110b
cinnabar equ 01010111b
gabbro equ 10011000b
copper equ 10001001b
silver equ 10101010b
quartz equ 10011011b
diamond equ 11001100b
hematite equ 10101101b
obsidian equ 1101110b
gold equ 10101111b
; The array of materials, in order
materials db dirt, special, water, loam, rhyolite, lignite, microcline, cinnabar
  db gabbro, copper, silver, quartz, diamond, hematite, obsidian, gold  ;16
;Color Constants
black equ 0
blue equ 1
green equ 2
cyan equ 3
red equ 4
magenta equ 5
brown equ 6
lgrey equ 7
dgrey equ 8
bblue equ 9
bgreen equ 0AH
bcyan equ 0BH
bred equ 0CH
bmag equ 0DH
yellow equ 0EH
white equ 0FH
dosColor equ 00000111b  ;Black BG, LGrey FG
;Dirt, Spec, Water, Loam, Rhyo, Lign, Micr, Cina, Gabb, Copp, Silv, Quar, Diam, Hema, Obsi, Gold
gameTile db 46, 35, 247, 176, 177, 156, 174, 233  ;ASCII codes for tiles
              db  254, 157, 36, 37, 4, 126, 178, 42
tileColo db lgrey, black, blue, green, lgrey, dgrey, cyan, bred ;Color codes following tile order
            db dgrey, brown, white, bmag, magenta, red, black, yellow
hpColors db 3 dup(black), 4 dup(lgrey)
  db 4 dup(dgrey), 1 dup(white), 4 dup(black)
; ^:Color to display on the background for each hitpoint level 0-15
;
start: mov si, 0
	mov di, 0
	call cutsceneStart
	call nameQuery
	call displayInstructions
regenGam:  call populateBoard
	call cutsceneGame
	call playGame
	cmp restartG, 0FFh
	je regenGam
	call cutsceneOut
	call cleanUp
	int 20h
;
;Procedure to play opening animation
cutsceneStart PROC
	ret
cutsceneStart ENDP
;
;Procedure to Ask for playernames
nameQuery PROC
	push ax
	mov ax, 1 ;Ax is the passed playernumber parameter
	call askName  ;Get player#ax's name
	mov ax, 2 ;Ax is the passed playernumber parameter
	call askName
	pop ax
	ret
nameQuery ENDP
;
askName PROC  ;Blank the screen and then ask in the middle for name #ax
	call blankScreen
	call printNamescreen
	ret
askName ENDP
;
;Procedure to ask for and echo text to the screen for names
printNameScreen PROC  
	ret
printNameScreen ENDP
;
;
displayInstructions PROC  ;Procedure to put out an instructions page and wait
  call printInstructions
  call waitforAnyKey
  ret
displayInstructions ENDP
;
printInstructions PROC  ;Prints out the instructions ZString
  ret
printInstructions ENDP
;
waitforAnyKey PROC  ;Asks for one keyboard input and then returns
  push ax
  mov ah, 0
  int 16h
  pop ax
  ret
waitforAnyKey ENDP
;
;
populateBoard PROC  ;Procedure to fill the Board array
  call populateLettering
  call populateLayers
  call populateVeins
  call populateClusters  
  ret
populateBoard ENDP
;
populateLettering PROC  ;Procedure to place the non-dynamic parts of the board down
  push si
  push di
  mov si, 0
letterLp: mov di, popsZstr[si]
  add si, 2 ;Double incrementation because we are looking up dws
  cmp di, 0
  je letterOu
  mov board[di], 219 ;Ascii for a full foreground block character
  jmp letterLp
letterOu: pop di
  pop si
  ret
populateLettering ENDP
;
cutsceneGame PROC  ;Procedure to play gamestart animation
  push ax
  call blankScreen
  mov ax, 1
cutsGame: call printGameFrame
  inc ax
  cmp ax, gameFram  ;Check versus the total number of frames
  jb cutsGame
  pop ax
  ret
cutsceneGame ENDP
;
gameFram dw 1
printGameFrame PROC ;Printing of the game intro cutscene frame AX
  ret
printGameFrame ENDP
;
;
; Game-related variables
whoTurn db 0 ;Variable for player number, for which player's turn it is. Should NOR every turn
gameOver db 0 ;Boolean checked in checkVictory, used for playGame looping
counter dw 0 ;Should be incremented every turn end
dwarf1 db 0, 0 ;Storage of dwarf X and Y
dwarf2 db 0, 0 ;Storage of dwarf X and Y
invent1 db 00000000b  ;Dwarf 1's Inventory booleans recording:
invent2 db 00000000b  ;Dwarf 2's Inventory Pick|Pick|Gold|Silver|Copper|Iron|Diamond|Quartz
;
playGame PROC  ;Procedure to run all player actions inside
gameloop: call printBoard
  call playerAction
  call checkVictory
  cmp gameOver, 1
  jne gameloop
  ret
playGame ENDP
;
; Constants the delimit the board into play areas and normal print areas
brdMinX equ 10
brdMaxX equ 61
brdMinY equ 8
brdMaxY equ 21
; Takes values Si and Di, for Row, Column. Prints the appropriate character from board[]
; Procedure for printing the entire 80x25 game board
;
;
cutsceneOut PROC  ;Procedure to display the end animation/winner name and ask to play again
  push ax
  call blankScreen
  mov ax, 0
cutsOut: call printOutFrame
  inc ax
  cmp ax, outFrame ;Check versus the total number of frames
  jb cutsOut
  pop ax
  ret
cutsceneOut ENDP
;
outFrame dw 1
printOutFrame PROC ;Procedure to print the outro cutscene frames
  ret
printOutFrame ENDP
;
;
cleanUp PROC ;Procedure to dump data, reset colors, and return to normal DOS view
  call blankScreen
  call defaultColors
  call backToDos
  ret
cleanUp ENDP
;
defaultColors PROC  ;Procedure to set DOS to normal colors
  ret
defaultColors ENDP
;
backToDos PROC  ;Procedure to clear out keys, dump data, and otherwise give back the computer
  ret
backToDos ENDP
;
;Makes the entire screen empty
;shorthand for newLine(cx=25)
;but requires no variables to use
blankScreen	PROC ;Procedure to print a full black screen
	push cx
	mov cx, 25
	call newLine
	pop cx
	ret
blankScreen	ENDP
;
;Takes DH, DL as two colors
;grabbed from their EQUs:
;Turns DH into a BG/FG color (dh,dl respectively)
;pair as a single variable, instead of two
colorPairToEGA	PROC
	call transformToBGColor
	add dh, dl
	ret
colorPairToEGA	ENDP
;
;Given a color loaded into dh,
;this turns dh into the background
;color version of the color (returns dh)
transformToBGColor	PROC
	push cx
	mov cl, 4
	SHL dh, cl
	pop cx
	ret
transformToBGColor	ENDP
;
;Prints out a user-defined amount of newLines
;Takes CX as parameter for newslines to print
;Is destructive to CX
newLine		PROC
	push ax
	push bx
	push si
	mov bh, 0
	mov ah, 0eh
	cmp cx, 0
	ja lineLoop
	inc cx
	cmp cx, 25
	jb lineLoop
	mov cx, 25
lineLoop: cmp si, cx
	ja lineDone
	mov al, 0ah
	int 10h
	mov al, 0dh
	int 10h
	inc si
	jmp lineLoop
lineDone: pop si
	pop bx
	pop ax
	ret
newLine		ENDP
;
;Takes dh,dl as row,col and returns the board[] value for character at
;that location in ch. Destructive to cx.
getBoardValue PROC
  push di
  push dx
  call coordinatePairToSingle
  mov ch, board[di]
  pop dx
  pop di
  ret
getBoardValue ENDP
;
;Returns the index value in the board[] array from an x,y pair
;(dh, dl) as row, col. Method is destructive, leaving the value in di
coordinatePairToSingle  PROC 
  push ax
  push bx
  push dx
  mov al, dh
  mov bl, 80
  MUL bl  ;Multiplies al by bl and leaves it in ax
  mov dh, 0
  add ax, dx  ;DL is the x value, ax should be only the adjusted DH value 
  mov di, ax  ;Swap ax over to a useable index type
  pop dx
  pop bx
  pop ax
  ret
coordinatePairToSingle ENDP
;
; Large-Scale Game Variables
popsZstr dw 81, 82, 83, 84, 90, 94, 100, 106, 107
  dw 108, 113, 115, 120, 121, 122, 125, 129, 161, 165
  dw 169, 172, 175, 179, 181, 185, 189, 192, 196
  dw 199, 205, 206, 209, 241, 243, 246, 249, 251
  dw 253, 255, 258, 262, 265, 269, 272, 276, 279
  dw 280, 281, 285, 287, 289, 321, 323, 324, 326
  dw 329, 332, 335, 338, 339, 340, 341, 342, 345
  dw 346, 347, 348, 352, 356, 359, 365, 368, 369
  dw 401, 403, 406, 410, 412, 414, 418, 422, 425
  dw 429, 433, 435, 439, 445, 449, 481, 485, 491
  dw 493, 499, 501, 505, 509, 514, 520, 521, 522
  dw 525, 529, 561, 562, 563, 564, 802, 803, 804
  dw 881, 885, 963, 1043, 1121, 1125, 1202
  dw 1203, 1204, 1442, 1443, 1444, 1521, 1525
  dw 1601, 1681, 1683, 1684, 1761, 1764, 1765
  dw 1842, 1843, 1845, 0 ;String of indexes for locations, boardwise, for static blocks
;
board db 2000 dup (' ') ;The game board as a single array
    ;Implementation is such that every spot on the screen has a part in this array
    ;Values 0-79 are each column in the 0 height row, then wrapping 80-159 to 1
    ;height, etc. There is no spot for column returns, those will be custom-handled
    ;in the PrintBoard procedure
;
  end
  