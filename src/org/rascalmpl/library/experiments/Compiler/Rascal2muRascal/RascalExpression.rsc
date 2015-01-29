@bootstrapParser
module experiments::Compiler::Rascal2muRascal::RascalExpression

import Prelude;
import IO;
import ValueIO;
import Node;
import Map;
import Set;
import String;
import ParseTree;

import lang::rascal::\syntax::Rascal;
import lang::rascal::types::TestChecker;
import lang::rascal::types::CheckTypes;
import lang::rascal::types::AbstractName;
import lang::rascal::types::AbstractType;
import lang::rascal::types::TypeInstantiation;
import lang::rascal::types::TypeExceptions;
import experiments::Compiler::Rascal2muRascal::TmpAndLabel;
import experiments::Compiler::Rascal2muRascal::RascalModule;
import experiments::Compiler::Rascal2muRascal::RascalPattern;
import experiments::Compiler::Rascal2muRascal::RascalStatement;
import experiments::Compiler::Rascal2muRascal::RascalType;
import experiments::Compiler::Rascal2muRascal::TypeReifier;
import experiments::Compiler::muRascal::AST;
import experiments::Compiler::Rascal2muRascal::TypeUtils;
import experiments::Compiler::RVM::Interpreter::ParsingTools;
import experiments::Compiler::muRascal::MuAllMuOr;

/*
 * Translate a Rascal expression to muRascal using the function: 
 * - MuExp translate(Expression e).
 */
 
/*********************************************************************/
/*                  Auxiliary functions                              */
/*********************************************************************/

int size_keywordArguments((KeywordArguments[Expression]) `<KeywordArguments[Expression] keywordArguments>`) = 
    (keywordArguments is \default) ? size([kw | KeywordArgument[Expression] kw <- keywordArguments.keywordArgumentList]) : 0;

// Produces multi- or backtrack-free expressions
MuExp makeMu(str muAllOrMuOr, list[MuExp] exps, loc src) {
    tuple[MuExp e,list[MuFunction] functions] res = makeMu(muAllOrMuOr,topFunctionScope(),exps,src);
    addFunctionsToModule(res.functions);
    return res.e;
}

MuExp makeMuMulti(MuExp exp, loc src) {
    tuple[MuExp e,list[MuFunction] functions] res = makeMuMulti(exp,topFunctionScope(),src);
    addFunctionsToModule(res.functions);
    return res.e;
}

MuExp makeMuOne(str muAllOrMuOr, list[MuExp] exps, loc src) {
    tuple[MuExp e,list[MuFunction] functions] res = makeMuOne(muAllOrMuOr,topFunctionScope(),exps,src);
    addFunctionsToModule(res.functions);
    return res.e;
}

// Generate code for completely type-resolved operators

bool isContainerType(str t) = t in {"list", "map", "set", "rel", "lrel"};

bool areCompatibleContainerTypes({"list", "lrel"}) = true;
bool areCompatibleContainerTypes({"set", "rel"}) = true;
bool areCompatibleContainerTypes({str c}) = true;
default bool areCompatibleContainerTypes(set[str] s) = false;

str reduceContainerType("lrel") = "list";
str reduceContainerType("rel") = "set";
default str reduceContainerType(str c) = c;

str typedBinaryOp(str lot, str op, str rot) {
  if(lot == "value" || rot == "value" || lot == "parameter" || rot == "parameter"){
     return op;
  }
  if(isContainerType(lot))
     return areCompatibleContainerTypes({lot, rot}) ? "<lot>_<op>_<rot>" : "<lot>_<op>_elm";
  else
     return isContainerType(rot) ? "elm_<op>_<rot>" : "<lot>_<op>_<rot>";
}

MuExp infix(str op, Expression e) = 
  muCallPrim3(typedBinaryOp(getOuterType(e.lhs), op, getOuterType(e.rhs)), 
             [*translate(e.lhs), *translate(e.rhs)],
             e.origin);

MuExp infix_elm_left(str op, Expression e){
   rot = getOuterType(e.rhs);
   return muCallPrim3("elm_<op>_<rot>", [*translate(e.lhs), *translate(e.rhs)], e.origin);
}

MuExp infix_rel_lrel(str op, Expression e){
  lot = getOuterType(e.lhs);
  if(lot == "set") lot = "rel"; else if (lot == "list") lot = "lrel";
  rot = getOuterType(e.rhs);
  if(rot == "set") rot = "rel"; else if (rot == "list") rot = "lrel";
  return muCallPrim3("<lot>_<op>_<rot>", [*translate(e.lhs), *translate(e.rhs)], e.origin);
}

// ----------- compose: exp o exp ----------------

MuExp compose(Expression e){
  lhsType = getType(e.lhs.origin);
  return isFunctionType(lhsType) || isOverloadedType(lhsType) ? translateComposeFunction(e) : infix_rel_lrel("compose", e);
}

MuExp translateComposeFunction(Expression e){
  //println("composeFunction: <e>");
  lhsType = getType(e.lhs.origin);
  rhsType = getType(e.rhs.origin);
  resType = getType(e.origin);
  
  MuExp lhsReceiver = translate(e.lhs);
  MuExp rhsReceiver = translate(e.rhs);
  
  //println("lhsReceiver: <lhsReceiver>");
  //println("rhsReceiver: <rhsReceiver>");
  
  str ofqname = "<lhsReceiver.fuid>_o_<rhsReceiver.fuid>#<e.origin.offset>_<e.origin.length>";  // name of composition
  
  if(hasOverloadingResolver(ofqname)){
    return muOFun(ofqname);
  }
  
  // Unique 'id' of a visit in the function body
  //int i = nextVisit();  // TODO: replace by generated function counter
    
  // Generate and add a function COMPOSED_FUNCTIONS_<i>
  str scopeId = topFunctionScope();
  str comp_name = "COMPOSED_FUNCTIONS_<e.origin.offset>_<e.origin.length>";
  str comp_fuid = scopeId + "/" + comp_name;
  
  Symbol comp_ftype;  
  int nargs;
  if(isFunctionType(resType)) {
     nargs = size(resType.parameters);
     comp_ftype = resType;
  } else {
     nargs = size(getOneFrom(resType.overloads).parameters);
     for(t <- resType.overloads){
         if(size(t.parameters) != nargs){
            throw "cannot handle composition/overloading for different arities";
         }
     }
     comp_ftype = Symbol::func(Symbol::\value(), [Symbol::\value() | int j <- [0 .. nargs]]);
  }
    
  enterFunctionScope(comp_fuid);
  kwargs = muCallMuPrim("make_mmap", []);
  rhsCall = muOCall4(rhsReceiver, \tuple([rhsType]), [muVar("parameter_<comp_name>", comp_fuid, j) | int j <- [0 .. nargs]] + [ kwargs ], e.rhs.origin);
  body_exps =  [muReturn1(muOCall4(lhsReceiver, \tuple([lhsType]), [rhsCall, kwargs ], e.lhs.origin))];
   
  leaveFunctionScope();
  fun = muFunction(comp_fuid, comp_name, comp_ftype, scopeId, nargs, 2, false, \e.origin, [], (), muBlock(body_exps));
 
  int uid = declareGeneratedFunction(comp_fuid, comp_ftype);
  addFunctionToModule(fun);  
  addOverloadedFunctionAndResolver(ofqname, <getModuleName(), [uid]>);
 
  return muOFun(ofqname);
}

// ----------- addition: exp + exp ----------------

MuExp add(Expression e){
    lhsType = getType(e.lhs.origin);
    return isFunctionType(lhsType) || isOverloadedType(lhsType) ? translateAddFunction(e) :infix("add", e);
}

MuExp translateAddFunction(Expression e){

  //println("translateAddFunction: <e>");
  lhsType = getType(e.lhs.origin);
  rhsType = getType(e.rhs.origin);
  
  str2uid = invertUnique(uid2str);

  MuExp lhsReceiver = translate(e.lhs);
  OFUN lhsOf;
  
  if(hasOverloadingResolver(lhsReceiver.fuid)){
    lhsOf = getOverloadedFunction(lhsReceiver.fuid);
  } else {
    uid = str2uid[lhsReceiver.fuid];
    lhsOf = <topFunctionScope(), [uid]>;
    addOverloadedFunctionAndResolver(lhsReceiver.fuid, lhsOf);
  }
 
  MuExp rhsReceiver = translate(e.rhs);
  OFUN rhsOf;
  
  if( hasOverloadingResolver(rhsReceiver.fuid)){
    rhsOf = getOverloadedFunction(rhsReceiver.fuid);
  } else {
    uid = str2uid[rhsReceiver.fuid];
    rhsOf = <topFunctionScope(), [uid]>;
    addOverloadedFunctionAndResolver(rhsReceiver.fuid, rhsOf);
  }
 
  OFUN compOf = <lhsOf[0], lhsOf[1] + rhsOf[1]>; // add all alternatives
  
  str ofqname = "<lhsReceiver.fuid>_+_<rhsReceiver.fuid>#<e.origin.offset>_<e.origin.length>";  // name of addition
 
  addOverloadedFunctionAndResolver(ofqname, compOf); 
  return muOFun(ofqname);
}

str typedUnaryOp(str ot, str op) = (ot == "value" || ot == "parameter") ? op : "<op>_<ot>";
 
MuExp prefix(str op, Expression arg) {
  return muCallPrim3(typedUnaryOp(getOuterType(arg), op), [translate(arg)], arg.origin);
}

MuExp postfix(str op, Expression arg) = muCallPrim3(typedUnaryOp(getOuterType(arg), op), [translate(arg)], arg.origin);

MuExp postfix_rel_lrel(str op, Expression arg) {
  ot = getOuterType(arg);
  if(ot == "set" ) ot = "rel"; else if(ot == "list") ot = "lrel";
  return muCallPrim3("<ot>_<op>", [translate(arg)], arg.origin);
}

set[str] numeric = {"int", "real", "rat", "num"};

MuExp comparison(str op, Expression e) {
 
  lot = reduceContainerType(getOuterType(e.lhs));
  rot = reduceContainerType(getOuterType(e.rhs));
  
  if(lot == "value" || rot == "value"){
     lot = ""; rot = "";
  } else {
    if(lot in numeric) lot += "_"; else lot = "";
 
    if(rot in numeric) rot = "_" + rot; else rot = "";
  }
  lot = reduceContainerType(lot);
  rot = reduceContainerType(rot);
  return muCallPrim3("<lot><op><rot>", [*translate(e.lhs), *translate(e.rhs)], e.origin);
}

// Determine constant expressions

