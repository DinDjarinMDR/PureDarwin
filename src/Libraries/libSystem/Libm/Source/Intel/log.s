/*
 *  log2_x87.s
 *
 *      by Jeff Kidder
 *
 *  Copyright � 2007 Apple Inc. All Rights Reserved.
 */
//TBD stack comes in misaligned by 4
	
#if defined(__i386__)
	// [temp8, nd = exp, [pad32, return ptr32], x]
#define LOCAL_STACK_SIZE	36
#else
	// [temp8, nd = exp, return ptr64, x]
#define LOCAL_STACK_SIZE	32
#endif

#include <machine/asm.h>
#include "abi.h"

.const
.align 5
xone:			.quad	0x3ff0000000000000, 0
frexp_exp_mask: 	.quad	0x7ff0000000000000, 0
frexp_mant_mask:	.quad	0x800fffffffffffff, 0
frexp_half_mask:	.quad	0x0008000000000000, 0
frexp_head_mask:	.quad	0x000ff00000000000, 0
//log10_key_mask: 	.quad	0x07e0000000000000, 0
log1p_not_ulp_mask:	.quad	0xfffffffffffffffe, 0

.align 5	
lgel:		.quad	0xB8AA3B295C17F0BC, 0x3fff
ln2l:		.quad	0xB17217F7D1CF79AC, 0x3ffe	//ln(2) rounded up to long double 

log10el:	.quad	0xDE5BD8A937287195, 0x3ffd	//log10(e) rounded down 
log102l:	.quad	0x9A209A84FBCFF799, 0x3ffd	//log10(2) rounded up (almost 1/2 ulp) to long double 

c0:		.quad	0xFFFFFFFFFFFFFFD7, 0xbffd	//c0 = -.4999999999999999988974167423L
	
.align 5	
a01:		.double .827742667285236703751556405085096, -2.00038644890076831031534988283768	//a0,a1
b01:		.double 1.51843353412997067893915870795354, 1.54454569915832086827096843200102	//b0,b1

// The lookup table is in a funny format since it has 2 long double and a single.
	// {10-byte va ; 2-byte pad ; 4-byte single a ; 10-byte lg1pa ; 6-byte pad}
