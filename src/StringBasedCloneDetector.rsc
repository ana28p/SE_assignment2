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
	println("(7/9) Print all clones");
	printClones(allClones);
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

void evaluate(Clone allClones, bool smallSet, CloneType ct) {
	Clone realClones = {};
	if (smallSet) {
		realClones = readNiCad5ResultForSmallSet();
	}
	else {
		realClones = readNiCad5ResultForLargeSet();
	}
	
	real type1Classified = 0.0;
	real type2Classified = 0.0;
	real type3Classified = 0.0;
	real noClone = 0.0;
	for (<f1, g1, ct1, ls1> <- allClones) {
		if (ct1 == ct) {
			bool contained = false;
			for (<f2, g2, ct2, ls2> <- realClones) {
				f1name = split("/", f1.uri)[-1];
				g1name = split("/", g1.uri)[-1];
				f2name = split("/", f2.uri)[-1];
				g2name = split("/", g2.uri)[-1];
				if (f1name == f2name && f1.begin.line == f2.begin.line
					&& g1name == g2name && g1.begin.line == g2.begin.line) {
						switch (ct2) {
							case type1(): type1Classified += 1.0;
							case type2(): type2Classified += 1.0;
							case type3(): type3Classified += 1.0;
						}
						contained = true;
						break;
				}
				if (f1name == g2name && f1.begin.line == g2.begin.line
					&& g1name == f2name && g1.begin.line == f2.begin.line) {
						switch (ct2) {
							case type1(): type1Classified += 1.0;
							case type2(): type2Classified += 1.0;
							case type3(): type3Classified += 1.0;
						}
						contained = true;
						break;
				}
			}
			if (!contained) {
				noClone += 1.0;
			}
		}
	}
	
	real precision = 0.0;
	if (ct == type1()) {
		precision = type1Classified / (type1Classified + type2Classified + type3Classified + noClone);
	}
	else {
		precision = type2Classified / (type1Classified + type2Classified + type3Classified + noClone);
	}
	
	real numMisses = 0.0;
	real otherClones = 0.0;
	for (<f2, g2, ct2, ls2> <- realClones) {
		if (ct2 == ct) {
			bool contained = false;
			for (<f1, g1, ct1, ls1> <- allClones) {
				f1name = split("/", f1.uri)[-1];
				g1name = split("/", g1.uri)[-1];
				f2name = split("/", f2.uri)[-1];
				g2name = split("/", g2.uri)[-1];
				if (f1name == f2name && f1.begin.line == f2.begin.line
					&& g1name == g2name && g1.begin.line == g2.begin.line) {
					contained = true;
					if (ct1 != ct) {
						otherClones += 1.0;
					}
					break;
				}
				if (f1name == g2name && f1.begin.line == g2.begin.line
					&& g1name == f2name && g1.begin.line == f2.begin.line) {
					contained = true;
					if (ct1 != ct) {
						otherClones += 1.0;
					}
					break;
				}
			}
			if (!contained) {
				numMisses += 1.0;
			}
		}
	}
	
	real recall = 0.0;
	if (ct == type1()) {
		recall = type1Classified / (type1Classified + otherClones + numMisses);
	}
	else {
		recall = type2Classified / (type2Classified + otherClones + numMisses);
	}
	real fmeasure = 2 * (precision * recall) / (precision + recall);
	// Are placed under each other in the columns
	print("Type 1 classified: ");
	print(type1Classified);
	print("\n");
	print("Type 2 classified: ");
	print(type2Classified);
	print("\n");
	print("Type 3 classified: ");
	print(type3Classified);
	print("\n");
	// Belong to the lower row
	print("No Clones: ");
	print(noClone);
	print("\n");
	// Belong to the right column
	print("Misses: "); 
	print(numMisses);
	print("\n");
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