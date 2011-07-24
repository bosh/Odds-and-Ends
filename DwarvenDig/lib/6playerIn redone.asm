;
; The procedure the 'runs' the game by asking for player input,
; running validation, executing the action, updating the board and players,
; and checking for gameover conditions
playGame PROC
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
playerAction PROC ;Full asking, checking, resolution, and execution of each action
  call askInput
  call validateAction
  call executeAction
  ret
playerAction ENDP
;
; Procedure to print the dwarves over the game board via locations in dwarf1/2XY
printDwarves PROC
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
  mov bl, red
  int 10h
  mov dh, dwarf2[1]
  mov dl, dwarf2[0]
  call setcursor
  mov bl, blue
  int 10h
  pop dx
  pop cx
  pop bx
  pop ax
  ret
printDwarves ENDP
;
;Asks for a player keypress. Valid: WADS, IJKL, M, ESC, else ask again
escKey equ 01bh ;The code for escape as keypress in al
askInput PROC
  push ax
  push bx
keyPlz:  mov ah, 0
  int 16h
  cmp al, escKey
  jne notExit
  mov restartG, 0FFh
  jmp askInEx
notExit: cmp al, 'A'
  jb badInput
  cmp al, 'Z'
  ja upcaseIn
  jmp validKey
;
badInput: jmp keyPlz
;
upcaseIn: sub al, ' ' ;Upcase it
  jmp validKey
;
validKey: cmp al, 'M'
  jne ckKyPlyr
  call toggleMusic
  jmp keyPlz
;
ckKyPlyr:  mov ah, turnNum
  AND ah, 00000001b
  cmp ah, 0
  je ply1go
  jne ply2go
;
ply1go: call targetAsP1
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
ply2go: call targetAsP2
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
p1left: dec targetXY[0]
  jmp askInEx
;
p1down: inc targetXY[1]
  jmp askInEx
;
p1right: inc targetXY[0]
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
p2up: inc targetXY[1]
  jmp askInEx
;
askInEx:  pop bx
  pop ax
  ret
askInput ENDP
;
targetAsP1 PROC
  push dx
  mov dh, dwarf1[1]
  mov dl, dwarf1[0]
  mov targetXY[0], dl
  mov targetXY[1], dh
  pop dx
  ret
targetAsP1 ENDP
;
targetAsP2 PROC
  push dx
  mov dh, dwarf2[1]
  mov dl, dwarf2[0]
  mov targetXY[0], dl
  mov targetXY[1], dh
  pop dx
  ret
targetAsP2 ENDP
;
;
actionOk db 0
validateAction PROC
  push cx
  call getBoardValue ;DH, DL, into ch
  cmp ch, special
  je pickUps
  cmp ch, water
  je badAct
  cmp ch, ' ' ;Space
  je badAct
  jmp okayAct
;
pickUps: call upgradePick
  mov actionOk, 1
  jmp validOut
;
badAct: mov actionOk, 0
  jmp validOut
okayAct: mov actionOk, 1
  jmp validOut
;
validOut:  pop cx
  ret
validateAction ENDP
;
; Pick-related constants and variables
pickStrs db 3, 4, 5, 6
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
upgradePick PROC
  push ax
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
pickChk: TEST byte ptr [di], ironVC
  jnz pik2Iron
  TEST byte ptr [di], diamVC
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
pickUp: NOT al  ;flip the material to off
  AND byte ptr [di], al ;takes the material out
  AND byte ptr [di], 11111100b  ;clears the pick
  or byte ptr [di], ah
;
pickOut: pop di
  pop ax
  ret
upgradePick ENDP
;
;
executeAction PROC
  push bx
  push cx
  push si
  LEA si, dwarf1
  LEA di, dwarf2
  TEST turnNum, 00000001b ;Test for even or odd turn
  jz tarVdorf  ;jump if it's player 1's turn
  XCHG si, di ;swap them if it's the other player's turn
  jmp tarVdorf
;
tarVdorf: cmp [di], dl
  jne noCombat
  cmp dwarf1 [di+1], dh
  jne noCombat
  jmp dorfFite
;
noCombat: call  getBoardValue ;DH,DL into ch
  cmp ch, dirt
  je movDwarf
  jmp mineTile
;
movDwarf: mov [si], dl
  mov [si+1], dh
  jmp execOut
;
mineTile: call mineTarget
  jmp execOut
;
dorfFite: call breakPicks
  jmp execOut
;
execOut: pop si
  pop cx
  pop bx
  ret
executeAction ENDP
;
; Subprocedure of executeAction that mines the rock at the appropriate location
; Takes target[0]-[1] as the X and Y of the mining target, checks turn number
; to determine which pick to use
mineTarget PROC
  push ax
  push bx
  push dx
  push di
  push si
  mov bl, invent1
  mov ah, turnNo
  AND ah, 00000001b ;turn off all but least bit
  cmp ah, 0
  je checkHp
  mov bl, invent2
;
checkHp: AND bl, 00000011b  ;turn off all but pick bits
  mov bh, 0
  mov si, bx
  mov bh, pickStrs[si]
  mov dh, targetXY[1]
  mov dl, targetXY[1]
  call coordinatePairToSingle ;DH, DL to DI
  cmp board[di], bh
  jbe mat2dirt
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
  pop bx
  pop ax
  ret
mineTarget ENDP
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
pickZeroer equ 11111100b ;used in ANDs before setting the pick anew
pick1flag equ 00000000b
pick2flag equ 00000001b
pick3flag equ 00000010b
pick4flag equ 00000011bs
;
giveMiningReward PROC
  push bx
  push si
  push di
  mov bl, turnNo
  AND bl, 00000001b
  LEA si, invent1
  cmp turnNo, 0
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
giveMiningReward ENDP
;
; Procedure to downgrade a dwarf's pick as the result of a combat action
breakPicks PROC
  ret ;currently mocked
breakPicks ENDP
;
toggleMusic PROC
  ret ;mocked
toggleMusic ENDP
;
  end