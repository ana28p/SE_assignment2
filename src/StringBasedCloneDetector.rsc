module StringBasedCloneDetector

import DataTypes;
import steps::stringbased::FileReader;
import steps::stringbased::Type1CloneDetection;

import IO;

void detectClonesUsingStringsOnSmallSet() = detectClonesUsingStrings(|project://SE_Assignment2/data/small|);
void detectClonesUsingStringsOnLargeSet() = detectClonesUsingStrings(|project://SE_Assignment2/data/large|);

void detectClonesUsingStrings(loc dataDir) {
	minLines = 10;
	MethodContent origMethods = readFiles(dataDir);
	Clone allClones = type1CloneDetection(origMethods, minLines);
}

