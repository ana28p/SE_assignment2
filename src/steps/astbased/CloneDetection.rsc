module steps::astbased::CloneDetection

import lang::java::m3::AST;

import steps::astbased::FileParser;
import DataTypes;
import EvaluateResult;

import IO;
import Map;
import Node;
import util::Math;

alias MethodInfo = rel[loc sourceLoc, Declaration parsedMethod, int lines];

Clone collectType1Clones(map[loc,Declaration] asts) {
	Clone type1Clones = {};
	  
	map[loc, Declaration] withoutSrcMethods = ();
	MethodInfo methods = {};
   
	for (ast <- asts) {
	  	for (/m1:method(_, str name,_,_, Statement impl) <- asts[ast] ) {
	  		if (couldSubTreeBeAClone(m1) == true) {
	  			int lines = m1.src.end.line - impl.src.begin.line;
	  		
		  		Declaration m1WithoutSrc = removeSourceLocations(m1);
		  		m1WithoutSrc = removeAnnotations(m1WithoutSrc);
		  		
	  			for (<m2loc, m2, m2Lines> <- methods) {
			  		if (m1WithoutSrc == m2) {
			  			type1Clones += <m1.src, m2loc, type1(), getLineSimilarity(lines, m2Lines)>;
			  		}
	  			}
		  		methods += <m1.src, m1WithoutSrc, lines>;
	  		}
		}
	}
	
	return type1Clones;
}

Clone collectType2Clones(map[loc,Declaration] asts, Clone type1Clones) {
	Clone type2Clones = {};

	MethodInfo methods = {};
  
	for (ast <- asts) {
		for (/m1:method(_, str name,_,_, Statement impl) <- asts[ast] ) {
	  		if (couldSubTreeBeAClone(m1) == true) {
	  			int lines = m1.src.end.line - impl.src.begin.line;
	  			
				Declaration standardM1WithoutSrc = removeSourceLocations(m1);
		  		standardM1WithoutSrc = removeAnnotations(standardM1WithoutSrc);
	  			standardM1WithoutSrc = standardizeMethod(standardM1WithoutSrc);
	
	  			for (<m2loc, m2, m2Lines> <- methods) {
				  	// check first if it's not a type 1 clone
			  		if (<m1.src, m2loc, type1(), 100> notin type1Clones) {
			  			if (standardM1WithoutSrc == m2) {
				  			type2Clones += {<m1.src, m2loc, type2(), getLineSimilarity(lines, m2Lines)>};
				  		}
			  		}
	  			}
		  		methods += <m1.src, standardM1WithoutSrc, lines>;
	  		}
		}
	}
	
	return type2Clones;
}

int getLineSimilarity(int lines1, int lines2) = (min(lines1, lines2) * 100) / max(lines1, lines2);

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
		case methodCall(bool isSuper, str name, list[Expression] arguments) => methodCall(isSuper, "none", arguments)
		case methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments) => methodCall(isSuper, receiver, "none", arguments)
	};
	
	return standardizeMethod;
}