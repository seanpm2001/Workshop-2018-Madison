newPackage(
        "ParametricGB",
        Version => "0.1", 
        Date => "April 16, 2018",
        Authors => {{Name => "Thomas Baath",
		     Email => "kb548@cornell.edu"},
		    {Name => "Dylan Peifer", 
                     Email => "djp282@cornell.edu", 
                     HomePage => "https://www.math.cornell.edu/~djp282"},
		    {Name => "David Swinarski",
		     Email => "dswinarski@fordham.edu"}},
        Headline => "Compute parametric Groebner bases",
        DebuggingMode => true
        )

export {"comprehensiveGroebnerSystem"}

-------------------------------------------------------------------------------
--- comprehensive Groebner systems
-------------------------------------------------------------------------------
comprehensiveGroebnerSystem = method()
comprehensiveGroebnerSystem(List) := List => (F) -> (
    -- F = a list of polynomials in k[U][X]
    -- returns a list containing the branches of a minimal comprehensive Groebner system of F
    
    comprehensiveGroebnerSystem({}, {1}, F)
    )
comprehensiveGroebnerSystem(List, List, List) := List => (E, N, F) -> (
    -- E = a list of polynomials in k[U]
    -- N = a list of polynomials in k[U]
    -- F = a list of polynomials in k[U][X]
    -- returns a list containing the branches of a minimal comprehensive Groebner system of F
    --     on V(E) \ V(N)

    -- handle special cases of trivial input
    if #F == 0 or not isConsistent(E, N) then return {};

    -- get the main rings k[U][X] and k[U] we are working over    
    kUX := ring first F;
    kU := coefficientRing kUX;

    F = F | apply(E, e -> sub(e, kUX));
    G := first entries gens gb ideal F;

    -- if the ideal is <1> then we are done
    if any(G, g -> g == 1) then return {(E, N, {1})};

    -- find all the elements in G that are actually in k[U], then sub them into k[U]
    Gr := select(G, g -> (degree g)#0 == 0);
    Gr = apply(Gr, g -> sub(g, kU));

    PGB := {};
    if isConsistent(E, prod(Gr, N)) then (
    	PGB = {(E, prod(Gr, N), {1})};
	);

    if isConsistent(Gr, N) then (
	Gm := noncomparable(select(G, g -> (degree g)#0 != 0));
	H := apply(Gm, leadCoefficient);
	h := if #H == 0 then 1 else lcm H;
	if isConsistent(Gr, prod(N, {h})) then (
	    PGB = append(PGB, (Gr, prod(N, {h}), Gm));
	    );
	PGB = PGB | flatten for i to #H-1 list (
	                        comprehensiveGroebnerSystem(append(Gr, H#i),
	                                                    prod(N, {product(take(H, i))}),
		                                            select(G, g -> (degree g)#0 != 0))
			        );
	);

    PGB
    )

-------------------------------------------------------------------------------
--- comprehensive Groebner bases
-------------------------------------------------------------------------------
ComprehensiveGroebnerSystemLocus = new Type of HashTable 

net ComprehensiveGroebnerSystemLocus := x -> (
     orderedPairs := {("Equations",x#"Equations"),("Inequations",x#"Inequations"),("gb",x#"gb")};    
     horizontalJoin flatten (
          "{",
          -- the first line prints the parts vertically, second: horizontally                                                         
          stack (horizontalJoin \ apply(orderedPairs,(k,v) -> (net k, " => ", net v))),
          -- between(", ", apply(pairs x,(k,v) -> net k | "=>" | net v)),                                                             
          "}"
          ))

makeCGSL = (E,N,F) -> (
    new ComprehensiveGroebnerSystemLocus from hashTable({"Equations"=>E,"Inequations"=>N,"gb"=>F})    
)

comprehensiveGroebnerBasis = method(Options => {Verbosity => 0})
comprehensiveGroebnerBasis(List) := List => opts -> (F) -> (
    comprehensiveGroebnerBasis({}, {1}, F, Verbosity => opts.Verbosity)
    )
comprehensiveGroebnerBasis(List, List, List) := List => opts -> (E, N, F) -> (
    cgs:=CGBPoly(E,N,F,opts);
    cgs = simplifyCGS(cgs);
    return apply(cgs, i -> makeCGSL(i_0,i_1,i_2))
)

CGBPoly =  (E, N, F, opts) -> (
    -- E = a list of polynomials
    -- N = a list of polynomials
    -- F = a list of polynomials

    -- Step 1
    if not isConsistent(E,N) then return {};
    if opts.Verbosity > 0 then (
	print concatenate("I am CGS on E=",toString(E),", N=",toString(N),", F=",toString(F)) << endl;
    );
    -- Step 2
    R:=ring(first F);
    y:=getSymbol "y";
    Ry:=R(monoid [y]);
    y=Ry_0;
    L1:=apply(F, f -> f*y);
    L2:=apply(E, e -> e*y-e);
    G0:= flatten entries gens gb ideal(join(L1,L2));
    -- Step 3
    G:=select(G0, g -> coefficient(y,g)!=0);
    if opts.Verbosity > 0 then (
    	print concatenate("G=",toString(G))<< endl;
    );
    G1st:=apply(G, g-> coefficient(y,g));
    if opts.Verbosity > 0 then (
    	print concatenate("G1st=",toString(G1st))<< endl;
    );
    -- Step 4
    if member(1_Ry,G1st) then (
        return {E,N,{first select(G, g-> coefficient(y,g)==1_Ry)}}	
    );
    -- Step 5
    Gry:=select(G, g-> first coefficients(coefficient(y,g)) == matrix {{1_R}});
    if opts.Verbosity > 0 then (
    	print concatenate("Gry=",toString(Gry)) << endl;
    );
    Gr:=apply(Gry, g -> lift(coefficient(y,g),coefficientRing(R)));
    Gr = unique join(Gr,E);
    if opts.Verbosity > 0 then (
    	print concatenate("Gr=",toString(Gr)) << endl;
    );
    -- Step 6
    CGS:={};
    if isConsistent(E,prod(Gr,N)) then (
	CGS = {{flatten entries mingens ideal(E),prod(Gr,N),Gry}}	
    );
    if opts.Verbosity > 0 then (
    	print concatenate("CGS at end of Step 6 = ",toString CGS) << endl;
    );
    -- Step 7
    if not isConsistent(Gr,N) then return CGS;
    -- Step 8
    Gm:=minimalDicksonBasis(select(G1st, g-> not member(g,apply(Gr, h -> h*1_R))));
    if opts.Verbosity > 0 then (
    	print concatenate("Gm=",toString(Gm)) << endl;
    );
    Gmy:=select(G, g-> not member(g,Gry));
    Gmy=select(Gmy, g-> member(coefficient(y,g),Gm)); 
    if opts.Verbosity > 0 then (
    	print concatenate("Gmy=",toString(Gmy)) << endl;
    );
    -- Step 9
    H:=unique apply(Gm, g-> leadCoefficient(g));
    if opts.Verbosity > 0 then (
    	print concatenate("H=",toString(H)) << endl;
    );
    h:=0;
    if H!={} then h=lcm(H) else h=1;
    if isConsistent(Gr,prod(N,{h})) then (
        CGS = append(CGS,{flatten entries mingens ideal(Gr),prod(N,{h}),Gmy});	
    );
    if opts.Verbosity > 0 then (
    	print concatenate("CGS at end of Step 9 = ",toString CGS) << endl;
    );
    newE:={};
    newN:={};
    newF:={};
    L:=for i from 0 to #H-1 list (
	newE=flatten entries mingens ideal(append(Gr,H_i));
	newN=prod(N,{product apply(i-1, j -> H_j)});
	newF=select(G, g -> not member(g,Gry));
	newF = apply(newF, g -> coefficient(y,g)+coefficient(1_Ry,g));
	if opts.Verbosity > 0 then (
	    print concatenate("i=",toString(i),",{E,N,F}=",toString {newE,newN,newF}) << endl;
        );
	CGBPoly(newE,newN,newF,opts)	
    );
    return unique join(CGS,flatten L)
)

-------------------------------------------------------------------------------
--- consistency of constraints
-------------------------------------------------------------------------------
isConsistent = method()
isConsistent(List, List) := Boolean => (E, N) -> (
    -- E = a list of polynomials in k[U]
    -- N = a list of polynomials in k[U]
    -- returns if V(E) \ V(N) is nonempty

    if #E == 0 then return #N > 0;
    for f in N do (
	if f % (ideal E) == 0 then continue;
	if not isInRadical(f, ideal E) then return true;
	);
    false
    )

isInRadical = method()
isInRadical(RingElement, Ideal) := Boolean => (f, I) -> (
    -- f = a polynomial
    -- I = a polynomial ideal
    -- returns if f is in the radical of I

    y := local y;
    R := ring I;
    Ry := (coefficientRing R)(monoid [gens R, y]);
    phi := map(Ry, R, drop(first entries vars Ry, -1));
    y = (gens Ry)_-1;
    ideal(gens phi(I), 1 - phi(f)*y) == 1
    )
isInRadical(ZZ, Ideal) := Boolean => (f, I) -> (
    -- f = a polynomial (with no variable terms)
    -- I = a polynomial ideal
    -- returns if f is in the radical of I

    isInRadical(sub(f, ring I), I)
    )

-------------------------------------------------------------------------------
--- utilities
-------------------------------------------------------------------------------
minimalDicksonBasis = method()
minimalDicksonBasis(List) := List => (G) -> (
    -- G = a list of polynomials
    -- returns minimal Dickson basis (Def 4.3, page 133)

    J:=flatten entries mingens ideal(apply(G, g-> leadMonomial g));
    P:=partition(i -> leadMonomial(i),G);
    return apply(J, m -> first(P#m))
)

noncomparable = method()
noncomparable(List) := List => (G) -> (
    -- G = a set of polynomials in k[U][X]
    -- returns Noncomparable(G) from 4.1 in KapurSunWang2010

    F := {};
    for g in G do (
	if all(F, f -> (leadMonomial g) % (leadMonomial f) != 0) then (
	    F = select(F, f -> (leadMonomial f) % (leadMonomial g) != 0);
	    F = append(F, g);
	    );
	);
    F
    )

prod = method()
prod(List, List) := List => (A, B) -> (
    -- A = a list of polynomials
    -- B = a list of polynomials
    -- returns the list {ab | a in A and b in B}

    flatten for a in A list for b in B list a*b
    )

simplifyPolynomial= (g) -> (
     RRy:=ring(g);
     cRRy:=coefficientRing(RRy);
     lift(coefficient(RRy_0,g),cRRy)
);

simplifyInequation = (N) -> (
    if N == {} then return N;
    L:=for n in N list (
        T:=factor(n); 
	reverse sort apply(#T, k -> T#k#0)
    );
    unique flatten L
);

simplifyCGS = (cgs) -> ( 
    unique apply(cgs, i-> {i_0,simplifyInequation(i_1),apply(i_2, g -> simplifyPolynomial g)})
)

-------------------------------------------------------------------------------
--- documentation
-------------------------------------------------------------------------------
beginDocumentation()

doc ///
Key
  ParametricGB
Headline
  Compute parametric Groebner bases
Description
  Text
    This package implements the Kapur-Sun-Wang algorithm for computing comprehensive
    Groebner systems and comprehensive Groebner bases.
  Example
    R = QQ[a,b,c][x,y];
    F = {a*x - b, b*y - a, c*x^2 - y, c*y^2 - x};
    CGS = comprehensiveGroebnerSystem F
SeeAlso
///

doc ///
Key
  comprehensiveGroebnerSystem
  (comprehensiveGroebnerSystem, List, List, List)
  (comprehensiveGroebnerSystem, List)
Headline
  compute a comprehensive Groebner system
Usage
  CGS = comprehensiveGroebnerSystem F
  CGS = comprehensiveGroebnerSystem(E, N, F)
Inputs
  E : List
      a list of equations
  N : List 
      a list of inequations
  F : List
      a list of generators of an ideal
Outputs
  CGS : List
        the comprehensive Groebner system    
Description
  Text
    The comprehensive Groebner system.
  Example
    R = QQ[a,b,c][x,y];
    F = {a*x - b, b*y - a, c*x^2 - y, c*y^2 - x};
    CGS = comprehensiveGroebnerSystem F
///

-------------------------------------------------------------------------------
--- tests
-------------------------------------------------------------------------------
TEST /// -- comprehensiveGroebnerSystem
R = QQ[a,b,c][x,y];
F = {a*x - b, b*y - a, c*x^2 - y, c*y^2 - x};
CGS = comprehensiveGroebnerSystem F
assert(#CGS == 4)
///

end





uninstallPackage "ParametricGB"
restart
installPackage "ParametricGB"
check ParametricGB
viewHelp ParametricGB

