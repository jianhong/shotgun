//
// Repeat the kneaddata pipeline by nextflow
//

include { KNEADDATA                   } from '../../modules/local/kneaddata'
include { KNEADDATA_COUNT             } from '../../modules/local/kneaddata_count'
include { KNEADDATA_MERGECOUNT        } from '../../modules/local/kneaddata_mergecount'

workflow KNEAD_DATA {
    take:
    reads               //tuple val(meta), path(reads)
    bowtie2_index       //path bowtie2_index

    main:
    //
    // MODULE: generate KneadData read for each sample
    //
    ch_versions =KNEADDATA(reads, bowtie2_index).versions

    //
    // MODULE: generate KneadData read count tables for each sample
    //
    KNEADDATA_COUNT(KNEADDATA.out.kneaddata)

    //
    // MODULE: Combine tsv files into a single KneadData read count table
    //
    KNEADDATA_MERGECOUNT(KNEADDATA_COUNT.out.counts.map{it[1]}.collect())

    emit:
    reads = KNEADDATA.out.reads                     // channel: [ meta,  fastq ]
    pairs = KNEADDATA.out.pairs                     // channel: [ meta, [fastq]]
    count = KNEADDATA_MERGECOUNT.out.counts         // channel: [ counts       ]
    versions = ch_versions                          // channel: [ versions.yml ]
}
