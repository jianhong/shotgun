//
// Repeat the kneaddata pipeline by nextflow
//

include { KRAKEN2_RUN                 } from '../../modules/local/kraken'
include { KRAKEN2_MERGE               } from '../../modules/local/kraken_mergecount'

workflow KRAKEN2 {
    take:
    reads               //tuple val(meta), path(reads)
    kraken2_db          //path kraken2_db
    kreport2mpa         //path kreport2mpa
    combine_mpa         //path combine_mpa

    main:
    //
    // MODULE: run kraken2 for each sample
    //
    ch_versions = KRAKEN2_RUN(reads, kraken2_db, kreport2mpa).versions

    //
    // MODULE: create kraken2 summary table
    //
    KRAKEN2_MERGE(KRAKEN2_RUN.out.kraken2_mpa.map{it[1]}.collect(), combine_mpa)

    emit:
    kraken2 = KRAKEN2_MERGE.out.kraken2_mpa          // channel: [ summary ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
