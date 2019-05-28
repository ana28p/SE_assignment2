module NiCad5ResultReader

import IO;
import lang::csv::IO;

import DataTypes;

Clone readNiCad5ResultForSmallSet() = readCSV(#Clone, |project://assignment2/data/sample_small.csv|);
Clone readNiCad5ResultForLargeSet() = readCSV(#Clone, |project://assignment2/data/sample_large.csv|);

Clone readNiCad5UniqueResultForSmallSet() = readCSV(#Clone, |project://assignment2/data/sample_small_unique.csv|);
Clone readNiCad5UniqueResultForLargeSet() = readCSV(#Clone, |project://assignment2/data/sample_large_unique.csv|);

void removeAllDuplicates() {
	removeDuplicates(readNiCad5ResultForSmallSet(), |project://assignment2/data/sample_small_unique.csv|);
	removeDuplicates(readNiCad5ResultForLargeSet(), |project://assignment2/data/sample_large_unique.csv|);
}

void removeDuplicates(Clone clones, loc location) {
	Clone newList = {}; 

	for(<fragment1, fragment2, cloneType, lineSimilarity> <- clones) {
		if (<fragment2, fragment1, cloneType, lineSimilarity> notin newList) {
			newList += <fragment1, fragment2, cloneType, lineSimilarity>;
		}
	}
	
	writeCSV(newList, location);
}