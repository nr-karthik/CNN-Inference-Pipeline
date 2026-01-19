Alpha hardware template

This is an example alpha layout. Follow the same structure as other Parts:
- `verilog/` for sources
- `datafiles/` for weight/activation/psum files
- `sim/` for `filelist` and testbenches

Use the provided example `filelist` to list relative paths to your sources.

```
datafiles/
    L   out.txt
    L   act_tile0.txt
    L   w_i0_o0_kij0.txt
    ...
    L   w_i0_o0_kij8.txt
```

ACT format

`#time0ic15[msb-lsb],time0ic6[msb-lst],....,time0ic0[msb-lst]#`

`#time1ic15[msb-lsb],time1ic6[msb-lst],....,time1ic0[msb-lst]#`

WGT format

`#oc0ic14[msb-lsb],oc0ic12[msb-lst],....,oc0ic0[msb-lst]#`

`#oc0ic15[msb-lsb],oc0ic13[msb-lst],....,oc0ic1[msb-lst]#`

`#oc1ic14[msb-lsb],oc1ic12[msb-lst],....,oc1ic0[msb-lst]#`

OUT format

`#time0oc7[msb-lsb],time0oc6[msb-lst],....,time0oc0[msb-lst]#`

`#time0oc15[msb-lsb],time0oc14[msb-lst],....,time0oc8[msb-lst]#`

Please see software/conv_gen_2b_16x16 for an example as to how to
generate the act/weight/outpput files.