.align 5
LOOKUP:
// This is the table for a, ap1, va, lg1pa: a = (float)k*scale, ap1 = a + 1, va = (long double)1./(1.+a), lg1pa = (long double)log2(1.+a)
// In C this would be 
// typedef struct {BYTE va[10]; BYTE pad1[2]; float a; BYTE log1p[10]; BYTE pad2[2]; float ap1} record_t;
// where we are using the fact that long doubles only use 10 of the 16 bytes they are packed in.
// 	va[0],    va[1],    va[2]     (float)a, lg1pa[0], lg1pa[1], lg1pa[2], (float)ap1
.long	0x00000000, 0x80000000, 0x00003fff, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3f800000
.long	0xff00ff01, 0xff00ff00, 0x00003ffe, 0x3b800000, 0xd563ba57, 0xb84e236b, 0x00003ff7, 0x3f808000
.long	0xe03f80fe, 0xfe03f80f, 0x00003ffe, 0x3c000000, 0x78428bfc, 0xb7f285b7, 0x00003ff8, 0x3f810000
.long	0x0fd08e55, 0xfd08e550, 0x00003ffe, 0x3c400000, 0x4bd8625e, 0x89b188bd, 0x00003ff9, 0x3f818000
.long	0x0fc0fc10, 0xfc0fc0fc, 0x00003ffe, 0x3c800000, 0x16914c53, 0xb73cb42e, 0x00003ff9, 0x3f820000
.long	0x06ddaba6, 0xfb188565, 0x00003ffe, 0x3ca00000, 0x287c3333, 0xe49b1dd4, 0x00003ff9, 0x3f828000
.long	0x52138ac0, 0xfa232cf2, 0x00003ffe, 0x3cc00000, 0x99a0976c, 0x88e68ea8, 0x00003ffa, 0x3f830000
.long	0x1855a865, 0xf92fb221, 0x00003ffe, 0x3ce00000, 0x42d13101, 0x9f6984a3, 0x00003ffa, 0x3f838000
.long	0xe0f83e10, 0xf83e0f83, 0x00003ffe, 0x3d000000, 0x77ec398a, 0xb5d69bac, 0x00003ffa, 0x3f840000
.long	0x2c700f75, 0xf74e3fc2, 0x00003ffe, 0x3d100000, 0x4a8ca305, 0xcc2dfe1a, 0x00003ffa, 0x3f848000
.long	0x0f6603da, 0xf6603d98, 0x00003ffe, 0x3d200000, 0x555af7a8, 0xe26fd5c8, 0x00003ffa, 0x3f850000
.long	0xd00f5740, 0xf57403d5, 0x00003ffe, 0x3d300000, 0x929cfd0e, 0xf89c4c19, 0x00003ffa, 0x3f858000
.long	0x85bb3950, 0xf4898d5f, 0x00003ffe, 0x3d400000, 0x14fcd59e, 0x8759c4fd, 0x00003ffb, 0x3f860000
.long	0xba872336, 0xf3a0d52c, 0x00003ffe, 0x3d500000, 0x9ad1e44d, 0x925adbf0, 0x00003ffb, 0x3f868000
.long	0x0f2b9d65, 0xf2b9d648, 0x00003ffe, 0x3d600000, 0x3f8e16c0, 0x9d517ee9, 0x00003ffb, 0x3f870000
.long	0xe0d399fa, 0xf1d48bce, 0x00003ffe, 0x3d700000, 0x19ddb6a8, 0xa83dc1b0, 0x00003ffb, 0x3f878000
.long	0xf0f0f0f1, 0xf0f0f0f0, 0x00003ffe, 0x3d800000, 0x4898b3e6, 0xb31fb7d6, 0x00003ffb, 0x3f880000
.long	0x0f00f00f, 0xf00f00f0, 0x00003ffe, 0x3d880000, 0xc51409e2, 0xbdf774b5, 0x00003ffb, 0x3f888000
.long	0xc4345238, 0xef2eb71f, 0x00003ffe, 0x3d900000, 0x319ad574, 0xc8c50b72, 0x00003ffb, 0x3f890000
.long	0x00ee500f, 0xee500ee5, 0x00003ffe, 0x3d980000, 0xa4249f5a, 0xd3888ef9, 0x00003ffb, 0x3f898000
.long	0xcc0ed730, 0xed7303b5, 0x00003ffe, 0x3da00000, 0x6d5dd31e, 0xde421205, 0x00003ffb, 0x3f8a0000
.long	0xf3fc4da2, 0xec979118, 0x00003ffe, 0x3da80000, 0xdc16d268, 0xe8f1a71a, 0x00003ffb, 0x3f8a8000
.long	0xc1619c8c, 0xebbdb2a5, 0x00003ffe, 0x3db00000, 0xfd2d90e6, 0xf397608b, 0x00003ffb, 0x3f8b0000
.long	0xab95900f, 0xeae56403, 0x00003ffe, 0x3db80000, 0x58052482, 0xfe335078, 0x00003ffb, 0x3f8b8000
.long	0x0ea0ea0f, 0xea0ea0ea, 0x00003ffe, 0x3dc00000, 0xd3cf1cb1, 0x8462c466, 0x00003ffc, 0x3f8c0000
.long	0xe2d8d35c, 0xe939651f, 0x00003ffe, 0x3dc80000, 0x48316ffa, 0x89a70da4, 0x00003ffc, 0x3f8c8000
.long	0x7603a197, 0xe865ac7b, 0x00003ffe, 0x3dd00000, 0xa95bdaf5, 0x8ee68cba, 0x00003ffc, 0x3f8d0000
.long	0x25fe30d9, 0xe79372e2, 0x00003ffe, 0x3dd80000, 0x3d31fc6c, 0x94214a58, 0x00003ffc, 0x3f8d8000
.long	0x1cd85689, 0xe6c2b448, 0x00003ffe, 0x3de00000, 0xc570d0fb, 0x99574f13, 0x00003ffc, 0x3f8e0000
.long	0x0e5f36cb, 0xe5f36cb0, 0x00003ffe, 0x3de80000, 0xd4531f80, 0x9e88a36c, 0x00003ffc, 0x3f8e8000
.long	0xf70c880e, 0xe525982a, 0x00003ffe, 0x3df00000, 0x1fba698a, 0xa3b54fcc, 0x00003ffc, 0x3f8f0000
.long	0xdc52100e, 0xe45932d7, 0x00003ffe, 0x3df80000, 0xd2e45246, 0xa8dd5c83, 0x00003ffc, 0x3f8f8000
.long	0x8e38e38e, 0xe38e38e3, 0x00003ffe, 0x3e000000, 0xdeb43cfd, 0xae00d1cf, 0x00003ffc, 0x3f900000
.long	0x6a4c2e10, 0xe2c4a688, 0x00003ffe, 0x3e040000, 0x4898b3e6, 0xb31fb7d6, 0x00003ffc, 0x3f908000
.long	0x1fc780e2, 0xe1fc780e, 0x00003ffe, 0x3e080000, 0x7813f94e, 0xb83a16a7, 0x00003ffc, 0x3f910000
.long	0x7500e136, 0xe135a9c9, 0x00003ffe, 0x3e0c0000, 0x82eef78c, 0xbd4ff63e, 0x00003ffc, 0x3f918000
.long	0x0e070382, 0xe070381c, 0x00003ffe, 0x3e100000, 0x781d97ef, 0xc2615e81, 0x00003ffc, 0x3f920000
.long	0x346c575f, 0xdfac1f74, 0x00003ffe, 0x3e140000, 0xa95b5dae, 0xc76e5741, 0x00003ffc, 0x3f928000
.long	0xa037ba57, 0xdee95c4c, 0x00003ffe, 0x3e180000, 0xf386f818, 0xcc76e83b, 0x00003ffc, 0x3f930000
.long	0x41f3d9d1, 0xde27eb2c, 0x00003ffe, 0x3e1c0000, 0x05c35652, 0xd17b1919, 0x00003ffc, 0x3f938000
.long	0x0dd67c8a, 0xdd67c8a6, 0x00003ffe, 0x3e200000, 0xa7649f7f, 0xd67af16d, 0x00003ffc, 0x3f940000
.long	0xc7f91ab8, 0xdca8f158, 0x00003ffe, 0x3e240000, 0xfcaf4b5f, 0xdb7678ba, 0x00003ffc, 0x3f948000
.long	0xd19c5958, 0xdbeb61ee, 0x00003ffe, 0x3e280000, 0xca6f7207, 0xe06db66e, 0x00003ffc, 0x3f950000
.long	0xf7702919, 0xdb2f171d, 0x00003ffe, 0x3e2c0000, 0xb86e44b6, 0xe560b1e3, 0x00003ffc, 0x3f958000
.long	0x40da740e, 0xda740da7, 0x00003ffe, 0x3e300000, 0x92cb7e48, 0xea4f7261, 0x00003ffc, 0x3f960000
.long	0xc0366e91, 0xd9ba4256, 0x00003ffe, 0x3e340000, 0x8a40770e, 0xef39ff1d, 0x00003ffc, 0x3f968000
.long	0x6406c80e, 0xd901b203, 0x00003ffe, 0x3e380000, 0x7352663e, 0xf4205f3a, 0x00003ffc, 0x3f970000
.long	0xc9151f43, 0xd84a598e, 0x00003ffe, 0x3e3c0000, 0x04793a3c, 0xf90299c9, 0x00003ffc, 0x3f978000
.long	0x0d79435e, 0xd79435e5, 0x00003ffe, 0x3e400000, 0x1340511d, 0xfde0b5c8, 0x00003ffc, 0x3f980000
.long	0xa482f00d, 0xd6df43fc, 0x00003ffe, 0x3e440000, 0x68331dd9, 0x815d5d12, 0x00003ffd, 0x3f988000
.long	0x2b80d62c, 0xd62b80d6, 0x00003ffe, 0x3e480000, 0x81804b78, 0x83c856dd, 0x00003ffd, 0x3f990000
.long	0x3f5fe551, 0xd578e97c, 0x00003ffe, 0x3e4c0000, 0xa1547528, 0x86314baa, 0x00003ffd, 0x3f998000
.long	0x531dec0d, 0xd4c77b03, 0x00003ffe, 0x3e500000, 0x985bae58, 0x88983ed6, 0x00003ffd, 0x3f9a0000
.long	0x870ac52e, 0xd4173289, 0x00003ffe, 0x3e540000, 0xd847facc, 0x8afd33b5, 0x00003ffd, 0x3f9a8000
.long	0x80d3680d, 0xd3680d36, 0x00003ffe, 0x3e580000, 0x8f838294, 0x8d602d94, 0x00003ffd, 0x3f9b0000
.long	0x445250ab, 0xd2ba083b, 0x00003ffe, 0x3e5c0000, 0xc470995f, 0x8fc12fb6, 0x00003ffd, 0x3f9b8000
.long	0x0d20d20d, 0xd20d20d2, 0x00003ffe, 0x3e600000, 0x7039cc12, 0x92203d58, 0x00003ffd, 0x3f9c0000
.long	0x28e50274, 0xd161543e, 0x00003ffe, 0x3e640000, 0x99341b18, 0x947d59ad, 0x00003ffd, 0x3f9c8000
.long	0xd2580d0b, 0xd0b69fcb, 0x00003ffe, 0x3e680000, 0x6cd57b79, 0x96d887e2, 0x00003ffd, 0x3f9d0000
.long	0x0d00d00d, 0xd00d00d0, 0x00003ffe, 0x3e6c0000, 0x5941acd7, 0x9931cb1b, 0x00003ffd, 0x3f9d8000
.long	0x819ec8e9, 0xcf6474a8, 0x00003ffe, 0x3e700000, 0x266f66cd, 0x9b892675, 0x00003ffd, 0x3f9e0000
.long	0x5b4169cb, 0xcebcf8bb, 0x00003ffe, 0x3e740000, 0x0ee7d4ac, 0x9dde9d05, 0x00003ffd, 0x3f9e8000
.long	0x25080ce1, 0xce168a77, 0x00003ffe, 0x3e780000, 0xd8224bae, 0xa03231d8, 0x00003ffd, 0x3f9f0000
.long	0xa886d242, 0xcd712752, 0x00003ffe, 0x3e7c0000, 0xea7e1ca7, 0xa283e7f6, 0x00003ffd, 0x3f9f8000
.long	0xcccccccd, 0xcccccccc, 0x00003ffe, 0x3e800000, 0x68dc57f2, 0xa4d3c25e, 0x00003ffd, 0x3fa00000
.long	0x7607f99f, 0xcc29786c, 0x00003ffe, 0x3e820000, 0x47db4fde, 0xa721c407, 0x00003ffd, 0x3fa08000
.long	0x65c393e0, 0xcb8727c0, 0x00003ffe, 0x3e840000, 0x64b59bee, 0xa96defe2, 0x00003ffd, 0x3fa10000
.long	0x1bbd6c95, 0xcae5d85f, 0x00003ffe, 0x3e860000, 0x9bc65588, 0xabb848d9, 0x00003ffd, 0x3fa18000
.long	0xb74f0329, 0xca4587e6, 0x00003ffe, 0x3e880000, 0xdeb43cfd, 0xae00d1cf, 0x00003ffd, 0x3fa20000
.long	0xd967300d, 0xc9a633fc, 0x00003ffe, 0x3e8a0000, 0x4a456cb8, 0xb0478da1, 0x00003ffd, 0x3fa28000
.long	0x871146ad, 0xc907da4e, 0x00003ffe, 0x3e8c0000, 0x3bdd3729, 0xb28c7f23, 0x00003ffd, 0x3fa30000
.long	0x0c86a789, 0xc86a7890, 0x00003ffe, 0x3e8e0000, 0x66a5c346, 0xb4cfa924, 0x00003ffd, 0x3fa38000
.long	0xe0c7ce0c, 0xc7ce0c7c, 0x00003ffe, 0x3e900000, 0xe866f2bc, 0xb7110e6c, 0x00003ffd, 0x3fa40000
.long	0x89b9f838, 0xc73293d7, 0x00003ffe, 0x3e920000, 0x5e0c14a2, 0xb950b1be, 0x00003ffd, 0x3fa48000
.long	0x80c6980c, 0xc6980c69, 0x00003ffe, 0x3e940000, 0xf7d9df23, 0xbb8e95d3, 0x00003ffd, 0x3fa50000
.long	0x17f9d00c, 0xc5fe7403, 0x00003ffe, 0x3e960000, 0x8d5622bb, 0xbdcabd62, 0x00003ffd, 0x3fa58000
.long	0x5f9d4d1c, 0xc565c87b, 0x00003ffe, 0x3e980000, 0xb0e2a195, 0xc0052b18, 0x00003ffd, 0x3fa60000
.long	0x0c4ce07b, 0xc4ce07b0, 0x00003ffe, 0x3e9a0000, 0xc30c6e3e, 0xc23de19e, 0x00003ffd, 0x3fa68000
.long	0x5d824ca6, 0xc4372f85, 0x00003ffe, 0x3e9c0000, 0x05912d26, 0xc474e397, 0x00003ffd, 0x3fa70000
.long	0x0495c773, 0xc3a13de6, 0x00003ffe, 0x3e9e0000, 0xae1b8d5a, 0xc6aa339d, 0x00003ffd, 0x3fa78000
.long	0x0c30c30c, 0xc30c30c3, 0x00003ffe, 0x3ea00000, 0xf8b845a6, 0xc8ddd448, 0x00003ffd, 0x3fa80000
.long	0xc0309e02, 0xc2780613, 0x00003ffe, 0x3ea20000, 0x3a04dc68, 0xcb0fc829, 0x00003ffd, 0x3fa88000
.long	0x95f6e947, 0xc1e4bbd5, 0x00003ffe, 0x3ea40000, 0xf11979a6, 0xcd4011c8, 0x00003ffd, 0x3fa90000
.long	0x152500c1, 0xc152500c, 0x00003ffe, 0x3ea60000, 0xd92efc47, 0xcf6eb3ac, 0x00003ffd, 0x3fa98000
.long	0xc0c0c0c1, 0xc0c0c0c0, 0x00003ffe, 0x3ea80000, 0xfb0284ec, 0xd19bb053, 0x00003ffd, 0x3faa0000
.long	0x00c0300c, 0xc0300c03, 0x00003ffe, 0x3eaa0000, 0xbdf7a294, 0xd3c70a37, 0x00003ffd, 0x3faa8000
.long	0x0bfa02ff, 0xbfa02fe8, 0x00003ffe, 0x3eac0000, 0xf8fa470d, 0xd5f0c3cb, 0x00003ffd, 0x3fab0000
.long	0xd278e8dd, 0xbf112a8a, 0x00003ffe, 0x3eae0000, 0x0321a333, 0xd818df7f, 0x00003ffd, 0x3fab8000
.long	0xe82fa0bf, 0xbe82fa0b, 0x00003ffe, 0x3eb00000, 0xc4150521, 0xda3f5fb9, 0x00003ffd, 0x3fac0000
.long	0x700bdf5a, 0xbdf59c91, 0x00003ffe, 0x3eb20000, 0xc433ccba, 0xdc6446df, 0x00003ffd, 0x3fac8000
.long	0x07661aa3, 0xbd691047, 0x00003ffe, 0x3eb40000, 0x3c81855a, 0xde87974f, 0x00003ffd, 0x3fad0000
.long	0xb1cc5b7b, 0xbcdd535d, 0x00003ffe, 0x3eb60000, 0x26572e01, 0xe0a95361, 0x00003ffd, 0x3fad8000
.long	0xc52640bc, 0xbc52640b, 0x00003ffe, 0x3eb80000, 0x4adab3f4, 0xe2c97d69, 0x00003ffd, 0x3fae0000
.long	0xd63069a1, 0xbbc8408c, 0x00003ffe, 0x3eba0000, 0x523d9e9c, 0xe4e817b6, 0x00003ffd, 0x3fae8000
.long	0xa54d880c, 0xbb3ee721, 0x00003ffe, 0x3ebc0000, 0xd2c3e64b, 0xe7052491, 0x00003ffd, 0x3faf0000
.long	0x0bab6561, 0xbab65610, 0x00003ffe, 0x3ebe0000, 0x5f93ea91, 0xe920a640, 0x00003ffd, 0x3faf8000
.long	0xe8ba2e8c, 0xba2e8ba2, 0x00003ffe, 0x3ec00000, 0x975077f2, 0xeb3a9f01, 0x00003ffd, 0x3fb00000
.long	0x0ff46588, 0xb9a7862a, 0x00003ffe, 0x3ec20000, 0x327dc809, 0xed531110, 0x00003ffd, 0x3fb08000
.long	0x36f5e02e, 0xb92143fa, 0x00003ffe, 0x3ec40000, 0x11b26276, 0xef69fea2, 0x00003ffd, 0x3fb10000
.long	0xe3e0453a, 0xb89bc36c, 0x00003ffe, 0x3ec60000, 0x4b94c070, 0xf17f69e8, 0x00003ffd, 0x3fb18000
.long	0x5c0b8170, 0xb81702e0, 0x00003ffe, 0x3ec80000, 0x3aa69063, 0xf393550f, 0x00003ffd, 0x3fb20000
.long	0x9300b793, 0xb79300b7, 0x00003ffe, 0x3eca0000, 0x8ade729f, 0xf5a5c23e, 0x00003ffd, 0x3fb28000
.long	0x19be3659, 0xb70fbb5a, 0x00003ffe, 0x3ecc0000, 0x471103e9, 0xf7b6b399, 0x00003ffd, 0x3fb30000
.long	0x0e4307d8, 0xb68d3134, 0x00003ffe, 0x3ece0000, 0xe62a0688, 0xf9c62b3d, 0x00003ffd, 0x3fb38000
.long	0x0b60b60b, 0xb60b60b6, 0x00003ffe, 0x3ed00000, 0x58367671, 0xfbd42b46, 0x00003ffd, 0x3fb40000
.long	0x18d1e7e4, 0xb58a4855, 0x00003ffe, 0x3ed20000, 0x1340511d, 0xfde0b5c8, 0x00003ffd, 0x3fb48000
.long	0x9b94821f, 0xb509e68a, 0x00003ffe, 0x3ed40000, 0x1ffcd5ce, 0xffebccd4, 0x00003ffd, 0x3fb50000
.long	0x4685fe97, 0xb48a39d4, 0x00003ffe, 0x3ed60000, 0x9326ff92, 0x80fab93b, 0x00003ffe, 0x3fb58000
.long	0x0b40b40b, 0xb40b40b4, 0x00003ffe, 0x3ed80000, 0xbccbf99d, 0x81fed45c, 0x00003ffe, 0x3fb60000
.long	0x0b38cf9b, 0xb38cf9b0, 0x00003ffe, 0x3eda0000, 0x927591f5, 0x830238cf, 0x00003ffe, 0x3fb68000
.long	0x8917c80b, 0xb30f6352, 0x00003ffe, 0x3edc0000, 0xfb81ea93, 0x8404e793, 0x00003ffe, 0x3fb70000
.long	0xda5519cf, 0xb2927c29, 0x00003ffe, 0x3ede0000, 0xc70fde00, 0x8506e1a7, 0x00003ffe, 0x3fb78000
.long	0x590b2164, 0xb21642c8, 0x00003ffe, 0x3ee00000, 0xb1d532c4, 0x86082806, 0x00003ffe, 0x3fb80000
.long	0x5606f00b, 0xb19ab5c4, 0x00003ffe, 0x3ee20000, 0x6be0889d, 0x8708bbaa, 0x00003ffe, 0x3fb88000
.long	0x0b11fd3c, 0xb11fd3b8, 0x00003ffe, 0x3ee40000, 0x9e4753d9, 0x88089d8a, 0x00003ffe, 0x3fb90000
.long	0x8d749d53, 0xb0a59b41, 0x00003ffe, 0x3ee60000, 0xf0c0396a, 0x8907ce9c, 0x00003ffe, 0x3fb98000
.long	0xc0b02c0b, 0xb02c0b02, 0x00003ffe, 0x3ee80000, 0x0f2a1cf1, 0x8a064fd5, 0x00003ffe, 0x3fba0000
.long	0x496fdf0e, 0xafb321a1, 0x00003ffe, 0x3eea0000, 0xaf00303c, 0x8b042224, 0x00003ffe, 0x3fba8000
.long	0x80af3ade, 0xaf3addc6, 0x00003ffe, 0x3eec0000, 0x94bb5276, 0x8c01467b, 0x00003ffe, 0x3fbb0000
.long	0x671529a5, 0xaec33e1f, 0x00003ffe, 0x3eee0000, 0x99210b8b, 0x8cfdbdc7, 0x00003ffe, 0x3fbb8000
.long	0x9882b931, 0xae4c415c, 0x00003ffe, 0x3ef00000, 0xae806f1e, 0x8df988f4, 0x00003ffe, 0x3fbc0000
.long	0x3fd48a86, 0xadd5e632, 0x00003ffe, 0x3ef20000, 0xe5dd30c4, 0x8ef4a8ec, 0x00003ffe, 0x3fbc8000
.long	0x0ad602b6, 0xad602b58, 0x00003ffe, 0x3ef40000, 0x74093212, 0x8fef1e98, 0x00003ffe, 0x3fbd0000
.long	0x1e6551bb, 0xaceb0f89, 0x00003ffe, 0x3ef60000, 0xb6acd18b, 0x90e8eadd, 0x00003ffe, 0x3fbd8000
.long	0x0ac76918, 0xac769184, 0x00003ffe, 0x3ef80000, 0x393e4040, 0x91e20ea1, 0x00003ffe, 0x3fbe0000
.long	0xc02b00ac, 0xac02b00a, 0x00003ffe, 0x3efa0000, 0xb9e822b4, 0x92da8ac5, 0x00003ffe, 0x3fbe8000
.long	0x8359cd11, 0xab8f69e2, 0x00003ffe, 0x3efc0000, 0x2e5fc02c, 0x93d2602c, 0x00003ffe, 0x3fbf0000
.long	0xe2970f60, 0xab1cbdd3, 0x00003ffe, 0x3efe0000, 0xc8ab0290, 0x94c98fb3, 0x00003ffe, 0x3fbf8000
.long	0xdc17f00b, 0xaa392f35, 0x00003fff, 0xbe7e0000, 0xfec7f9b5, 0xd293feca, 0x0000bffd, 0x3f408000
.long	0xa07f5638, 0xa9c84a47, 0x00003fff, 0xbe7c0000, 0x4c0d9ebe, 0xd0a978a1, 0x0000bffd, 0x3f410000
.long	0x402a55ff, 0xa957fab5, 0x00003fff, 0xbe7a0000, 0x4c90dc61, 0xcec0375e, 0x0000bffd, 0x3f418000
.long	0x17c0a8e8, 0xa8e83f57, 0x00003fff, 0xbe780000, 0xb6359379, 0xccd83954, 0x0000bffd, 0x3f420000
.long	0x8e262b6f, 0xa8791708, 0x00003fff, 0xbe760000, 0x8f827179, 0xcaf17cda, 0x0000bffd, 0x3f428000
.long	0x0a80a80b, 0xa80a80a8, 0x00003fff, 0xbe740000, 0x26e9dbfc, 0xc90c0049, 0x0000bffd, 0x3f430000
.long	0xea64d422, 0xa79c7b16, 0x00003fff, 0xbe720000, 0x0a2f6d7e, 0xc727c1fd, 0x0000bffd, 0x3f438000
.long	0x7829cbc1, 0xa72f0539, 0x00003fff, 0xbe700000, 0xfde99333, 0xc544c055, 0x0000bffd, 0x3f440000
.long	0xe1625c80, 0xa6c21df6, 0x00003fff, 0xbe6e0000, 0xf51eddd3, 0xc362f9b6, 0x0000bffd, 0x3f448000
.long	0x2d7b73a8, 0xa655c439, 0x00003fff, 0xbe6c0000, 0x08fe9952, 0xc1826c86, 0x0000bffd, 0x3f450000
.long	0x347f0721, 0xa5e9f6ed, 0x00003fff, 0xbe6a0000, 0x70b44141, 0xbfa3172c, 0x0000bffd, 0x3f458000
.long	0x95fad40a, 0xa57eb502, 0x00003fff, 0xbe680000, 0x79556990, 0xbdc4f816, 0x0000bffd, 0x3f460000
.long	0xb00a5140, 0xa513fd6b, 0x00003fff, 0xbe660000, 0x7de9b525, 0xbbe80db3, 0x0000bffd, 0x3f468000
.long	0x96833751, 0xa4a9cf1d, 0x00003fff, 0xbe640000, 0xdf8c75b3, 0xba0c5675, 0x0000bffd, 0x3f470000
.long	0x0a440291, 0xa4402910, 0x00003fff, 0xbe620000, 0xfda791cc, 0xb831d0d2, 0x0000bffd, 0x3f478000
.long	0x70a3d70a, 0xa3d70a3d, 0x00003fff, 0xbe600000, 0x2e47501b, 0xb6587b43, 0x0000bffd, 0x3f480000
.long	0xcb033128, 0xa36e71a2, 0x00003fff, 0xbe5e0000, 0xb686a83a, 0xb4805441, 0x0000bffd, 0x3f488000
.long	0xae7cd0e0, 0xa3065e3f, 0x00003fff, 0xbe5c0000, 0xc313bb59, 0xb2a95a4c, 0x0000bffd, 0x3f490000
.long	0x3bb6500a, 0xa29ecf16, 0x00003fff, 0xbe5a0000, 0x60cc188b, 0xb0d38be5, 0x0000bffd, 0x3f498000
.long	0x16cfd772, 0xa237c32b, 0x00003fff, 0xbe580000, 0x75707221, 0xaefee78f, 0x0000bffd, 0x3f4a0000
.long	0x5f7268ee, 0xa1d13985, 0x00003fff, 0xbe560000, 0xb86f6b11, 0xad2b6bd1, 0x0000bffd, 0x3f4a8000
.long	0xa8fc377d, 0xa16b312e, 0x00003fff, 0xbe540000, 0xabc724e5, 0xab591735, 0x0000bffd, 0x3f4b0000
.long	0xf2ca891f, 0xa105a932, 0x00003fff, 0xbe520000, 0x94fd384f, 0xa987e847, 0x0000bffd, 0x3f4b8000
.long	0xa0a0a0a1, 0xa0a0a0a0, 0x00003fff, 0xbe500000, 0x762cc3c7, 0xa7b7dd96, 0x0000bffd, 0x3f4c0000
.long	0x732b3032, 0xa03c1688, 0x00003fff, 0xbe4e0000, 0x072a3d44, 0xa5e8f5b4, 0x0000bffd, 0x3f4c8000
.long	0x809fd80a, 0x9fd809fd, 0x00003fff, 0xbe4c0000, 0xaebcb551, 0xa41b2f34, 0x0000bffd, 0x3f4d0000
.long	0x2d7836d0, 0x9f747a15, 0x00003fff, 0xbe4a0000, 0x7bec3b64, 0xa24e88af, 0x0000bffd, 0x3f4d8000
.long	0x254813e2, 0x9f1165e7, 0x00003fff, 0xbe480000, 0x1f651473, 0xa08300be, 0x0000bffd, 0x3f4e0000
.long	0x53ae2ddf, 0x9eaecc8d, 0x00003fff, 0xbe460000, 0xe4ef7663, 0x9eb895fc, 0x0000bffd, 0x3f4e8000
.long	0xdd5f3a20, 0x9e4cad23, 0x00003fff, 0xbe440000, 0xacfb7bf9, 0x9cef470a, 0x0000bffd, 0x3f4f0000
.long	0x194aa416, 0x9deb06c9, 0x00003fff, 0xbe420000, 0xe6410678, 0x9b271288, 0x0000bffd, 0x3f4f8000
.long	0x89d89d8a, 0x9d89d89d, 0x00003fff, 0xbe400000, 0x8773432d, 0x995ff71b, 0x0000bffd, 0x3f500000
.long	0xd6411308, 0x9d2921c3, 0x00003fff, 0xbe3e0000, 0x09078c87, 0x9799f369, 0x0000bffd, 0x3f508000
.long	0xc3fb19b9, 0x9cc8e160, 0x00003fff, 0xbe3c0000, 0x5f0f5f7f, 0x95d5061a, 0x0000bffd, 0x3f510000
.long	0x30446dfa, 0x9c69169b, 0x00003fff, 0xbe3a0000, 0xf3251f47, 0x94112dda, 0x0000bffd, 0x3f518000
.long	0x09c09c0a, 0x9c09c09c, 0x00003fff, 0xbe380000, 0x9e6b6268, 0x924e6958, 0x0000bffd, 0x3f520000
.long	0x4a2f6e10, 0x9baade8e, 0x00003fff, 0xbe360000, 0xa39e8598, 0x908cb743, 0x0000bffd, 0x3f528000
.long	0xf03a3caa, 0x9b4c6f9e, 0x00003fff, 0xbe340000, 0xa93841af, 0x8ecc164e, 0x0000bffd, 0x3f530000
.long	0xf957c10f, 0x9aee72fc, 0x00003fff, 0xbe320000, 0xb3a50346, 0x8d0c852e, 0x0000bffd, 0x3f538000
.long	0x5bc609a9, 0x9a90e7d9, 0x00003fff, 0xbe300000, 0x1f8ac392, 0x8b4e029b, 0x0000bffd, 0x3f540000
.long	0x009a33cd, 0x9a33cd67, 0x00003fff, 0xbe2e0000, 0x9c212322, 0x89908d4d, 0x0000bffd, 0x3f548000
.long	0xbde58f06, 0x99d722da, 0x00003fff, 0xbe2c0000, 0x259a8843, 0x87d42402, 0x0000bffd, 0x3f550000
.long	0x50efd00a, 0x997ae76b, 0x00003fff, 0xbe2a0000, 0xff9e03b3, 0x8618c576, 0x0000bffd, 0x3f558000
.long	0x5885fb37, 0x991f1a51, 0x00003fff, 0xbe280000, 0xafd1bf61, 0x845e706c, 0x0000bffd, 0x3f560000
.long	0x4f5db00a, 0x98c3bac7, 0x00003fff, 0xbe260000, 0xf875bbfc, 0x82a523a5, 0x0000bffd, 0x3f568000
.long	0x868c8098, 0x9868c809, 0x00003fff, 0xbe240000, 0xd30ea2ed, 0x80ecdde7, 0x0000bffd, 0x3f570000
.long	0x201301c8, 0x980e4156, 0x00003fff, 0xbe220000, 0xd640e6de, 0xfe6b3bf2, 0x0000bffc, 0x3f578000
.long	0x097b425f, 0x97b425ed, 0x00003fff, 0xbe200000, 0x31f1a484, 0xfafec548, 0x0000bffc, 0x3f580000
.long	0xf68a58af, 0x975a750f, 0x00003fff, 0xbe1e0000, 0xb9118906, 0xf7945566, 0x0000bffc, 0x3f588000
.long	0x5c04b809, 0x97012e02, 0x00003fff, 0xbe1c0000, 0xb09b3def, 0xf42be9e9, 0x0000bffc, 0x3f590000
.long	0x6a850097, 0x96a85009, 0x00003fff, 0xbe1a0000, 0x9891e833, 0xf0c58070, 0x0000bffc, 0x3f598000
.long	0x0964fda7, 0x964fda6c, 0x00003fff, 0xbe180000, 0x220e97f2, 0xed61169f, 0x0000bffc, 0x3f5a0000
.long	0xd1b887e9, 0x95f7cc72, 0x00003fff, 0xbe160000, 0x256ae3d2, 0xe9feaa1d, 0x0000bffc, 0x3f5a8000
.long	0x095a0257, 0x95a02568, 0x00003fff, 0xbe140000, 0x98884993, 0xe69e3896, 0x0000bffc, 0x3f5b0000
.long	0x9e0829fd, 0x9548e497, 0x00003fff, 0xbe120000, 0x8533ef03, 0xe33fbfbb, 0x0000bffc, 0x3f5b8000
.long	0x2094f209, 0x94f2094f, 0x00003fff, 0xbe100000, 0xffa66038, 0xdfe33d3f, 0x0000bffc, 0x3f5c0000
.long	0xc02526e5, 0x949b92dd, 0x00003fff, 0xbe0e0000, 0x1d1ee96a, 0xdc88aedc, 0x0000bffc, 0x3f5c8000
.long	0x45809446, 0x94458094, 0x00003fff, 0xbe0c0000, 0xea9a2c67, 0xd930124b, 0x0000bffc, 0x3f5d0000
.long	0x0e726b7c, 0x93efd1c5, 0x00003fff, 0xbe0a0000, 0x63a39316, 0xd5d9654f, 0x0000bffc, 0x3f5d8000
.long	0x0939a85c, 0x939a85c4, 0x00003fff, 0xbe080000, 0x69414202, 0xd284a5aa, 0x0000bffc, 0x3f5e0000
.long	0xb009345a, 0x93459be6, 0x00003fff, 0xbe060000, 0xb8fa2f56, 0xcf31d124, 0x0000bffc, 0x3f5e8000
.long	0x0497889c, 0x92f11384, 0x00003fff, 0xbe040000, 0xe3f6042d, 0xcbe0e589, 0x0000bffc, 0x3f5f0000
.long	0x8bbd90e5, 0x929cebf4, 0x00003fff, 0xbe020000, 0x46366f7a, 0xc891e0a9, 0x0000bffc, 0x3f5f8000
.long	0x49249249, 0x92492492, 0x00003fff, 0xbe000000, 0xfde99333, 0xc544c055, 0x0000bffc, 0x3f600000
.long	0xbb02d9cd, 0x91f5bcb8, 0x00003fff, 0xbdfc0000, 0xe2d535c6, 0xc1f98266, 0x0000bffc, 0x3f608000
.long	0xd5e6f809, 0x91a2b3c4, 0x00003fff, 0xbdf80000, 0x7dda633a, 0xbeb024b6, 0x0000bffc, 0x3f610000
.long	0x00915009, 0x91500915, 0x00003fff, 0xbdf40000, 0x00912aa3, 0xbb68a523, 0x0000bffc, 0x3f618000
.long	0x0fdbc091, 0x90fdbc09, 0x00003fff, 0xbdf00000, 0x3cfc25f1, 0xb823018e, 0x0000bffc, 0x3f620000
.long	0x42af3009, 0x90abcc02, 0x00003fff, 0xbdec0000, 0x9d537b43, 0xb4df37dd, 0x0000bffc, 0x3f628000
.long	0x3e06c43b, 0x905a3863, 0x00003fff, 0xbde80000, 0x1be70855, 0xb19d45fa, 0x0000bffc, 0x3f630000
.long	0x09009009, 0x90090090, 0x00003fff, 0xbde40000, 0x3b1769a9, 0xae5d29d0, 0x0000bffc, 0x3f638000
.long	0x08fb823f, 0x8fb823ee, 0x00003fff, 0xbde00000, 0xfd659064, 0xab1ee14f, 0x0000bffc, 0x3f640000
.long	0xfdc26178, 0x8f67a1e3, 0x00003fff, 0xbddc0000, 0xdd989af8, 0xa7e26a6c, 0x0000bffc, 0x3f648000
.long	0xfdc3a219, 0x8f1779d9, 0x00003fff, 0xbdd80000, 0xc6f9a5d5, 0xa4a7c31d, 0x0000bffc, 0x3f650000
.long	0x7255e41d, 0x8ec7ab39, 0x00003fff, 0xbdd40000, 0x0da54a91, 0xa16ee95d, 0x0000bffc, 0x3f658000
.long	0x1408e783, 0x8e78356d, 0x00003fff, 0xbdd00000, 0x66f2850b, 0x9e37db28, 0x0000bffc, 0x3f660000
.long	0xe702c6cd, 0x8e2917e0, 0x00003fff, 0xbdcc0000, 0xe1eeb725, 0x9b029680, 0x0000bffc, 0x3f668000
.long	0x37694809, 0x8dda5202, 0x00003fff, 0xbdc80000, 0xdfee84d1, 0x97cf196a, 0x0000bffc, 0x3f670000
.long	0x95d71590, 0x8d8be33f, 0x00003fff, 0xbdc40000, 0x0d33432f, 0x949d61ee, 0x0000bffc, 0x3f678000
.long	0xd3dcb08d, 0x8d3dcb08, 0x00003fff, 0xbdc00000, 0x59a4b697, 0x916d6e15, 0x0000bffc, 0x3f680000
.long	0x008cf009, 0x8cf008cf, 0x00003fff, 0xbdbc0000, 0xf19edc59, 0x8e3f3bee, 0x0000bffc, 0x3f688000
.long	0x6514e023, 0x8ca29c04, 0x00003fff, 0xbdb80000, 0x36d37e21, 0x8b12c98c, 0x0000bffc, 0x3f690000
.long	0x815ed5ca, 0x8c55841c, 0x00003fff, 0xbdb40000, 0xb93f4dc5, 0x87e81501, 0x0000bffc, 0x3f698000
.long	0x08c08c09, 0x8c08c08c, 0x00003fff, 0xbdb00000, 0x3032495d, 0x84bf1c67, 0x0000bffc, 0x3f6a0000
.long	0xdeb420c0, 0x8bbc50c8, 0x00003fff, 0xbdac0000, 0x736b2864, 0x8197ddd7, 0x0000bffc, 0x3f6a8000
.long	0x139bc75a, 0x8b70344a, 0x00003fff, 0xbda80000, 0xe88b274a, 0xfce4aee0, 0x0000bffb, 0x3f6b0000
.long	0xe19008b2, 0x8b246a87, 0x00003fff, 0xbda40000, 0x6df5d521, 0xf69d0ea6, 0x0000bffb, 0x3f6b8000
.long	0xa9386823, 0x8ad8f2fb, 0x00003fff, 0xbda00000, 0x97eab326, 0xf058d747, 0x0000bffb, 0x3f6c0000
.long	0xeeae465c, 0x8a8dcd1f, 0x00003fff, 0xbd9c0000, 0x926a0bb6, 0xea180512, 0x0000bffb, 0x3f6c8000
.long	0x5669db46, 0x8a42f870, 0x00003fff, 0xbd980000, 0x878e27d1, 0xe3da945b, 0x0000bffb, 0x3f6d0000
.long	0xa23920e0, 0x89f87469, 0x00003fff, 0xbd940000, 0x929c9e33, 0xdda0817c, 0x0000bffb, 0x3f6d8000
.long	0xae4089ae, 0x89ae4089, 0x00003fff, 0xbd900000, 0xb33a7280, 0xd769c8d5, 0x0000bffb, 0x3f6e0000
.long	0x6e055dec, 0x89645c4f, 0x00003fff, 0xbd8c0000, 0xc0c2944d, 0xd13666cc, 0x0000bffb, 0x3f6e8000
.long	0xe9819b50, 0x891ac73a, 0x00003fff, 0xbd880000, 0x5dbe4f6f, 0xcb0657cd, 0x0000bffb, 0x3f6f0000
.long	0x3a4133d7, 0x88d180cd, 0x00003fff, 0xbd840000, 0xeb7f40a7, 0xc4d99848, 0x0000bffb, 0x3f6f8000
.long	0x88888889, 0x88888888, 0x00003fff, 0xbd800000, 0x7dda633a, 0xbeb024b6, 0x0000bffb, 0x3f700000
.long	0x0883fddf, 0x883fddf0, 0x00003fff, 0xbd780000, 0xcf03cdb6, 0xb889f992, 0x0000bffb, 0x3f708000
.long	0xf78087f8, 0x87f78087, 0x00003fff, 0xbd700000, 0x338ab5a2, 0xb2671360, 0x0000bffb, 0x3f710000
.long	0x992d0d40, 0x87af6fd5, 0x00003fff, 0xbd680000, 0x8e755349, 0xac476ea6, 0x0000bffb, 0x3f718000
.long	0x34e47ef1, 0x8767ab5f, 0x00003fff, 0xbd600000, 0x457c4070, 0xa62b07f3, 0x0000bffb, 0x3f720000
.long	0x13008720, 0x872032ac, 0x00003fff, 0xbd580000, 0x3564ee1c, 0xa011dbd9, 0x0000bffb, 0x3f728000
.long	0x7a34acc6, 0x86d90544, 0x00003fff, 0xbd500000, 0xa67acf0f, 0x99fbe6f0, 0x0000bffb, 0x3f730000
.long	0xacf1ce96, 0x869222b1, 0x00003fff, 0xbd480000, 0x4126d610, 0x93e925d7, 0x0000bffb, 0x3f738000
.long	0xe6d1d608, 0x864b8a7d, 0x00003fff, 0xbd400000, 0x02a4e866, 0x8dd99530, 0x0000bffb, 0x3f740000
.long	0x5a0b8473, 0x86053c34, 0x00003fff, 0xbd380000, 0x31d6e65f, 0x87cd31a3, 0x0000bffb, 0x3f748000
.long	0x2cee3c9b, 0x85bf3761, 0x00003fff, 0xbd300000, 0x5434ed04, 0x81c3f7de, 0x0000bffb, 0x3f750000
.long	0x7765ab89, 0x85797b91, 0x00003fff, 0xbd280000, 0x45b4eb0a, 0xf77bc928, 0x0000bffa, 0x3f758000
.long	0x40853408, 0x85340853, 0x00003fff, 0xbd200000, 0xff5ff023, 0xeb75e8f8, 0x0000bffa, 0x3f760000
.long	0x7c1b0085, 0x84eedd35, 0x00003fff, 0xbd180000, 0xd561728e, 0xdf7648a8, 0x0000bffa, 0x3f768000
.long	0x084a9f9d, 0x84a9f9c8, 0x00003fff, 0xbd100000, 0xee98d4f3, 0xd37ce1bb, 0x0000bffa, 0x3f770000
.long	0xab2f1008, 0x84655d9b, 0x00003fff, 0xbd080000, 0x83c88cea, 0xc789adc0, 0x0000bffa, 0x3f778000
.long	0x10842108, 0x84210842, 0x00003fff, 0xbd000000, 0xcac6aaef, 0xbb9ca64e, 0x0000bffa, 0x3f780000
.long	0xc7570ce1, 0x83dcf94d, 0x00003fff, 0xbcf00000, 0xe1e308e3, 0xafb5c508, 0x0000bffa, 0x3f788000
.long	0x3fbe3368, 0x83993052, 0x00003fff, 0xbce00000, 0xbb82795a, 0xa3d5039a, 0x0000bffa, 0x3f790000
.long	0xc897db10, 0x8355ace3, 0x00003fff, 0xbcd00000, 0x09ee5478, 0x97fa5bba, 0x0000bffa, 0x3f798000
.long	0x8d4fdf3b, 0x83126e97, 0x00003fff, 0xbcc00000, 0x2b57c149, 0x8c25c726, 0x0000bffa, 0x3f7a0000
.long	0x93ac3319, 0x82cf7503, 0x00003fff, 0xbcb00000, 0x160e1cd8, 0x80573fa8, 0x0000bffa, 0x3f7a8000
.long	0xb9a020a3, 0x828cbfbe, 0x00003fff, 0xbca00000, 0x89cfc4de, 0xe91d7e24, 0x0000bff9, 0x3f7b0000
.long	0xb3262bc5, 0x824a4e60, 0x00003fff, 0xbc900000, 0x47baf53e, 0xd1987e81, 0x0000bff9, 0x3f7b8000
.long	0x08208208, 0x82082082, 0x00003fff, 0xbc800000, 0xf9aab1b3, 0xba1f7430, 0x0000bff9, 0x3f7c0000
.long	0x123fdf8e, 0x81c635bc, 0x00003fff, 0xbc600000, 0xc941a2f2, 0xa2b25310, 0x0000bff9, 0x3f7c8000
.long	0xfaf0d277, 0x81848da8, 0x00003fff, 0xbc400000, 0x5052285e, 0x8b510f10, 0x0000bff9, 0x3f7d0000
.long	0xb94f462f, 0x814327e3, 0x00003fff, 0xbc200000, 0xe72ee35d, 0xe7f73862, 0x0000bff8, 0x3f7d8000
.long	0x10204081, 0x81020408, 0x00003fff, 0xbc000000, 0x7b993adb, 0xb963dd10, 0x0000bff8, 0x3f7e0000
.long	0x8bd1ba98, 0x80c121b2, 0x00003fff, 0xbbc00000, 0x764180a3, 0x8ae7f475, 0x0000bff8, 0x3f7e8000
.long	0x80808081, 0x80808080, 0x00003fff, 0xbb800000, 0x541af537, 0xb906ce03, 0x0000bff7, 0x3f7f0000
.long	0x08040201, 0x80402010, 0x00003fff, 0xbb000000, 0x72fed131, 0xb8d87521, 0x0000bff6, 0x3f7f8000
.long	0x00000000, 0x80000000, 0x00003fff, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x3f800000
	
