//
// mOTUs2
//

include { MOTUS_RUN                 } from '../../modules/local/motus'
include { MOTUS_MERGE               } from '../../modules/local/motus_merge'
include { KRONA as KRONA_MOTUS      } from '../../modules/local/krona'

workflow MOTUS {
    take:
    reads               //tuple val(meta), path(reads)
    motus_db            //path motus_db

    main:
    //
    // MODULE: run mOTUs for each sample
    //
    ch_versions = MOTUS_RUN(reads, motus_db).versions

    //
    // MODULE: create krona output
    //
    KRONA_MOTUS(MOTUS_RUN.out.motus_out)

    //
    // MODULE: create mOTUs summary table
    //
    MOTUS_MERGE(MOTUS_RUN.out.motus_out.map{it[1]}.collect(), motus_db)

    emit:
    motus = MOTUS_MERGE.out.merged_out               // channel: [ summary ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
