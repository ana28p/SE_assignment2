module EvaluateResult

import DataTypes;
import NiCad5ResultReader;

import IO;
import Set;
import String;

void evaluate(Clone clones, bool smallSet, CloneType ct) {
	if (smallSet) {
		//evaluate(clones, readNiCad5ResultForSmallSet(), ct);
		evaluate(clones, readNiCad5UniqueResultForSmallSet(), ct);
	} else {
		//evaluate(clones, readNiCad5ResultForLargeSet(), ct);
		evaluate(clones, readNiCad5UniqueResultForLargeSet(), ct);
	}
}

void evaluate(Clone clones, Clone realClones, CloneType ct) {
	real type1Classified = 0.0;
	real type2Classified = 0.0;
	real type3Classified = 0.0;
	real noClone = 0.0;
	for (<f1, g1, ct1, ls1> <- clones) {
		if (ct1 == ct) {
			bool contained = false;
			for (<f2, g2, ct2, ls2> <- realClones) {
				if ((f1 == f2 && g1 == g2) || (f1 == g2 && g1 == f2)) {
						switch (ct2) {
							case type1(): type1Classified += 1.0;
							case type2(): type2Classified += 1.0;
							case type3(): {
								type3Classified += 1.0; 
								//println("type3: <f1>, <g1>, <ct1>, <ls1>");
								}
						}
						contained = true;
						break;
				}
			}
			if (!contained) {
				noClone += 1.0;
				//println("incorrect (noClone): <f1>, <g1>, <ct1>, <ls1>");
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
			for (<f1, g1, ct1, ls1> <- clones) {
				if ((f1 == f2 && g1 == g2) || (f1 == g2 && g1 == f2)) {
					contained = true;
					if (ct1 != ct) {
						otherClones += 1.0;
					}
					break;
				}
			}
			if (!contained) {
				numMisses += 1.0;
				//println("missed: <f2>, <g2>, <ct2>, <ls2>");
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