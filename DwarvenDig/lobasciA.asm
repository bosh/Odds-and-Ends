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
obsidian equ 11011110b
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
dosColor equ 00000111b			;Black BG, LGrey FG
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
regenGam: mov restartG, 0
	call populateBoard
	call cutsceneGame
	call playGame
	cmp restartG, 0FFh
	je regenGam
	call cutsceneOut
	call cleanUp
	int 20h
;
;Procedure to play opening animation
cutsceneStart		PROC
  push si
  LEA si, frame1
  call printZString
  LEA si, frame2
  call printZString
  pop si
	ret
cutsceneStart		ENDP
;
nameQuery		PROC		;Procedure to Ask for playernames
	push ax
	mov ax, 1			;Ax is the passed playernumber parameter
	call askName			;Get player#ax's name
	mov ax, 2			;Ax is the passed playernumber parameter
	call askName
	pop ax
	ret
nameQuery		ENDP
;
;Blank the screen and then ask in the middle for name #ax
askName			PROC
	call blankScreen
	call printNamescreen
	ret
askName			ENDP
;
printNameScreen		PROC		;Procedure to ask for and echo text to the screen for names
	;push si
	;LEA si, nameText
	;call printZString
	;pop si
	ret
printNameScreen		ENDP
;
;
displayInstructions	PROC		;Procedure to put out an instructions page and wait
	call printInstructions
	call waitforAnyKey
	ret
displayInstructions	ENDP
;
;Prints out the instructions ZString
printInstructions	PROC
	push si
	LEA si, controls
	call printZString
	pop si
	ret
printInstructions	ENDP
;
; Procedure to print an array, ending on a 9 value
printZString PROC
  push ax
  push bx
  push cx
  push dx
  push di
  push si
  call resetCursor
zLp:  mov ah, 0eh
  mov al, byte ptr [si]
  cmp al, 0
  je zOut
  int 10h
  inc si
  jmp zLp
zOut:  pop si
  pop di
  pop dx
  pop cx
  pop bx
  pop ax
  ret
printZString ENDP
;
;Asks for one keyboard input and then returns, discarding the input
waitforAnyKey		PROC
  push ax
	mov ah, 0
	int 16h
	pop ax
	ret
waitforAnyKey		ENDP
;
;
;Procedure to fill the Board array
populateBoard		PROC
	call populateLettering
	call populateLayers
	call populateVeins
	call populateClusters
	call paintGold
	ret
populateBoard ENDP
;
populateLettering	PROC		;Procedure to place the non-dynamic parts of the board down
	push si
	push di
	mov si, 0
letterLp: mov di, popsZstr[si]
	add si, 2			;Double incrementation because we are looking up dws
	cmp di, 0
	je letterOu
	mov board[di], 219		;Ascii for a full foreground block character
	jmp letterLp
letterOu: pop di
	pop si
	ret
populateLettering	ENDP
;
;
gameFram equ 4  ;Count of game intro frames
;Procedure to play gamestart animation
cutsceneGame		PROC
	push ax
	call blankScreen
	mov ax, 1
cutsGame: call printGameFrame
	inc ax
	cmp ax, gameFram		;Check versus the total number of frames
	jb cutsGame
	pop ax
	ret
cutsceneGame		ENDP
;
; Printing of the game intro cutscene frames
printGameFrame		PROC
	;push si
	;LEA si, gameTxt1
	;call printZString
	;LEA si, gameTxt2
	;call printZString
	;call printGoldenIntro
	;pop si
	ret
printGameFrame		ENDP
;
;
; Game-related variables
turnNum db 0				;Variable for player number, for which player's turn it is. Should NOR every turn
gameOver db 0				;Boolean checked in checkVictory, used for playGame looping
;
; Constants the delimit the board into play areas and normal print areas
brdMinX equ 10
brdMaxX equ 61
brdMinY equ 8
brdMaxY equ 21
;
;Sets "gameOver" to 1 if there is a dwarf in a win condition
checkVictory		PROC
	push ax
	mov gameOver, 0
	mov al, invent1
	mov ah, invent2
	AND al, 10000000b
	AND ah, 10000000b
	cmp al, 10000000b
	je setVic
	cmp ah, 10000000b
	je setVic
	jmp ckVicOut
;
setVic: mov gameOver, 1
;
ckVicOut: pop ax
	ret
checkVictory		ENDP
;
;
;Procedure to display the end animation/winner name and ask to play again
cutsceneOut		PROC
  ret ;CURRENTLY UNOPERABLE
	push ax
	call blankScreen
	mov ax, 0
cutsOut: call printOutFrame
	inc ax
	cmp ax, outFrame		;Check versus the total number of frames
	jb cutsOut
	pop ax
	ret
cutsceneOut		ENDP
;
outFrame dw 1
;Procedure to print the outro cutscene frames
printOutFrame 		PROC
  push si
  call resetCursor
  call blankScreen
  LEA si, credits
  call printZString
  call waitforAnyKey
  pop si
	ret
printOutFrame		ENDP
;
;
;Procedure to dump data, reset colors, and return to normal DOS view
cleanUp			PROC
	call blankScreen
	call defaultColors
	call backToDos
	ret
cleanUp			ENDP
;
;Procedure to set DOS to normal colors
defaultColors		PROC
	ret
defaultColors		ENDP
;
;Procedure to clear out keys, dump data, and otherwise give back the computer
backToDos		PROC
	ret
backToDos		ENDP
;
;Procedure to print a full black screen
;Makes the entire screen empty
;shorthand for newLine(cx=25)
;but requires no variables to use
blankScreen		PROC
	push cx
	mov cx, 25
	call newLine
	pop cx
	ret
blankScreen		ENDP
;
;Takes DH, DL as two colors
;grabbed from their EQUs:
;Turns DH into a BG/FG color (dh,dl respectively)
;pair as a single variable, instead of two
colorPairToEGA		PROC
	call transformToBGColor
	add dh, dl
	ret
colorPairToEGA		ENDP
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
newLine			PROC
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
newLine			ENDP
;
;Takes dh,dl as row,col and returns the board[] value for character at
;that location in ch. Destructive to cx.
getBoardValue		PROC
	push di
	push dx
	call coordinatePairToSingle
	mov ch, board[di]
	pop dx
	pop di
	ret
