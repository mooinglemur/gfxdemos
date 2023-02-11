#!/usr/bin/env python3

import math
import numpy as np

# Tables for bounding a rotated 64x64 inside of a 64x64

print(".export affinetable_l, affinetable_h\n")

for angle in range(256): # 256 8-bit degrees
    arad = angle/128*math.pi # 2pi radians = full circle
    x2 = (math.cos(arad) * -31.5 - math.sin(arad) * -31.5) + 32
    y2 = (math.sin(arad) * -31.5 + math.cos(arad) * -31.5) + 32
    addr = 0x20000

    while (x2 < 0):
        addr -= 0x1000
        x2 += 64
    
    while (x2 >= 64):
        addr += 0x1000
        x2 -= 64
    
    while (y2 < 0):
        addr -= 0x2000
        y2 += 64
    
    while (y2 >= 64):
        addr += 0x2000
        y2 -= 64

    affine_inc_col = math.cos(arad)
    affine_inc_row = math.sin(arad)

    addr &= 0x1ffff

    # output
    affine_col_dec = 0
    if affine_inc_col < 0:
        affine_col_dec = 1
        affine_inc_col = abs(affine_inc_col)

    affine_row_dec = 0
    if affine_inc_row < 0:
        affine_row_dec = 1
        affine_inc_row = abs(affine_inc_row)

    affine_inc_col_l = int((affine_inc_col - int(affine_inc_col)) * 0xff)
    affine_inc_col_h = int(affine_inc_col) & 0xff

    affine_inc_row_l = int((affine_inc_row - int(affine_inc_row)) * 0xff)
    affine_inc_row_h = int(affine_inc_row) & 0xff

    addr += int(x2) + (int(y2)*64)
    addr_l = addr & 0xff
    addr_m = (addr >> 8) & 0xff
    addr_h = (addr >> 16) & 0x1

    dec = (affine_row_dec << 3)

    affine_inc_col_h |= (affine_col_dec << 7)
    affine_inc_col_h |= 0x24

    affine_inc_row_h |= 0x24

    print("box64_{:d}: ; x_inc: {:.4f} y_inc: {:.4f}".format(angle,affine_inc_col,affine_inc_row))
    print("\t.byte ${:02x},${:02x},${:02x},${:02x},${:02x},${:02x},${:02x}".format(addr_l,addr_m,(addr_h | dec),affine_inc_col_l,affine_inc_col_h,affine_inc_row_l,affine_inc_row_h))

print("affinetable_l:")    
for angle in range(256):
    print("\t.lobytes box64_{0:d}".format(angle))

print("affinetable_h:")    
for angle in range(256):
    print("\t.hibytes box64_{0:d}".format(angle))


