  int 20h
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
; Arrays of options to select from for tiling and board generation
; Some values are doubled up to increase their liklihoods
clusterL db loam, lignite, microcline, quartz ;4
clusterM db dirt, water, lignite, copper, quartz, quartz  ;5
clusterH db water, microcline, microcline, gabbro, silver, diamond, obsidian, obsidian ;8
veinLow db lignite, lignite, cinnabar, cinnabar, copper, copper, silver ;7
veinHigh db cinnabar, copper, silver, silver, hematite, hematite, obsidian ;7
layer1 db loam, loam, loam, rhyolite ;4
layer2 db loam, loam, rhyolite, rhyolite, rhyolite, lignite ;6
layer3 db rhyolite, rhyolite, lignite, lignite, microcline  ;5
layer4 db microcline, microcline, gabbro  ;3
layer5 db gabbro, gabbro, obsidian, microcline  ;4
layer6 db obsidian, obsidian, gabbro  ;3
;Count values represent how many options there are for each liklihood array
;This is done such that the random generation code does not error as long as
;any changes to frequencies in the above and below are made consistently
countCL equ 4
countCM equ 5
countCH equ 8
countVL equ 7
countVH equ 7
countL1 equ 4
countL2 equ 6
countL3 equ 5
countL4 equ 3
countL5 equ 4
countL6 equ 3
;
popsZstr dw 81, 82, 83, 84, 90, 94, 100, 106, 107
  dw 108, 113, 115, 120, 121, 122, 125, 128, 161, 165
  dw 169, 172, 175, 179, 181, 185, 189, 192, 196
  dw 199, 205, 206, 209, 241, 243, 246, 249, 251
  dw 253, 255, 258, 262, 265, 269, 272, 276, 279
  dw 280, 281, 285, 287, 289, 321, 323, 324, 326
  dw 329, 332, 335, 338, 339, 340, 341, 342, 345
  dw 346, 347, 348, 352, 356, 359, 365, 368, 369
  dw 401, 403, 406, 410, 412, 414, 418, 422, 425
  dw 429, 433, 435, 439, 445, 449, 481, 485, 491
  dw 493, 499, 501, 505, 509, 514, 520, 521, 522
  dw 526, 529, 561, 562, 563, 564, 802, 803, 804
  dw 881, 885, 963, 1043, 1121, 1125, 1202
  dw 1203, 1204, 1442, 1443, 1444, 1521, 1525
  dw 1601, 1681, 1683, 1684, 1761, 1764, 1765
  dw 1842, 1843, 1845, 0 ;String of indexes for locations, boardwise, for static blocks
;
  end
  