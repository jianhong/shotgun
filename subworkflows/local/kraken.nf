//
// Kraken2
//

include { KRAKEN2_RUN                 } from '../../modules/local/kraken'
include { KRAKEN2_MERGE               } from '../../modules/local/kraken_mergecount'
include { BRACKEN_INSTALL             } from '../../modules/local/brachen_install_database'
include { BRACKEN                     } from '../../modules/local/bracken'
include { KRONA as KRONA_KRAKEN2      } from '../../modules/local/krona'
include { KRONA as KRONA_KRAKEN2_ALL  } from '../../modules/local/krona'
include { SANKEY as SANKEY_KRAKEN2    } from '../../modules/local/sankey'

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

    //
    // MODULE: Abundance estimation
    //
    BRACKEN_INSTALL(KRAKEN2_RUN.out.kraken2_rep.first(), kraken2_db)
    BRACKEN(KRAKEN2_RUN.out.kraken2_rep.combine(BRACKEN_INSTALL.out.kmer_distrib), kraken2_db)
    ch_versions = ch_versions.mix(BRACKEN.out.versions.ifEmpty(null))

    //
    // MODULE: create krona output
    //
    KRONA_KRAKEN2(KRAKEN2_RUN.out.kraken2_rep)
    ch_versions = ch_versions.mix(KRONA_KRAKEN2.out.versions.ifEmpty(null))
    KRONA_KRAKEN2_ALL(KRAKEN2_RUN.out.kraken2_rep
                                .map{it[1]}
                                .collect()
                                .map{[[id: "KRAKEN2_KRONA"], it]})

    //
    // MODULE: create sankey plot output
    //
    SANKEY_KRAKEN2(KRAKEN2_RUN.out.kraken2_rep.map{it[1]}.collect())
    ch_versions = ch_versions.mix(SANKEY_KRAKEN2.out.versions.ifEmpty(null))

    emit:
    kraken2 = KRAKEN2_MERGE.out.kraken2_mpa          // channel: [ summary ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