//gcc makeispowerof10.c -o p10 && ./p10
isPowerOf10: // {10^n, log10(10^n)} for n < 64
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=0
.quad	0x4024000000000000, 0x3ff0000000000000	//{0x1.4p+3, 0x1p+0}, k=1
.quad	0x4059000000000000, 0x4000000000000000	//{0x1.9p+6, 0x1p+1}, k=2
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=3
.quad	0x408f400000000000, 0x4008000000000000	//{0x1.f4p+9, 0x1.8p+1}, k=4
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=5
.quad	0x40c3880000000000, 0x4010000000000000	//{0x1.388p+13, 0x1p+2}, k=6
.quad	0x40f86a0000000000, 0x4014000000000000	//{0x1.86ap+16, 0x1.4p+2}, k=7
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=8
.quad	0x412e848000000000, 0x4018000000000000	//{0x1.e848p+19, 0x1.8p+2}, k=9
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=10
.quad	0x416312d000000000, 0x401c000000000000	//{0x1.312dp+23, 0x1.cp+2}, k=11
.quad	0x4197d78400000000, 0x4020000000000000	//{0x1.7d784p+26, 0x1p+3}, k=12
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=13
.quad	0x41cdcd6500000000, 0x4022000000000000	//{0x1.dcd65p+29, 0x1.2p+3}, k=14
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=15
.quad	0x4202a05f20000000, 0x4024000000000000	//{0x1.2a05f2p+33, 0x1.4p+3}, k=16
.quad	0x42374876e8000000, 0x4026000000000000	//{0x1.74876e8p+36, 0x1.6p+3}, k=17
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=18
.quad	0x426d1a94a2000000, 0x4028000000000000	//{0x1.d1a94a2p+39, 0x1.8p+3}, k=19
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=20
.quad	0x42a2309ce5400000, 0x402a000000000000	//{0x1.2309ce54p+43, 0x1.ap+3}, k=21
.quad	0x42d6bcc41e900000, 0x402c000000000000	//{0x1.6bcc41e9p+46, 0x1.cp+3}, k=22
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=23
.quad	0x430c6bf526340000, 0x402e000000000000	//{0x1.c6bf52634p+49, 0x1.ep+3}, k=24
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=25
.quad	0x4341c37937e08000, 0x4030000000000000	//{0x1.1c37937e08p+53, 0x1p+4}, k=26
.quad	0x4376345785d8a000, 0x4031000000000000	//{0x1.6345785d8ap+56, 0x1.1p+4}, k=27
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=28
.quad	0x43abc16d674ec800, 0x4032000000000000	//{0x1.bc16d674ec8p+59, 0x1.2p+4}, k=29
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=30
.quad	0x43e158e460913d00, 0x4033000000000000	//{0x1.158e460913dp+63, 0x1.3p+4}, k=31
.quad	0x4415af1d78b58c40, 0x4034000000000000	//{0x1.5af1d78b58c4p+66, 0x1.4p+4}, k=32
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=33
.quad	0x444b1ae4d6e2ef50, 0x4035000000000000	//{0x1.b1ae4d6e2ef5p+69, 0x1.5p+4}, k=34
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=35
.quad	0x4480f0cf064dd592, 0x4036000000000000	//{0x1.0f0cf064dd592p+73, 0x1.6p+4}, k=36
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=37
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=38
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=39
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=40
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=41
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=42
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=43
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=44
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=45
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=46
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=47
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=48
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=49
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=50
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=51
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=52
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=53
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=54
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=55
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=56
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=57
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=58
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=59
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=60
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=61
.quad	0x0000000000000000, 0x0000000000000000	//{0x0p+0, 0x0p+0}, k=62
.quad	0x3ff0000000000000, 0x0000000000000000	//{0x1p+0, 0x0p+0}, k=63
	
