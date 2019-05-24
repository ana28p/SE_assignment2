module NiCad5ResultReader

import IO;
import lang::csv::IO;

import DataTypes;

Clone readNiCad5ResultForSmallSet() = readCSV(#Clone, |project://SE_Assignment2/data/sample_small.csv|);
Clone readNiCad5ResultForLargeSet() = readCSV(#Clone, |project://SE_Assignment2/data/sample_large.csv|);