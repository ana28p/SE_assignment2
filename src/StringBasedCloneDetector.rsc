module StringBasedCloneDetector

import DataTypes;
import steps::stringbased::FileReader;
import steps::stringbased::CloneDetection;
import NiCad5ResultReader;

import IO;
import Set;
import String;

void detectClonesUsingStringsOnSmallSet() = detectClonesUsingStrings(|project://SE_Assignment2/data/small|, true);
void detectClonesUsingStringsOnLargeSet() = detectClonesUsingStrings(|project://SE_Assignment2/data/large|, false);

void detectClonesUsingStrings(loc dataDir, bool smallSet) {
	minLines = 10;
	println("(1/9) Reading the files");
	MethodContent origMethods = readFiles(dataDir);
	println("(2/9) Rewriting the lines for type 1 clones");
	Clone type1Clones = detectClones(origMethods, minLines, false);
	println("(4/9) Rewriting the lines for type 2 clones");
	Clone type2Clones = detectClones(origMethods, minLines, true);
	println("(6/9) Filter duplicate occurrence clones");
	type1Clones = filterType1Clones(type1Clones, type2Clones);
	type2Clones = filterType2Clones(type1Clones, type2Clones);
	Clone allClones = type1Clones + type2Clones;
	println("(7/9) Print all clones");
	printClones(allClones);
	println("(8/9) Evaluate clone duplication tool on type 1");
	evaluate(allClones, smallSet, type1());
	println("(9/9) Evaluate clone duplication tool on type 2");
	evaluate(allClones, smallSet, type2());
}


Clone filterType1Clones(Clone clones1, Clone clones2) {
	Clone filtered = {};
	for (<f1, g1, ct1, ls1> <- clones1) {
		bool include = true;
		for (<f2, g2, ct2, ls2> <- clones2) {
			if (f1.uri == f2.uri && f1.begin.line >= f2.begin.line && f1.begin.line + ls1 <= f2.begin.line + ls2 && ls2 > ls1) {
				include = false;
				break;
			}
		} 
		if (include) {
			filtered += {<f1, g1, ct1, ls1>};
		}
	}
	return filtered;
}

Clone filterType2Clones(Clone clones1, Clone clones2) {
	Clone filtered = {};
	for (<f2, g2, ct2, ls2> <- clones2) {
		bool include = true;
		for (<f1, g1, ct1, ls1> <- clones1) {
			if (f1.uri == f2.uri && f1.begin.line <= f2.begin.line && f1.begin.line + ls1 >= f2.begin.line + ls2 && ls2 <= ls1) {
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

void evaluate(Clone allClones, bool smallSet, CloneType ct) {
	Clone realClones = {};
	if (smallSet) {
		realClones = readNiCad5ResultForSmallSet();
	}
	else {
		realClones = readNiCad5ResultForLargeSet();
	}
	
	real numPrecision = 0.0;
	real numAllClones = 0.0;
	for (<f1, g1, ct1, ls1> <- allClones) {
		if (ct1 == ct) {
			numAllClones += 1.0;
			bool contained = false;
			for (<f2, g2, ct2, ls2> <- realClones) {
				f1name = split("/", f1.uri)[-1];
				g1name = split("/", g1.uri)[-1];
				f2name = split("/", f2.uri)[-1];
				g2name = split("/", g2.uri)[-1];
				if ((ct2 == ct || ct2 == type3()) && f1name == f2name && collide(f1.begin.line, f2.begin.line, ls1, ls2)
					&& g1name == g2name && collide(g1.begin.line, g2.begin.line, ls1, ls2)) {
						contained = true;
						break;
				}
				if ((ct2 == ct || ct2 == type3()) && f1name == g2name && collide(f1.begin.line, g2.begin.line, ls1, ls2)
					&& g1name == f2name && collide(g1.begin.line, f2.begin.line, ls1, ls2)) {
						contained = true;
						break;
				}
			}
			if (contained) {
				numPrecision += 1.0;
			}
		}
	}
	
	real precision = numPrecision / numAllClones;
	
	real numRecall = 0.0;
	numAllClones = 0.0;
	for (<f2, g2, ct2, ls2> <- realClones) {
		if (ct2 == ct) {
			numAllClones += 1.0;
			bool contained = false;
			for (<f1, g1, ct1, ls1> <- allClones) {
				f1name = split("/", f1.uri)[-1];
				g1name = split("/", g1.uri)[-1];
				f2name = split("/", f2.uri)[-1];
				g2name = split("/", g2.uri)[-1];
				if (ct1 == ct && f1name == f2name && collide(f1.begin.line, f2.begin.line, ls1, ls2)
					&& g1name == g2name && collide(g1.begin.line, g2.begin.line, ls1, ls2)) {
					contained = true;
				}
				if (ct1 == ct && f1name == g2name && collide(f1.begin.line, g2.begin.line, ls1, ls2)
					&& g1name == f2name && collide(g1.begin.line, f2.begin.line, ls1, ls2)) {
					contained = true;
				}
			}
			if (contained) {
				numRecall += 1.0;
			}
		}
	}
	
	real recall = numRecall / numAllClones;
	real fmeasure = 2 * (precision * recall) / (precision + recall);
	print("Precision: ");
	print(precision);
	print("\n");
	print("Recall: ");
	print(recall);
	print("\n");
	print("F-Measure: ");
	print(fmeasure);
	print("\n");
}

bool collide(int bl1, int bl2, int ls1, int ls2) {
	return (bl1 <= bl2 && bl1 + ls1 >= bl2) || (bl2 <= bl1 && bl2 + ls2 >= bl1);
}