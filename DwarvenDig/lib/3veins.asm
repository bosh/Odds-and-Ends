;blitzpad for vein workings:
  call populateVeins
  int 20h
;
; Vein workings variables
vein1 db brdMinX+1, brdMinX+15 ;The X start value range allowable for the vein
vein2 db brdMinX+10, brdMinX+30
vein3 db brdMaxX-30, brdMaxX-10
vein4 db brdMaxX-15, brdMaxX-1
veinMat db 0 ;The material populating the current vein
veinLow db 2 dup(lignite), 2 dup(cinnabar), 2 dup(copper), silver ;7 The options for a low-value vein
veinHigh db cinnabar, copper, 2 dup (silver), 2 dup(hematite), obsidian ;7 The options for a high-value vein
veinDir db 0  ;Direction storage for vein travel. 0 is down left, 1 is down, 2 is down right
veinMag db 0  ;Magnitude left in the current placement (should never be above 3)
veinXY db 0, 0  ;The current last location for the vein
veinOOB db 0  ;Tracks whether the vein is in an Out of Bounds location
countVL equ 7
countVH equ 7
;
;Populates the board with four veins,
;via use of paintVein(low/high, veinlimits)
;Veins 1 and 4 are low, 2 and 3 are high
populateVeins PROC
  push si
  push di
  push bx
  LEA si, vein1
  LEA di, veinLow
  mov bl, countVL
  call paintVein  ;vein 1
  LEA si, vein2
  LEA di, veinHigh
  mov bl, countVH
  call paintVein  ;vein 2
  LEA si, vein3
  LEA di, veinHigh
  mov bl, countVH
  call paintVein  ;vein 3
  LEA si, vein4
  LEA di, veinHigh
  mov bl, countVL
  call paintVein  ;vein 4
  pop bx
  pop di
  pop si
  ret
populateVeins ENDP
;
;Paints an individual vein to the board
;Called from populateVeins
;Takes si, di as vein#[], veinMaterials[]
;And BL as materials.length
paintVein PROC
  push ax
  mov ax, 0 ;Initialize to 0
  mov veinOOB, 0  ;Initialize the OOB to say 'in-bounds'
  mov al, bl ;Generate 0-#-1 where # is the number of options for the current vein type
  int 62h
  push di
  add di, ax
  mov al, [di] ;Grab the #-1th member of the viable materials for the vein
  pop di
  mov veinMat, al ;Save the vein's material into the current use position
  mov al, [si+1]  ;Grab the right bound tile for the new vein placement
  sub al, [si]  ;Subtract out the left bound, to get a # indicating total # of available tiles
  int 62h
  add al, [si]  ;Re-add the left bound so that you get a real point value
  mov veinXY[0], al ;Set the current placement X = the random start point
  mov veinXY[1], brdMinY+1 ;Or not +1... Set the placement Y to board top
newMag: mov al, 3 ;Generate a magnitude for distance to travel, 1-4 squares
  int 62h
  add al, 1
  mov veinMag, al ;Set up magnitude for current direction
  mov al, 3 ;Generate a direction, 0 = Down Left, 1 = Down, 2 = Down Right
  int 62h
  mov veinDir, al ;Save the current direction
veinLp: call paintVeinTile  ;Also moves to the next available tile and decrements veinMag
  call checkVeinBounds  ;Sets OOB
  cmp veinOOB, 0  ;Jump out if it's OOB
  jne veinDone
  cmp veinMag, 0  ;Make a new magnitude if the current is exhausted
  je newMag
  jmp veinLp  ;Unconditional reloop for more vein painting
veinDone: pop ax
  ret
paintVein ENDP
;
; Place a single tile from a vein to the board. Move the vein location to the
; next valid spot, decrease the magnitude counter. Method has no location
; error checking; that occurs in checkVeinBounds/veinOOB
paintVeinTile PROC
  push cx
  push dx
  push di
  mov dh, veinXY[1] ;Grab the current vein tail's Y
  mov dl, veinXY[0] ;Grab the current vein tail's X
  call coordinatePairToSingle ;Convert dh and dl to di
  cmp board[di], dirt ;Check if we would be placing on dirt
  je nextVTil
  mov cl, veinMat ;Grab the material
  mov board[di], cl ;Save the material to the board
nextVTil:  inc veinXY[1] ;Always move the Y value closer to the bottom edge
  cmp veinDir, 0  ;Move X left if it's traveling direction 0
  je veinDLft
  cmp veinDir, 2  ;Move X right if it's traveling direction 2
  je veinDRt
  jmp vTileOut  ;All other directions, most importantly D1: Straight down, do no side move
;
veinDLft: dec veinXY[0] ;X position left
  jmp vTileOut
;
veinDRt: inc veinXY[0]  ;X position right
  jmp vTileOut
;
vTileOut:  dec veinMag  ;Decrement the magnitude left in this current bend
  pop di
  pop dx
  pop cx
  ret
paintVeinTile ENDP
;
; Marks veinOOB as 1 if the current location is out of bounds.
; Otherwise marks it as 0. Check this for JAE and JBE vs JA and JB
checkVeinBounds PROC
  push cx
  mov veinOOB, 0  ;Set out-of-bounds to false
  mov cl, veinXY[0] ;Grab the X
  mov ch, veinXY[1] ;Y
  cmp cl, brdMinX ;Check X vs min
  jbe ooberror  ;JBE vs JB or JE
  cmp cl, brdMaxX ;X vs max
  jae ooberror
  cmp ch, brdMinY ;Y vs min
  jbe ooberror
  cmp ch, brdMaxY ;Y vs max
  jae ooberror
  jmp oobOut  ;Only hits if not OOB
ooberror: mov veinOOB, 1  ;Set OOB to true
oobOut: pop cx
  ret
checkVeinBounds ENDP
;
  end