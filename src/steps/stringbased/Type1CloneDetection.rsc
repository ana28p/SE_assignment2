module steps::stringbased::Type1CloneDetection

import DataTypes;
import steps::stringbased::FileReader;

import List;
import IO;
import String;

Clone type1CloneDetection(MethodContent origMethods, int minLines) {
	// Rewrite the lines such that Clone 1 lines are the same
	for (l <- origMethods) {
		origMethods[l] = removeSingleComment(origMethods[l]);
		origMethods[l] = removeBlockComment(origMethods[l]);
		origMethods[l] = removeSpace(origMethods[l]);
		origMethods[l] = removeEmptyLines(origMethods[l]);
	} 
	
	Clone clones = {};
	
	// Compare all methods
	for (l <- origMethods) {
		for (l2 <- origMethods) {
			if (l != l2) {
				clones += getClones(origMethods[l], origMethods[l2], minLines);
			}
		}
	}
	return clones;
}

Clone getClones(Content methods1, Content methods2, int minLines) {
	int lineSim = 0;
	map[tuple[int, int], int] matching = ();
	if (size(methods1) > 1 && size(methods2) > 0) {
		for (int i <- [0 .. (size(methods1) - 1) ]) {
			int j = size(methods2) - 1;
			if (methods1[i].line == methods2[j].line) {
				matching += (<i, j> : 1);
			}
			else {
				matching += (<i, j>: 0);
			}
		}
	}
	
	if (size(methods1) > 0 && size(methods2) > 1) {
		for (int j <- [0 .. (size(methods2) - 1)]) {
			int i = size(methods1) - 1;
			if (methods1[i].line == methods2[j].line) {
				matching += (<i, j> : 1);
			}
			else {
				matching += (<i, j>: 0);
			}
		}
	}
	
	if (size(methods1) > 1 && size(methods2) > 1) {
		for (int i <- reverse([0 .. (size(methods1) - 2)])) {
			for (int j <- reverse([0 .. (size(methods2) - 2)])) {
				if (methods1[i].line == methods2[j].line) {	
					matching += (<i, j> : 1  + matching[<i + 1, j + 1>]);
				}
				else {
					matching += (<i, j>: 0);
				}
			}
		}
	}
	
	int max_score = -1;
	loc loc1;
	loc loc2;
	if (size(methods1) > 0 && size(methods2) > 0) {
		for (int i <- [0 .. (size(methods1) - 1)]) {
			for (int j <- [0 .. (size(methods2) - 1)]) {
				int score = matching[<i, j>];
				if (score > max_score) {
					max_score = score;
					loc1 = methods1[i].nr;
					loc2 = methods2[i].nr;
				}
			}
		}
	}
	
	if (max_score < minLines) {
		return {};
	}
	else {
		return {<loc1, loc2, type1(), max_score>};
	}
}

Content removeSingleComment(Content fileMethods) {
	Content filtered = [];
	for (<nr, line> <- fileMethods) {
		int index = findFirst(line, "//");
		if (index != -1) {
			line = line[..index];
		}
		filtered += [<nr, line>]; 
	}
	return filtered;
}

Content removeBlockComment(Content fileMethods) {
	Content filtered = [];
	bool inBlock = false;
	for (<nr, line> <- fileMethods) {
		if (inBlock) {
			int index = findFirst(line, "/*");
			if (index == -1) {
				filtered += [<nr, line>]; 
			}
			else {
				inBlock = true;
				line = line[..index];
				filtered += [<nr, line>]; 
			}
		}
		else {
			int index = findFirst(line, "*/");
			if (index != -1) {
				inBlock = false;
				index += 2;
				line = line[index..];
				filtered += [<nr, line>];
			}
		}
	}
	return filtered;
}

Content removeSpace(Content fileMethods) {
	Content filtered = [];
	for (<nr, line> <- fileMethods) {
		line = replaceAll(line, " ", "");
		filtered += [<nr, line>]; 
	}
	return filtered;
}

Content removeEmptyLines(Content fileMethods) {
	Content filtered = [];
	for (<nr, line> <- fileMethods) {
		if (size(line) > 0) {
			filtered += [<nr, line>];
		} 
	}
	return filtered;
}