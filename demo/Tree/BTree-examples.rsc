module Tree-Examples

// Ex1: Count leaves in a BTREE
// Idea: int N : T generates alle Integer leaves in the tree
// Observe that there is no need to touch the contents of 
// each Integer since we only count them.

int cnt(BTREE T) {
    return size({N | Integer N : T});
}

// Ex1: alternative solution using a visit statement

int cnt(BTREE T) {
    int C = 0;
    visit(T) {
      case <Integer N> : C = C+1;
    };
    return C;
}
 
// Ex2: Sum all leaves in a BTREE
// NB sum is a built-in that adds all elements in a set or list.
// Here we see immediately the need to convert between
// - the syntactic sort "Integer"
// - the built-in sort "int"
// We use the toInt function that attempts convert any tree
// to an int.

int sumtree(BTREE T) {
    return sum({toInt(N) | Integer N : T});
}

// Ex2: using visit statement

int cnt(BTREE T) {
    int C = 0;
    visit(T) {
      case <Integer N> : C = C+toInt(N);
    };
    return C;
}

// Ex3: Increment all leaves in a BTREE
// Idea: using the visit statement visit all leaves in
// the tree T that match an integer and replace each N in T by N+1.
// The expression as a whole returns the modified tree
// Note that two conversions are needed here:
// - from Integer to int (using toInt)
// - from int back to Integer (using parseString)

BTREE inc(BTREE T) {
    return visit (T) {
      case <Integer N>: insert parseString(toInt(N)+1);
    };
}

// Ex4: full replacement of g by i
// The whole repertoire of ASF+SDF traversal functions is available:
// - bottom-up visit (T) { ... }
// - bottom-up-break visit (T) { ... }
// - etc.
// A nice touch is that these properties are not tied to the
// declaration of a travesal function (as in ASF+SDF) but to 
// its use.

BTREE frepl(BTREE T) {
    return bottom-up visit (T) {
      case [| g(<BTREE T1>, <BTREE T2>) |] =>
           i(<BTREE T1>, <BTREE T2>)
    };
}

// Ex5: Deep replacement of g by i

BTREE drepl(BTREE T) {
    return bottom-up-break visit (T) {
      case[| g(<BTREE T1>, <BTREE T2>) |] =>
             i(<BTREE T1>, <BTREE T2>)
    };
}

// Ex6: shallow replacement of g by i (i.e. only outermost 
// g's are replaced); 

BTREE srepl(BTREE T) {
    return top-down-break visit (T) {
      case [| g(<BTREE T1>, <BTREE T2>) |] => 
              i(<BTREE T1>, <BTREE T2>)
    };
}

// Ex7: We can also add the top-down-break directive to the 
// generator to get only outermost nodes.

set[BTREE] find_outer_gs(BTREE T) {
    return
    { S | top-down-break STATEMENT S : T, 
          [| g(<BTREE T1>, <BTREE T2>) |] ~~ S };
}
 
// Ex8: accumulating transformer that increments leaves with 
// amount D and counts them
tuple[int, BTREE] count_and_inc(BTREE T, int D) {
    int C = 0;
    
    visit (T) {
      case <Integer N>: { C = C + 1; 
                          int N1 = toInt(N) + D; 
                          insert parse(unparseToString(N1));
                        }
    };
    return <C, T>;
}
