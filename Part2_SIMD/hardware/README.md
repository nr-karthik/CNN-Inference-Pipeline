Hardware folder layout and quick run steps

Place sources in `verilog/`, data files in `datafiles/`, and the `filelist` in `sim/`.

Run steps (for reference):
```pwsh
cd Part2_SIMD/hardware/sim
iveri filelist
irun
```

The default testbench should cover both 2-bit and 4-bit modes without recompilation.

Expected files (you can add the required number of each file below with appropriate suffixes):
```
datafiles/
    L   2/
        L   out.txt
        L   a0.txt
        L   w0.txt
        ...
        L   w8.txt

    L   4/
        L   out.txt
        L   a0.txt
        L   w0.txt
        ...
        L   w8.txt
```

Please note that on my system, IVerilog doesn't want to cooperate with path name strings that are too long; for example the path `../datafiles/2b_16x8/w_i0_o0_kij0.txt` threw errors in runtime so I had to shorten it to the above. So if you run you may have to rename the files like such.

ACT format

`#time0ic15[msb-lsb],time0ic6[msb-lst],....,time0ic0[msb-lst]#`

`#time1ic15[msb-lsb],time1ic6[msb-lst],....,time1ic0[msb-lst]#`

WGT format

`#oc0ic14[msb-lsb],oc0ic12[msb-lst],....,oc0ic0[msb-lst]#`

`#oc0ic15[msb-lsb],oc0ic13[msb-lst],....,oc0ic1[msb-lst]#`

`#oc1ic14[msb-lsb],oc1ic12[msb-lst],....,oc1ic0[msb-lst]#`

OUT format

`#time0oc7[msb-lsb],time0oc6[msb-lst],....,time0oc0[msb-lst]#`

`#time1oc7[msb-lsb],time1oc6[msb-lst],....,time1oc0[msb-lst]#`

explanation

ACT file should be IC in reverse order, time in forward order.

WGT should be IC in reverse order, splitting alternating EVEN and ODD ICs in next row. OC in forward order.

OUT should be in OC reverse order , time in forward order.

