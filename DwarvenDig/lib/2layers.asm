;blitzpad for vein workings:
  call populateLayers
  int 20h
;
; Layer workings variables
; Mat is an array tracking each layer's material
; Numbered ones are the materials to generate from
layerMat db dirt, 6 dup(?)  ;Layer0 is dirt, which is nonrandom
layer1 db 3 dup(loam), rhyolite ;4
layer2 db 2 dup(loam), 3 dup(rhyolite), lignite ;6
layer3 db 2 dup(rhyolite), 2 dup(lignite), microcline  ;5
layer4 db 2 dup(microcline), gabbro  ;3
layer5 db 2 dup(gabbro), obsidian, microcline  ;4
layer6 db 2 dup(obsidian), gabbro  ;3
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
populatelayers PROC
  call generateLayerMaterials
  call paintRows
  call restartDwarves
  call paintGold
  ;LEA di, downText  ;broken
  ;mov si, 1931  ;broken
  ;call stringIntoBoard  ;broken
  ret
populateLayers ENDP
;
; Sub-procedure to generate, from the layer# arrays paired with the countL#
; values, which material is to be used by each layer, saved into layerMat[#]
; Code here is completely refactorable, but saves no space, as all vars would
; take the same amount of code to pass, regardless
generateLayerMaterials PROC
  push ax
  push bx
  push si
  mov ax, countL1 ;Generate a random from the count
  int 62h ;Generates from 0-(Count-1)
  mov si, ax  ;Move to a usable indexer
  mov bh, layer1[si]  ;Grab the correct material
  mov layerMat[1], bh ;Stick it in the correct slot
  mov ax, countL2 ;Repeat
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
generateLayerMaterials ENDP
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
	mov dl, brdMinX+1	;Row is starting, the X should be at edge
	mov si, -1
nextMat: inc si			;Get next si
	cmp si, 12		;Check if past bound
	ja rowOut		;If yes, end the row
	call setMaterial	;Grab the material needed into bh
  push di
  add di, si
	mov cl, [di]		;Moves the loop count in
  pop di
	cmp cl, 0		;Manual looping
	je nextMat
sameMat: push di
  call coordinatePairToSingle	;(dh,dl)-->di
	mov board[di], bh	;bh is the current material's code
  pop di
	inc dl			;Go to the next X value to place
	dec cl			;Loop decrementer
  cmp cl, 0
  je nextMat
	jmp sameMat
rowOut: inc dh			;Row is done, increment Y to next
	ret
paintOneRow		ENDP
;
; Procedure to grab the appropriate material
; from the randomly generated group and pass it to
; a caller procedure (should only be paintOneRow) in bh
; Takes si as the counter, 0-12, for which one to pass
setMaterial	PROC
	push ax
  push si
	cmp si, 6 ;Check if above 6, as Materials[] goes only from 0-6
	ja reverseM ;Jump to special caser
	mov bh, layerMat[si]  ;Grab the right material
	jmp setMDone
reverseM: mov ax, 12  ;Setup for repositioning to correct material
	sub ax, si  ;Math to get the right index value
	XCHG ax, si ;Same as mov si, ax, for these purposes
	mov bh, layerMat[si]  ;Grab the right material
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
  ret
paintGold ENDP
;
  end
  