getBoardValue		ENDP
;
;Returns the index value in the board[] array from an x,y pair
;(dh, dl) as row, col. Method is destructive, leaving the value in di
coordinatePairToSingle  PROC 
	push ax
	push bx
	push dx
	mov al, dh
	mov bl, 80
	MUL bl				;Multiplies al by bl and leaves it in ax
	mov dh, 0
	add ax, dx			;DL is the x value, ax should be only the adjusted DH value 
	mov di, ax			;Swap ax over to a useable index type
	pop dx
	pop bx
	pop ax
	ret
coordinatePairToSingle ENDP
;
;
; Layer workings variables
; Mat is an array tracking each layer's material
; Numbered ones are the materials to generate from
layerMat db dirt, 6 dup(?)  		;Layer0 is dirt, which is nonrandom
layer1 db 3 dup(loam), rhyolite 	;4
layer2 db 2 dup(loam), 3 dup(rhyolite), lignite ;6
layer3 db 2 dup(rhyolite), 2 dup(lignite), microcline  ;5
layer4 db 2 dup(microcline), gabbro  	;3
layer5 db 2 dup(gabbro), obsidian, microcline  ;4
layer6 db 2 dup(obsidian), gabbro  	;3
; Counts track how many options there are for the materials in a single layer
countL1 equ 4
countL2 equ 6
countL3 equ 5
countL4 equ 3
countL5 equ 4
countL6 equ 3
;
; These are the board patterns for tiles to place
; materials into. Each row must sum to 51. Tinkering
; with the contents of the array should not break the
; game as long as the exact total of 51 is kept intact.
;
;Layer#: Dirt 1  2  3  4  5  6  5  4  3  2   1  Dirt
row1  db  0,  0, 6, 7, 5, 4, 7, 4, 5, 7, 6,  0, 0
row2  db  0,  1, 5, 8, 6, 4, 3, 4, 6, 8, 5,  1, 0
row3  db  0,  3, 6, 9, 5, 5, 0, 0, 5, 9, 6,  3, 0
row4  db  1,  5, 7, 8, 4, 1, 0, 0, 4, 8, 7,  5, 1
row5  db  3,  7, 9, 5, 3, 0, 0, 0, 0, 5, 9,  7, 3
row6  db  5, 10, 7, 7, 0, 0, 0, 0, 0, 0, 7, 10, 5
row7  db  8, 13, 9, 0, 0, 0, 0, 0, 0, 0, 0, 13, 8
row8  db 12, 12, 3, 0, 0, 0, 0, 0, 0, 0, 0, 12, 12
row9  db 17, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 17
row10 db 20, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 20
row11 db 23,  5, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 23
row12 db 24,  3, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 24
row13 db 51,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0
;
;Populates the board with all layers
populatelayers		PROC
	call generateLayerMaterials
	call paintRows
	call restartDwarves
	;LEA di, downText		;broken
	;mov si, 1931			;broken
	;call stringIntoBoard		;broken
	ret
