;blitzpad for cluster workings:
  call populateClusters
  int 20h
;
; Cluster workings variables
clustMat db ? ;The value currently being used to populate clusters with
clusterL db loam, lignite, microcline, quartz ;4 The options for a low-value cluster
clusterM db dirt, water, lignite, copper, 2 dup(quartz) ;5 The options for a medium-value cluster
clusterH db water, 2 dup(microcline), gabbro, silver, diamond, 2 dup(obsidian) ;8 The options for a high-value cluster
clusSize db 0  ;Size storage for clusters. 0 is a 1x1, 1 is 2x2, 2 is a 5 tile cross, 3 is 3x3
clusCent db 0, 0  ;Board[] ary location for the upper left part of the vein
clusLwX1 db brdMinX+1, brdMaxX-4  ;Range for X start values for low clusters(one)
clusLwX2 db brdMinX+5, brdMaxX-8  ;Range for X start values (low number 2)
clusMedX db brdMinX+10, brdMaxX-13  ;Range for X start values for medium clusters
clusHigX  db brdMinX+13, brdMaxX-16 ;Range for X start values for high clusters
clusYrng db 10, 16 ;Range for Y start values for all clusters
countCL equ 4
countCM equ 5
countCH equ 8
;
;Populates the game area with clusters, with counts:
;2 LowX1, 2 LowX2, 2 Medium, 1 High
populateClusters PROC
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
populateClusters ENDP
;
; Method to paint a cluster to the game board:
; Given [si] as the location of the X range for the cluster to paint
; with [di] as the location of the materials options array
; and bl as the value for how many material options there are
; and clusYrng as the location of the Y range array
; Using clus(Mat, Cent, Size)
paintCluster PROC
  push si
  push di
  push ax
  push dx
  mov ax, 0
  mov al, [si+1]  ;Get X right bound
  sub al, [si]  ;Offset by X left bound
  int 62h ;Generate an X
  add al, [si]  ;Reincorporate the left bound
  mov clusCent[0], al  ;Save off the key X value
  mov al, clusYrng[1]  ;Get Y lower bound
  sub al, clusYrng[0]  ;Offset by Y upper bound
  int 62h ;Generate a Y
  add al, clusYrng[0]  ;Reincorporate the upper bound
  mov clusCent[1], al  ;Save off the key Y value
  mov al, 4 ;Generate a size, 0-3
  int 62h
  mov clusSize, al  ;Save off the cluster's size
  mov al, bl  ;Generate the material for the certain cluster
  int 62h
  XCHG ax, si ;Flip for indexing use
  push di
  push si
  push dx
  add di, si
  mov dh, [di]
  mov clustMat, dh  ;Grab the material from the options array
  pop dx
  pop si
  pop di
  XCHG si, ax ;Flip them back
  call paintClusterTiles
  pop dx
  pop ax
  pop di
  pop si
  ret
paintCluster ENDP
;
; This procedure should NEVER be called outside of paintCluster, as it is
; variable unsafe, and will likely destroy something stored
paintClusterTiles PROC
  mov bh, clustMat
  mov dh, clusCent[1] ;Grab the Y value for the cluster start location
  mov dl, clusCent[0] ;Grab the X value
  cmp clusSize, 0 ;Size checking mapping to different types of placement
  je cluPoint
  cmp clusSize, 1
  je clSquare
  cmp clusSize, 2
  je cDiamond
  cmp clusSize, 3
  je clustBox
  jmp cluTileX  ;If it didn't match any, something's up, just quit out.
;
cluPoint: call pairToSingleAndPlaced  ;1x1
  jmp cluTileX
;
clSquare: call pairToSingleAndPlaced  ;2x2
  inc dh  ;Go to the bottom left
  call pairToSingleAndPlaced
  inc dl  ;Bottom right
  call pairToSingleAndPlaced
  dec dh  ;Top right
  call pairToSingleAndPlaced
  jmp cluTileX
;
cDiamond: call pairToSingleAndPlaced  ;3x3 with no corners, a plus sign
  inc dh  ;Get to the center point
  call pairToSingleAndPlaced
  inc dh  ;Southern point
  call pairToSingleAndPlaced
  dec dh  ;Back to center
  inc dl  ;Eastern point
  call pairToSingleAndPlaced
  dec dl  ;Back to center
  dec dl  ;And on to Western point
  call pairToSingleAndPlaced
  jmp cluTileX
;
clustBox: call pairToSingleAndPlaced ;3x3 with corners
  inc dl  ;True North
  call pairToSingleAndPlaced
  inc dl  ;Northeast
  call pairToSingleAndPlaced
  inc dh  ;True East
  call pairToSingleAndPlaced
  dec dl  ;Center
  call pairToSingleAndPlaced
  dec dl  ;True West
  call pairToSingleAndPlaced
  inc dh  ;Southwest
  call pairToSingleAndPlaced
  inc dl  ;True South
  call pairToSingleAndPlaced
  inc dl  ;Southeast
  call pairToSingleAndPlaced
  jmp cluTileX
;
cluTileX: ret
paintClusterTiles ENDP
;
; Refactored out subroutine for paintClusterTiles
; Not technically destructive to anything except board[di]
; but calls out of context probably will not lead to good things
pairToSingleAndPlaced PROC
  call coordinatePairToSingle
  mov board[di], bh
  ret
pairToSingleAndPlaced ENDP
;
  end
  