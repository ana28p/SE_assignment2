module StringBasedCloneDetector

import DataTypes;
import steps::stringbased::FileReader;
import steps::stringbased::CloneDetection;
import NiCad5ResultReader;
import EvaluateResult;

import IO;
import Set;
import String;

void detectClonesUsingStringsOnSmallSet() = detectClonesUsingStrings(|project://assignment2/data/small|, true);
void detectClonesUsingStringsOnLargeSet() = detectClonesUsingStrings(|project://assignment2/data/large|, false);

void detectClonesUsingStrings(loc dataDir, bool smallSet) {
	bool evaluationOn = true;
	int minLines = 10;
	println("(1/9) Reading the files");
	MethodContent origMethods = readFiles(dataDir);
	println("(2/9) Rewriting the lines for type 1 clones");
	Clone type1Clones = detectClones(origMethods, minLines, false);
	println("(4/9) Rewriting the lines for type 2 clones");
	Clone type2Clones = detectClones(origMethods, minLines, true);
	println("(6/9) Filter duplicate occurrence clones");
	type2Clones = filterType2Clones(type1Clones, type2Clones);
	Clone allClones = type1Clones + type2Clones;
	//println("(7/9) Print all clones");
	//printClones(allClones);
	if (evaluationOn) {
		println("(8/9) Evaluate clone duplication tool on type 1");
		evaluate(allClones, smallSet, type1());
		println("(9/9) Evaluate clone duplication tool on type 2");
		evaluate(allClones, smallSet, type2());
	}
}

Clone filterType2Clones(Clone clones1, Clone clones2) {
	Clone filtered = {};
	for (<f2, g2, ct2, ls2> <- clones2) {
		bool include = true;
		for (<f1, g1, ct1, ls1> <- clones1) {
			if (f1.uri == f2.uri && f1.begin.line == f2.begin.line && g1.uri == g2.uri && g1.begin.line == g2.begin.line) {
				include = false;
				break;
			}
		} 
		if (include) {
			filtered += {<f2, g2, ct2, ls2>};
		}
	}
	return filtered;
}

void printClones(Clone allClones) {
	for (<f1, f2, ct, ls> <- allClones) {
		print(f1);
		print(" - ");
		print(f2);
		print(" - ");
		print(ct);
		print(" - ");
		print(ls);
		print("\n");
	}
}