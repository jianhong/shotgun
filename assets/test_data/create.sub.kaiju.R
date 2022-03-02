all <- readLines("viruses/source/all.gbff")
locus <- grepl("^LOCUS", all)
sum(locus)
length(all)
grp <- cumsum(as.numeric(locus))
head(grp)
all.s <- split(all, grp)
organism <- all[grepl("ORGANISM", all)]
length(organism)
length(all.s)
head(names(all.s))
names(all.s)[1000]
names(all.s)[10000]
names(all.s)[100000]
all(names(all.s)==as.character(seq_along(all.s)))
length(all.s)==length(organism)
head(organism)
organism <- sub("^.*ORGANISM\\s+", "", organism)
head(organism)
names.dmp <- readLines("names.dmp")
head(names.dmp)
names.dmp <- read.delim("names.dmp")
head(names.dmp)
names.dmp <- read.delim("names.dmp", header=FALSE)
tail(names.dmp)
nrow(names.dmp)
3561369 - 1704910
names.dmp <- readLines("names.dmp")
n.d <- sub("^\\d+\\t\\|\\t(.*?)\\t.*$", "\\1", names.dmp)
head(n.d)
length(intersect(n.d, organism)
)
keep <- intersect(n.d, organism)
head(keep)
sum(grepl("sars", keep, ignore.case=TRUE))
keep[grepl("sars", keep, ignore.case=TRUE)]
sel <- c(which(grepl("sars", keep, ignore.case=TRUE)), sample(seq_along(keep), 1000))
sel <- sort(sel)
keep.s <- keep[seql]
keep.s <- keep[sel]
keep.s
keep.s <- unique(keep.s)
length(keep.s)
nodes.dmp <- readLines("nodes.dmp")
head(nodes.dmp)
ls()
nodes.name <- sub("^\\d+\\t\\|\\t(.*?)\\t.*$", "\\1", nodes.dmp)
nodes.name1 <- sub("\\t.*$", "", nodes.dmp)
head(nodes.name1)
names.id <- sub("\\t.*$", "", names.dmp)
all(nodes.name1 %in% names.id)
all(nodes.name %in% names.id)
names.dmp[names.id=="131567"]
nodes.dmp[nodes.name1 %in% c(1:7, 10239)]
nodes.dmp[nodes.name %in% c(1:7, 10239)]
names.dmp[names.id=="2842242"]
ls()
keep_ids <- c(1:7, 10239)
head(n.d)
length(n.d)
length(names.dmp)
keep_ids <- c(keep_ids, nodes.name1[nodes.name %in% c(1:7, 10239)], names.id[n.d %in% keep.s])
keep_ids <- sort(unique(keep_ids))
head(keep_ids)
length(keep_ids)
keep_ids <- keep_ids[order(as.numeric(keep_ids))]
head(keep_ids)
writeLines(names.dmp[names.id %in% keep_ids], "names.sub.dmp")
writeLines(nodes.dmp[nodes.name1 %in% keep_ids & nodes.name %in% keep_ids], "nodes.sub.dmp")
ls()
all.sel <- all.s[organism %in% keep.s]
length(all.sel)
length(keep.s)
head(all.sel[[1]])
all.sel <- unlist(all.sel)
length(all.sel)
writeLines(all.sel, "viral.sub.gbff")
savehistory("create.sub.kaiju.R")
system("
kaiju-gbk2faa.pl viral.sub.gbff viral.sub.faa
DB=sub
mkdir sub
mkdir sub/source
mv viral.sub.* sub/source
ls sub/source
find $DB/source -name '*.faa' -print0 | xargs -0 cat | perl -lsne 'BEGIN{open(F,$m);while(<F>){@F=split(/[\|\s]+/);$h{$F[0]}=$F[1]}}if(/(>.+)_(\d+)/){print $1,"_",defined($h{$2})?$h{$2}:$2;}else{print}' -- -m=merged.dmp  > $DB/kaiju_db_$DB.faa\n
threadsBWT=5
parallelDL=5
parallelConversions=5
exponentSA=3
exponentSA_NR=5
DL=1
index_only=0
kaiju-mkbwt -n $threadsBWT -e $exponentSA -a ACDEFGHIKLMNPQRSTVWY -o $DB/kaiju_db_$DB $DB/kaiju_db_$DB.faa
kaiju-mkfmi $DB/kaiju_db_$DB

")
