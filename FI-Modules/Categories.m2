FIMorphism = new Type of BasicList
FIRingElement = new Type of HashTable
FIMatrix = new Type of MutableHashTable
FIRing = new Type of Type

globalAssignment FIRing

-- FI MORPHISMS
--================================

FI = method()

FI List := l -> (
    if #l == 2 then new FIMorphism from l
    else new FIMorphism from {drop(l, -1), last l}
    )

FIMorphism * FIMorphism := (g, f) -> (
    if f#1 < g#1 then error "Morphisms are not composable."
    else new FIMorphism from {apply(#(g#0), i -> f#0#(g#0#i-1)), f#1}
    )

target FIMorphism := f -> last f

source FIMorphism := f -> (length first f) 

net FIMorphism := l -> net "["|net l#0|net ","|net l#1|net"]"


-- FI RINGS
--================================

fiRing = method()

fiRing (Ring) := R -> (
    RFI := new FIRing of FIRingElement from hashTable{
        baseRings => (R.baseRings)|{R}
	};
    RFI + RFI := (m,n) -> (
    	new RFI from hashTable{
    	    (symbol ring) => RFI,
    	    (symbol terms) => hashTable	apply(unique( keys terms m| keys terms n), key ->(
    			 coefsum = coefficient(m,key) + coefficient(n,key);
    			 if coefsum =!= 0_R then key => coefsum
    			 ))	
    	    }
	);
    R * RFI := (r,m) -> (
        new RFI from hashTable{
            (symbol ring) => F;
            (symbol terms) => hashTable apply( keys terms m, key -> key => r*coefficient(m,key))
        }
    );
    RFI * R := (m,r) -> r*m;
    RFI * RFI := (m,n) -> (
        eltsum = 0_RFI;
        for mkey in keys terms m do
            for nkey in keys terms n do
                if target mkey === source nkey then
                    eltsum = eltsum + (coefficient(m,mkey)*coefficient(n,nkey))*fiRingElement(mkey*nkey,RFI);
        return eltsum
    );
    RFI - RFI := (m, n) -> m + (-1)_R*n;
    return RFI
    ) 


coefficient (FIRingElement, FIMorphism) := (m,f) -> (
    if (terms m)#?f then return (terms m)#f
    else return 0
    )

terms FIRingElement := g -> g.terms


net FIRingElement := f -> (
    termsf := terms f;
    keysf := keys termsf;
    kk := coefficientRing ring f;
    N := #(keysf);
    printCoefficient := m -> (
	c := coefficient(f,m);
	if c == 1_kk then net ""
	else net c
	);
    local m;
    if N == 1 then (
	m = first keysf;
	return printCoefficient(m)|net m
	)
    else if N > 1 then (
	horizontalJoin apply(N, i -> (
		m := keysf#i;
		if i < N-1 then printCoefficient(m)|net m|net " + "
		else printCoefficient(m)|net m
		)
	    )
	)
    else net 0
    )


isFromTarget=method()

isFromTarget (FIRingElement,Thing) := (m,b) -> (
        if m === 0_(ring m) then return true
        else return all (keys terms m,key ->target key == b)
    )    

isFromSource=method()

isFromSource (FIRingElement, Thing) := (m,a) -> (
        if m === 0_(ring m) then return true
        else return all (keys terms m,key -> source key == a)
    )

isHomogeneous FIRingElement := m -> (
        if m === 0_(ring m) then return true
        else return all (keys terms m,key -> source key == source first keys terms m and target key == target first keys terms m)
    )


coefficientRing FIRing := R -> last R.baseRings


FIRing_List := (R, l) -> fiRingElement(FI l, R)

ZZ _ FIRing := (n,R) -> (
    if n =!= 0 then error "ZZ_FIRing is only defined for 0_FIRing"
    else return new R from hashTable{
        symbol ring => R,
        symbol terms => hashTable{}
    }
    )


fiRingElement = method()

fiRingElement (FIMorphism,FIRing) := (l,R) ->(
    kk := coefficientRing R;
    L := new R from hashTable{
	(symbol ring) => R,
	(symbol terms) => hashTable{
	    l => 1_kk
	    }
	};
    return L
    )



ring (FIRingElement) := m -> m.ring


-- FI MATRICES
--================================

fiMatrix = method()

fiMatrix (List,List,List) := (rowdeglist,fiEntries,coldeglist) -> (
    if not isTable fiEntries then error "Expected a rectangular matrix.";
    -- number of rows, cols
    if 1 != fiEntries // flatten / class // unique // length then error "Expected all entries to be from the same FIRing.";
    if #rowdeglist =!= #fiEntries then error "Row degrees don't match matrix";
    if #coldeglist =!= #(fiEntries#0) then error "Col degrees don't match matrix";
    if not all(#rowdeglist, i -> all(fiEntries#i, m->isFromSource(m,rowdeglist#i))) then error "The sources of the entries don't match the degrees in the rows.";
    if not all(fiEntries, row -> all(#coldeglist, i->isFromTarget(row#i,coldeglist#i))) then error "The targets of the entries don't match the degrees in the columns.";
    -- find a common ring to promote all entries to. For now, just
    -- expect them to be from the same ring. If not, throw an error.
    return new FIMatrix from hashTable {
    (symbol ring, (fiEntries#0#0).ring),
    (symbol rowdegs, rowdeglist),
	(symbol matrix, fiEntries),
    (symbol coldegs, coldeglist),
	(symbol cache, new CacheTable from {})};
    )


net FIMatrix := M -> net expression M
expression FIMatrix := M -> MatrixExpression applyTable(M.matrix, expression)
entries FIMatrix := M -> M.matrix
numRows FIMatrix := M -> #(entries M)
numColumns FIMatrix := M -> #(first entries M)
ring FIMatrix := M -> M.ring

FIMatrix * FIMatrix := (M, N) -> (
    entriesM := entries M;
    entriesN := entries N;
    if numColumns M == numRows N then (
	new FIMatrix from hashTable{
	    (symbol ring) => ring M,
	    (symbol matrix) => apply(numRows M, 
		i -> apply(numColumns N, 
		    j -> sum apply(numColumns M, k -> entriesM#i#k*entriesN#k#j)
		    )
		),
	    (symbol cache) => new CacheTable from {}
	    }
	)
    )

rowDegrees = method()

rowDegrees FIMatrix := M -> M.rowdegs

colDegrees = method()

colDegrees FIMatrix := M -> M.coldegs


/// TEST 

restart
load "Categories.m2"
S = fiRing(ZZ/3)
f = S_{2,1,3}+S_{2,1,3}+S_{2,1,3}
g = S_{1,4,5,6}
f*g

M = fiMatrix{{S_{2,1,3}, S_{2,1,3}, S_{2,1,4}}}
N = fiMatrix{{S_{1,2,3,5}},{S_{1,4,2,6}},{S_{4,3,2,1,7}}}
x = m+n
y = m+m
z = n+p
x*z
y === 2*m
y === 2/1*m
y === m*(2/1)
isFromSource(x*z,2)
isHomogeneous(x*z)
isHomogeneous(0_RFI)
isHomogeneous x

-- FIMatrix Tests

restart
load "Categories.m2"

R = fiRing(ZZ/3)
f = FI{1,2,5}
g = FI{3,1,2,4,6,7}
h = FI{5,2,6,1,3,7}
x = fiRingElement(f,R);
y = fiRingElement(g,R);
z = fiRingElement(h,R);
mat = fiMatrix ({2,5},{{x,0_R},{0_R,y+z}},{5,7})
rowDegrees mat

///
