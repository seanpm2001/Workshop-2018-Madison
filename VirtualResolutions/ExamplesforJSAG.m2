--Example 2.2

restart
needsPackage "VirtualResolutions"
X = toricProjectiveSpace(1)**toricProjectiveSpace(1);
S = ring X; B = ideal X;
J = saturate(intersect(
    ideal(x_1 - x_0, x_3 - 4*x_2),
    ideal(x_1 - 2*x_0, x_3 - 5*x_2),
    ideal(x_1 - 3*x_0, x_3 - 6*x_2)),
     B)
hilbertPolynomial(X,S^1/J)
hilbertFunction(X,J,{2,0})
minres = res J;
multigraded betti minres
vres = multiWinnow(X,minres,{{3,1}}) --(3,1) = (2,0) + (1,1)
multigraded betti vres
isVirtual(J,B,vres)
vres2 = multiWinnow(X,minres,{{2,0}})
isVirtual(J,B,vres2)


-- Trying to find example for intersectionRes
restart
needsPackage "VirtualResolutions"
N=6
X = toricProjectiveSpace(1)**toricProjectiveSpace(1)**toricProjectiveSpace(2);
S = ring X; B = ideal X;
I = intersect apply(N,i -> ideal(random({1,0,0},S)
	,random({0,1,0},S),random({0,0,1},S), random({0,0,1},S)));
J = saturate(I,B);
hilbertPolynomial(X,I)
I == J
B1 = ideal(x_0,x_1); B2 = ideal(x_2,x_3); B3 = ideal(x_4,x_5,x_6);
for i in 0 to 5 do
saturate(intersect(B1^3,B2^4,B3^2,J),B) == J
isVirtual(J,B,intersectionRes(J,B,{1,2,3}))

--example for Mike of spacecurves failing
restart
needsPackage "SpaceCurves"
curve(2,0)
curve(3,0)
curve(3,0,ZZ/2[x_0..x_3])
curve(3,0,ZZ/7[x_0..x_3])
curve(3,0,ZZ/11[x_0..x_3])
