module AstBasedCloneDetector

import lang::java::m3::AST;

import steps::astbased::FileParser;
import DataTypes;
import StringBasedCloneDetector;
import EvaluateResult;

import IO;
import Map;
import Node;

void detectClonesUsingAstsOnSmallSet() = detectClonesUsingAsts(|project://assignment2/data/small|, true);
void detectClonesUsingAstsOnLargeSet() = detectClonesUsingAsts(|project://assignment2/data/large|, false);

void detectClonesUsingAsts(loc dataDir, bool smallSet) {
  
	println("(1/5) Reading the files");
	  
	map[loc,Declaration] asts = parseFiles(dataDir);
	  
	Clone type1Clones = {};
	Clone type2Clones = {};
	  
	println("(2/5) Finding type1 clones");
    type1Clones = collectType1Clones(asts);
    
	println("(3/5) Finding type2 clones");
	type2Clones = collectType2Clones(asts, type1Clones);
  
	println("(4/5) Evaluate clone duplication tool on type 1");
	evaluate(type1Clones + type2Clones, smallSet, type1());
	
	println("(5/5) Evaluate clone duplication tool on type 2");
	evaluate(type1Clones + type2Clones, smallSet, type2());
}

Clone collectType1Clones(map[loc,Declaration] asts) {
	Clone type1Clones = {};
	  
	map[loc, Declaration] withoutSrcMethods = ();
   
	for (ast <- asts) {
	  	for (/m1:method(_, str name,_,_, Statement impl) <- asts[ast] ) {
	  		if (couldSubTreeBeAClone(m1) == true) {
		  		Declaration m1WithoutSrc = removeSourceLocations(m1);
		  		m1WithoutSrc = removeAnnotations(m1WithoutSrc);
		  		
	  			for (m2loc <- withoutSrcMethods) {
	  				// get from map
	  				Declaration m2 = withoutSrcMethods[m2loc];
			  		
			  		if (m1WithoutSrc == m2) {
			  			type1Clones += <m1.src, m2loc, type1(), 100>;
			  		}
	  			}
		  		withoutSrcMethods += (m1.src: m1WithoutSrc);
	  		}
		}
	}
	
	return type1Clones;
}

Clone collectType2Clones(map[loc,Declaration] asts, Clone type1Clones) {
	Clone type2Clones = {};

	map[loc, Declaration] standardizeMethods = ();
  
	for (ast <- asts) {
		for (/m1:method(_, str name,_,_, Statement impl) <- asts[ast] ) {
	  		if (couldSubTreeBeAClone(m1) == true) {
				Declaration m1WithoutSrc = removeSourceLocations(m1);
		  		mi1WithoutSrc = removeAnnotations(m1WithoutSrc);
	  			Declaration standardM1 = standardizeMethod(m1WithoutSrc);
	
	  			for (m2loc <- standardizeMethods) {
	  				// get from map
	  				Declaration m2 = standardizeMethods[m2loc];
	  				
				  	// check first if it's not a type 1 clone
			  		if (<m1.src, m2loc, type1(), 100> notin type1Clones) {
			  			if (standardM1 == m2) {
				  			type2Clones += {<m1.src, m2loc, type2(), 100>};
				  		}
			  		}
	  			}
		  		standardizeMethods += (m1.src: standardM1);
	  		}
		}
	}
	
	return type2Clones;
}

bool couldSubTreeBeAType2Clone(\m1:method(_,_,_,_, Statement impl1), \m2:method(_,_,_,_, Statement impl2)) = (m1.src.end.line - impl1.src.begin.line) == (m2.src.end.line - impl2.src.begin.line);

Declaration standardizeMethod(Declaration method) {
	Declaration standardizeMethod = removeSourceLocations(method);
	standardizeMethod = removeAnnotations(standardizeMethod);

    standardizeMethod = standardizeMethod[name = "none"];
    
	standardizeMethod = visit (standardizeMethod) {
		case vararg(Type \type, str name) => vararg(\type, "none")
		case parameter(Type \type, str name, int extraDimensions) => parameter(\type, "none", extraDimensions)
		case simpleName(str name) => simpleName("none")
		case fieldAccess(bool isSuper, str name) => fieldAccess(isSuper, "none")
		case fieldAccess(bool isSuper, Expression expression, str name) => fieldAccess(isSuper, expression, "none")
		case variable(str name, int extraDimensions) => variable("none", extraDimensions)
		case variable(str name, int extraDimensions, Expression \initializer) => variable("none", extraDimensions, \initializer)
		case infix(Expression lhs, str operator, Expression rhs) => infix(lhs, "", rhs)
		case postfix(Expression operand, str operator) => postfix(operand, "")
		case prefix(str operator, Expression operand) => prefix("", operand)
		case number(str numberValue) => number("none")
		case booleanLiteral(bool boolValue) => booleanLiteral(false)
		case stringLiteral(str stringValue) => stringLiteral("none")
		case characterLiteral(str charValue) => characterLiteral("none")
	};
	
	return standardizeMethod;
}