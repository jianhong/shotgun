//
// Centrifuge
//

include { CENTRIFUGE_RUN            } from '../../modules/local/centrifuge'
include { KRONA as KRONA_CENTRIFUGE } from '../../modules/local/krona'

workflow CENTRIFUGE {
    take:
    reads               //tuple val(meta), path(reads)
    centrifuge_db       //path centrifuge_db

    main:
    //
    // MODULE: run Centrifuge for each sample
    //
    ch_versions = CENTRIFUGE_RUN(reads, centrifuge_db).versions

    //
    // MODULE: create centrifuge summary table
    //


    //
    // MODULE: create krona output
    //
    KRONA_CENTRIFUGE(CENTRIFUGE_RUN.out.kraken_like_report)

    emit:
    centrifuge = CENTRIFUGE_RUN.out.centrifuge_report// channel: [ summary ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