//bool isConstantLiteral((Literal) `<LocationLiteral src>`) = src.protocolPart is nonInterpolated;
//bool isConstantLiteral((Literal) `<StringLiteral n>`) = n is nonInterpolated;
//default bool isConstantLiteral(Literal l) = true;
//
//bool isConstant(Expression e:(Expression)`{ <{Expression ","}* es> }`) = size(es) == 0 || all(elm <- es, isConstant(elm));
//bool isConstant(Expression e:(Expression)`[ <{Expression ","}* es> ]`)  = size(es) == 0 ||  all(elm <- es, isConstant(elm));
//bool isConstant(Expression e:(Expression) `( <{Mapping[Expression] ","}* mappings> )`) = size(mappings) == 0 || all(m <- mappings, isConstant(m.from), isConstant(m.to));
//
//bool isConstant(e:(Expression) `\< <{Expression ","}+ elements> \>`) = size(elements) == 0 ||  all(elm <- elements, isConstant(elm));
//bool isConstant((Expression) `<Literal s>`) = isConstantLiteral(s);
//default bool isConstant(Expression e) = false;
//
//value getConstantValue(Expression e) = readTextValueString("<e>");

/*********************************************************************/
/*                  Translate Literals                               */
/*********************************************************************/

// -- boolean literal  -----------------------------------------------

MuExp translate((Literal) `<BooleanLiteral b>`) = 
    "<b>" == "true" ? muCon(true) : muCon(false);

// -- integer literal  -----------------------------------------------
 
MuExp translate((Literal) `<IntegerLiteral n>`) = 
    muCon(toInt("<n>"));

// -- regular expression literal  ------------------------------------

MuExp translate((Literal) `<RegExpLiteral r>`) { 
    throw "RexExpLiteral cannot occur in expression"; 
}

// -- string literal  ------------------------------------------------

MuExp translate((Literal) `<StringLiteral n>`) = 
    translateStringLiteral(n);

/* Recap of relevant rules from Rascal grammar:

   syntax StringLiteral
        = template: PreStringChars pre StringTemplate template StringTail tail 
	   | interpolated: PreStringChars pre Expression expression StringTail tail 
	   | nonInterpolated: StringConstant constant ;
	
   lexical PreStringChars
	   = [\"] StringCharacter* [\<] ;
	
   lexical MidStringChars
	   =  [\>] StringCharacter* [\<] ;
	
   lexical PostStringChars
	   = @category="Constant" [\>] StringCharacter* [\"] ;
*/	

private MuExp translateStringLiteral(s: (StringLiteral) `<PreStringChars pre> <StringTemplate template> <StringTail tail>`) {
    str fuid = topFunctionScope();
	preResult = nextTmp();
	return muBlock( [ muAssignTmp(preResult, fuid, translatePreChars(pre)),
                      muCallPrim3("template_addunindented", [ translateTemplate(template, computeIndent(pre), preResult, fuid), *translateTail(tail)], s.origin)
                    ]);
}
    
private MuExp translateStringLiteral(s: (StringLiteral) `<PreStringChars pre> <Expression expression> <StringTail tail>`) {
    str fuid = topFunctionScope();
    preResult = nextTmp();
    return muBlock( [ muAssignTmp(preResult, fuid, translatePreChars(pre)),
					  muCallPrim3("template_addunindented", [ translateTemplate(expression, computeIndent(pre), preResult, fuid), *translateTail(tail)], s.origin)
					]   );
}
                    
private MuExp translateStringLiteral((StringLiteral)`<StringConstant constant>`) = muCon(readTextValueString(removeMargins("<constant>")));