populateLayers		ENDP
;
; Sub-procedure to generate, from the layer# arrays paired with the countL#
; values, which material is to be used by each layer, saved into layerMat[#]
; Code here is completely refactorable, but saves no space, as all vars would
; take the same amount of code to pass, regardless
generateLayerMaterials	PROC
	push ax
	push bx
	push si
	mov ax, countL1			;Generate a random from the count
	int 62h				;Generates from 0-(Count-1)
	mov si, ax			;Move to a usable indexer
	mov bh, layer1[si]		;Grab the correct material
	mov layerMat[1], bh		;Stick it in the correct slot
	mov ax, countL2			;Repeat
	int 62h
	mov si, ax
	mov bh, layer2[si]
	mov layerMat[2], bh
	mov ax, countL3
	int 62h
	mov si, ax
	mov bh, layer3[si]
 	mov layerMat[3], bh
	mov ax, countL4
	int 62h
	mov si, ax
	mov bh, layer4[si]
	mov layerMat[4], bh
	mov ax, countL5
	int 62h
	mov si, ax
	mov bh, layer5[si]
	mov layerMat[5], bh
	mov ax, countL6
	int 62h
	mov si, ax
	mov bh, layer6[si]
	mov layerMat[6], bh
	pop si
	pop bx
	pop ax
	ret
generateLayerMaterials	ENDP
;
; Procedure to set up the full placement of all layers
; to the board[] array
; This proc. is refactored, and still is huge; a testament to genLayMats's opinion
paintRows		PROC
	push bx
	push cx
	push dx
	push si
	push di
	mov dh, brdMinY+1	;Start dl at top edge, dh is set inside
	LEA di, row1		;Set up for a call
	call paintOneRow	;Paint the first row
	LEA di, row2		;etc...
	call paintOneRow	;DH and DL are passed between each
	LEA di, row3		;paintOneRow call
	call paintOneRow
	LEA di, row4
	call paintOneRow
	LEA di, row5
	call paintOneRow
	LEA di, row6
	call paintOneRow
	LEA di, row7
	call paintOneRow
	LEA di, row8
	call paintOneRow
	LEA di, row9
	call paintOneRow
	LEA di, row10
	call paintOneRow
	LEA di, row11
	call paintOneRow
	LEA di, row12
	call paintOneRow
	LEA di, row13
	call paintOneRow
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	ret
paintRows		ENDP
;
; Paints a single row, given as di
; Should never EVER be called apart from paintRows,
; so there is no safety in terms of variable pushing.
paintOneRow		PROC
	mov dl, brdMinX+1		;Row is starting, the X should be at edge
	mov si, -1
nextMat: inc si				;Get next si
	cmp si, 12			;Check if past bound
	ja rowOut			;If yes, end the row
	call setMaterial		;Grab the material needed into bh
	push di
	add di, si
	mov cl, [di]			;Moves the loop count in
	pop di
	cmp cl, 0			;Manual looping
	je nextMat
sameMat: push di
	call coordinatePairToSingle	;(dh,dl)-->di
	mov board[di], bh		;bh is the current material's code
	pop di
	inc dl				;Go to the next X value to place
	dec cl				;Loop decrementer
	cmp cl, 0
	je nextMat
	jmp sameMat
rowOut: inc dh				;Row is done, increment Y to next
	ret
paintOneRow		ENDP
;
;
; Procedure to grab the appropriate material
; from the randomly generated group and pass it to
; a caller procedure (should only be paintOneRow) in bh
; Takes si as the counter, 0-12, for which one to pass
setMaterial		PROC
	push ax
	push si
	cmp si, 6			;Check if above 6, as Materials[] goes only from 0-6
	ja reverseM			;Jump to special caser
	mov bh, layerMat[si]		;Grab the right material
	jmp setMDone
reverseM: mov ax, 12			;Setup for repositioning to correct material
	sub ax, si			;Math to get the right index value
	XCHG ax, si			;Same as mov si, ax, for these purposes
	mov bh, layerMat[si]		;Grab the right material
setMDone: pop si
	pop ax
	ret
setMaterial		ENDP
;
;
d1XStrt equ 29
d1YStrt equ 19
d2XStrt equ 43
d2YStrt equ 19
; Procedure to relocate the dwarves to their starting positions,
; used when the game restarts a level/regenerates
restartDwarves PROC
  mov dwarf1[0], d1XStrt
  mov dwarf1[1], d1YStrt
  mov dwarf2[0], d2XStrt
  mov dwarf2[1], d2YStrt
  ret
restartDwarves ENDP
;
; Procedure to move a ZString into the board array at location board[si] onward
; Takes di as an LEA'd location of the string and si as the board location to begin
stringIntoBoard		PROC  ;BROKEN
	push si
	push di
	push dx
	mov di, 0
txt2brdL: mov dh, [di]
	cmp dh, 0
	je textDone
	mov board[si], dh
	inc di
	inc si
	cmp si, 2000
	jae textDone
	jmp txt2brdL
textDone: pop dx
	pop di
	pop si
stringIntoBoard		ENDP
;
; Procedure to make sure that gold exists in the game board.
paintGold PROC
	mov board[755], gold
	mov board[756], gold
	mov board[757], gold
  mov board[1691], special
  mov board[1741], special
	ret
paintGold		ENDP
;
;
; Cluster workings variables
clustMat db ? 			;The value currently being used to populate clusters with
clusterL db loam, lignite, microcline, quartz 			;4 The options for a low-value cluster
clusterM db dirt, water, lignite, copper, 2 dup(quartz)  	;5 The options for a medium-value cluster
clusterH db water, 2 dup(microcline), gabbro, silver, diamond, 2 dup(obsidian)	;8 The options for a high-value cluster
clusSize db 0  ;Size storage for clusters. 0 is a 1x1, 1 is 2x2, 2 is a 5 tile cross, 3 is 3x3
clusCent db 0, 0						;Board[] ary location for the upper left part of the vein
clusLwX1 db brdMinX+2, brdMaxX-4  				;Range for X start values for low clusters(one)
clusLwX2 db brdMinX+5, brdMaxX-8				;Range for X start values (low number 2)
clusMedX db brdMinX+10, brdMaxX-13				;Range for X start values for medium clusters
clusHigX  db brdMinX+13, brdMaxX-16				;Range for X start values for high clusters
clusYrng db 10, 16						;Range for Y start values for all clusters
countCL equ 4
countCM equ 5
countCH equ 8
;
;Populates the game area with clusters, with counts:
;2 LowX1, 2 LowX2, 2 Medium, 1 High
populateClusters	PROC
	push di
	push si
	push bx
	LEA di, clusterL
	mov bl, countCL
	LEA si, clusLwX1
	call paintCluster
	call paintCluster
	LEA si, clusLwX2
	call paintCluster
	call paintCluster
	LEA di, clusterM
	mov bl, countCM
	LEA si, clusMedX
	call paintCluster
	call paintCluster
	LEA di, clusterH
	mov bl, countCH
	LEA si, clusHigX
	call paintCluster
	pop bx
	pop si
	pop di
	ret
populateClusters	ENDP
;
;
; Method to paint a cluster to the game board:
; Given [si] as the location of the X range for the cluster to paint
; with [di] as the location of the materials options array
; and bl as the value for how many material options there are
; and clusYrng as the location of the Y range array
; Using clus(Mat, Cent, Size)
paintCluster		PROC
	push si
	push di
	push ax
	push dx
	mov ax, 0
	mov al, [si+1]				;Get X right bound
	sub al, [si]				;Offset by X left bound
	int 62h					;Generate an X
	add al, [si]				;Reincorporate the left bound
	mov clusCent[0], al			;Save off the key X value
	mov al, clusYrng[1]			;Get Y lower bound
	sub al, clusYrng[0]			;Offset by Y upper bound
	int 62h 				;Generate a Y
	add al, clusYrng[0]			;Reincorporate the upper bound
	mov clusCent[1], al			;Save off the key Y value
	mov al, 4				;Generate a size, 0-3
	int 62h
	mov clusSize, al			;Save off the cluster's size
	mov al, bl				;Generate the material for the certain cluster
	int 62h
	XCHG ax, si				;Flip for indexing use
	push di
	push si
	push dx
	add di, si
	mov dh, [di]
	mov clustMat, dh			;Grab the material from the options array
	pop dx
	pop si
	pop di
	XCHG si, ax				;Flip them back
	call paintClusterTiles
	pop dx
	pop ax
	pop di
	pop si
	ret
paintCluster		ENDP
;
; This procedure should NEVER be called outside of paintCluster, as it is
; variable unsafe, and will likely destroy something stored
paintClusterTiles	PROC
	mov bh, clustMat
	mov dh, clusCent[1]			;Grab the Y value for the cluster start location
	mov dl, clusCent[0]			;Grab the X value
	cmp clusSize, 0				;Size checking mapping to different types of placement
	je cluPoint
	cmp clusSize, 1
	je clSquare
	cmp clusSize, 2
	je cDiamond
	cmp clusSize, 3
	je clustBox
	jmp cluTileX				;If it didn't match any, something's up, just quit out.
;	
cluPoint: call pairToSingleAndPlaced		;1x1
	jmp cluTileX
;
clSquare: call pairToSingleAndPlaced		;2x2
	inc dh					;Go to the bottom left
	call pairToSingleAndPlaced
	inc dl					;Bottom right
	call pairToSingleAndPlaced
	dec dh					;Top right
	call pairToSingleAndPlaced
	jmp cluTileX
;
cDiamond: call pairToSingleAndPlaced		;3x3 with no corners, a plus sign
	inc dh					;Get to the center point
	call pairToSingleAndPlaced
	inc dh					;Southern point
	call pairToSingleAndPlaced
	dec dh					;Back to center
	inc dl					;Eastern point
	call pairToSingleAndPlaced
	dec dl					;Back to center
	dec dl					;And on to Western point
	call pairToSingleAndPlaced
	jmp cluTileX
;
clustBox: call pairToSingleAndPlaced		;3x3 with corners
	inc dl					;True North
	call pairToSingleAndPlaced
	inc dl					;Northeast
	call pairToSingleAndPlaced
	inc dh					;True East
	call pairToSingleAndPlaced
	dec dl					;Center
	call pairToSingleAndPlaced
	dec dl					;True West
	call pairToSingleAndPlaced
	inc dh					;Southwest
	call pairToSingleAndPlaced
	inc dl					;True South
	call pairToSingleAndPlaced
	inc dl					;Southeast
	call pairToSingleAndPlaced
	jmp cluTileX
;
cluTileX: ret
paintClusterTiles	ENDP
;
;
; Refactored out subroutine for paintClusterTiles
; Not technically destructive to anything except board[di]
; but calls out of context probably will not lead to good things
pairToSingleAndPlaced	PROC
	call coordinatePairToSingle
	mov board[di], bh
	ret
pairToSingleAndPlaced	ENDP
;
; Vein workings variables
vein1 db brdMinX+1, brdMinX+15			;The X start value range allowable for the vein
vein2 db brdMinX+10, brdMinX+30
vein3 db brdMaxX-30, brdMaxX-10
vein4 db brdMaxX-15, brdMaxX-1
veinMat db 0					;The material populating the current vein
veinLow db 2 dup(lignite), 2 dup(cinnabar), 2 dup(copper), silver	;7 The options for a low-value vein
veinHigh db cinnabar, copper, 2 dup (silver), 2 dup(hematite), obsidian ;7 The options for a high-value vein
veinDir db 0				;Direction storage for vein travel. 0 is down left, 1 is down, 2 is down right
veinMag db 0				;Magnitude left in the current placement (should never be above 3)
veinXY db 0, 0				;The current last location for the vein
veinOOB db 0				;Tracks whether the vein is in an Out of Bounds location
countVL equ 7
countVH equ 7
;
;Populates the board with four veins,
;via use of paintVein(low/high, veinlimits)
;Veins 1 and 4 are low, 2 and 3 are high
populateVeins		PROC
	push si
	push di
	push bx
	LEA si, vein1
	LEA di, veinLow
	mov bl, countVL
	call paintVein				;vein 1
	LEA si, vein2
	LEA di, veinHigh
	mov bl, countVH
	call paintVein				;vein 2
	LEA si, vein3
	LEA di, veinHigh
	mov bl, countVH
	call paintVein				;vein 3
	LEA si, vein4
	LEA di, veinHigh
	mov bl, countVL
	call paintVein				;vein 4
	pop bx
	pop di
	pop si
	ret
populateVeins		ENDP
;
;
; Paints an individual vein to the board
; Called from populateVeins
; Takes si, di as vein#[], veinMaterials[]
; And BL as materials.length
paintVein		PROC
	push ax
	mov ax, 0 ;Initialize to 0
	mov veinOOB, 0					;Initialize the OOB to say 'in-bounds'
	mov al, bl					;Generate 0-#-1 where # is the number of options for the current vein type
	int 62h
	push di
	add di, ax
	mov al, [di]					;Grab the #-1th member of the viable materials for the vein
	pop di
	mov veinMat, al					;Save the vein's material into the current use position
	mov al, [si+1]					;Grab the right bound tile for the new vein placement
	sub al, [si]					;Subtract out the left bound, to get a # indicating total # of available tiles
	int 62h
	add al, [si]					;Re-add the left bound so that you get a real point value
	mov veinXY[0], al				;Set the current placement X = the random start point
	mov veinXY[1], brdMinY+1			;Or not +1... Set the placement Y to board top
newMag: mov al, 3					;Generate a magnitude for distance to travel, 1-4 squares
	int 62h
	add al, 1
	mov veinMag, al					;Set up magnitude for current direction
	mov al, 3					;Generate a direction, 0 = Down Left, 1 = Down, 2 = Down Right
	int 62h
	mov veinDir, al					;Save the current direction
veinLp: call paintVeinTile				;Also moves to the next available tile and decrements veinMag
	call checkVeinBounds				;Sets OOB
	cmp veinOOB, 0					;Jump out if it's OOB
	jne veinDone
	cmp veinMag, 0					;Make a new magnitude if the current is exhausted
	je newMag
	jmp veinLp					;Unconditional reloop for more vein painting
veinDone: pop ax
	ret
paintVein		ENDP
;
; Place a single tile from a vein to the board. Move the vein location to the
; next valid spot, decrease the magnitude counter. Method has no location
; error checking; that occurs in checkVeinBounds/veinOOB
paintVeinTile		PROC
	push cx
	push dx
	push di
	mov dh, veinXY[1]				;Grab the current vein tail's Y
	mov dl, veinXY[0]				;Grab the current vein tail's X
	call coordinatePairToSingle			;Convert dh and dl to di
	cmp board[di], dirt				;Check if we would be placing on dirt
	je nextVTil
	mov cl, veinMat					;Grab the material
	mov board[di], cl				;Save the material to the board
nextVTil:  inc veinXY[1]				;Always move the Y value closer to the bottom edge
	cmp veinDir, 0					;Move X left if it's traveling direction 0
	je veinDLft
	cmp veinDir, 2					;Move X right if it's traveling direction 2
	je veinDRt
	jmp vTileOut					;All other directions, most importantly D1: Straight down, do no side move
;
veinDLft: dec veinXY[0]					;X position left
  jmp vTileOut
;
veinDRt: inc veinXY[0]					;X position right
  jmp vTileOut
;
vTileOut:  dec veinMag					;Decrement the magnitude left in this current bend
	pop di
	pop dx
	pop cx
	ret
paintVeinTile		ENDP
;
; Marks veinOOB as 1 if the current location is out of bounds.
; Otherwise marks it as 0. Check this for JAE and JBE vs JA and JB
checkVeinBounds		PROC
	push cx
	mov veinOOB, 0					;Set out-of-bounds to false
	mov cl, veinXY[0]				;Grab the X
	mov ch, veinXY[1]				;Y
	cmp cl, brdMinX					;Check X vs minx
	jbe ooberror
	cmp cl, brdMaxX					;X vs max
	jae ooberror
	cmp ch, brdMinY					;Y vs min
	jbe ooberror
	cmp ch, brdMaxY					;Y vs max
	jae ooberror
	jmp oobOut					;Only hits if not OOB
ooberror: mov veinOOB, 1				;Set OOB to true
oobOut: pop cx
	ret
checkVeinBounds 	ENDP
;
;
; Procedure to print the entire game board, which is
; 80x25 characters in side.
printBoard		PROC
	push si						;X value tracker
	push di						;Y value tracker
	push dx
	mov si, 0
	mov di, 0
	call resetCursor
printLp: call getBoardSD				;si/di-->dx
	cmp si, brdMinX					;Check if the current X is left of the dynamic area
	jbe printStd					;Go to the printStandard label
	cmp si, brdMaxX					;check X to the right
	ja printStd
	cmp di, brdMinY					;check Y above top of dynamic
  	jbe printStd
	cmp di, brdMaxY					;check Y below bottom
	ja printStd
	jmp brdPuts					;If it's not on some outside of the gameplay area
							;it must be in the dynamic Board. Jump to the special printer
;
printStd: call printDirect				;Takes si, di, prints one character
	jmp nextPos					;Go to the next board position finder
;
brdPuts: mov inLoS, 0					;set the "in line of sight" flag false
	call checkVision				;Checks the current x/y to the dwarves
	cmp inLoS, 0					;checkVision may set this to 1, true
	je noLoS					;if false, use the no line of sight printer
	call visionPrint				;else must be true, use the inLoS printer
	jmp nextPos					;go to the next board position
;
noLoS:  call invisPrint					;print as though the currentLoc is invisible
	jmp nextPos					;go to the next board position
;
nextPos: inc si						;increase X
	cmp si, 80					;if X would wrap, go to the nextLine label
	jae nextLine
	jmp printLp					;if X is still valid, reloop
;
nextLine: mov si, 0					;reset X if it's 80+
	inc di						;increase Y because X wrapped
	cmp di, 25					;if Y is further than the possible row values
	jae printBX					;jump out of the method
	jmp printLp					;else reloop
;
printBX: pop dx
	pop di
	pop si
	ret
printBoard		ENDP
;
; Procedure to get the value of board(si,di) and leave it in dx
; Method is nondestructive to all but cx, leaving the board value in ch
; Starts by conversion of (si,di) to dx as a pair for use in getBoardValue
getBoardSD		PROC
	push si						;Input X
	push di						;Input Y
	push dx
	mov dx, di					;move the Y into dl
	mov cl, 8					;rotate by 8
	SHL dx, cl					;move dl into dh
	add dx, si					;add in the X to dl
	call getBoardValue				;dh:Y, dl: X
	pop dx
	pop di
	pop si
	ret
getBoardSD		ENDP
;
; Procedure to print ch to screen, in the 'normal' color
normColo equ dgrey
printDirect		PROC
	push ax
	push bx
	push cx
	mov ah, 9					;int version
	mov al, ch					;char to print
	mov cx, 1					;number of chars to print
	mov bh, 0					;video page
	mov bl, normColo				;BG/FG color
	int 10h						;print value out
	call incrementCursor
	pop cx
	pop bx
	pop ax
	ret
printDirect		ENDP
;
; Procedure to check if either dwarf is within two squares of the
; current character to print. Sets inLoS to 1 if yes.
inLoS db 0
checkVision		PROC
	push ax
	push bx
	mov ax, si					;Grab the X value
	sub al, dwarf1[0]				;subtract the first dwarven X value
	add al, 2					;Adjust by 2 such that a range of -2 is still valid
	cmp al, 4					;Check if the distance is in the set [0-4]
	ja chDwarf2					;No means out of sight, check dwarf 2
	mov bx, di					;Grab the Y value
	sub bl, dwarf1[1]				;subtract the first dwarven Y value
	add bl, 2					;readjust
	cmp bl, 4					;check if 0-4
	ja chDwarf2					;again, out of dwarf1's sight
	call checkCornersLoS				;check if the location to print is still too far from d1
	cmp inLoS, 1					;checkCorners will set it to 1 if in sight
	je trueLoS					;jump to the return segment for inLoS is true
	jmp chDwarf2					;else check dwarf2
;  
chDwarf2: mov ax, si					;Repeated documentation skipped
	sub al, dwarf2[0]				;dwarf 2's X
	add al, 2
	cmp al, 4
	ja falseLoS					;if in neither LoS, must be false, exit
	mov bx, di
	sub bl, dwarf2[1]				;dwarf 2's Y
	add bl, 2
	cmp bl, 4
	ja falseLoS
	call checkCornersLoS
	cmp inLoS, 1
	je trueLoS
	jmp falseLoS					;Jump to false if not in sight
;
trueLoS:  mov inLoS, 1					;Unnecessary but done for errorchecking
	jmp exitLoS
;
falseLoS: mov inLoS, 0					;Unnecessary, but made for explicit coverage
	jmp exitLoS
;
exitLoS:  pop bx
	pop ax
	ret
checkVision		ENDP
;
; Sub-procedure to checkVision to check if a spot is just out of sight
; NNYNN :Diagram
; NYYYN case 2  (see below)
; YYYYY case 3 (all true)
; NYYYN case 2 again
; NNYNN case 1
checkCornersLoS		PROC
	cmp al, 0
	je cornerC1					;If true, then go to case one
	cmp al, 1
	je cornerC2					;True--> case two
	cmp al, 2
	je isInSite					;True --> the point is in vision
	cmp al, 3
	je cornerC2					;Symmetrical about al==2, thus Case 2 again
	cmp al, 4
	je cornerC1					;Case one again
	jmp noInSite					;If it's not 0-4 there's something wrong
;
cornerC1: cmp bl, 2					;check if bl is in the middle
	je isInSite					;if so, true
	jmp noInSite					;else not true, then set to false
;
cornerC2: cmp bl, 1					;check if bl is below 1
	jb noInSite
	cmp bl, 3					;check if bl is above 3
	ja noInSite
	jmp isInSite					;if it falls through, it must be true
;
isInSite: mov inLoS, 1
	jmp cornerX
;
noInSite: mov inLoS, 0
	jmp cornerX
;
cornerX:  ret
checkCornersLoS		ENDP
;
; Procedure to print dh to screen, in the 'normal' color
; given CH as the value of the board at the current position
; method should be completely nondestructive
visionPrint		PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov dh, 0					;Set to 0 for safety in using dx and cx
	mov cl, ch
	mov ch, 0
	mov dl, cl					;Duplicate the board value
	AND cl, 00001111b				;Grab only the value bits
	AND dl, 11110000b				;Grab only the hp bits
	push cx
	mov cl, 4					;rotation of 4
	SHR dl, cl					;shift the left four bits to the right in dl
	pop cx
	mov di, cx					;add cl to di : this gives the material array values
	mov si, dx					;add dl to si : this gives the hp array value
	mov dh, hpColors[si]
	mov dl, tileColo[di]
	call colorPairToEGA				;convert the HP and Tile colors into a single color in dh
	mov ah, 9					;int version
	mov al, gameTile[di]				;char to print
	mov cx, 1					;number of chars to print
	mov bh, 0					;video page
	mov bl, dh					;BG/FG color
	int 10h						;print value out
	call incrementCursor
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
visionPrint		ENDP
;
; Print a darkened vision box to the screen instead of what is actually on the tile
brwblack equ 60h
invisPrint		PROC
	push ax
	push bx
	push cx
	mov ah, 9					;int version
	mov al, 178					;char to print, a darkened box
	mov cx, 1					;number of chars to print
	mov bh, 0					;video page
	mov bl, brwblack				;BG/FG color
	int 10h						;print value out
	call incrementCursor
	pop cx
	pop bx
	pop ax
	ret
invisPrint		ENDP
;
; Procedure to move the cursor to location dh,dl
; Takes dh, dl as row, col
setCursor		PROC
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
getCursor		PROC
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
getCursor		ENDP
;
; Procedure to increment the location of the cursor,
; wrapping at the edge of the screen. This will go
; past row 24 (the 25th row) if called improperly
incrementCursor		PROC
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
incrementCursor		ENDP
;
;
; Procedure the wraps setCursor, passing 0,0 to DH,DL so that
; the cursor can be set to position 0 when necessary
resetCursor		PROC
	push dx
	mov dx, 0
	call setCursor
	pop dx
	ret
resetCursor		ENDP
;
; Moves the cursor offscreen for better game presentation/feel
; Uses setCursor with the passed values 25 deci, 0
offScreenCursor		PROC
	push dx
	mov dx, 1900h	;Cursor is set to 26 rows down, 00 places over.
	call setCursor	;Aka offscreen
	pop dx
;
;
; The procedure the 'runs' the game by asking for player input,
; running validation, executing the action, updating the board and players,
; and checking for gameover conditions
playGame		PROC
gameloop: call printBoard
	call printDwarves
	call playerAction
	cmp restartG, 0FFh
	jne checkWin
	ret
checkWin: call checkVictory
	cmp gameOver, 1
	jne gameloop
	ret
playGame ENDP
;
restartG db 0
targetXY db 0,0
dwarf1 db 0,0
dwarf2 db 0,0
invent1 db 0
invent2 db 0
;Full asking, checking, resolution, and execution of each action
playerAction		PROC
reAskIn:  call askInput
	call validateAction
	cmp actionOk, 1
	jne reAskIn
	call executeAction
	inc turnNum
	ret
playerAction 		ENDP
;
; Procedure to print the dwarves over the game board via locations in dwarf1/2XY
printDwarves		PROC
	push ax
	push bx
	push cx
	push dx
	mov cx, 1
	mov ah, 09h
	mov al, 1
	mov bh, 0
	mov dh, dwarf1[1]
	mov dl, dwarf1[0]
	call setcursor
	mov bl, bred
	int 10h
	mov dh, dwarf2[1]
	mov dl, dwarf2[0]
	call setcursor
	mov bl, bblue
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
printDwarves		ENDP
;
;Asks for a player keypress. Valid: WADS, IJKL, M, ESC, else ask again
escKey equ 01bh 				;The code for escape as keypress in al
askInput		PROC
	push ax
	push bx
keyPlz:  mov ah, 0
	int 16h
	cmp al, escKey
	jne notExit
  cmp turnNum, 0
  jne resG
  call cleanUp
  int 20h
;
resG:	mov restartG, 0FFh
  mov turnNum, -1
	jmp askInEx
notExit: cmp al, 'A'
	jb badInput
	cmp al, 'Z'
	ja upcaseIn
	jmp validKey
;
badInput: jmp keyPlz
;
upcaseIn: sub al, ' '				;Upcase it
	jmp validKey
;
validKey: cmp al, 'M'
	jne ckKyPlyr
	;call toggleMusic			;Currently no music
	jmp keyPlz
;
ckKyPlyr:  mov ah, turnNum
	AND ah, 00000001b
	cmp ah, 0				;Check if even or odd
	je ply1go				;Jmp if even
	jmp ply2go
;
ply1go: call targetAsP1				;Checking for all p1 move options
	cmp al, 'A'
	je p1left
	cmp al, 'S'
	je p1down
	cmp al, 'D'
	je p1right
	cmp al, 'W'
	je p1up
	jmp badInput
;
ply2go: call targetAsP2				;Checking for all p2 move options
	cmp al, 'J'
	je p2left
	cmp al, 'K'
	je p2down
	cmp al, 'L'
	je p2right
	cmp al, 'I'
	je p2up
	jmp badInput
;
p1left: dec targetXY[0]				;Update the target location
	jmp askInEx
;
p1down: inc targetXY[1]				;Update the target
	jmp askInEx
;
p1right: inc targetXY[0]			;etc
	jmp askInEx
;
p1up: dec targetXY[1]
	jmp askInEx
;
p2left: dec targetXY[0]
	jmp askInEx
;
p2down: inc targetXY[1]
	jmp askInEx
;
p2right: inc targetXY[0]
	jmp askInEx
;
p2up: dec targetXY[1]
	jmp askInEx
;
askInEx:  pop bx
	pop ax
	ret
askInput		ENDP
;
; Sets the targetXY pair to player 1's location
targetAsP1		PROC
	push dx
	mov dh, dwarf1[1]
	mov dl, dwarf1[0]
	mov targetXY[0], dl
	mov targetXY[1], dh
	pop dx
	ret
targetAsP1		ENDP
;
; Sets the targetXY pair to player 2's location
targetAsP2		PROC
	push dx
	mov dh, dwarf2[1]
	mov dl, dwarf2[0]
	mov targetXY[0], dl
	mov targetXY[1], dh
	pop dx
	ret
targetAsP2		ENDP
;
;
actionOk db 0
validateAction PROC
	push cx
	push dx
	mov dl, targetXY[0]
	mov dh, targetXY[1]
	call getBoardValue			;DH, DL, into ch
	pop dx
	cmp ch, special				;
	je pickUps
	cmp ch, water
	je badAct
	cmp ch, ' '				;Space
	je badAct
	jmp okayAct
;
pickUps: call upgradePick
	mov actionOk, 0
	jmp validOut
;
badAct: mov actionOk, 0
	jmp validOut
okayAct: mov actionOk, 1
	jmp validOut
;
validOut:  pop cx
	ret
validateAction		ENDP
;
; Pick-related constants and variables
pickStrs db 2, 3, 4, 6
pick0 equ 00000000b
pick1 equ 00000001b
pick2 equ 00000010b
pick3 equ 00000011b
goldVC equ 1000000b
ironVC equ 01000000b
diamVC equ 00100000b
silverVC equ 00010000b
copperVC equ 00001000b
obsidVC equ 00000100b
; Procedure to upgrade the pick quality of a dwarf on a special location
upgradePick		PROC
	push ax
	push bx
	push di
	mov ah, turnNum
	AND ah, 00000001b
	cmp ah, 0
	je ply1pick
	jne ply2pick
;
ply1pick: LEA di, invent1
	jmp pickChk
ply2pick: LEA di, invent2
	jmp pickChk
;
pickChk: cmp byte ptr [di], ironVC
	jnz pik2Iron
	cmp byte ptr [di], diamVC
	jnz pik2Diam
	TEST byte ptr [di], copperVC
	jnz pik2Copp
	jmp pickOut
;
pik2Iron: mov ah, pick2
	mov al, ironVC
	jmp pickUp
;
pik2Diam: mov ah, pick3
	mov al, diamVC
	jmp pickUp
;
pik2Copp: mov ah, pick1
	mov al, copperVC
	jmp pickUp
;
pickUp: NOT al						;flip the material to off
	AND byte ptr [di], al				;takes the material out
	AND byte ptr [di], 11111100b			;clears the pick
	or byte ptr [di], ah
;
pickOut: pop di
	pop bx
	pop ax
	ret
upgradePick		ENDP
;
;
executeAction		PROC
	push bx
	push cx
	push si
	push dx
	LEA di, dwarf1
	LEA si, dwarf2
	mov bh, turnNum
	AND bh, 00000001b				;Test for even or odd turn
	cmp bh, 0
	je tarVdorf					;jump if it's player 1's turn
	XCHG si, di					;swap them if it's the other player's turn
	jmp tarVdorf
;
tarVdorf: mov dl, targetXY[0]
	mov dh, targetXY[1]
	cmp [si], dl
	jne noCombat
	cmp [si+1], dh
	jne noCombat
	jmp dorfFite
;
noCombat: call getBoardValue				;DH,DL into ch
	cmp ch, dirt
	je movDwarf
	jmp mineTile
;
movDwarf: mov [di], dl
	mov [di+1], dh
	jmp execOut
;
mineTile: call mineTarget
	jmp execOut
;
dorfFite: call breakPicks
	jmp execOut
;
execOut: pop dx
	pop si
	pop cx
	pop bx
	ret
executeAction		ENDP
;
; Subprocedure of executeAction that mines the rock at the appropriate location
; Takes target[0]-[1] as the X and Y of the mining target, checks turn number
; to determine which pick to use
mineTarget		PROC
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	mov bl, invent1
	mov ah, turnNum
	AND ah, 00000001b				;turn off all but least bit
	cmp ah, 0
	je checkHp
	mov bl, invent2
	jmp checkHp
;
checkHp: AND bl, 00000011b				;turn off all but pick bits
	mov bh, 0
	mov si, bx
	mov bh, pickStrs[si]
	mov dh, targetXY[1]
	mov dl, targetXY[0]
	call coordinatePairToSingle			;DH, DL to DI
	mov ch, board[di]
	mov cl, 4
	SHR ch, cl
	cmp ch, bh
	jbe mat2dirt
	SHL bh, cl
	sub board[di], bh
	jmp mineOut
;
mat2dirt: mov bh, board[di]
	call giveMiningReward
	mov board[di], dirt
	jmp mineOut
;
mineOut:  pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
mineTarget		ENDP
;
; giveMiningReward Updates the dwarf's inventory with rewards
; from mining. BH is passed as the material just mined out
;FLAGS:
; To get the inverse setter of a flag, save it to a var, NOT it, and then use in an AND
; Alternatively, just subtract the flag from the inventory byte. WARNING:
; ONLY USE SUBTRACTION IF YOU ARE SURE THAT THE PLAYER HAS THE ITEM.
goldflag equ 10000000b
silverflag equ 01000000b
copperflag equ 00100000b
diamondflag equ 00010000b
obsidianflag equ 00001000b
ironflag equ 00000100b
pickZeroer equ 11111100b		;used in ANDs before setting the pick anew
pick1flag equ 00000000b
pick2flag equ 00000001b
pick3flag equ 00000010b
pick4flag equ 00000011b
;
giveMiningReward	PROC
	push bx
	push si
	push di
	mov bl, turnNum
	AND bl, 00000001b
	LEA si, invent1
	cmp turnNum, 0
	je toMater
	LEA si, invent2
	jmp toMater
;
toMater: AND bh, 00001111b
	mov bl, bh
	mov bh, 0
	mov di, bx
	mov bl, materials[di]
	cmp bl, gold
	je giveGold
	cmp bl, silver
	je giveSilv
	cmp bl, diamond
	je giveDiam
	cmp bl, hematite
	je giveIron
	cmp bl, copper
	je giveCopp
	cmp bl, obsidian
	je giveObsi
	jmp rewardX
;
giveGold: or byte ptr [si], goldflag
	jmp rewardX
;
giveSilv: or byte ptr [si], silverflag
	jmp rewardX
;
giveDiam: or byte ptr [si], diamondflag
	jmp rewardX
;
giveIron: or byte ptr [si], ironflag
	jmp rewardX
;
giveCopp: or byte ptr [si], copperflag
	jmp rewardX
;
giveObsi: or byte ptr [si], obsidianflag
	jmp rewardX
;
rewardX:  pop di
	pop si
	pop bx
	ret
giveMiningReward	ENDP
;
; Procedure to downgrade a dwarf's pick as the result of a combat action
breakPicks		PROC
	ret ;currently mocked
breakPicks 		ENDP
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
;
frame1 db 330 dup(' '), 62 dup('x'), 'X', 17 dup(' '), 23 dup('X')
  db 'xx', 38 dup('X'), 17 dup(' '), 'XXXxx', 21 dup(' '), 'xxXXXXx'
  db 15 dup(' '), 'xxxXXXx', 8 dup('X'), 17 dup(' ')
  db 'XXXx', 24 dup(' '), 'XXx          ___     xx   ', 9 dup('X'), 17 dup(' ')
  db 'Xx', 26 dup(' '), 'xX          /<O>\    x     XxXXXXXX', 17 dup(' ')
  db 'x', 39 dup(' '), '=====           XXXXXXX', 56 dup(' ')
  db '/a   a\        ', 9 dup('X'), 55 dup(' ')
  db '|   |.  |<==^===>xXXxXXXX', 56 dup(' ')
  db '\WwWwW/    ||    xxXXXXX', 56 dup(' ')
  db '_\wWw/_____||    xxXXXXX', 55 dup(' ')
  db '// \W/ \----|E)   xxXXXXX', 54 dup(' ')
  db '//|     |        xxXXxXXXx', 53 dup(' ')
  db '(|){==o==}         xxXXXXXX', 56 dup(' ')
  db '|     |         xXXXXXXX', 29 dup(' ')
  db 'X           x', 14 dup(' '), '|VVVVV|        xXXXXxXXX', 28 dup(' ')
  db 'XXX         XXx', 14 dup(' '), '|| ||       xxx', 8 dup('X'), 27 dup(' ')
  db 'XXXX         XXXx', 13 dup(' '), '|| ||     xxxXXXXxXXXXX', 26 dup(' ')
  db 'XXXXXXxxxx  xXXXXXX    xxxx   /_/ \_\   xxxx', 10 dup('X'), 17 dup(' ')
  db 56 dup('x'), 7 dup('X'), 17 dup(' ')
  db 63 dup('X'), 0AH, 0DH, 0AH, 0DH, 0
 ;
frame2 db 330 dup(' '), 62 dup('x'), 'X', 17 dup(' ')
  db 23 dup('X'), 'xx', 38 dup('X'), 17 dup(' ')       
  db 'XXXxx', 21 dup(' '), 'xxXXXXx               xxxXXX*'
  db 8 dup('X'), 17 dup(' ')
  db 'XXXx', 24 dup(' '), 'XXx          ___     xx   ', 9 dup('X'), 17 dup(' ')
  db 'Xx' 26 dup(' '), 'xX          /<O>\    x     X*XXXXXX', 17 dup(' ')
  db 'x', 39 dup (' '), '=====           XXXXXXX', 56 dup(' ')
  db '/a   a\        ', 9 dup('X'), 55 dup(' ')
  db '|   |.  |<==^===>*XX*XXXX', 56 dup(' ')
  db '\WwWwW/    ||    x*XXXXX', 56 dup (' ')
  db '_\wWw/_____||    xxXXXXX', 55 dup(' ')
  db '// \W/ \----|E)   xxXXXXX', 54 dup(' ')
  db '//|     |        *xXX*XXXx', 53 dup(' ')
  db '(|){==o==}         xxXXXXXX', 56 dup(' ')
  db '|     |         xXXXXXXX', 29 dup(' ')
  db 'X           x', 14 dup(' '), '|VVVVV|        xXXXX*XXX', 28 dup(' ')
  db 'XXX         XXx', 14 dup(' '), '|| ||       xxx', 8 dup('X'), 27 dup(' ')
  db 'XXXX         XXXx', 13 dup(' '), '|| ||     xxxXXXX*XXXXX', 26 dup(' ') 
  db 'XXXXXXxxxx  xXXXXXX    xxxx   /_/ \_\   xxxx', 10 dup('X'), 17 dup(' ')
  db 56 dup('x'), 7 dup('X'), 17 dup(' ')
  db 63 dup('X'), 0AH, 0DH, 0AH, 0DH, 0
;
goldPXs db 5, 7, 10, 10, 11, 14, 14, 17, 19
goldPYs db 65, 67, 66, 69, 68, 65, 69, 70, 68
;
;
controls db 325 dup(' '), 'Welcome to:', 0AH, 0DH, 90 dup(' ')
  db 'Dwarven Dig!', 0AH, 0DH, 165 dup(' '), 'Objective:', 0AH, 0DH
  db 90 dup(' '), 'Mine the fastest to the mountain', 39, 's center'
  db ' to reach the gold first.', 0AH, 0DH 
  db 10 dup(' '), 'Controls:', 0AH, 0DH
  db 15 dup(' '), '(case insensitive)', 0AH, 0DH, 90 dup(' ')
  db 201, 8 dup(205), 209, 12 dup(205), 209
  db 12 dup(205), 187, 0AH, 0DH
  db 10 dup(' '), 186, 'Command | Player One | Player Two ', 186, 0AH, 0DH
  db 10 dup(' '), 204, 8 dup(205), 216, 12 dup(205)
  db  216, 12 dup(205), 185, 0AH, 0DH
  db 10 dup(' '), 186, 'Up      | W          | I          ', 186, 0AH, 0DH
  db 10 dup(' '), 186, 'Left    | A          | J          ', 186, 0AH, 0DH
  db 10 dup(' '), 186, 'Down    | S          | K          ', 186, 0AH, 0DH
  db 10 dup(' '), 186, 'Right   | D          | L          ', 186, 0AH, 0DH
  db 10 dup(' '), 199, 8 dup(196), 193, 4 dup(196), 194
  db 7 dup(196), 193, 12 dup(196), 182, 0AH, 0DH
  db 10 dup(' '), 186, 'Toggle Music | M                  ', 186, 0AH, 0DH
  db 10 dup(' '), 186, 'Restart      | Esc                ', 186, 0AH, 0DH
  db 10 dup(' '), 186, 'Quit         | Esc Twice          ', 186, 0AH, 0DH
  db 10 dup(' '), 200, 13 dup(205), 207, 20 dup(205), 188, 0AH, 0DH
  db 50 dup(' ') '<Press any key to continue>', 0
;
credits db ' ', 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 32 dup(' ')
  db 'Dwarven Dig', 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH
  db 'Thanks for playing!' , 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH
  db 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH, 0AH, 0DH
  db '(C) 2009 Lobascio', 0
;
board db 2000 dup (' ') ;The game board as a single array
    ;Implementation is such that every spot on the screen has a part in this array
    ;Values 0-79 are each column in the 0 height row, then wrapping 80-159 to 1
    ;height, etc. There is no spot for column returns, those will be custom-handled
    ;in the PrintBoard procedure
;
  end
  