import torch
import torch.nn as nn
import numpy as np

singleTileMode = True
reluEnable = True
# Set random seed for reproducibility
torch.manual_seed(42)

# Create the convolution layer
conv = nn.Conv2d(
    in_channels=16,     # 16 input channels
    out_channels=16,    # 8 output channels  
    kernel_size=3,     # 3x3 kernel
    padding=0,         # no padding
    bias=False          # no bias
)

prefix = "tests/2_16x8/" if singleTileMode else "tests/2_16x16/"

# Print layer information
print(f"Conv layer: {conv}")
print(f"Weight shape: {conv.weight.shape}")  # [out_channels, in_channels, kernel_h, kernel_w]
conv.weight = nn.Parameter(torch.randint(-8, 8, (16, 16, 3, 3)), requires_grad=False)

# Create random input tensor: [batch_size, channels, height, width]
# Require 2-bit max (value=4)
input_tensor = torch.randint(4, (16, 6, 6))  # batch_size=1, 8 channels, 6x6 spatial
print(f"Input shape: {input_tensor.shape}")

# Perform convolution
output = conv(input_tensor)
print(f"Output shape: {output.shape}") 

# print(output)
# this part is the same as previously
X = torch.flatten(input_tensor, 1,2)

bit_precision = 2
file = open(prefix+'act_tile0.txt', 'w') #write to file
file.write('#time0ic15[msb-lsb],time0ic6[msb-lst],....,time0ic0[msb-lst]#\n')
file.write('#time1ic15[msb-lsb],time1ic6[msb-lst],....,time1ic0[msb-lst]#\n')
file.write('#................#\n')

for i in range(X.size(1)):  # time step
    for j in range(X.size(0)): # IC #
        X_bin = '{0:02b}'.format(round(X[15-j,i].item()))
        for k in range(bit_precision):
            file.write(X_bin[k])        
        #file.write(' ')  # for visibility with blank between words, you can use
    file.write('\n')
file.close() #close file    

# print(X)

z = lambda x: ("{0:04b}".format(x) if x >= 0 else "1{0:03b}".format(8+x))

# weights will change from before. more OCs = more rows?

W = torch.flatten(conv.weight, 2,3)

bit_precision = 4


# technically this is for both otile0 and otile1 in 1 file, which is a little misleading.
# first half is otile0, second half is otile1.

