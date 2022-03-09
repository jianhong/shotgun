//
// Kaiju
//

include { KAIJU_RUN                   } from '../../modules/local/kaiju'
include { KAIJU2TABLE                 } from '../../modules/local/kaiju2table'
include { KRONA as KRONA_KAIJU        } from '../../modules/local/krona'

workflow KAIJU {
    take:
    reads               //tuple val(meta), path(reads)
    kaiju_db            //path kaiju_db

    main:
    //
    // MODULE: run kaiju for each sample
    //
    ch_versions = KAIJU_RUN(reads, kaiju_db).versions

    //
    // MODULE: krona html output
    //
    KRONA_KAIJU(KAIJU_RUN.out.krona_input)
    ch_versions = ch_versions.mix(KRONA_KAIJU.out.versions.ifEmpty(null))

    //
    // MODULE: create kaiju summary table
    //
    KAIJU2TABLE(KAIJU_RUN.out.kaiju_out.map{it[1]}.collect(), kaiju_db)

    emit:
    kaiju = KAIJU2TABLE.out.summary                  // channel: [ summary ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
