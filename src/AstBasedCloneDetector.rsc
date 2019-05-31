module AstBasedCloneDetector

import lang::java::m3::AST;

import steps::astbased::FileParser;
import steps::astbased::CloneDetection;
import DataTypes;
import EvaluateResult;

import IO;
import Node;
import DateTime;

void detectClonesUsingAstsOnSmallSet() = detectClonesUsingAsts(|project://assignment2/data/small|, true);
void detectClonesUsingAstsOnLargeSet() = detectClonesUsingAsts(|project://assignment2/data/large|, false);

void detectClonesUsingAsts(loc dataDir, bool smallSet) {
  
	println("(1/5) Reading the files");
	map[loc,Declaration] asts = parseFiles(dataDir);
	
	println("Start time: <now()>");
	println("(2/5) Finding type1 clones");
    Clone type1Clones = collectType1Clones(asts);
    
	println("(3/5) Finding type2 clones");
	Clone type2Clones = collectType2Clones(asts, type1Clones);
	println("End time: <now()>");
  	
	println("(4/5) Evaluate clone duplication tool on type 1");
	evaluate(type1Clones + type2Clones, smallSet, type1());
	
	println("(5/5) Evaluate clone duplication tool on type 2");
	evaluate(type1Clones + type2Clones, smallSet, type2());
	
	println("Done.");
}