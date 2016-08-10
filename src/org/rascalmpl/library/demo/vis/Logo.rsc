@license{
  Copyright (c) 2009-2015 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI}
@contributor{Jeroen van den Bos - Jeroen.van.den.Bos@cwi.nl (CWI)}
//START
// tag::module[]
module demo::vis::Logo

import vis::Figure;
import vis::Render;

public list[int] LogoData = [
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xfff9f9f9, 0xff9d9c9e, 0xff616063, 0xffa3a2a4, 0xfffcfcfc, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xfff7f7f7, 0xff595759, 0xff121014, 0xff616063, 0xfffcfcfc, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xfffbfbfb, 0xff7f7e80, 0xff646163, 0xffc2c1c3, 0xfff7f7f7,
0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffdddddd, 0xff747375, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffc1c0c1, 0xff8e8782, 0xffc6bdb2, 0xff908984, 0xff5b595a,
0xffcccccd, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xff565357, 0xffd7d7d7, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xfff3f3f3, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff504e4f, 0xffd3c9be, 0xffe2d7cb, 0xffe1d7cb, 0xffdfd4c9,
0xff4c4848, 0xffb5b5b7, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffdcdbdc, 0xff242226, 0xffdfdfdf, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff7f7e80, 0xff131115, 0xff636264, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffc8c8c9, 0xff696360, 0xffeadfd2, 0xffbcb3aa, 0xffbbb2a9, 0xffdfd5c8,
0xffe5d9cd, 0xff645e5c, 0xffa09ea1, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xfffefefe, 0xffffffff, 0xff7c7b7d, 0xff161418, 0xff9d9c9e, 0xfff9f9f9, 0xffffffff, 0xfffefefe, 0xffffffff,
0xfffefefe, 0xffffffff, 0xffe4e4e4, 0xffe5e5e5, 0xffffffff, 0xffffffff, 0xfff7f7f7, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff747274, 0xff0e0c10, 0xff09070c, 0xfffafafa, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff58575a, 0xffd5cbc0, 0xffe0d5c9, 0xffdfd4c8, 0xffb5ada4, 0xff948d87,
0xffede1d5, 0xffded4c8, 0xff7c7672, 0xff8c8b8d, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xfffefefe, 0xffffffff, 0xffffffff, 0xfff7f7f8, 0xff4a484b, 0xff151217, 0xff454447, 0xffe6e7e6, 0xffffffff, 0xffffffff,
0xffd8d7d8, 0xffd7d7d7, 0xffffffff, 0xffa3a2a4, 0xfff4f4f4, 0xffffffff, 0xffd5d4d5, 0xffffffff, 0xffffffff, 0xffffffff,
0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xfff7f7f7, 0xff939193, 0xff717072, 0xfffefefe, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfff5f5f6, 0xff504d4f, 0xffede2d4, 0xffdfd5c9, 0xffe1d6ca, 0xffe8ddd1, 0xffa8a099,
0xff817b76, 0xffdfd5ca, 0xffe4dace, 0xff6a6562, 0xffc2c2c2, 0xffffffff, 0xfffefefe, 0xffffffff, 0xfffdfdfd, 0xffffffff,
0xffffffff, 0xffe3e3e4, 0xfff2f2f3, 0xffffffff, 0xffffffff, 0xff403d41, 0xff141217, 0xff131116, 0xff9a999b, 0xffd3d3d4,
0xffdfdfdf, 0xff59575a, 0xffc6c6c7, 0xff3a373b, 0xffecebec, 0xffdfdfdf, 0xffbcbcbd, 0xffeaeaea, 0xffdddcdd, 0xffeeedee,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffe2e1e2, 0xffa3a2a4, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffd0d0d1, 0xff8a8480, 0xffe8ded1, 0xffcbc1b7, 0xffaca49c, 0xffebe1d3, 0xffe7ddd0,
0xffbab1a8, 0xff827b76, 0xffe9ded1, 0xffdacfc4, 0xff4f4b4b, 0xffcccccd, 0xffffffff, 0xffffffff, 0xfffcfcfc, 0xffc1c0c1,
0xffffffff, 0xfffefefe, 0xffb4b3b5, 0xffcccccc, 0xfff9f8f8, 0xff211f24, 0xff2c2924, 0xff373323, 0xff0a0a13, 0xff0f0c11,
0xff18161a, 0xff1d1b1f, 0xff18161a, 0xff323034, 0xff666568, 0xff4b494c, 0xff838183, 0xff878688, 0xfff6f6f6, 0xffffffff,
0xffffffff, 0xfffefefe, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffabaaac, 0xffbcbbbc, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffb5b5b6, 0xffaba39d, 0xffe2d8cc, 0xffdfd4c8, 0xffcec4ba, 0xff6b6563, 0xffc1b9af,
0xffe3d8cc, 0xffb1a8a0, 0xff6d6764, 0xffe8dcd0, 0xffd9cfc3, 0xff3f3c3e, 0xffebebeb, 0xffffffff, 0xffffffff, 0xffedeced,
0xff5d5c5f, 0xfff0f0f0, 0xffffffff, 0xff5d5b5e, 0xff312f32, 0xff2e2b24, 0xffe3d54c, 0xffe7d42d, 0xff625122, 0xff211e24,
0xff403e42, 0xff1a181c, 0xff1a181c, 0xff1a181c, 0xff1a181c, 0xff19161b, 0xff151317, 0xffa6a4a6, 0xff838284, 0xffa3a2a4,
0xffcfced0, 0xffffffff, 0xffffffff, 0xffffffff, 0xffefeeef, 0xff312f33, 0xfff1f1f1, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffa3a2a4, 0xffc3b9b0, 0xffe4d9cd, 0xffe2d7cb, 0xffe4dacd, 0xffe4d9ce, 0xff89827e,
0xff817a75, 0xffa9a199, 0xffa39a93, 0xff938b86, 0xffe1d6ca, 0xffb9b0a7, 0xff777577, 0xffffffff, 0xfffefefe, 0xffffffff,
0xffcfcecf, 0xff323134, 0xff858385, 0xff8e8d8f, 0xff1a181c, 0xffcdc262, 0xfff4df32, 0xff786320, 0xff8b898e, 0xffffffff,
0xffffffff, 0xffb0b0b1, 0xff171519, 0xff383417, 0xffcdc45f, 0xffa9a8a8, 0xff6a653a, 0xff161413, 0xff6c6a6f, 0xffcfcfcf,
0xffffffff, 0xfffefefe, 0xffffffff, 0xffe8e8e8, 0xff302e32, 0xff919092, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xff9b9a9b, 0xffc4bbb1, 0xffe3d8cb, 0xffbab1a8, 0xff918a84, 0xffb3aba2, 0xffe9ded1,
0xffdbcfc4, 0xffbab1a8, 0xff736e6b, 0xff403b3c, 0xffa29992, 0xffe6dbcf, 0xff77706c, 0xffa9a8aa, 0xffffffff, 0xfff9f9f9,
0xfff2f2f2, 0xffdddcdd, 0xff262327, 0xff13111a, 0xff989260, 0xfffcea49, 0xff8f7b1f, 0xff747374, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xff454346, 0xff131116, 0xffb2a947, 0xfffffb8f, 0xfffdee50, 0xffd7c826, 0xff26221a, 0xff211f24,
0xff5d5b5e, 0xfff6f6f7, 0xffdfdfe0, 0xff2e2c30, 0xff525154, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xff959394, 0xffc7bdb4, 0xffe0d6ca, 0xffe1d6ca, 0xffe1d6ca, 0xffa8a199, 0xff66615e,
0xffbab0a7, 0xffddd3c7, 0xffe4d9cd, 0xffc8bfb5, 0xff494545, 0xffbdb4ab, 0xffe6dbcf, 0xff363234, 0xffe1e0e1, 0xffffffff,
0xffa7a6a8, 0xff5f5d61, 0xff5e5d5f, 0xff2e2b20, 0xffe7dc7a, 0xffdfcb27, 0xff3b321c, 0xfff8f8f8, 0xffffffff, 0xffefefef,
0xfff9f9f9, 0xffffffff, 0xff9e9d9e, 0xff100e12, 0xff12111a, 0xffada123, 0xffcbbc25, 0xffaca125, 0xff474221, 0xff18161b,
0xff161419, 0xff2a282c, 0xff120f14, 0xff484649, 0xfff4f4f5, 0xfffefefe, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xff959495, 0xffc8beb4, 0xffe4d9cd, 0xffe1d7cb, 0xffdfd4c8, 0xffe7dccf, 0xffe1d6ca,
0xffa69e97, 0xff76706c, 0xffdfd5c8, 0xffe6dbcf, 0xffe4dace, 0xff7c7572, 0xffcac1b7, 0xffcbc1b7, 0xff636264, 0xfff9f9f9,
0xffffffff, 0xffc6c6c7, 0xff838284, 0xff635e38, 0xfffbee60, 0xffae9925, 0xff5a585a, 0xffffffff, 0xffffffff, 0xff545356,
0xff69686a, 0xfffcfcfc, 0xff939194, 0xff3f3418, 0xff19171b, 0xff14121b, 0xff161314, 0xff1c191d, 0xff151319, 0xff17151a,
0xff13111c, 0xff1c1819, 0xff2f2d30, 0xffc7c6c7, 0xffaeacae, 0xffe3e3e4, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xff9b9a9b, 0xffc4bab0, 0xffe3d8cc, 0xffded3c7, 0xffe3d9cc, 0xffe0d5ca, 0xffddd3c7,
0xffe2d7cb, 0xffccc3b9, 0xff3b3839, 0xffd5cbc0, 0xffdfd5c9, 0xffcfc4ba, 0xff847d79, 0xffe4d9cc, 0xff817a76, 0xffc3c2c3,
0xffffffff, 0xffffffff, 0xffabaaab, 0xff999351, 0xfffcec4a, 0xff7f6b23, 0xff85848b, 0xffffffff, 0xffffffff, 0xff383639,
0xff1b191d, 0xffc1c1c1, 0xff575558, 0xff947d21, 0xff23201c, 0xff1a181c, 0xff817f82, 0xffffffff, 0xffdfdee0, 0xff3d3a30,
0xffa59120, 0xff4c3a20, 0xff29262b, 0xff8b898b, 0xffededee, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffa5a5a7, 0xffc0b7ad, 0xffe3d8cb, 0xffe0d5c9, 0xffdacfc4, 0xffbfb5ad, 0xffb5ada4,
0xffd3c8bd, 0xffebdfd2, 0xffd0c6bb, 0xff55504f, 0xffc3bab0, 0xffe7dccf, 0xff97908a, 0xff918a84, 0xffdad0c4, 0xff484446,
0xfffafafa, 0xffffffff, 0xff676468, 0xffcbc375, 0xfff8e645, 0xff625122, 0xffa5a5aa, 0xffdad9d9, 0xfff5f5f5, 0xff323034,
0xff161418, 0xff939295, 0xff2f2920, 0xffd4bc2d, 0xff29261a, 0xff6c6a6d, 0xffffffff, 0xffffffff, 0xffffffff, 0xff575444,
0xffe9d223, 0xff33271c, 0xff413f43, 0xff89888a, 0xffa1a0a2, 0xffbfbfbf, 0xfff3f3f4, 0xffffffff, 0xfffefefe, 0xfffefefe,
0xffffffff, 0xffffffff, 0xffffffff, 0xffbcbcbe, 0xffa29b94, 0xffe4dacd, 0xffdfd5c9, 0xffe3d8cb, 0xffdcd2c6, 0xffd5cbc0,
0xff968f8a, 0xff645f5d, 0xff827b76, 0xff958e87, 0xff403d3d, 0xffc5bbb2, 0xffeadfd2, 0xff726b69, 0xffb2aaa1, 0xffa8a098,
0xff636266, 0xffffffff, 0xff2b292d, 0xffe4dd96, 0xfff9e744, 0xff655423, 0xffb3b3b8, 0xff727174, 0xff525054, 0xff1e1c20,
0xff18161a, 0xff4a4a52, 0xff665722, 0xffefdc30, 0xff2e2b1d, 0xfffdfdfd, 0xffeaeaea, 0xff515052, 0xfff0f0f2, 0xff535146,
0xffd5be24, 0xff140f13, 0xff858486, 0xffc7c7c8, 0xffdddcdd, 0xfff4f4f4, 0xffd7d7d8, 0xff838184, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffe0e0e0, 0xff6c6866, 0xffebe0d3, 0xffe1d6ca, 0xffd9d0c4, 0xffdad0c4, 0xffd9cfc4,
0xffeadfd2, 0xffeee2d6, 0xffc6beb5, 0xff96908a, 0xff87817d, 0xff605a58, 0xffc1b8ae, 0xffe5d9ce, 0xff5f5a58, 0xffdfd4c9,
0xff64605e, 0xffd2d1d3, 0xff19171b, 0xffece7ac, 0xfffded54, 0xff856f23, 0xffa0a0a6, 0xff9d9c9e, 0xff0d0b0f, 0xff19171b,
0xff1b191e, 0xff1d1a1f, 0xffd3bb1f, 0xffecdd40, 0xff656256, 0xffffffff, 0xffd7d6d7, 0xff18161a, 0xff6a696e, 0xff6c683c,
0xff9b8822, 0xff3b3b44, 0xff464347, 0xffa5a5a6, 0xfffbfbfb, 0xffe9e9e9, 0xff656262, 0xff1b191d, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff4d4b4f, 0xffd8cec2, 0xffe0d5ca, 0xffd2c8bd, 0xffc8bfb5, 0xffa8a199,
0xffa29a94, 0xff9d958e, 0xff928985, 0xffded3c8, 0xffe3d8cb, 0xffded3c8, 0xff6d6764, 0xffcbc1b6, 0xff9e968f, 0xff847d78,
0xffcdc3b8, 0xff6a686a, 0xff19171c, 0xffe4dfaf, 0xfffef587, 0xffc0a920, 0xff504d4e, 0xffe8e7e8, 0xff4d4c4f, 0xff16151b,
0xff16131a, 0xffa49311, 0xfffbe923, 0xffe4d764, 0xff444241, 0xff5a585b, 0xff7d7b7e, 0xff1a181c, 0xff23212b, 0xff9d9129,
0xff3a321f, 0xffababad, 0xffffffff, 0xffffffff, 0xffffffff, 0xff666466, 0xffa79f97, 0xff403e42, 0xffffffff, 0xfffefefe,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffc1c2c3, 0xff655e5c, 0xffe6dccf, 0xffe4d9cd, 0xffe2d7cb, 0xffe8ded2,
0xff726c67, 0xff524f49, 0xff97936f, 0xff3a3632, 0xffc5bcb2, 0xffdfd4c8, 0xffe3d8cd, 0xff3d3a3a, 0xffdacfc3, 0xff3c383a,
0xffbdb4aa, 0xff686261, 0xff19171b, 0xffcdc789, 0xfffffde9, 0xfff1e36f, 0xff504822, 0xff1a171b, 0xff17141b, 0xff37331a,
0xffd3c627, 0xfffff252, 0xfffbeb49, 0xffd6cd7f, 0xff29272b, 0xff1a181c, 0xff1a181c, 0xff19171b, 0xff1f1d1c, 0xffa09020,
0xff23232e, 0xffe2e1e2, 0xffffffff, 0xffffffff, 0xff6d6d6f, 0xff99938e, 0xffa09890, 0xff838284, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xff636163, 0xffbab1a7, 0xffded4c8, 0xffddd3c7, 0xff534e53,
0xff7d7725, 0xffffffd1, 0xfffef47d, 0xffe6db55, 0xff565134, 0xff9e9694, 0xffe5dacd, 0xffd2c8bd, 0xff5b5655, 0xffbcb3aa,
0xff363234, 0xffb5aca4, 0xff1a181c, 0xffa59f62, 0xfff8f3c5, 0xff8d864b, 0xffd7ca62, 0xffbcb036, 0xff9e941d, 0xff6f6717,
0xff6a663f, 0xffaeab97, 0xfffffacc, 0xffbfbb9e, 0xff5c595c, 0xff1c1a1e, 0xff19171b, 0xff312f35, 0xff615a1d, 0xff403a19,
0xff69676b, 0xffffffff, 0xfffbfafb, 0xff7e7d7f, 0xff9a938e, 0xffb7afa6, 0xff6c6561, 0xffcdcdce, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffe2e2e2, 0xff5a5556, 0xffe6dbce, 0xff7f797a, 0xff6d6413,
0xfffff02c, 0xffedd933, 0xffb59d25, 0xffbfb228, 0xffe7d730, 0xff605b2d, 0xff605a5c, 0xffe8ddd0, 0xff98908a, 0xff756f6b,
0xff87807b, 0xff847c78, 0xff18161b, 0xff736f47, 0xfff2e891, 0xff242117, 0xff776f24, 0xffd4c626, 0xffecdb28, 0xffbfb224,
0xff544d19, 0xff13121b, 0xff646265, 0xffadaba4, 0xff777678, 0xffeeedee, 0xff92919c, 0xff4d4928, 0xffa19521, 0xff181517,
0xfff7f6f7, 0xfff3f3f3, 0xff444246, 0xffbab1a9, 0xff857e79, 0xffd2c9be, 0xff595453, 0xfffcfcfc, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffabaaac, 0xff585453, 0xff302c21, 0xffe6db55,
0xfffef8c6, 0xffe3d04b, 0xff3e3a2a, 0xff2f2c23, 0xff7d7628, 0xffcbbc19, 0xff58534f, 0xff575251, 0xffd4cabf, 0xff413e3e,
0xff8c8480, 0xff423d3e, 0xff292629, 0xff47442b, 0xfff3ea90, 0xff80761d, 0xfff8e60c, 0xffe2d548, 0xfffbeb3d, 0xfff9e92e,
0xffefdf25, 0xff847b24, 0xff1e1b1a, 0xff2a272a, 0xff252218, 0xff393418, 0xff958b26, 0xffecdc28, 0xff2c2919, 0xffa3a2a5,
0xffdededf, 0xff514f50, 0xffd7cdc4, 0xffada59c, 0xffaba39c, 0xffcbc1b7, 0xff737171, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xff7d7d7e, 0xff564f0c, 0xfffaf291,
0xfffdf59e, 0xfffbed44, 0xfff2e43c, 0xffc1b74d, 0xff4a472e, 0xff433e1e, 0xff534f3f, 0xff423d41, 0xff312d32, 0xff585354,
0xff111016, 0xff221f24, 0xff1c1a1d, 0xff1a181a, 0xffdcd15f, 0xffe4d52a, 0xffcdc026, 0xff26242d, 0xffc2ba77, 0xfffff250,
0xfffae82d, 0xffe1d121, 0xff898127, 0xff211e1c, 0xffa1951d, 0xfffcf5a0, 0xfff4e763, 0xff4b461f, 0xff535259, 0xff908f92,
0xff696564, 0xffd8cec3, 0xffaca49b, 0xff7e7875, 0xffcac1b7, 0xffaca39b, 0xff9c9b9d, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff5e5c5f, 0xff938813, 0xffffed17,
0xffe5d518, 0xffc0ae24, 0xffc9bb22, 0xffdccc1d, 0xfffeeb17, 0xff544f19, 0xffc9bf5f, 0xfff6efa1, 0xffbdb888, 0xff989371,
0xff8f8b66, 0xff676450, 0xff36332c, 0xff1b171b, 0xff776e20, 0xfffef05f, 0xfffff344, 0xff504a1f, 0xff19171e, 0xff8a866a,
0xfff6ee8c, 0xfffaee63, 0xffe2d338, 0xffa1951b, 0xffdace4b, 0xffefe79b, 0xff5d561e, 0xff232024, 0xff6b6a6d, 0xff8f8a86,
0xffe5d9ce, 0xff978f88, 0xff686462, 0xffa59d96, 0xffdcd1c6, 0xff65605e, 0xffd0d0d1, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff3f3d40, 0xffc0b546, 0xfffffab0,
0xffd7c138, 0xff352f22, 0xff2f2b21, 0xff534d24, 0xff807720, 0xff4a441d, 0xffe6d625, 0xfff2e223, 0xffe7d726, 0xff978c20,
0xff39341e, 0xff6b641f, 0xffbda71e, 0xffd9bd1f, 0xff6a5c1c, 0xffdfd264, 0xfffdef67, 0xffe8d935, 0xff2b281b, 0xff100e16,
0xff100e14, 0xff3b392f, 0xff6d6629, 0xfffbe812, 0xffd5c736, 0xff5e5719, 0xff241d1b, 0xff383538, 0xffa59e97, 0xffcec4b9,
0xff75706c, 0xff4b4848, 0xff8f8983, 0xffb7afa7, 0xffd5cbc0, 0xff3e3c40, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff504e51, 0xffcab420, 0xfffef153,
0xfff9eb55, 0xffe1d64c, 0xffd3c41e, 0xff8a801e, 0xff191719, 0xff4e4820, 0xffa59b2e, 0xff7c7527, 0xff2d291c, 0xff18161b,
0xff2a271b, 0xffd4c728, 0xfffaef62, 0xfffdf594, 0xfff1e558, 0xff726c3b, 0xfffffcb6, 0xffeedd37, 0xffbeb232, 0xff151317,
0xff85826d, 0xffebe16e, 0xffecdb1e, 0xffa39824, 0xff2e2c1d, 0xff211d1c, 0xff8f7120, 0xff3c383b, 0xff76706b, 0xff565151,
0xffc1b8b0, 0xffcbc0b7, 0xff706a68, 0xffddd3c7, 0xff5e5956, 0xffaeadaf, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffa3a2a4, 0xff6c5d1d, 0xffa19120,
0xff9f931f, 0xff988d1f, 0xff807727, 0xff484429, 0xff5d5c5e, 0xff737177, 0xff241f1d, 0xff755c23, 0xff3e381b, 0xff19171b,
0xff302c1b, 0xffeade66, 0xfffdfdfd, 0xfffdfdff, 0xfffff9a8, 0xffbaae33, 0xffccc9af, 0xfff7efb0, 0xffe0d033, 0xffddd048,
0xffe0d677, 0xffbfb124, 0xff5f5924, 0xff26211d, 0xff6c5821, 0xff342c1d, 0xffcba721, 0xff372c1e, 0xff746f6f, 0xffe5dace,
0xffaea69d, 0xff605c5a, 0xffded5ca, 0xffcbc1b6, 0xff403c3f, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffb6b6bb, 0xff969497,
0xff918f8f, 0xff9a999d, 0xffacacb3, 0xffcbcbce, 0xffffffff, 0xff807b71, 0xffa58d24, 0xffe3ce31, 0xfff1e13a, 0xff8f841b,
0xff564e1e, 0xfff9ec5c, 0xfffdf8c3, 0xfffbf6c9, 0xfffbf5c0, 0xfff2e240, 0xff938c4a, 0xffffffda, 0xffe5db78, 0xff8f8521,
0xff49421c, 0xff4c461f, 0xff80761e, 0xffad9524, 0xff43381f, 0xff3c351b, 0xfff4da17, 0xff977925, 0xff5d5a5f, 0xff807a76,
0xffa69f98, 0xffaaa29a, 0xffd4cac0, 0xff827b76, 0xffbcbbbd, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xfffcfcfc, 0xff494852, 0xffab8f2a, 0xffead942, 0xfffefad1, 0xfffdfdf8, 0xfffaed69,
0xffcdb722, 0xffe8d62e, 0xfffbed61, 0xfffbee6d, 0xfffbee7d, 0xfffbeb46, 0xffc2b428, 0xff4c4629, 0xff524b22, 0xff938824,
0xffddcd28, 0xffd3c522, 0xffc3b523, 0xff443e1e, 0xff13121c, 0xff82771b, 0xffffef20, 0xffd4be20, 0xff4a4240, 0xffc3bab0,
0xff56514f, 0xff9f9792, 0xffdbd1c5, 0xff525052, 0xfff5f5f5, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xfffefefe, 0xffffffff, 0xff777577, 0xff0d0c18, 0xffc4ac32, 0xffffffc7, 0xffa0a6a4, 0xffa0b39d, 0xfff6ea97,
0xffead926, 0xffd8c924, 0xfff9e937, 0xfffbea35, 0xfffae932, 0xfffcec33, 0xfff0df25, 0xffb0a41f, 0xff9f973a, 0xff847c30,
0xff776e1d, 0xffc8ba22, 0xffa19723, 0xff2a261e, 0xff12111b, 0xffccbe1e, 0xfffcea2e, 0xffe8d918, 0xff4c401e, 0xff484447,
0xffbfb7ae, 0xffe9ded1, 0xff454040, 0xffc4c3c4, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xfffefefe, 0xffffffff, 0xff8a898b, 0xff151317, 0xff12101b, 0xffa89b29, 0xfffffb91, 0xffceca7e, 0xff157688, 0xff44756b,
0xffe1cb24, 0xffd7c826, 0xfff0df28, 0xfffbe92a, 0xfffbea1f, 0xffe2d214, 0xff7e793c, 0xffded894, 0xffecece0, 0xfff4f3e7,
0xffb5aa39, 0xff5d571c, 0xffada22a, 0xff7a6627, 0xff554820, 0xffdacb23, 0xfffbeb4f, 0xfff4e222, 0xff70621b, 0xff908986,
0xffe3d8cc, 0xff5f5956, 0xffa7a6a7, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe,
0xffffffff, 0xffbcbcbe, 0xff241e18, 0xff1c1a1c, 0xff11101c, 0xff95891b, 0xfffff854, 0xffb9b155, 0xff24899c, 0xff07a9ba,
0xff25574d, 0xffdecb25, 0xffd4c525, 0xfffae828, 0xfff3e216, 0xff686335, 0xffeee587, 0xffddc62f, 0xfffcee55, 0xfffbf06b,
0xfffdf28a, 0xff998f2b, 0xff514723, 0xff655325, 0xffa68b25, 0xffd4c424, 0xfffbec5a, 0xfff7e841, 0xff86781c, 0xff696361,
0xff8a827d, 0xff807e81, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe,
0xfff1f1f2, 0xff4c433c, 0xffb49723, 0xffac9f12, 0xff544d16, 0xff57501d, 0xffdcc81c, 0xff617c76, 0xff17aebd, 0xff00616e,
0xff56562a, 0xffb9ac2f, 0xffb4a019, 0xfff3e023, 0xff79701f, 0xffddcf2d, 0xff655e23, 0xff352d15, 0xffe7dd68, 0xfffefce7,
0xfffaf2a0, 0xffffee2f, 0xffbaad2a, 0xff463f20, 0xffaa8e25, 0xffdccd25, 0xfffbee62, 0xfff8ea4d, 0xff94861e, 0xff2c2828,
0xff979798, 0xfffdfdfd, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xff797779, 0xff7b651d, 0xffecdd4d, 0xfffffbd3, 0xfffcf057, 0xffd4c418, 0xff6d7b60, 0xff28adbb, 0xff008694, 0xff13656f,
0xff317c84, 0xff319ca7, 0xff369da8, 0xff70772c, 0xff645c1b, 0xff8b8124, 0xff2d2a24, 0xffe1d873, 0xfffbed5e, 0xfffbec35,
0xfff7e948, 0xfff8ea50, 0xfffae81a, 0xffeddc24, 0xff6c641f, 0xff8f8521, 0xfff6eb75, 0xfffaed5b, 0xff9a8919, 0xff5d5b5a,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffc3c2c3,
0xff171210, 0xffb09d25, 0xfffbf8da, 0xfff7f1c9, 0xffebe18f, 0xff7e8a5e, 0xff2ca7b9, 0xff007a89, 0xff414b28, 0xffc1ae21,
0xffdfc913, 0xff556e39, 0xff007485, 0xff626a2a, 0xff413c1e, 0xff3e3a24, 0xffdcd268, 0xffa89d35, 0xff87750f, 0xfff9ec68,
0xfffdf8bb, 0xfffaee64, 0xfffae924, 0xfffbe91f, 0xfffff55b, 0xfff5e647, 0xfff9f193, 0xfffbf286, 0xff9b8915, 0xff6f6b6b,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfff2f2f2, 0xff3a383b,
0xff17151b, 0xff8e8222, 0xff808568, 0xff6d9a93, 0xff7ea19b, 0xff28a8b7, 0xff007f8f, 0xff273427, 0xffcfbf24, 0xfffae92e,
0xfff3e12a, 0xff4f7753, 0xff4d5523, 0xffe6d519, 0xff3e3920, 0xffab9f20, 0xff887f2b, 0xff1e1c1d, 0xff837f52, 0xfff7f0a3,
0xfff7ea60, 0xfff1e037, 0xfff7e726, 0xfffbe90e, 0xfffbed52, 0xfffcf9e1, 0xfffdfdff, 0xfffaf17f, 0xff927e15, 0xff8b8888,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffa2a1a3, 0xff27221d,
0xff1a181a, 0xff29261d, 0xffc7b913, 0xff0a6c7b, 0xff01a0b1, 0xff008e9e, 0xff234137, 0xffeede29, 0xffe3d326, 0xffe1d029,
0xfff8e72d, 0xffb9a923, 0xfff1df1d, 0xffcabb16, 0xff25221b, 0xff625b23, 0xff4d471a, 0xfff9eb4c, 0xfffffa7d, 0xfff2e12f,
0xffbfaa1e, 0xff7c6522, 0xffbba51f, 0xffe2ce19, 0xfff2df0f, 0xfff7e62b, 0xfff8eb56, 0xffecd91c, 0xff856b1c, 0xffafadad,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xff3f3932, 0xffa89321,
0xffada447, 0xff655d19, 0xff8a7e1e, 0xff838225, 0xff016b7a, 0xff037c88, 0xffab9f23, 0xfffbea2d, 0xfff9e82a, 0xffd0ba23,
0xffcaba28, 0xfff0df1f, 0xffe5d41a, 0xffdacb1b, 0xff645b23, 0xff13111b, 0xff4f491d, 0xffaea220, 0xffbcad20, 0xff928021,
0xff3f351c, 0xff606068, 0xff352e26, 0xff4b3e15, 0xff7a691c, 0xff93811d, 0xff95821a, 0xff79661a, 0xff4c3d26, 0xffdfdedf,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xff848385, 0xff504216, 0xffe5d87a,
0xfffefef9, 0xfffbf3a2, 0xfff4e32d, 0xffd7c025, 0xff7b6f1d, 0xff054a57, 0xff24645a, 0xfff9e82c, 0xfffae92a, 0xffe5d51e,
0xff211e1e, 0xff887e23, 0xffc5b322, 0xffc6b724, 0xffaa8b29, 0xff11111b, 0xff1a181c, 0xff19171b, 0xff18161a, 0xff2f2d30,
0xffb2b1b3, 0xffffffff, 0xfffcfcfc, 0xffb1b1b1, 0xff6b696c, 0xff4f4d50, 0xff5b5a5c, 0xff9d9c9d, 0xfff3f3f3, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffe3e3e4, 0xff18161a, 0xff887324, 0xfff6eec2,
0xfffcf6c6, 0xfffbf4b7, 0xfffaec66, 0xfff7e628, 0xffe1cb24, 0xffb09c1c, 0xff79731b, 0xfff5e423, 0xffeada21, 0xffb4a427,
0xff0f0e1b, 0xff11101b, 0xff14121c, 0xff342c1f, 0xff513c1f, 0xff111117, 0xff525053, 0xffc9c8c9, 0xffffffff, 0xffffffff,
0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xff727073, 0xff19171b, 0xff675721, 0xfff4e15a,
0xfffaeb42, 0xfffae93e, 0xfffae933, 0xfffae931, 0xfff2e124, 0xffb9a720, 0xff322d1c, 0xff625b1f, 0xffaa9827, 0xff776325,
0xff15141b, 0xff1a181c, 0xff171519, 0xff0d0a0f, 0xff474649, 0xffc7c6c8, 0xfff8f8f8, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffdcdcdc, 0xff252326, 0xff1a181c, 0xff312a1d, 0xffd3c122,
0xfff7e72d, 0xfff5e42d, 0xfff3e22d, 0xffecdb2d, 0xffd3c423, 0xffaf9f25, 0xff261f1d, 0xff15131a, 0xff141119, 0xff1a171a,
0xff232125, 0xff302e32, 0xff626063, 0xffd0d0d1, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xfffdfdfd, 0xffe0e0e1, 0xffb1b0b2, 0xff39373a, 0xff0a070c, 0xff0e0b10, 0xff0b0910, 0xff332e12,
0xff797019, 0xff96891d, 0xff93831d, 0xff817219, 0xff716217, 0xff62511f, 0xff373233, 0xff525053, 0xff777679, 0xffa6a5a7,
0xffc9c9ca, 0xfff1f1f1, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffe2e2e2, 0xffc0bfc0, 0xffbcbbbc, 0xffbcbcbd, 0xffbab9ba, 0xffb6b5b6, 0xffb4b3b4,
0xffb4b3b5, 0xffb7b6b7, 0xffbfbfc0, 0xffd4d4d5, 0xffeeeeee, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xfffefefe, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff];

int width = 50;
int height = 50;

Figure logo(){
	list[list[Figure]] boxes;
	boxes = for(i <- [0..height]){
		        append for(j <- [0..width]){
			               append box(fillColor(LogoData[i*50+j]),lineWidth(0));
		}
	}
	return grid(boxes,aspectRatio(1.0));
}

void renderLogo() {
  render(logo());
}
// end::module[]