private str removeMargins(str s) {
	if(findFirst(s, "\n") < 0){
		return s;
	} else {
		return visit(s) { case /^[ \t]*'/m => "" /* case /^[ \t]+$/m => "" */};
	}
}

private str computeIndent(str s) {
   lines = split("\n", removeMargins(s)); 
   return isEmpty(lines) ? "" : left("", size(lines[-1]));
} 

private str computeIndent(PreStringChars pre) = computeIndent(removeMargins(deescape("<pre>"[1..-1])));
private str computeIndent(MidStringChars mid) = computeIndent(removeMargins(deescape("<mid>"[1..-1])));

private MuExp translateChars(str s) = muCon(removeMargins(deescape(s[1..-1])))
when bprintln(s[1..-1]);

private MuExp translatePreChars(PreStringChars pre) =
  muCon(removeMargins(deescape("<pre>"[1..-1])));

private MuExp translateMidChars(MidStringChars mid) =
  muCon(removeMargins(deescape("<mid>"[1..-1])));


private str deescape(str s)  =  visit(s) { case /\\<c: [\" \' \< \> \\ b f n r t]>/m => c };

/* Recap of relevant rules from Rascal grammar:

   syntax StringTemplate
	   = ifThen    : "if"    "(" {Expression ","}+ conditions ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" 
	   | ifThenElse: "if"    "(" {Expression ","}+ conditions ")" "{" Statement* preStatsThen StringMiddle thenString Statement* postStatsThen "}" "else" "{" Statement* preStatsElse StringMiddle elseString Statement* postStatsElse "}" 
	   | \for       : "for"   "(" {Expression ","}+ generators ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" 
	   | doWhile   : "do"    "{" Statement* preStats StringMiddle body Statement* postStats "}" "while" "(" Expression condition ")" 
	   | \while     : "while" "(" Expression condition ")" "{" Statement* preStats StringMiddle body Statement* postStats "}" ;
	
   syntax StringMiddle
	   = mid: MidStringChars mid 
	   | template: MidStringChars mid StringTemplate template StringMiddle tail 
	   | interpolated: MidStringChars mid Expression expression StringMiddle tail ;
	
   syntax StringTail
        = midInterpolated: MidStringChars mid Expression expression StringTail tail 
        | post: PostStringChars post 
        | midTemplate: MidStringChars mid StringTemplate template StringTail tail ;
*/

public MuExp translateMiddle((StringMiddle) `<MidStringChars mid>`) = muCon(removeMargins(deescape("<mid>"[1..-1])));

public MuExp translateMiddle(s: (StringMiddle) `<MidStringChars mid> <StringTemplate template> <StringMiddle tail>`) {
    str fuid = topFunctionScope();
    midResult = nextTmp();
    return muBlock( [ muAssignTmp(midResult, fuid, translateMidChars(mid)),
   			          muCallPrim3("template_addunindented", [ translateTemplate(template, computeIndent(mid), midResult, fuid), translateMiddle(tail) ], s.origin)
   			        ]);
   	}

public MuExp translateMiddle(s: (StringMiddle) `<MidStringChars mid> <Expression expression> <StringMiddle tail>`) {
    str fuid = topFunctionScope();
    midResult = nextTmp();
    return muBlock( [ muAssignTmp(midResult, fuid, translateMidChars(mid)),
                      muCallPrim3("template_addunindented", [ translateTemplate(expression, computeIndent(mid), midResult, fuid), translateMiddle(tail) ], s.origin)
                    ]);
}
  
private list[MuExp] translateTail(s: (StringTail) `<MidStringChars mid> <Expression expression> <StringTail tail>`) {
    str fuid = topFunctionScope();
    midResult = nextTmp();
    return [ muBlock( [ muAssignTmp(midResult, fuid, translateMidChars(mid)),
                      muCallPrim3("template_addunindented", [ translateTemplate(expression, computeIndent(mid), midResult, fuid), *translateTail(tail)], s.origin)
                    ])
           ];
}
	
private list[MuExp] translateTail((StringTail) `<PostStringChars post>`) {
  content = removeMargins(deescape("<post>"[1..-1]));
  return size(content) == 0 ? [] : [muCon(deescape(content))];
}

private list[MuExp] translateTail(s: (StringTail) `<MidStringChars mid> <StringTemplate template> <StringTail tail>`) {
    str fuid = topFunctionScope();
    midResult = nextTmp();
    return [ muBlock( [ muAssignTmp(midResult, fuid, translateMidChars(mid)),
                        muCallPrim3("template_addunindented", [ translateTemplate(template, computeIndent(mid), midResult, fuid), *translateTail(tail) ], s.origin)
                    ])
           ];
 }  
 
 private MuExp translateTemplate(Expression e, str indent, str preResult, str prefuid){
    str fuid = topFunctionScope();
    result = nextTmp();
    return muBlock([ muAssignTmp(result, fuid, muCallPrim3("template_open", [muCon(indent), muTmp(preResult,prefuid)], e.origin)),
    				 muAssignTmp(result, fuid, muCallPrim3("template_add", [ muTmp(result,fuid), muCallPrim3("value_to_string", [translate(e)], e.origin) ], e.origin)),
                     muCallPrim3("template_close", [muTmp(result,fuid)], e.origin)
                   ]);
 }
 
// -- location literal  ----------------------------------------------

MuExp translate((Literal) `<LocationLiteral src>`) = 
    translateLocationLiteral(src);
 
/* Recap of relevant rules from Rascal grammar:
   syntax LocationLiteral
	   = \default: ProtocolPart protocolPart PathPart pathPart ;
	
   syntax ProtocolPart
        = nonInterpolated: ProtocolChars protocolChars 
        | interpolated: PreProtocolChars pre Expression expression ProtocolTail tail ;
    
   lexical PreProtocolChars
        = "|" URLChars "\<" ;
    
   lexical MidProtocolChars
        = "\>" URLChars "\<" ;
    
   lexical ProtocolChars
        = [|] URLChars "://" !>> [\t-\n \r \ \u00A0 \u1680 \u2000-\u200A \u202F \u205F \u3000];

   syntax ProtocolTail
        = mid: MidProtocolChars mid Expression expression ProtocolTail tail 
        | post: PostProtocolChars post ;

   lexical PostProtocolChars
        = "\>" URLChars "://" ; 
    
   syntax PathPart
        = nonInterpolated: PathChars pathChars 
        | interpolated: PrePathChars pre Expression expression PathTail tail ;

   lexical PathChars
        = URLChars [|] ;
        
   syntax PathTail
        = mid: MidPathChars mid Expression expression PathTail tail 
        | post: PostPathChars post ;

   lexical PrePathChars
        = URLChars "\<" ;

   lexical MidPathChars
        = "\>" URLChars "\<" ;
    
   lexical PostPathChars
        = "\>" URLChars "|" ;
 */
 
 private MuExp translateLocationLiteral(l: (LocationLiteral) `<ProtocolPart protocolPart> <PathPart pathPart>`) =
     muCallPrim3("loc_create", [muCallPrim3("str_add_str", [translateProtocolPart(protocolPart), translatePathPart(pathPart)], l.origin)], l.origin);
 
private MuExp translateProtocolPart((ProtocolPart) `<ProtocolChars protocolChars>`) = muCon("<protocolChars>"[1..]);
 
private MuExp translateProtocolPart(p: (ProtocolPart) `<PreProtocolChars pre> <Expression expression> <ProtocolTail tail>`) =
    muCallPrim3("str_add_str", [muCon("<pre>"[1..-1]), translate(expression), translateProtocolTail(tail)], p.origin);
 
private MuExp  translateProtocolTail(p: (ProtocolTail) `<MidProtocolChars mid> <Expression expression> <ProtocolTail tail>`) =
   muCallPrim3("str_add_str", [muCon("<mid>"[1..-1]), translate(expression), translateProtocolTail(tail)], p.origin);
   
private MuExp translateProtocolTail((ProtocolTail) `<PostProtocolChars post>`) = muCon("<post>"[1 ..]);

private MuExp translatePathPart((PathPart) `<PathChars pathChars>`) = muCon("<pathChars>"[..-1]);

private MuExp translatePathPart(p: (PathPart) `<PrePathChars pre> <Expression expression> <PathTail tail>`) =
   muCallPrim3("str_add_str", [ muCon("<pre>"[..-1]), translate(expression), translatePathTail(tail)], p.origin);

private MuExp translatePathTail(p: (PathTail) `<MidPathChars mid> <Expression expression> <PathTail tail>`) =
   muCallPrim3("str_add_str", [ muCon("<mid>"[1..-1]), translate(expression), translatePathTail(tail)], p.origin);
   
private MuExp translatePathTail((PathTail) `<PostPathChars post>`) = muCon("<post>"[1..-1]);

// -- all other literals  --------------------------------------------

default MuExp translate((Literal) `<Literal s>`) = 
    muCon(readTextValueString("<s>"));


/*********************************************************************/
/*                  Translate expressions                            */
/*********************************************************************/

// -- literal expression ---------------------------------------------

MuExp translate(e:(Expression)  `<Literal s>`) = 
    translate(s);

// -- concrete syntax expression  ------------------------------------

MuExp translate(e:(Expression) `<Concrete concrete>`) {
    return translateConcrete(concrete);
}

MuExp getConstructor(str cons) {
   cons = unescape(cons);
   uid = -1;
   for(c <- getConstructors()){
     //println("c = <c>, uid2name = <uid2name[c]>, uid2str = <convert2fuid(c)>");
     if(cons == getSimpleName(getConfiguration().store[c].name)){
        //println("c = <c>, <config.store[c]>,  <uid2addr[c]>");
        uid = c;
        break;
     }
   }
   if(uid < 0)
      throw("No definition for constructor: <cons>");
   return muConstr(convert2fuid(uid));
}

/* Recap of relevant rules from Rascal grammar:

   lexical Concrete 
        = typed: "(" LAYOUTLIST l1 Sym symbol LAYOUTLIST l2 ")" LAYOUTLIST l3 "`" ConcretePart* parts "`";

   lexical ConcretePart
        = @category="MetaSkipped" text   : ![`\<\>\\\n]+ !>> ![`\<\>\\\n]
        | newline: "\n" [\ \t \u00A0 \u1680 \u2000-\u200A \u202F \u205F \u3000]* "\'"
        | @category="MetaVariable" hole : ConcreteHole hole
        | @category="MetaSkipped" lt: "\\\<"
        | @category="MetaSkipped" gt: "\\\>"
        | @category="MetaSkipped" bq: "\\`"
        | @category="MetaSkipped" bs: "\\\\"
        ;
  
   syntax ConcreteHole 
        = \one: "\<" Sym symbol Name name "\>"
        ;
    
   Recap from ParseTree declaration:
  
   data Tree 
        = appl(Production prod, list[Tree] args)
        | cycle(Symbol symbol, int cycleLength) 
        | amb(set[Tree] alternatives)  
        | char(int character)
        ;
*/


MuExp translateConcrete(e: appl(Production cprod, list[Tree] cargs)){ 
    fragType = getType(e.origin);
    println("translateConcrete, fragType = <fragType>");
    reifiedFragType = symbolToValue(fragType);
    println("translateConcrete, reified: <reifiedFragType>");
    Tree parsedFragment = parseFragment(getModuleName(), reifiedFragType, e, e.origin, getGrammar());
    //println("parsedFragment, before"); iprintln(parsedFragment);
    return translateConcreteParsed(parsedFragment, parsedFragment.origin);
}

default MuExp translateConcrete(lang::rascal::\syntax::Rascal::Concrete c) = muCon(c);

MuExp translateConcreteParsed(Tree e, loc src){
   if(appl(Production prod, list[Tree] args) := e){
       my_src = e has origin ? e.origin : src;
       iprintln(e);
       if(prod.def == label("hole", lex("ConcretePart"))){
           varloc = args[0].args[4].args[0].origin;		// TODO: refactor (see concrete patterns)
           println("varloc = <getType(varloc)>");
           <fuid, pos> = getVariableScope("ConcreteVar", varloc);
           
           return muVar("ConcreteVar", fuid, pos);
        } 
        MuExp translated_elems;
        if(any(arg <- args, isConcreteListVar(arg))){ 
           println("splice in concrete list");      
           str fuid = topFunctionScope();
           writer = nextTmp();
        
           translated_args = [ muCallPrim3(isConcreteListVar(arg) ? "listwriter_splice_concrete_list_var" : "listwriter_add", 
                                          [muTmp(writer,fuid), translateConcreteParsed(arg, my_src)], my_src)
                             | Tree arg <- args
                             ];
           translated_elems = muBlock([ muAssignTmp(writer, fuid, muCallPrim3("listwriter_open", [], my_src)),
                                        *translated_args,
                                        muCallPrim3("listwriter_close", [muTmp(writer,fuid)], my_src) 
                                      ]);
        } else {
           translated_args = [translateConcreteParsed(arg, my_src) | Tree arg <- args];
           if(allConstant(translated_args)){
        	  return muCon(appl(prod, [ce | muCon(ce) <- translated_args]));
           }
           translated_elems = muCallPrim3("list_create", translated_args, my_src);
        }
        
        return muCall(muConstr("ParseTree/adt(\"Tree\",[])::appl(adt(\"Production\",[]) prod;list(adt(\"Tree\",[])) args;)"), 
                      [muCon(prod), translated_elems, muTypeCon(Symbol::\void())]);
    } else {
        return muCon(e);
    }
}

bool isConcreteListVar(e: appl(Production prod, list[Tree] args)){
   if(prod.def == label("hole", lex("ConcretePart"))){
      varloc = args[0].args[4].args[0].origin;
      varType = getType(varloc);
      typeName = getName(varType);
      return typeName in {"iter", "iter-star", "iter-seps", "iter-star-seps"};
   }
   return false;
}

default bool isConcreteListVar(Tree t) = false;

//default MuExp translateConcreteParsed(Tree t) = muCon(t);

// -- block expression ----------------------------------------------

MuExp translate(e:(Expression) `{ <Statement+ statements> }`) = 
    muBlock([translate(stat) | stat <- statements]);

// -- parenthesized expression --------------------------------------

MuExp translate(e:(Expression) `(<Expression expression>)`) =
     translate(expression);

// -- closure expression --------------------------------------------

MuExp translate (e:(Expression) `<Type \type> <Parameters parameters> { <Statement+ statements> }`) =
    translateClosure(e, parameters, statements);

MuExp translate (e:(Expression) `<Parameters parameters> { <Statement* statements> }`) =
    translateClosure(e, parameters, statements);

// Translate a closure   
 
 MuExp translateClosure(Expression e, Parameters parameters, Tree cbody) {
 	uid = loc2uid[e.origin];
	fuid = convert2fuid(uid);
	
	enterFunctionScope(fuid);
	
    ftype = getClosureType(e.origin);
	nformals = size(ftype.parameters);
	bool isVarArgs = (varArgs(_,_) := parameters);
  	
  	// Keyword parameters
    list[MuExp] kwps = translateKeywordParameters(parameters, fuid, getFormals(uid), e.origin);
    
    // TODO: we plan to introduce keyword patterns as formal parameters
    MuExp body = translateFunction("CLOSURE", parameters.formals.formals, isVarArgs, kwps, cbody, []);
    
    tuple[str fuid,int pos] addr = uid2addr[uid];
    
    addFunctionToModule(muFunction(fuid, "CLOSURE", ftype, (addr.fuid in moduleNames) ? "" : addr.fuid, 
  									  getFormals(uid), getScopeSize(fuid), 
  									  isVarArgs, e.origin, [], (), 
  									  body));
  	
  	leaveFunctionScope();								  
  	
	return (addr.fuid == convert2fuid(0)) ? muFun1(fuid) : muFun2(fuid, addr.fuid); // closures are not overloaded
}

MuExp translateBoolClosure(Expression e){
    tuple[str fuid,int pos] addr = <topFunctionScope(),-1>;
	fuid = addr.fuid + "/non_gen_at_<e.origin>()";
	
	enterFunctionScope(fuid);
	
    ftype = Symbol::func(Symbol::\bool(),[]);
	nformals = 0;
	nlocals = 0;
	bool isVarArgs = false;
  	
    MuExp body = muReturn1(translate(e));
    addFunctionToModule(muFunction(fuid, "CLOSURE", ftype, addr.fuid, nformals, nlocals, isVarArgs, e.origin, [], (), body));
  	
  	leaveFunctionScope();								  
  	
	return muFun2(fuid, addr.fuid); // closures are not overloaded

}

// -- enumerator with range expression ------------------------------

MuExp translate (e:(Expression) `<Pattern pat> \<- [ <Expression first> .. <Expression last> ]`) {
    kind = getOuterType(first) == "int" && getOuterType(last) == "int" ? "_INT" : "";
    return muMulti(muApply(mkCallToLibFun("Library", "RANGE<kind>"), [ translatePat(pat), translate(first), translate(last)]));
 }

// -- enumerator with range and step expression ---------------------
    
MuExp translate (e:(Expression) `<Pattern pat> \<- [ <Expression first> , <Expression second> .. <Expression last> ]`) {
     kind = getOuterType(first) == "int" && getOuterType(second) == "int" && getOuterType(last) == "int" ? "_INT" : "";
     return muMulti(muApply(mkCallToLibFun("Library", "RANGE_STEP<kind>"), [ translatePat(pat), translate(first), translate(second), translate(last)]));
}

// -- range expression ----------------------------------------------

MuExp translate (e:(Expression) `[ <Expression first> .. <Expression last> ]`) {
  //println("range: <e>");
  str fuid = topFunctionScope();
  loopname = nextLabel(); 
  writer = asTmp(loopname);
  var = nextTmp();
  patcode = muApply(mkCallToLibFun("Library","MATCH_VAR"), [muTmpRef(var,fuid)]);

  kind = getOuterType(first) == "int" && getOuterType(last) == "int" ? "_INT" : "";
  rangecode = muMulti(muApply(mkCallToLibFun("Library", "RANGE<kind>"), [ patcode, translate(first), translate(last)]));
  
  return
    muBlock(
    [ muAssignTmp(writer, fuid, muCallPrim3("listwriter_open", [], e.origin)),
      muWhile(loopname, makeMu("ALL", [ rangecode ], e.origin), [ muCallPrim3("listwriter_add", [muTmp(writer,fuid), muTmp(var,fuid)], e.origin)]),
      muCallPrim3("listwriter_close", [muTmp(writer,fuid)], e.origin) 
    ]);
    
}

// -- range with step expression ------------------------------------

MuExp translate (e:(Expression) `[ <Expression first> , <Expression second> .. <Expression last> ]`) {
  str fuid = topFunctionScope();
  loopname = nextLabel(); 
  writer = asTmp(loopname);
  var = nextTmp();
  patcode = muApply(mkCallToLibFun("Library","MATCH_VAR"), [muTmpRef(var,fuid)]);

  kind = getOuterType(first) == "int" && getOuterType(second) == "int" && getOuterType(last) == "int" ? "_INT" : "";
  rangecode = muMulti(muApply(mkCallToLibFun("Library", "RANGE_STEP<kind>"), [ patcode, translate(first), translate(second), translate(last)]));
  
  return
    muBlock(
    [ muAssignTmp(writer, fuid, muCallPrim3("listwriter_open", [], e.origin)),
      muWhile(loopname, makeMu("ALL", [ rangecode ], e.origin), [ muCallPrim3("listwriter_add", [muTmp(writer,fuid), muTmp(var,fuid)], e.origin)]),
      muCallPrim3("listwriter_close", [muTmp(writer,fuid)], e.origin) 
    ]);
}

// -- visit expression ----------------------------------------------

MuExp translate (e:(Expression) `<Label label> <Visit visitItself>`) = translateVisit(label, visitItself);

// Translate Visit
// 
// The global translation scheme is to translate each visit to a function PHI, with local functions per case.
// For the fixedpoint strategies innermost and outermost, a wrapper function PHI_FIXPOINT is generated that
// carries out the fixed point computation. PHI and PHIFIXPOINT have 5 common formal parameters, and the latter has
// two extra local variables:
//
// PHI:	iSubject		PHI_FIXPOINT:	iSubject
//		matched							matched
//		hasInsert						hasInsert
//		begin							begin
//		end								end
//										changed
//										val

//,PHI functions

private int iSubjectPos = 0;
private int matchedPos = 1;
private int hasInsertPos = 2;
private int beginPos = 3;
private int endPos = 4;

private int NumberOfPhiFormals = 5;

// Generated PHI_FIXPOINT functions
// iSubjectPos, matchedPos, hasInsert, begin, end as for PHI
// Extra locals

private int changedPos = 5;
private int valPos = 6;

private int NumberOfPhiFixFormals = 5;
private int NumberOfPhiFixLocals = 7;


MuExp translateVisit(Label label, lang::rascal::\syntax::Rascal::Visit \visit) {
	MuExp traverse_fun;
	bool fixpoint = false;
	
	if(\visit is defaultStrategy) {
		traverse_fun = mkCallToLibFun("Library","TRAVERSE_BOTTOM_UP");
	} else {
		switch("<\visit.strategy>") {
			case "bottom-up"      :   traverse_fun = mkCallToLibFun("Library","TRAVERSE_BOTTOM_UP");
			case "top-down"       :   traverse_fun = mkCallToLibFun("Library","TRAVERSE_TOP_DOWN");
			case "bottom-up-break":   traverse_fun = mkCallToLibFun("Library","TRAVERSE_BOTTOM_UP_BREAK");
			case "top-down-break" :   traverse_fun = mkCallToLibFun("Library","TRAVERSE_TOP_DOWN_BREAK");
			case "innermost"      : { traverse_fun = mkCallToLibFun("Library","TRAVERSE_BOTTOM_UP"); fixpoint = true; }
			case "outermost"      : { traverse_fun = mkCallToLibFun("Library","TRAVERSE_TOP_DOWN"); fixpoint = true; }
		}
	}
	
	bool rebuild = false;
	if( Case c <- \visit.cases, (c is patternWithAction && c.patternWithAction is replacing 
									|| hasTopLevelInsert(c)) ) {
		rebuild = true;
	}
	
	// Unique 'id' of a visit in the function body
	int i = nextVisit();
	
	previously_declared_functions = size(getFunctionsInModule());
	
	// Generate and add a nested function 'phi'
	str scopeId = topFunctionScope();
	str phi_fuid = scopeId + "/" + "PHI_<i>";
	Symbol phi_ftype = Symbol::func(Symbol::\value(), [Symbol::\value(),	// iSubject
	                                                   Symbol::\bool(),		// matched
	                                                   Symbol::\bool(),		// hasInsert
	                                                   Symbol::\int(),		// begin
	                                                   Symbol::\int()		// end
	                                                  ]);
	
	enterVisit();
	enterFunctionScope(phi_fuid);
	
	MuExp body = translateVisitCases([ c | Case c <- \visit.cases ], phi_fuid, getType(\visit.subject.origin));
	
	// ***Note: (fixes issue #434) 
	//    (1) All the variables introduced within a visit scope should become local variables of the phi-function
	//    (2) All the nested functions (a) introduced within a visit scope or 
	//                                 (b) introduced within the phi's scope as part of translation
	//        are affected
	// TODO: It seems possible to perform this lifting during translation 
	rel[str fuid,int pos] decls = getAllVariablesAndFunctionsOfBlockScope(\visit.origin);
	
	//println("getAllVariablesAndFunctionsOfBlockScope:");
	//for(tup <- decls){
	//	println(tup);
	//}
	// Starting from the number of formal parameters (iSubject, matched, hasInsert, begin, end)
	int pos_in_phi = NumberOfPhiFormals;
	// Map from <scopeId,pos> to <phi_fuid,newPos>
	map[tuple[str,int],tuple[str,int]] mapping = ();
	for(<str fuid,int pos> <- decls, pos != -1) {
	    assert fuid == scopeId;
	    mapping[<scopeId,pos>] = <phi_fuid,pos_in_phi>;
	    pos_in_phi = pos_in_phi + 1;
	}
	
	//println("mapping");
	//for(k <- mapping){ println("\t<k>: <mapping[k]>"); }
	//println("lifting, scopeId = <scopeId>, phi_fuid = <phi_fuid>");
	//println("previously_declared_functions = <previously_declared_functions>, added by visit: <size(getFunctionsInModule()) - previously_declared_functions>");
	
	
	body = lift(body,scopeId,phi_fuid,mapping);

    all_functions = getFunctionsInModule();
    
    //println("all_functions");
    //for(f <- all_functions){
    //	println("<f.qname>, <f.src>, inside visit: <f.src < \visit@\loc>");
    //
    //}
    //print("sizes: <size(all_functions[ .. previously_declared_functions])>, <size(all_functions[previously_declared_functions..])>");
    
    lifted_functions = lift(all_functions[previously_declared_functions..], scopeId, phi_fuid, mapping);
    
    //println("size lifted_functions: <size(lifted_functions)>");
    
	setFunctionsInModule(all_functions[ .. previously_declared_functions] + lifted_functions);
	
	//setFunctionsInModule(lift(all_functions, scopeId, phi_fuid, mapping));
	
	//println("size functions after lift: <size(getFunctionsInModule())>");
	
	addFunctionToModule(muFunction(phi_fuid, "PHI", phi_ftype, scopeId, NumberOfPhiFormals, pos_in_phi, false, \visit.origin, [], (), body));
	
	leaveFunctionScope();
	leaveVisit();
	
	if(fixpoint) {
		str phi_fixpoint_fuid = scopeId + "/" + "PHI_FIXPOINT_<i>";
		
		enterFunctionScope(phi_fixpoint_fuid);
		
		// Local variables of 'phi_fixpoint_fuid': 'iSubject', 'matched', 'hasInsert', 'begin', 'end', 'changed', 'val'
		list[MuExp] body_exps = [];
		body_exps += muAssign("changed", phi_fixpoint_fuid, changedPos, muBool(true));
		body_exps += muWhile(nextLabel(), muVar("changed", phi_fixpoint_fuid, changedPos), 
						[ muAssign("val", phi_fixpoint_fuid, valPos, 
						                  muCall(muFun2(phi_fuid,scopeId), [ muVar("iSubject", phi_fixpoint_fuid, iSubjectPos), 
						                                                     muVar("matched", phi_fixpoint_fuid, matchedPos), 
						                                                     muVar("hasInsert", phi_fixpoint_fuid, hasInsertPos),
						                                                     muVar("begin", phi_fixpoint_fuid, beginPos),	
						                                                     muVar("end", phi_fixpoint_fuid, endPos)			                                                                                   
						                                                   ])),
						  muIfelse(nextLabel(), makeMu("ALL", [ muCallPrim3("equal", [ muVar("val", phi_fixpoint_fuid, valPos), 
						                                                              muVar("iSubject", phi_fixpoint_fuid, iSubjectPos) ], \visit.origin) ], \visit.origin ),
						  						[ muAssign("changed", phi_fixpoint_fuid,changedPos, muBool(false)) ], 
						  						[ muAssign("iSubject", phi_fixpoint_fuid, iSubjectPos, muVar("val", phi_fixpoint_fuid, valPos)) ] )]);
		body_exps += muReturn1(muVar("iSubject", phi_fixpoint_fuid, iSubjectPos));
		
		leaveFunctionScope();
		
		addFunctionToModule(muFunction(phi_fixpoint_fuid, "PHI_FIXPOINT", phi_ftype, scopeId, NumberOfPhiFixFormals, NumberOfPhiFixLocals, false, \visit.origin, [], (), muBlock(body_exps)));
	
	    // Local variables of the surrounding function
		str hasMatch = asTmp(nextLabel());
		str beenChanged = asTmp(nextLabel());
		str begin = asTmp(nextLabel());
		str end = asTmp(nextLabel());
		return muBlock([ muAssignTmp(hasMatch,scopeId,muBool(false)),
						 muAssignTmp(beenChanged,scopeId,muBool(false)),
						// muAssignTmp(advance,scopeId,muCon(1)),
					 	 muCall(traverse_fun, [ muFun2(phi_fixpoint_fuid,scopeId), 
					 	 						      translate(\visit.subject), 
					 	 						      muTmpRef(hasMatch,scopeId), 
					 	 						      muTmpRef(beenChanged,scopeId), 
					 	 						      muTmpRef(begin,scopeId), 
					 	 						      muTmpRef(end,scopeId),
					 	 						      muBool(rebuild) ]) 
				   	   ]);
	}
	
	// Local variables of the surrounding function
	str hasMatch = asTmp(nextLabel());
	str beenChanged = asTmp(nextLabel());
	str begin = asTmp(nextLabel());
	str end = asTmp(nextLabel());
	return muBlock([ muAssignTmp(hasMatch,scopeId,muBool(false)), 
	                 muAssignTmp(beenChanged,scopeId,muBool(false)),
	                 //muAssignTmp(advance,scopeId,muCon(1)),
					 muCall(traverse_fun, [ muFun2(phi_fuid,scopeId), 
					                        translate(\visit.subject), 
					                        muTmpRef(hasMatch,scopeId), 
					                        muTmpRef(beenChanged,scopeId), 
					                        muTmpRef(begin,scopeId), 
					 	 					muTmpRef(end,scopeId),
					                        muBool(rebuild) ]) 
				   ]);
}

@doc{Generates the body of a phi function}
MuExp translateVisitCases(list[Case] cases, str fuid, Symbol subjectType) {
	// TODO: conditional
	if(size(cases) == 0) {
		return muReturn1(muVar("iSubject", fuid, iSubjectPos));
	}
	
	c = head(cases);
	
	if(c is patternWithAction) {
		pattern = c.patternWithAction.pattern;
		typePat = getType(pattern.origin);
		cond = muMulti(muApply(translatePatInVisit(pattern, fuid, subjectType), [ muVar("iSubject", fuid, iSubjectPos) ]));
		ifname = nextLabel();
		enterBacktrackingScope(ifname);
		if(c.patternWithAction is replacing) {
			replacement = translate(c.patternWithAction.replacement.replacementExpression);
			list[MuExp] conditions = [];
			if(c.patternWithAction.replacement is conditional) {
				conditions = [ translate(e) | Expression e <- c.patternWithAction.replacement.conditions ];
			}
			replacementType = getType(c.patternWithAction.replacement.replacementExpression.origin);
			tcond = muCallPrim3("subtype", [ muTypeCon(replacementType), 
			                                 muCallPrim3("typeOf", [ muVar("iSubject", fuid, iSubjectPos) ], c.origin) ], c.origin);
			list[MuExp] cbody = [ muAssignVarDeref("matched", fuid, matchedPos, muBool(true)), 
			                      muAssignVarDeref("hasInsert", fuid, hasInsertPos, muBool(true)), 
			                      replacement ];
        	exp = muIfelse(ifname, makeMu("ALL",[ cond,tcond,*conditions ], pattern.origin), [ muReturn1(muBlock(cbody)) ], [ translateVisitCases(tail(cases),fuid, subjectType) ]);
        	leaveBacktrackingScope();
        	return exp;
		} else {
			// Arbitrary
			case_statement = c.patternWithAction.statement;
			\case = translate(case_statement);
			insertType = topCaseType();
			clearCaseType();
			tcond = muCallPrim3("subtype", [ muTypeCon(insertType), muCallPrim3("typeOf", [ muVar("iSubject",fuid,iSubjectPos) ], c.origin) ], c.origin);
			list[MuExp] cbody = [ muAssignVarDeref("matched", fuid, matchedPos, muBool(true)) ];
			if(!(muBlock([]) := \case)) {
				cbody += \case;
			}
			cbody += muReturn1(muVar("iSubject", fuid, iSubjectPos));
			exp = muIfelse(ifname, makeMu("ALL",[ cond,tcond ], pattern.origin), cbody, [ translateVisitCases(tail(cases),fuid, subjectType) ]);
        	leaveBacktrackingScope();
			return exp;
		}
	} else {
		// Default
		return muBlock([ muAssignVarDeref("matched", fuid, matchedPos, muBool(true)), 
		                 translate(c.statement), 
		                 muReturn1(muVar("iSubject", fuid, iSubjectPos)) ]);
	}
}

private bool hasTopLevelInsert(Case c) {
	println("Look for an insert...");
	top-down-break visit(c) {
		case (Statement) `insert <DataTarget dt> <Statement stat>`: return true;
		case Visit v: ;
	}
	return false;
}
/*
default MuExp translatePat(p:(Pattern) `<Literal lit>`) = translateLitPat(lit);

MuExp translateLitPat(Literal lit) = muApply(mkCallToLibFun("Library","MATCH_LITERAL"), [translate(lit)]);

// -- regexp pattern -------------------------------------------------

MuExp translatePat(p:(Pattern) `<RegExpLiteral r>`) = translateRegExpLiteral(r);

*/

MuExp translatePatInVisit(Pattern pattern, str fuid, Symbol subjectType){
   if(subjectType == \str()){
      switch(pattern){
        case p:(Pattern) `<RegExpLiteral r>`: return translateRegExpLiteral(r, muVar("begin", fuid, beginPos), muVar("end", fuid, endPos));
        
      	case p:(Pattern) `<Literal lit>`: 
      		return muApply(mkCallToLibFun("Library","MATCH_SUBSTRING"), [translate(lit), muVar("begin", fuid, beginPos), muVar("end", fuid, endPos)]);
      	default: return translatePat(pattern);
      }
   }
   return translatePat(pattern);
}

// -- reducer expression --------------------------------------------

MuExp translate (e:(Expression) `( <Expression init> | <Expression result> | <{Expression ","}+ generators> )`) = translateReducer(e); //translateReducer(init, result, generators);

MuExp translateReducer(Expression e){ //Expression init, Expression result, {Expression ","}+ generators){
    Expression init = e.init;
    Expression result = e.result;
    {Expression ","}+  generators = e.generators;
    str fuid = topFunctionScope();
    loopname = nextLabel(); 
    tmp = asTmp(loopname); 
    pushIt(tmp,fuid);
    code = [ muAssignTmp(tmp, fuid, translate(init)), muWhile(loopname, makeMuMulti(makeMu("ALL", [ translate(g) | g <- generators ], e.origin), e.origin), [muAssignTmp(tmp,fuid,translate(result))]), muTmp(tmp,fuid)];
    popIt();
    return muBlock(code);
}

// -- reified type expression ---------------------------------------

MuExp translate (e:(Expression) `type ( <Expression symbol> , <Expression definitions >)`) {
	
    return muCallPrim3("reifiedType_create", [translate(symbol), translate(definitions)], e.origin);
    
}

//MuExp translateConstantCall("List", "size", [muCon(list[value] lst)]) = muCon(size(lst));
//
//MuExp translateConstantCall("ParseTree", "left", []) = muCon(\left());
//MuExp translateConstantCall("ParseTree", "right", []) = muCon(\right());
//MuExp translateConstantCall("ParseTree", "assoc", []) = muCon(\assoc());
//MuExp translateConstantCall("ParseTree", "non-assoc", []) = muCon(\non-assoc());
//
//MuExp translateConstantCall("ParseTree", "assoc", [muCon(Associativity a)]) = muCon(\assoc(a));
//MuExp translateConstantCall("ParseTree", "bracket", [muCon(Associativity a)]) = muCon(\bracket());
//
//MuExp translateConstantCall("ParseTree", "prod", [muCon(Symbol def), muCon(list[Symbol] symbols), muCon(set[Attr] attributes)]) = muCon(prod(def,symbols,attributes));
//MuExp translateConstantCall("ParseTree", "regular", [muCon(Symbol def)]) = muCon(regular(def));
//MuExp translateConstantCall("ParseTree", "error", [muCon(Production prod), muCon(int dot)]) = muCon(error(prod, dot));
//MuExp translateConstantCall("ParseTree", "skipped", []) = muCon(skipped());
//
//MuExp translateConstantCall("ParseTree", "appl", [muCon(Production prod), muCon(list[Tree] args)]) = muCon(appl(prod, args));
//MuExp translateConstantCall("ParseTree", "cycle", [muCon(Symbol symbol), muCon(int cycleLength)]) = muCon(cycle(symbol, cycleLength));
//MuExp translateConstantCall("ParseTree", "char", [muCon(int character)]) = muCon(char(character));
//
//MuExp translateConstantCall("ParseTree", "range", [muCon(int begin), muCon(int end)]) = muCon(range(begin, end));
//
//// Symbol
//MuExp translateConstantCall("ParseTree", "start", [muCon(Symbol symbol)]) = muCon(\start(symbol));
//MuExp translateConstantCall("ParseTree", "sort", [muCon(str name)]) = muCon(sort(name));
//MuExp translateConstantCall("ParseTree", "lex", [muCon(str name)]) = muCon(lex(name));
//MuExp translateConstantCall("ParseTree", "layouts", [muCon(str name)]) = muCon(layouts(name));
//MuExp translateConstantCall("ParseTree", "keywords", [muCon(str name)]) = muCon(keywords(name));
//MuExp translateConstantCall("ParseTree", "parameterized-sort", [muCon(str name), muCon(list[Symbol] parameters)]) = muCon(\parameterized-sort(name, parameters));
//MuExp translateConstantCall("ParseTree", "parameterized-lex", [muCon(str name), muCon(list[Symbol] parameters)]) = muCon(\parameterized-lex(name, parameters));
//
//MuExp translateConstantCall("ParseTree", "lit", [muCon(str s)]) = muCon(lit(s));
//MuExp translateConstantCall("ParseTree", "cilit", [muCon(str s)]) = muCon(cilit(s));
//MuExp translateConstantCall("ParseTree", "char-class", [muCon(list[CharRange] ranges)]) = muCon(\char-class(ranges));
//
//
//MuExp translateConstantCall("ParseTree", "empty", []) = muCon(empty());
//MuExp translateConstantCall("ParseTree", "opt", [muCon(Symbol symbol)]) = muCon(opt(symbol));
//MuExp translateConstantCall("ParseTree", "iter", [muCon(Symbol symbol)]) = muCon(iter(symbol));
//MuExp translateConstantCall("ParseTree", "iter-star", [muCon(Symbol symbol)]) = muCon(\iter-star(symbol));
//MuExp translateConstantCall("ParseTree", "iter-seps", [muCon(Symbol symbol)], muCon(list[Symbol] separators)) = muCon(\iter-seps(symbol), separators);
//MuExp translateConstantCall("ParseTree", "iter-star-seps", [muCon(Symbol symbol)], muCon(list[Symbol] separators)) = muCon(\iter-star-seps(symbol), separators);
//MuExp translateConstantCall("ParseTree", "alt", [muCon(set[Symbol] alternatives)]) = muCon(alt(alternatives));
//MuExp translateConstantCall("ParseTree", "seq", [muCon(list[Symbol] symbols)]) = muCon(seq(symbols));
//
//MuExp translateConstantCall("ParseTree", "conditional", [muCon(Symbol symbol), muCon(list[Symbol] conditions)]) = muCon(conditional(symbol, conditions));
//
//MuExp translateConstantCall("ParseTree", "label", [muCon(str name), muCon(Symbol symbol)]) = muCon(label(name, symbol));
//MuExp translateConstantCall("Type", "label", [muCon(str name), muCon(Symbol symbol)]) = muCon(label(name, symbol));
//
//
//
//default MuExp translateConstantCall(_, _, _) { throw "NotConstant"; }

// -- call expression -----------------------------------------------

MuExp translate(e:(Expression) `<Expression expression> ( <{Expression ","}* arguments> <KeywordArguments[Expression] keywordArguments>)`){

   //println("translate: <e>");
   MuExp kwargs = translateKeywordArguments(keywordArguments);
      
   MuExp receiver = translate(expression);
   //println("receiver: <receiver>");
   list[MuExp] args = [ translate(a) | a <- arguments ];
   
   //println("BACK at translate <e>");
   
   if(getOuterType(expression) == "str"){
   		return muCallPrim3("node_create", [receiver, *args, *kwargs], e.origin);
       //return muCallPrim3("node_create", [receiver, *args] + (size_keywordArguments(keywordArguments) > 0 ? [kwargs] : [/* muCon(()) */]), e@\loc);
   }
  
   if(getOuterType(expression) == "loc"){
       return muCallPrim3("loc_with_offset_create", [receiver, *args], e.origin);
   }
   if(muFun1(str _) := receiver || muFun2(str _, str _) := receiver || muConstr(str _) := receiver) {
       return muCall(receiver, args + [ kwargs ]);
   }
   
   // Now overloading resolution...
   ftype = getType(expression.origin); // Get the type of a receiver
                                     // and a version with type parameters uniquely renamed
   ftype_renamed = visit(ftype) { case parameter(str name, Symbol sym) => parameter("1" + name, sym) };
   
   if(isOverloadedFunction(receiver) && hasOverloadingResolver(receiver.fuid)){
       // Get the types of arguments
       list[Symbol] targs = [ getType(arg.origin) | arg <- arguments ];
       // Generate a unique name for an overloaded function resolved for this specific use 
       str ofqname = receiver.fuid + "(<for(targ<-targs){><targ>;<}>)#<e.origin.offset>_<e.origin.length>";
       
// Resolve alternatives for this specific call
       OFUN of = getOverloadedFunction(receiver.fuid);
       
       list[int] resolved = [];
       
       bool isVarArgs(Symbol ftype) = ftype@isVarArgs? ? ftype@isVarArgs : false;
       
       // match function use and def, taking varargs into account
       bool function_subtype(Symbol fuse, Symbol fdef){
       	upar = fuse.parameters;
       	dpar = fdef.parameters;
       	if(isVarArgs(fdef) && !isVarArgs(fuse)){
       		un = size(upar);
       		dn = size(dpar);
       		var_elm_type = dpar[-1][0];
       		i = un - 1;
       		while(i > 0){
       			if(subtype(upar[i], var_elm_type)){
       				i -= 1;
       			} else {
       				break;
       			}
       		}
       		upar = upar[0 .. i + 1] + dpar[-1];
       	}
       
       	return subtype(upar, dpar);
       }
       
       bool matches(Symbol t) {
       	   //println("matches: <ftype>, <t>");
           if(isFunctionType(ftype) || isConstructorType(ftype)) {
               if(/parameter(_,_) := t) { // In case of polymorphic function types
                   ftype_selected = ftype;
                   //common = {name | /parameter(str name, _) := t} & {name | /parameter(str name, _) := ftype};
                   //if(!isEmpty(common)){
                   //println("USING RENAMED");
                   // ftype_selected = ftype_renamed;
                   //}
                   try {
                       if(isConstructorType(t) && isConstructorType(ftype_selected)) {
                           bindings = match(\tuple([ a | Symbol arg <- getConstructorArgumentTypes(t),     label(_,Symbol a) := arg || Symbol a := arg ]),
                                            \tuple([ a | Symbol arg <- getConstructorArgumentTypes(ftype_selected), label(_,Symbol a) := arg || Symbol a := arg ]),());
                           bindings = bindings + ( name : Symbol::\void() | /parameter(str name,_) := t, name notin bindings );
                           return instantiate(t.\adt,bindings) == ftype_selected.\adt;
                       }
                       if(isFunctionType(t) && isFunctionType(ftype_selected)) {
                           //println("t:              <t>");
                           //println("ftype_selected: <ftype_selected>");
                 
                           bindings = match(getFunctionArgumentTypesAsTuple(t),getFunctionArgumentTypesAsTuple(ftype_selected),());
                           
                           //println("bindings1: <bindings>");
                           
                           bindings = bindings + ( name : Symbol::\void() | /parameter(str name,_) := t, name notin bindings );
                           
                           //println("bindings2: <bindings>");
                           //println("t.ret:               <t.ret> becomes <instantiate(t.ret,bindings)>");
                           //println("ftype_selected.ret:  <ftype_selected.ret> becomes <instantiate(ftype_selected.ret,bindings)>");
                           
                           bool res =  instantiate(t.ret,bindings) == ftype_selected.ret;
                           
                           //println("res: <res>");
                           
                           return res;
                       }
                       return false;
                   } catch invalidMatch(_,_,_): {
                       return false;
                   } catch invalidMatch(_,_): {
                       return false; 
                   } catch err: {
                       println("WARNING: Cannot match <ftype> against <t> for location: <expression.origin>! <err>");
                   }
               }
               //println("matches returns: <function_subtype(ftype, t)>");
               //return t == ftype;
               return function_subtype(ftype, t);
           }           
           if(isOverloadedType(ftype)) {
               if(/parameter(_,_) := t) { // In case of polymorphic function types
                   for(Symbol alt <- (getNonDefaultOverloadOptions(ftype) + getDefaultOverloadOptions(ftype))) {
                       try {
           	               if(isConstructorType(t) && isConstructorType(alt)) {
           	                   bindings = match(\tuple([ a | Symbol arg <- getConstructorArgumentTypes(t),   label(_,Symbol a) := arg || Symbol a := arg ]),
           	                                    \tuple([ a | Symbol arg <- getConstructorArgumentTypes(alt), label(_,Symbol a) := arg || Symbol a := arg ]),());
           	                   bindings = bindings + ( name : Symbol::\void() | /parameter(str name,_) := t, name notin bindings );
           	                   return instantiate(t.\adt,bindings) == alt.\adt;
           	               }
           	               if(isFunctionType(t) && isFunctionType(alt)) {
           	                   bindings = match(getFunctionArgumentTypesAsTuple(t),getFunctionArgumentTypesAsTuple(alt),());
           	                   bindings = bindings + ( name : Symbol::\void() | /parameter(str name,_) := t, name notin bindings );
           	                   return instantiate(t.ret,bindings) == alt.ret;
           	               }
           	               return false;
           	           } catch invalidMatch(_,_,_): {
           	               ;
                       } catch invalidMatch(_,_): {
                           ;
                       } catch err: {
                           println("WARNING: Cannot match <alt> against <t> for location: <expression.origin>! <err>");
                       }
                   }
                   return false;
           	   }
               //return t in (getNonDefaultOverloadOptions(ftype) + getDefaultOverloadOptions(ftype));
               return any(Symbol sup <- (getNonDefaultOverloadOptions(ftype) + getDefaultOverloadOptions(ftype)), subtype(t.parameters, sup.parameters)); // TODO function_subtype
           }
           throw "Ups, unexpected type of the call receiver expression!";
       }
       
     
       //println("ftype = <ftype>, of.alts = <of.alts>");
       for(int alt <- of.alts) {
       	   assert uid2type[alt]? : "cannot find type of alt";
           t = uid2type[alt];
           if(matches(t)) {
           	   //println("alt <alt> matches");
               resolved += alt;
           }
       }
       //println("resolved = <resolved>");
       if(isEmpty(resolved)) {
           for(int alt <- of.alts) {
               t = uid2type[alt];
               matches(t);
               println("ALT: <t> ftype: <ftype>");
           }
           throw "ERROR in overloading resolution: <ftype>; <expression.origin>";
       }
       
   //    if(size(resolved) == 1 && (isEmpty(args) || all(muCon(_) <- args))){
   //    		fuid = resolved[0];
   //    		name = unescape("<expression>");
   //    		println("resolved to single function with constant aruments: <fuid>, outer: <uid2addr[fuid]>, <name>");
			//
   //    		try {
   //    			return translateConstantCall(uid2addr[fuid][0], name, args);
   //    		} 
   //    		catch "NotConstant":  /* pass */;
   //    }
       	addOverloadedFunctionAndResolver(ofqname, <of.fuid,resolved>);      
       	return muOCall3(muOFun(ofqname), args + [ kwargs ], e.origin);
   }
   if(isOverloadedFunction(receiver) && !hasOverloadingResolver(receiver.fuid)) {
      throw "The use of a function has to be managed via an overloading resolver!";
   }
   // Push down additional information if the overloading resolution needs to be done at runtime
   return muOCall4(receiver, 
   				  isFunctionType(ftype) ? Symbol::\tuple([ ftype ]) : Symbol::\tuple([ t | Symbol t <- (getNonDefaultOverloadOptions(ftype) + getDefaultOverloadOptions(ftype)) ]), 
   				  args + [ kwargs ],
   				  e.origin);
}

MuExp translateKeywordArguments((KeywordArguments[Expression]) `<KeywordArguments[Expression] keywordArguments>`) {
   // Keyword arguments
   if(keywordArguments is \default){
      kwargs = [ muCon(unescape("<kwarg.name>")), translate(kwarg.expression)  | /*KeywordArgument[Expression]*/ kwarg <- keywordArguments.keywordArgumentList ];
      if(size(kwargs) > 0){
         return muCallMuPrim("make_mmap", kwargs);
      }
   }
   return muCallMuPrim("make_mmap", []);
   
   //str fuid = topFunctionScope();
   //list[MuExp] kwargs = [ muAssignTmp("map_of_keyword_arguments", fuid, muCallPrim("mapwriter_open",[])) ];
   //if(keywordArguments is \default) {
   //    for(KeywordArgument kwarg <- keywordArguments.keywordArgumentList) {
   //        kwargs += muCallPrim("mapwriter_add",[ muTmp("map_of_keyword_arguments",fuid), muCon("<kwarg.name>"), translate(kwarg.expression) ]);           
   //    }
   //}
   //return muBlock([ *kwargs, muCallPrim("mapwriter_close", [ muTmp("map_of_keyword_arguments",fuid) ]) ]);
}

// -- any expression ------------------------------------------------

MuExp translate (e:(Expression) `any ( <{Expression ","}+ generators> )`) = makeMuOne("ALL",[ translate(g) | g <- generators ], e.origin);

// -- all expression ------------------------------------------------

MuExp translate (e:(Expression) `all ( <{Expression ","}+ generators> )`) {
  
  // First split generators with a top-level && operator
  generators1 = [*(((Expression) `<Expression e1> && <Expression e2>` := g) ? [e1, e2] : [g]) | g <- generators];
  isGen = [!backtrackFree(g) | g <- generators1];
  //println("isGen: <isGen>");
  tgens = [];
  for(i <- index(generators1)) {
     gen = generators1[i];
     //println("all <i>: <gen>");
     if(isGen[i]){
	 	tgen = translate(gen);
	 	if(muMulti(exp) := tgen){ // Unwraps muMulti, if any
	 	   tgen = exp;
	 	}
	 	tgens += tgen;
	 } else {
	    tgens += translateBoolClosure(gen);
	 }
  }
  return muCall(mkCallToLibFun("Library", "RASCAL_ALL"), [ muCallMuPrim("make_array", tgens), muCallMuPrim("make_array", [ muBool(b) | bool b <- isGen ]) ]);
}

// -- comprehension expression --------------------------------------

MuExp translate (e:(Expression) `<Comprehension comprehension>`) =translateComprehension(comprehension);

//private MuExp translateGenerators({Expression ","}+ generators){
//   println("translateGenerators: <generators>, <generators@\loc>");
//   res = makeMu("ALL",[translate(g) | g <-generators], generators@\loc);
//   println("res = <res>");
//   return res;
//}

private list[MuExp] translateComprehensionContribution(str kind, str tmp, str fuid, list[Expression] results){
  return 
	  for( r <- results){
	    if((Expression) `* <Expression exp>` := r){
	       append muCallPrim3("<kind>writer_splice", [muTmp(tmp,fuid), translate(exp)], exp.origin);
	    } else {
	      append muCallPrim3("<kind>writer_add", [muTmp(tmp,fuid), translate(r)], r.origin);
	    }
	  }
} 

private MuExp translateComprehension(c: (Comprehension) `[ <{Expression ","}+ results> | <{Expression ","}+ generators> ]`) {
    //println("translateComprehension (list): <generators>");
    str fuid = topFunctionScope();
    loopname = nextLabel(); 
    tmp = asTmp(loopname);
    return
    muBlock(
    [ muAssignTmp(tmp, fuid, muCallPrim3("listwriter_open", [], c.origin)),
      muWhile(loopname, makeMuMulti(makeMu("ALL",[ translate(g) | g <- generators ], c.origin), c.origin), translateComprehensionContribution("list", tmp, fuid, [r | r <- results])),
      muCallPrim3("listwriter_close", [muTmp(tmp,fuid)], c.origin) 
    ]);
}

private MuExp translateComprehension(c: (Comprehension) `{ <{Expression ","}+ results> | <{Expression ","}+ generators> }`) {
    //println("translateComprehension (set): <generators>");
    str fuid = topFunctionScope();
    loopname = nextLabel(); 
    tmp = asTmp(loopname); 
    return
    muBlock(
    [ muAssignTmp(tmp, fuid, muCallPrim3("setwriter_open", [], c.origin)),
      muWhile(loopname, makeMuMulti(makeMu("ALL",[ translate(g) | g <- generators ], c.origin), c.origin), translateComprehensionContribution("set", tmp, fuid, [r | r <- results])),
      muCallPrim3("setwriter_close", [muTmp(tmp,fuid)], c.origin) 
    ]);
}

private MuExp translateComprehension(c: (Comprehension) `(<Expression from> : <Expression to> | <{Expression ","}+ generators> )`) {
    //println("translateComprehension (map): <generators>");
    str fuid = topFunctionScope();
    loopname = nextLabel(); 
    tmp = asTmp(loopname); 
    return
    muBlock(
    [ muAssignTmp(tmp, fuid, muCallPrim3("mapwriter_open", [], c.origin)),
      muWhile(loopname, makeMuMulti(makeMu("ALL",[ translate(g) | g <- generators ], c.origin), c.origin), [muCallPrim3("mapwriter_add", [muTmp(tmp,fuid)] + [ translate(from), translate(to)], c.origin)]), 
      muCallPrim3("mapwriter_close", [muTmp(tmp,fuid)], c.origin) 
    ]);
}

// -- set expression ------------------------------------------------

MuExp translate(Expression e:(Expression)`{ <{Expression ","}* es> }`) =
    translateSetOrList(e, es, "set");

// -- list expression -----------------------------------------------

MuExp translate(Expression e:(Expression)`[ <{Expression ","}* es> ]`) = 
    translateSetOrList(e, es, "list");

// Translate SetOrList including spliced elements

private bool containSplices({Expression ","}* es) =
    any(Expression e <- es, e is splice);

private MuExp translateSetOrList(Expression e, {Expression ","}* es, str kind){
 if(containSplices(es)){
       str fuid = topFunctionScope();
       writer = nextTmp();
       enterWriter(writer);
       code = [ muAssignTmp(writer, fuid, muCallPrim3("<kind>writer_open", [], e.origin)) ];
       for(elem <- es){
           if(elem is splice){
              code += muCallPrim3("<kind>writer_splice", [muTmp(writer,fuid), translate(elem.argument)], elem.argument.origin);
            } else {
              code += muCallPrim3("<kind>writer_add", [muTmp(writer,fuid), translate(elem)], elem.origin);
           }
       }
       code += [ muCallPrim3("<kind>writer_close", [ muTmp(writer,fuid) ], e.origin) ];
       leaveWriter();
       return muBlock(code);
    } else {
      //if(size(es) == 0 || all(elm <- es, isConstant(elm))){
      //   return kind == "list" ? muCon([getConstantValue(elm) | elm <- es]) : muCon({getConstantValue(elm) | elm <- es});
      //} else 
        return muCallPrim3("<kind>_create", [ translate(elem) | elem <- es ], e.origin);
    }
}

// -- reified type expression ---------------------------------------

MuExp translate (e:(Expression) `# <Type tp>`) =
	muCon(symbolToValue(translateType(tp)));

// -- tuple expression ----------------------------------------------

MuExp translate (e:(Expression) `\< <{Expression ","}+ elements> \>`) {
    //if(isConstant(e)){
    //  return muCon(readTextValueString("<e>"));
    //} else
        return muCallPrim3("tuple_create", [ translate(elem) | elem <- elements ], e.origin);
}

// -- map expression ------------------------------------------------

MuExp translate (e:(Expression) `( <{Mapping[Expression] ","}* mappings> )`) {
   //if(isConstant(e)){
   //  return muCon(readTextValueString("<e>"));
   //} else 
     return muCallPrim3("map_create", [ translate(m.from), translate(m.to) | m <- mappings ], e.origin);
}   

// -- it expression (in reducer) ------------------------------------

MuExp translate (e:(Expression) `it`) = 
    muTmp(topIt().name,topIt().fuid);
 
// -- qualified name expression -------------------------------------
 
MuExp translate((Expression) `<QualifiedName v>`) = 
    translate(v);
 
MuExp translate(q:(QualifiedName) `<QualifiedName v>`) =
    mkVar("<v>", v.origin);

// For the benefit of names in regular expressions

MuExp translate((Name) `<Name name>`) =
    mkVar(unescape("<name>"), name.origin);

// -- subscript expression ------------------------------------------

MuExp translate(Expression e:(Expression) `<Expression exp> [ <{Expression ","}+ subscripts> ]`){
    ot = getOuterType(exp);
    op = "<ot>_subscript";
    if(ot in {"sort", "iter", "iter-star", "iter-seps", "iter-star-seps"}){
       op = "nonterminal_subscript_<intercalate("-", [getOuterType(s) | s <- subscripts])>";
    } else
    if(ot notin {"map", "rel", "lrel"}) {
       op += "_<intercalate("-", [getOuterType(s) | s <- subscripts])>";
    }
    
    return muCallPrim3(op, translate(exp) + ["<s>" == "_" ? muCon("_") : translate(s) | s <- subscripts], e.origin);
}

// -- slice expression ----------------------------------------------

MuExp translate (e:(Expression) `<Expression expression> [ <OptionalExpression optFirst> .. <OptionalExpression optLast> ]`) =
	translateSlice(expression, optFirst, optLast);

// -- slice with step expression ------------------------------------

MuExp translate (e:(Expression) `<Expression expression> [ <OptionalExpression optFirst> , <Expression second> .. <OptionalExpression optLast> ]`) =
	translateSlice(expression, optFirst, second, optLast);

MuExp translateSlice(Expression expression, OptionalExpression optFirst, OptionalExpression optLast) =
    muCallPrim3("<getOuterType(expression)>_slice", [ translate(expression), translateOpt(optFirst), muCon("false"), translateOpt(optLast) ], expression.origin);

MuExp translateOpt(OptionalExpression optExp) =
    optExp is noExpression ? muCon("false") : translate(optExp.expression);

MuExp translateSlice(Expression expression, OptionalExpression optFirst, Expression second, OptionalExpression optLast) =
    muCallPrim3("<getOuterType(expression)>_slice", [  translate(expression), translateOpt(optFirst), translate(second), translateOpt(optLast) ], expression.origin);

// -- field access expression ---------------------------------------

MuExp translate (e:(Expression) `<Expression expression> . <Name field>`) {
   tp = getType(expression.origin);
   if(isTupleType(tp) || isRelType(tp) || isListRelType(tp) || isMapType(tp)) {
       return translate((Expression)`<Expression expression> \< <Name field> \>`);
   }
   op = isNonTerminalType(tp) ? "nonterminal" : getOuterType(expression);
   if(op == "label") println("field_access: <tp>, <e>");
   return muCallPrim3("<op>_field_access", [ translate(expression), muCon(unescape("<field>")) ], e.origin);
}

// -- field update expression ---------------------------------------

MuExp translate (e:(Expression) `<Expression expression> [ <Name key> = <Expression replacement> ]`) {
   
    tp = getType(expression.origin);  
    list[str] fieldNames = [];
    if(isRelType(tp)){
       tp = getSetElementType(tp);
    } else if(isListType(tp)){
       tp = getListElementType(tp);
    } else if(isMapType(tp)){
       tp = getMapFieldsAsTuple(tp);
    } else if(isADTType(tp)){
        return muCallPrim3("adt_field_update", [ translate(expression), muCon(unescape("<key>")), translate(replacement) ], e.origin);
    } else if(isLocType(tp)){
     	return muCallPrim3("loc_field_update", [ translate(expression), muCon(unescape("<key>")), translate(replacement) ], e.origin);
    }
    if(tupleHasFieldNames(tp)){
    	  fieldNames = getTupleFieldNames(tp);
    }	
    return muCallPrim3("<getOuterType(expression)>_update", [ translate(expression), muCon(indexOf(fieldNames, "<key>")), translate(replacement) ], e.origin);
}

// -- field project expression --------------------------------------

MuExp translate (e:(Expression) `<Expression expression> \< <{Field ","}+ fields> \>`) {
    tp = getType(expression.origin);   
    list[str] fieldNames = [];
    if(isRelType(tp)){
       tp = getSetElementType(tp);
    } else if(isListType(tp)){
       tp = getListElementType(tp);
    } else if(isMapType(tp)){
       tp = getMapFieldsAsTuple(tp);
    }
    if(tupleHasFieldNames(tp)){
       	fieldNames = getTupleFieldNames(tp);
    }	
    fcode = [(f is index) ? muCon(toInt("<f>")) : muCon(indexOf(fieldNames, "<f>")) | f <- fields];
    //fcode = [(f is index) ? muCon(toInt("<f>")) : muCon("<f>") | f <- fields];
    return muCallPrim3("<getOuterType(expression)>_field_project", [ translate(expression), *fcode], e.origin);
}

// -- set annotation expression -------------------------------------



MuExp translate (e:(Expression) `<Expression expression> [ @ <Name name> = <Expression val> ]`) =
    muCallPrim3("annotation_set", [translate(expression), muCon(unescape("<name>")), translate(val)], e.origin);

// -- get annotation expression -------------------------------------

MuExp translate (e:(Expression) `<Expression expression> @ <Name name>`) =
    muCallPrim3("annotation_get", [translate(expression), muCon(unescape("<name>"))], e.origin);

// -- is expression --------------------------------------------------

MuExp translate (e:(Expression) `<Expression expression> is <Name name>`) =
    muCallPrim3("is", [translate(expression), muCon(unescape("<name>"))], e.origin);

// -- has expression -----------------------------------------------

MuExp translate (e:(Expression) `<Expression expression> has <Name name>`) {
    outer = getOuterType(expression);
    return (outer == "adt") ? muCallPrim3("adt_has_field", [translate(expression), muCon(unescape("<name>"))], e.origin)
  						    : muCon(hasField(getType(expression.origin), unescape("<name>")));   
}
// -- transitive closure expression ---------------------------------

MuExp translate(e:(Expression) `<Expression argument> +`) =
    postfix_rel_lrel("transitive_closure", argument);

// -- transitive reflexive closure expression -----------------------

MuExp translate(e:(Expression) `<Expression argument> *`) = 
    postfix_rel_lrel("transitive_reflexive_closure", argument);

// -- isDefined expression ------------------------------------------

MuExp translate(e:(Expression) `<Expression argument> ?`) =
    generateIfDefinedOtherwise(muBlock([ translate(argument), muCon(true) ]),  muCon(false), e.origin);

// -- isDefinedOtherwise expression ---------------------------------

MuExp translate(e:(Expression) `<Expression lhs> ? <Expression rhs>`) =
    generateIfDefinedOtherwise(translate(lhs), translate(rhs), e.origin);

MuExp generateIfDefinedOtherwise(MuExp muLHS, MuExp muRHS, loc src) {
    str fuid = topFunctionScope();
    str varname = asTmp(nextLabel());
	// Check if evaluation of the expression throws a 'NoSuchKey' or 'NoSuchAnnotation' exception;
	// do this by checking equality of the value constructor names
	
	cond1 = muCallMuPrim("equal", [ muCon("UninitializedVariable"), muCallMuPrim("get_name", [ muTmp(asUnwrapedThrown(varname),fuid) ])]);
	cond2 = muCallMuPrim("equal", [ muCon("NoSuchKey"), muCallMuPrim("get_name", [ muTmp(asUnwrapedThrown(varname),fuid) ]) ]);
	cond3 = muCallMuPrim("equal", [ muCon("NoSuchAnnotation"), muCallMuPrim("get_name", [ muTmp(asUnwrapedThrown(varname),fuid) ]) ]);
		
	elsePart3 = muIfelse(nextLabel(), cond3, [ muRHS ], [ muThrow(muTmp(varname,fuid), src) ]);
	elsePart2 = muIfelse(nextLabel(), cond2, [ muRHS ], [ elsePart3 ]);
	catchBody = muIfelse(nextLabel(), cond1, [ muRHS ], [ elsePart2 ]);
	return muTry(muLHS, muCatch(varname, fuid, Symbol::\adt("RuntimeException",[]), catchBody), 
			  		 	muBlock([]));
}

// -- not expression ------------------------------------------------

MuExp translate(e:(Expression) `!<Expression argument>`) = 
    translateBool(e);

// -- negate expression ---------------------------------------------

MuExp translate(e:(Expression) `-<Expression argument>`) =
    prefix("negative", argument);

// -- splice expression ---------------------------------------------

MuExp translate(e:(Expression) `*<Expression argument>`) {
    throw "Splice cannot occur outside set or list";
}
   
// -- asType expression ---------------------------------------------

MuExp translate(e:(Expression) `[ <Type typ> ] <Expression argument>`)  =
   muCallPrim3("parse", [muCon(getModuleName()), 
   					    muCon(type(symbolToValue(translateType(typ)).symbol,getGrammar())), 
   					    translate(argument)], 
   					    e.origin);
   
// -- composition expression ----------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> o <Expression rhs>`) = 
    compose(e);

// -- product expression --------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> * <Expression rhs>`) =
    infix("product", e);

// -- join expression -----------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> join <Expression rhs>`) =
    infix("join", e);

// -- remainder expression -----------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> % <Expression rhs>`) =
    infix("remainder", e);

// -- division expression -------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> / <Expression rhs>`) =
    infix("divide", e);

// -- intersection expression ---------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> & <Expression rhs>`) =
    infix("intersect", e);

// -- addition expression -------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> + <Expression rhs>`) =
    add(e);

// -- subtraction expression ----------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> - <Expression rhs>`) =
    infix("subtract", e);

// -- insert before expression --------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \>\> <Expression rhs>`) =
    infix("add", e);

// -- append after expression ---------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \<\< <Expression rhs>`) =
    infix("add", e);

// -- modulo expression ---------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> mod <Expression rhs>`) =
    infix("mod", e);

// -- notin expression ----------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> notin <Expression rhs>`) =
    infix_elm_left("notin", e);

// -- in expression -------------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> in <Expression rhs>`) =
    infix_elm_left("in", e);

// -- greater equal expression --------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \>= <Expression rhs>`) = 
    infix("greaterequal", e);

// -- less equal expression -----------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \<= <Expression rhs>`) = 
    infix("lessequal", e);

// -- less expression ----------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \< <Expression rhs>`) = 
    infix("less", e);

// -- greater expression --------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> \> <Expression rhs>`) = 
    infix("greater", e);

// -- equal expression ----------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> == <Expression rhs>`) = 
    comparison("equal", e);

// -- not equal expression ------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> != <Expression rhs>`) = 
    comparison("notequal", e);


// -- no match expression -------------------------------------------

MuExp translate(e:(Expression) `<Pattern pat> !:= <Expression rhs>`) = 
    translateMatch(e);

// -- match expression ----------------------------------------------

MuExp translate(e:(Expression) `<Pattern pat> := <Expression exp>`) =
    translateMatch(e);

// -- enumerate expression ------------------------------------------

MuExp translate(e:(Expression) `<QualifiedName name> \<- <Expression exp>`) {
    <fuid, pos> = getVariableScope("<name>", name.origin);
    return muMulti(muApply(mkCallToLibFun("Library", "ENUMERATE_AND_ASSIGN"), [muVarRef("<name>", fuid, pos), translate(exp)]));
}

MuExp translate(e:(Expression) `<Type tp> <Name name> \<- <Expression exp>`) {
    <fuid, pos> = getVariableScope("<name>", name.origin);
    return muMulti(muApply(mkCallToLibFun("Library", "ENUMERATE_CHECK_AND_ASSIGN"), [muTypeCon(translateType(tp)), muVarRef("<name>", fuid, pos), translate(exp)]));
}

MuExp translate(e:(Expression) `<Pattern pat> \<- <Expression exp>`) =
    muMulti(muApply(mkCallToLibFun("Library", "ENUMERATE_AND_MATCH"), [translatePat(pat), translate(exp)]));

// -- implies expression --------------------------------------------

MuExp translate(e:(Expression) `<Expression lhs> ==\> <Expression rhs>`) =
    translateBool(e);

// -- equivalent expression -----------------------------------------
MuExp translate(e:(Expression) `<Expression lhs> \<==\> <Expression rhs>`) = 
    translateBool(e);

// -- and expression ------------------------------------------------

MuExp translate(Expression e:(Expression) `<Expression lhs> && <Expression rhs>`) =
    translateBool(e);

// -- or expression -------------------------------------------------

MuExp translate(Expression e:(Expression) `<Expression lhs> || <Expression rhs>`) =
    translateBool(e);
 
// -- conditional expression ----------------------------------------

MuExp translate(e:(Expression) `<Expression condition> ? <Expression thenExp> : <Expression elseExp>`) =
	// ***Note that the label (used to backtrack) here is not important (no backtracking scope is pushed) 
	// as it is not allowed to have 'fail' in conditional expressions
	muIfelse(nextLabel(),translate(condition), [translate(thenExp)],  [translate(elseExp)]);

// -- any other expression (should not happn) ------------------------

default MuExp translate(Expression e) {
	throw "MISSING CASE FOR EXPRESSION: <e>";
}

/*********************************************************************/
/*                  End of Ordinary Expessions                       */
/*********************************************************************/

/*********************************************************************/
/*                  BooleanExpessions                                */
/*********************************************************************/
 
// Is an expression free of backtracking? 

bool backtrackFree(Expression e){
    top-down visit(e){
    //case (Expression) `<Expression expression> ( <{Expression ","}* arguments> <KeywordArguments[Expression] keywordArguments>)`:
    //	return true;
    case (Expression) `all ( <{Expression ","}+ generators> )`: 
    	return true;
    case (Expression) `any ( <{Expression ","}+ generators> )`: 
    	return true;
    case (Expression) `<Pattern pat> \<- <Expression exp>`: 
    	return false;
    case (Expression) `<Pattern pat> \<- [ <Expression first> .. <Expression last> ]`: 
    	return false;
    case (Expression) `<Pattern pat> \<- [ <Expression first> , <Expression second> .. <Expression last> ]`: 
    	return false;
    case (Expression) `<Pattern pat> := <Expression exp>`:
    	return false;
    	case (Expression) `<Pattern pat> !:= <Expression exp>`:
    	return false;
    }
    return true;
}

// Boolean expressions

MuExp translateBool(e: (Expression) `<Expression lhs> && <Expression rhs>`) = makeMu("ALL",[translate(lhs), translate(rhs)], e.origin); //translateBoolBinaryOp("and", lhs, rhs);

MuExp translateBool(e: (Expression) `<Expression lhs> || <Expression rhs>`) = makeMu("OR",[translate(lhs), translate(rhs)], e.origin); //translateBoolBinaryOp("or", lhs, rhs);

MuExp translateBool(e: (Expression) `<Expression lhs> ==\> <Expression rhs>`) {
	println("Implication <lhs> (<lhs.origin>) <rhs>  (<rhs.origin>) "); 
	return makeMu("IMPLICATION",[ translate(lhs), translate(rhs) ], e.origin); }//translateBoolBinaryOp("implies", lhs, rhs);

MuExp translateBool(e: (Expression) `<Expression lhs> \<==\> <Expression rhs>`) = makeMu("EQUIVALENCE",[ translate(lhs), translate(rhs) ], e.origin); //translateBoolBinaryOp("equivalent", lhs, rhs);

MuExp translateBool((Expression) `! <Expression lhs>`) =
	backtrackFree(lhs) ? muCallMuPrim("not_mbool", [translateBool(lhs)])
  					   : muCallMuPrim("not_mbool", [ makeMu("ALL",[translate(lhs)], lhs.origin) ]);
 
MuExp translateBool(e: (Expression) `<Pattern pat> := <Expression exp>`)  = translateMatch(e);
   
MuExp translateBool(e: (Expression) `<Pattern pat> !:= <Expression exp>`) = translateMatch(e);

// All other expressions are translated as ordinary expression

default MuExp translateBool(Expression e) {
   return translate(e);
}

