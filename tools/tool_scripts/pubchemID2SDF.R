#!/usr/bin/env Rscript
# requires: ChemmineR,R.utils,ctc,rjson,RPostgreSQL
# use: ./pubchemID2SDF.R --outfile=output.sdf  < idfile

library(ChemmineR)
library(R.utils)
library(RPostgreSQL)

conn = dbConnect(dbDriver("PostgreSQL"),dbname="pubchem",host="chemminetools-2.bioinfo.ucr.edu",user="pubchem_updater",password="48ruvbvnmwejf408rfdj")

if(! exists("debug_mode")){
	# parse command line arguments
	args = commandArgs(asValues=TRUE)
	outfile    = args$outfile

	f <- file("stdin")
	open(f)
	pubchemIds = read.table(f)[[1]]
	close(f)

}


#print("ids: ")
#print(pubchemIds)
#print(paste(pubchemIds,collapse=","))

# look in database for PubChem ids
compoundIds = findCompoundsByName(conn,pubchemIds,keepOrder=TRUE,allowMissing=TRUE)

# if any don't exist, grab them via the internet (pubchem soap)
missingIds <- pubchemIds[is.na(compoundIds)]
result <- SDFset()
if(length(missingIds) > 0){
    idstring <- paste(missingIds, collapse="\n")
    missingSDF <- system("/srv/chemminetools/pubchem_soap_interface/DownloadCIDs_standalone.py",
           intern = TRUE,
           input = idstring)
    result <- read.SDFset(read.SDFstr(missingSDF))
    if(length(result) != length(missingIds)){
        stop()
    }
}

# get SDFs in database
if(length(compoundIds[! is.na(compoundIds)]) > 0){
    dbCompounds <- getCompounds(conn,compoundIds[! is.na(compoundIds)],keepOrder=TRUE)
    result <- append(result, dbCompounds)
}

# reorder result properly
if((length(missingIds) > 0) && (length(compoundIds[! is.na(compoundIds)]) > 0)){
    index <- insert((length(missingIds) + 1):length(result),
           which(is.na(compoundIds)),
           values=1:length(missingIds))
    result <- result[index]
}

# save result
write.SDF(result, outfile)
