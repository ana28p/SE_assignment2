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
			origMethods[l] = removeSpace(origMethods[l]);
		}
	}
	
	if (type2) {
		println("(5/9) Detect type 2 clones");
	}
	else {
		println("(3/9) Detect type 1 clones");
	}
	map[loc, str] mergedLines = getMergedLines(origMethods, type2);
	map[loc, int] sizes = getSizes(origMethods);
	return getClones(mergedLines, sizes, minLines, origMethods, type2);
}

Clone getClones(map[loc, str] mergedLines, map[loc, int] sizes, int minLines, MethodContent origMethods, bool isType2) {
	map[str, set[loc]] locMap = ();
	Clone clones = {};
	for (l <- mergedLines) {
		line = mergedLines[l];
		if (line in locMap) {
			locMap[line] = locMap[line] + {l};
		}
		else {
			locMap[line] = {l};
		}
	}
	
	for (l <- mergedLines) {
		line = mergedLines[l];
		for (l2 <- locMap[line], l != l2) {
			minSize = min(sizes[l], sizes[l2]);
			if (minSize >= minLines) {
				if (isType2) {
					clones += {<l, l2, type2(), minSize>};
				}
				else {
					clones += {<l, l2, type1(), minSize>};
				}
			}
		}
	}
	return clones;
}

map[loc, int] getSizes(MethodContent origMethods) {
	map[loc, int] sizes = ();
	for (l <- origMethods) {
		int size = 0;
		for (<nr, line> <- origMethods[l]) {
			size += 1;
		}
		sizes[l] = size;
	}
	return sizes;
}

map[loc, str] getMergedLines(MethodContent origMethods, bool isType2) {
	map[loc, str] mergedLines = ();
	for (l <- origMethods) {
		str merged = "";
		for (<nr, line> <- origMethods[l]) {
			merged += line;
			if (isType2) {
				merged += "-";
			}
		}
		mergedLines[l] = merged;
	}
	return mergedLines;
}

Content typeTransform(Content fileMethods) {
	Content filtered = [];
	Content filtered2 = [];
	map[str, str] replacing = ("" : "", "{": "{", "}": "}");
	int counter = 0;
	for (<nr, line> <- fileMethods) {
		line = escape(line, ("!": " ", "\"": " ", "#": " ", "$": " ", "%": " ", "&": " ", "\'": " ", "(": " ", ")": " ", 
			"*": " ", "+": " ", ",": " ", "-": " ", ".": " ", "/": " ", ":": " ", ";": " ", "\<": " ", "=": " ", "\>": " ",
			"?": " ", "@": " ", "[": " ", "\\": " ", "]": " ", "^": " ", "_": " ", "|": " ", "~": " ", "{": " ", "}": " "));
		list[str] words = split(" ", line);
		filtered += [<nr, line>];
	}
	
	for (<nr, line> <- filtered) {
		list[str] words = split(" ", line);
		for	(int i <- [0 .. size(words)]) {
			if (words[i] notin replacing) {
				replacing[words[i]] = "w" + toString(counter);
				counter += 1;
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
		emptyLine = replaceAll(line, " ", "");
		if (size(emptyLine) > 0) {
			filtered += [<nr, line>];
		}
	}
	return filtered;
}