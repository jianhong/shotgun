//
// HUMAnN
//

include { HUMANN_RUN                  } from '../../modules/local/humann'
include { HUMANN_NORM as NORM_GENE    } from '../../modules/local/humann_normalize'
include { HUMANN_NORM as NORM_COVG    } from '../../modules/local/humann_normalize'
include { HUMANN_NORM as NORM_ABUN    } from '../../modules/local/humann_normalize'
include { HUMANN_JOIN as JOIN_GENE    } from '../../modules/local/humann_join'
include { HUMANN_JOIN as JOIN_COVG    } from '../../modules/local/humann_join'
include { HUMANN_JOIN as JOIN_ABUN    } from '../../modules/local/humann_join'
include { HUMANN_GROUP                } from '../../modules/local/humann_regroup'
include { HUMANN_BARPLOT as PLOT_GENE } from '../../modules/local/humann_barplot'
include { HUMANN_BARPLOT as PLOT_COVG } from '../../modules/local/humann_barplot'
include { HUMANN_BARPLOT as PLOT_ABUN } from '../../modules/local/humann_barplot'

workflow HUMANN {
    take:
    reads               //tuple val(meta), path(reads)
    humann_dna_db       // path humann_db
    humann_pro_db       // path humann_db

    main:
    //
    // MODULE: run HUMAnN for each sample
    //
    ch_versions = HUMANN_RUN(reads, humann_dna_db, humann_pro_db).versions

    //
    // MODULE: HUMAnN regroup
    //
    HUMANN_GROUP(HUMANN_RUN.out.genefamilies)

    //
    // MODULE: HUMAnN renormalize
    //
    NORM_GENE(HUMANN_GROUP.out.regroup)
    NORM_COVG(HUMANN_RUN.out.pathcoverage)
    NORM_ABUN(HUMANN_RUN.out.pathabundance)

    //
    // MODULE: HUMAnN renormalize
    //
    JOIN_GENE(NORM_GENE.out.norm.collect{it[1]}.map{[[id:"genefamilies"], it]})
    JOIN_COVG(NORM_COVG.out.norm.collect{it[1]}.map{[[id:"pathcoverage"], it]})
    JOIN_ABUN(NORM_ABUN.out.norm.collect{it[1]}.map{[[id:"pathabundance"], it]})

    //
    // MODULE: barplot
    //
    //PLOT_GENE(JOIN_GENE.out.table)
    //PLOT_COVG(JOIN_COVG.out.table)
    //PLOT_ABUN(JOIN_ABUN.out.table)

    emit:
    genefamilies = JOIN_GENE.out.table               // channel: [ table ]
    pathcoverage = JOIN_COVG.out.table               // channel: [ table ]
    pathabundance = JOIN_ABUN.out.table              // channel: [ table ]
    versions = ch_versions                           // channel: [ versions.yml ]
}
