#!/usr/bin/env python3

import math
import numpy as np

# Tables for bounding a rotated 64x64 inside of a 64x64

print(".export affinetable\n")

for angle in range(64): # 256 8-bit degrees
    arad = angle/128*math.pi # 2pi radians = full circle
    for y1 in np.arange(-31.5, 32,1):
        oob_l = 0
        oob_r = 0
        inside = 0
        start_l = 0
        end_r = 0
        aff_inc_0 = 0
        aff_inc_1 = 0
        for x1 in np.arange(-31.5, 32,1):
            x2 = math.cos(arad) * x1 - math.sin(arad) * y1
            y2 = math.sin(arad) * x1 + math.cos(arad) * y1
            if (x2 <= -32 or x2 >= 32 or y2 <= -32 or y2 >= 32):
                if inside:
                    oob_r += 1
                else:
                    oob_l += 1
            else:
                if inside:
                    end_r = [x2+32,y2+32]
                else:
                    inside = 1
                    start_l = [x2+32,y2+32]
        row = int(y1+32)
        # print("Row: {} Angle: {} ({}°) Left OOB: {} Start: {},{} End: {},{} Right OOB: {}".format(row,angle,angle*360/256,oob_l,start_l[0],start_l[1],end_r[0],end_r[1],oob_r))
        if row == 0:
            affine_inc_row = math.sin(arad)
            affine_inc_col = math.cos(arad)
            print("slope_{:d}:".format(angle))
            print("\t.byte ${:02x},${:02x},${:02x},${:02x} ; Affine x inc {:0.4f}, y inc {:0.4f}".format(int((affine_inc_col-int(affine_inc_col)) * 256) & 0xff, (int(affine_inc_col) & 0xff),int((affine_inc_row-int(affine_inc_row)) * 256) & 0xff, (int(affine_inc_row) & 0xff),affine_inc_col,affine_inc_row))
            print("box64_{:d}:".format(angle))
        print("\t.byte ${:02x},${:02x},${:02x},${:02x} ; Row {}".format(oob_l,int(start_l[0]),int(start_l[1]),oob_r,row))

print("affinetable:")    
for angle in range(64):
    print("\t.word slope_{0:d}, box64_{0:d}".format(angle))

    