.literal8
.align 3
one:            .double 	1.0
mone:            .double 	-1.0

c5_2:		.quad		0x3fcA3F080966DC6D	// c5 * log2(e) = 0x0.347E1012CDB8DAp0
c5_e:		.quad		0x3fc2314715265A8a	// c5 * ln(e) = c5 = .1421288350363350533019772545
c5_10:		.quad		0x3faF9A851C6C68C2	// c5 * log10(e) = 0x0.0FCD428E363461p0

threehalves:	.double 	1.50
half:           .double 	0.50
mquarter:	.double		-0.25
third:		.quad		0x3fd5555555555555	// 1/3
_1pm54:		.quad		0x3c90000000000000	// 0x1p-54
_1pm14:		.quad		0x3f10000000000000	// 0x1p-14
mzero:		.quad		0x8000000000000000	// -0
notmzero:	.quad		0x7fffffffffffffff	// -0
logup_ulp_mask:	.quad		0x8030000000000000	// xor(-0x1p-53, 0x1p-54) = 0x8030000000000000

#if defined( __x86_64__ )
.literal8
small_cut:	.quad 0x0010000000000000
large_cut:	.quad 0x7fe0000000000000
#endif

/****************************************************************************

	PIC code

****************************************************************************/
.text
#if defined(__x86_64__)
	#define REL_ADDR(_a)	(_a)(%rip)
#else
	#define REL_ADDR(_a)	(_a)-0b(%ecx)
#endif
	
#if defined( BUILDING_FOR_CARBONCORE_LEGACY )
// log2 goes into libmathCommon.A.dylib instead of libm.a.
//	BUILDING_FOR_CARBONCORE_LEGACY is a device to control which library it goes into. 
	
#define BASE2	1	
#include "log_universal.h"
#undef BASE2
#undef BASEE
#undef BASE10
	
#else	
	
#define BASEE	1	
#include "log_universal.h"
#undef BASE2
#undef BASEE
#undef BASE10

#define BASE10	1	
#include "log_universal.h"
#undef BASE2
#undef BASEE
#undef BASE10
	
#define BASEE	1	
	
#undef LOG1P
#undef LOGUP	
#define LOGUP	1	
#include "log_universal.h"

#include "log1p.h"

#undef BASE2
#undef BASEE
#undef BASE10
#undef LOG1P
#undef LOGUP	

#endif //defined( BUILDING_FOR_CARBONCORE_LEGACY )
