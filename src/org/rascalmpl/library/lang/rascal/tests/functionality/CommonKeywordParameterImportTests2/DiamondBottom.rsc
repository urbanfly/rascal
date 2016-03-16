module  lang::rascal::tests::functionality::CommonKeywordParameterImportTests2::DiamondBottom

import lang::rascal::tests::functionality::CommonKeywordParameterImportTests2::DiamondLeft;
import lang::rascal::tests::functionality::CommonKeywordParameterImportTests2::DiamondRight;
import lang::rascal::tests::functionality::CommonKeywordParameterImportTests2::DiamondTop;

test bool diamondTest() = x().left == x().right && x().leftsq == x().rightsq;

test bool Bottom_x_left1() = x() has left;
test bool Bottom_x_left2() = !x().left?;
test bool Bottom_x_left3() = x().left == 10;
test bool Bottom_x_left4() = x(left = 20).left == 20;
test bool Bottom_x_left5() = x(left = 20)?;
test bool Bottom_x_left6() = x(left = 20).left == 20;

test bool Bottom_x_leftsq1() = x() has leftsq;
test bool Bottom_x_leftsq2() = !x().leftsq?;
test bool Bottom_x_leftsq3() = x().leftsq == 100;
test bool Bottom_x_leftsq4() = !(x(left = 20).leftsq?);
test bool Bottom_x_leftsq5() = x(left = 20).leftsq == 400;

test bool Bottom_x_right1() = x() has right;
test bool Bottom_x_right2() = !x().right?;
test bool Bottom_x_right3() = x().right == 10;
test bool Bottom_x_right4() = x(right = 20).right == 20;
test bool Bottom_x_right5() = x(right = 20)?;
test bool Bottom_x_right6() = x(right = 20).right == 20;

test bool Bottom_x_rightsq1() = x() has rightsq;
test bool Bottom_x_rightsq2() = !x().rightsq?;
test bool Bottom_x_rightsq3() = x().rightsq == 100;
test bool Bottom_x_rightsq4() = !(x(right = 20).rightsq?);
test bool Bottom_x_rightsq5() = x(right = 20).rightsq == 400;