print(W[:,:,0])
for kij in range(9):
    file = open(f'{prefix}w_i0_o0_kij{kij}.txt', 'w') #write to file
    file.write('#oc0ic14[msb-lsb],oc0ic12[msb-lst],....,oc0ic0[msb-lst]#\n')
    file.write('#oc0ic15[msb-lsb],oc0ic13[msb-lst],....,oc0ic1[msb-lst]#\n')
    file.write('#................#\n')
    for j in range(W.size(0)//2 if singleTileMode else W.size(0)): # per OC (8) -> 16
        
        for i in range(1, W.size(1), 2):  # per EVEN IC
            W_bin = z(round(W[j,15-i,kij].item())) # reverse IC
            for k in range(bit_precision):
                file.write(W_bin[k])        
        
        file.write("\n") # split at middle to fit (7-0) (15-8)
        for i in range(0, W.size(1), 2):  # per ODD IC
            W_bin = z(round(W[j,15-i,kij].item())) # reverse IC
            for k in range(bit_precision):
                file.write(W_bin[k])      
        file.write('\n')
    file.close() #close file   

P = output.flatten(1,2).T
if reluEnable:
    P = nn.ReLU()(P)

print(P.shape)

z = lambda x: ("{0:016b}".format(x) if x >= 0 else "1{0:015b}".format(2**15+x))

bit_precision = 16
file = open(f'{prefix}out.txt', 'w') #write to file

# only want oc 7-0 for single tile mode
file.write('#time0oc7[msb-lsb],time0oc6[msb-lst],....,time0oc0[msb-lst]#\n')
file.write('#time0oc15[msb-lsb],time0oc14[msb-lst],....,time8oc0[msb-lst]#\n')
file.write('#................#\n')
for j in range(P.size(0)): # per TIMESTEP
    for i in range(P.size(1)//2 if singleTileMode else P.size(1)):  # per OC/col
        # want to write 7:0
        # then 15:8
        W_bin = z(round(P[j,(7-i) if i < 8 else (15-i+8)].item())) # reverse OC
        for k in range(bit_precision):
            file.write(W_bin[k])        
        
        if (i == 7 and not singleTileMode):
            file.write('\n') 
    file.write('\n')
file.close() #close file 

np.set_printoptions(linewidth=150)
print(np.array(P))


'''
weights [0]
tensor([[ 0, -4,  1, -7,  5,  7,  1, -4,  2, -3,  4,  4,  1, -6, -5, -6],
        [ 7,  2,  7,  2,  6,  3,  0,  0, -4, -4,  7,  2,  7, -1,  4, -3],
        [-2,  0, -1,  6,  1, -7,  1, -4, -3, -6,  3, -4, -8, -5, -6, -4],
        [-2, -3, -1,  0, -1,  1,  5,  0, -4,  6, -7, -6,  5,  5,  6,  5],
        [-7,  6,  1, -8, -6,  5,  0,  2, -3, -8,  3, -8, -6, -4,  1, -5],
        [ 2, -4, -4, -4,  7,  1,  4, -1, -1, -4,  1,  2,  1, -4, -8,  2],
        [-7,  4, -6, -5,  2,  3, -7, -7,  5,  4,  0, -6, -4, -5,  7, -2],
        [ 0, -7, -4,  4,  7,  2,  0, -8,  0, -5,  7,  6, -6,  5, -6, -2],
        [-8, -3,  4,  4, -3, -4, -7,  2, -5,  4,  0,  7, -4, -8,  7, -2],
        [-4, -5, -4,  6,  0, -5, -7,  4,  2, -1,  5, -4,  0,  5, -3, -7],
        [-6, -8, -2,  1, -1, -4,  4,  3,  2,  1, -6,  1, -2,  1, -7, -6],
        [ 6, -8,  2, -3,  5, -5,  5, -6, -4,  1,  0,  0,  3,  5,  4, -7],
        [-2, -1,  7, -2,  7,  6,  4, -8, -4,  7, -1, -8,  5, -5,  1,  3],
        [ 0,  3, -4, -7, -6,  3,  2,  0, -2,  1, -8, -6, -6,  0,  1, -6],
        [ 0,  5, -7, -5, -5,  0, -2, -3, -3,  6,  1, -6,  6, -5,  5, -4],
        [-5, -1,  5, -4,  4,  7,  3, -3, -5, -6, -8,  4, -8,  7,  5, -2]])

psum
[[  -3  -56 -104 -196  -44 -198 -216  -43 -189  -48 -249 -141 -281  -49 -128   25]
 [  20  -81 -194  -20 -128 -125 -258  -83 -239   99 -118 -103 -240 -129 -119 -180]
 [-255    8  -35 -220 -129  -61 -289 -247 -184  -42 -223 -150 -141 -182  -83 -249]
 [  74  -29 -128 -174  -97 -113 -337 -104 -212  -70  -71   26 -174 -133 -271 -197]
 [  56 -103  -52  -80  -89 -186 -233  -99 -225   -3 -106 -100 -134  -93  -41 -227]
 [  11 -128 -170 -139 -120  -87 -164 -137 -197   84  -96 -115 -119 -170  -94 -166]
 [  91  -28  -61 -145 -148  -63 -219 -106 -259  -30 -112 -154 -291  -30    0  -92]
 [ -12 -149  -96   13 -161 -160 -244 -119 -188  132 -121 -133 -131  -52  -71 -175]
 [ -56  -75  -79  -99 -126  -77 -252 -137 -301   49 -108 -161 -217 -146 -122 -222]
 [  15 -212 -107  -84 -199 -136 -263 -198 -318   -5 -130  -39 -208  -99   -7 -110]
 [ -75  -26 -139 -150 -127  -95 -145 -148 -193  -37  -93 -164 -264  -65 -180 -110]
 [ -34  -81 -150 -175  -67   48 -367 -106 -129 -154 -133  -68 -196 -148 -123  -89]
 [  94  -92 -122  -79 -178  -10 -277 -177 -378  -92 -149  -29 -124 -128  -33 -186]
 [  53  -28  -98 -146 -161  -44 -254  -54 -195   40 -131  -80 -236 -185  -80  -90]
 [  19  -74 -204 -105   -4  -18 -299  -34 -256   39 -175  -78 -270 -261 -191 -104]
 [ -21  -77    3   -8 -134  -63 -172  -82 -264   10 -152 -133  -76  -62 -115 -145]]


'''
# print(W.shape)
