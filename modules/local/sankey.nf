process SANKEY {
    label 'process_low'
    label 'error_ignore'

    conda (params.enable_conda ? "bioconda::r-htmlwidgets=0.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-htmlwidgets:0.5--r3.3.2_0' :
        'quay.io/biocontainers/r-htmlwidgets:0.5--r3.3.2_0' }"

    input:
    path reports

    output:
    path "${prefix}_sankey.html"                         , emit: summary
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "pvaian"
    """
    #!/usr/bin/env Rscript

    #######################################################################
    #######################################################################
    ## Created on March 10, 2022 use pavian to create sankey plots
    ## Copyright (c) 2021 Jianhong Ou (jianhong.ou@gmail.com)
    #######################################################################
    #######################################################################
    if(!require(pavian)) {
        if(!require(remotes)) { install.packages("remotes")}
        remotes::install_github("fbreitwieser/pavian")
    }
    versions <- c("${task.process}:")
    pkgs <- "pavian"
    for(pkg in pkgs){
        # load library
        library(pkg, character.only=TRUE)
        # parepare for versions.yml
        versions <- c(versions,
            paste0("    ", pkg, ": ", as.character(packageVersion(pkg))))
    }
    writeLines(versions, "versions.yml") # wirte versions.yml

    getNames <- function(n){
        x <- strsplit(n, "")
        maxN <- max(lengths(x))
        x <- lapply(x, function(.ele){
            rev(c(rep("_", maxN), .ele))[seq.int(maxN)]
        })
        x <- do.call(rbind, x)
        x <- apply(x, 2, unique, simply=FALSE)
        xl <- lengths(x)
        stopID <- which(xl>1)
        if(length(stopID)){
            stopID <- stopID[1]
            if(stopID>1){
                x <- x[seq.int(stopID-1)]
                x <- paste(rev(x), collapse="")
                n <- sub(x, "", n, fixed=TRUE)
            }
        }
        n
    }

    REPORTS <- strsplit("$reports", " ")[[1]]
    NAMES <- getNames(REPORTS)
    FILENAME <- "${prefix}_sankey.html"

    ## prepare data from out to data frame with colnames:
    ## "name","taxLineage","taxonReads", "cladeReads","depth", "taxRank"
    report <- pavian::read_reports(REPORTS, NAMES)
    merged_reports <- pavian::merge_reports2(reports, col_names = NAMES)
    network <- pavian::build_sankey_network(merged_reports)
    htmlwidgets::saveWidget(network, FILENAME)
    """
}
