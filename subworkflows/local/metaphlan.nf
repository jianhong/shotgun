//
// MetaPhlAn
//

include { METAPHLAN_RUN               } from '../../modules/local/metaphlan'
include { METAPHLAN_MERGE             } from '../../modules/local/metaphlan_mergecount'

workflow METAPHLAN {
    take:
    reads               //tuple val(meta), path(reads)
    metaphlan_db        //path metaphlan_db

    main:
    //
    // MODULE: generate metaphlan3 read count tables for each sample
    //
    ch_versions = METAPHLAN_RUN(reads, metaphlan_db).versions

    //
    // MODULE: Combine metaphlan3 read count table
    //
    METAPHLAN_MERGE(METAPHLAN_RUN.out.counts.map{it[1]}.collect())

    emit:
    metaphlan = METAPHLAN_MERGE.out.metaphlan        // channel: [ metaphlan ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
