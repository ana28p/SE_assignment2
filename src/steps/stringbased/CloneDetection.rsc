module steps::stringbased::CloneDetection

import DataTypes;
import steps::stringbased::FileReader;

import List;
import IO;
import String;
import Set;
import util::Math;

Clone detectClones(MethodContent origMethods, int minLines, bool type2) {
	// Rewrite the lines such that Clone 1 lines are the same
	for (l <- origMethods) {
		origMethods[l] = removeSingleComment(origMethods[l]);
		origMethods[l] = removeBlockComment(origMethods[l]);
		origMethods[l] = removeSpChars(origMethods[l]);
		origMethods[l] = removeEmptyLines(origMethods[l]);	
		if (type2) {
			origMethods[l] = typeTransform(origMethods[l]);	
		}
		//origMethods[l] = removeSpace(origMethods[l]);
	}
	if (type2) {
		println("(5/9) Detect type 2 clones");
	}
	else {
		println("(3/9) Detect type 1 clones");
	}
	map[loc, set[loc]] correspond = filterCloneMethods(origMethods, minLines);
	Clone clones = {};

	// Compare all methods
	for (l <- correspond) {
		for (l2 <- correspond[l]) {
			occurs1 = occuringLines(origMethods[l]);
			occurs2 = occuringLines(origMethods[l2]);
			if (l != l2 && (size(occurs1 & occurs2) >= minLines || type2)) {
				clones += getClones(origMethods[l], origMethods[l2], minLines, type2);
			}
		}
	}
	return clones;
}

set[str] occuringLines(Content fileMethods) {
	set[str] occurs = {};
	for (<nr, line> <- fileMethods) {
		occurs += {line};
	}
	return occurs;
}

map[loc, set[loc]] filterCloneMethods(MethodContent origMethods, int minLines) {
	real max_occur_threshold = 5.0;
	real minimum_threshold = 5.0;
	int size = 0;
	set[loc] filtered = {};
	map[str, int] lineOccur = ();
	map[str, set[loc]] lineInMethod = ();
	map[loc, set[loc]] result = ();
	for (l <- origMethods) {
		size += 1;
		for (<nr, line> <- origMethods[l]) {
			if (line in lineOccur) {
				lineInMethod[line] = lineInMethod[line] + {l};
				lineOccur[line] = lineOccur[line] + 1;
			}
			else {
				lineInMethod[line] = {l};
				lineOccur[line] = 1;
			}
		}
	}
	for (l <- origMethods) {
		int duplicateCount = 0;
		for (<nr, line> <- origMethods[l]) {
			if (lineOccur[line] >= 2) {
				duplicateCount += 1;
			} 
		}
		if (duplicateCount >= minLines) {
			filtered += {l};
		}
	}
	for (l <- filtered) {
		set[loc] others = {};
		for (<nr, line> <- origMethods[l]) {
			others += lineInMethod[line];
		}
		result[l] = others & filtered;
	}
	return result;
}

Clone getClones(Content methods1, Content methods2, int minLines, bool isType2) {
	int lineSim = 0;
	map[tuple[int, int], int] matching = ();
	if (size(methods1) > 1 && size(methods2) > 0) {
		for (int i <- [0 .. (size(methods1)) ]) {
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
		for (int j <- [0 .. (size(methods2))]) {
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
		for (int i <- reverse([0 .. (size(methods1) - 1)])) {
			for (int j <- reverse([0 .. (size(methods2) - 1)])) {
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
					loc2 = methods2[j].nr;
				}
			}
		}
	}
	
	if (max_score < minLines) {
		return {};
	}
	else {
		if (isType2) {
			return {<loc1, loc2, type2(), max_score>};
		}
		else {
			return {<loc1, loc2, type1(), max_score>};
		}
	}
}

Content typeTransform(Content fileMethods) {
	int word_threshold = 3;
	Content filtered = [];
	Content filtered2 = [];
	map[str, int] occurs = ();
	map[str, str] replacing = ("" : "", "{": "{", "}": "}");
	int counter = 0;
	for (<nr, line> <- fileMethods) {
		line = escape(line, ("!": "", "\"": "", "#": "", "$": "", "%": "", "&": "", "\'": "", "(": "", ")": "", 
			"*": "", "+": "", ",": "", "-": "", ".": "", "/": "", ":": "", ";": "", "\<": "", "=": "", "\>": "",
			"?": "", "@": "", "[": "", "\\": "", "]": "", "^": "", "_": "", "|": "", "~": ""));
		list[str] words = split(" ", line);
		for (str w <- words) {
			if (w in occurs) {
				occurs[w] = occurs[w] + 1;
			}
			else {
				occurs[w] = 1;
			}
		}
		filtered += [<nr, line>];
	}
	
	for (<nr, line> <- filtered) {
		list[str] words = split(" ", line);
		for	(int i <- [0 .. size(words)]) {
			if (words[i] notin replacing) {
				if (occurs[words[i]] >= word_threshold) {
					replacing[words[i]] = "w" + toString(counter);
					counter += 1;
				}
				else {
					replacing[words[i]] = "";
				}
			}
			words[i] = replacing[words[i]];
		}
		line = "";
		for (str w <- words) {
			line += w;
		}
		filtered2 += [<nr, line>];
	}
	return filtered2;
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
			int index = findFirst(line, "*/");
			if (index != -1) {
				inBlock = false;
			}
		}
		else {
			int index = findFirst(line, "/*");
			if (index == -1) {
				filtered += [<nr, line>]; 
			}
			else {
				if (!contains(line, "*/")) {
					inBlock = true;
				}
				line = line[..index];
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

Content removeSpChars(Content fileMethods) {
	Content filtered = [];
	for (<nr, line> <- fileMethods) {
		line = replaceAll(line, "\t", "");
		line = replaceAll(line, "\r", "");
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