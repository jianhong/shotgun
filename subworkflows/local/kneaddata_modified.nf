//
// Repeat the kneaddata pipeline by nextflow
//

include { TRIMMOMATIC              } from '../../modules/local/trimmomatic'
include { SEQTK_SEQ                } from '../../modules/local/seqtk_seq'
include { UCSC_FASPLIT             } from '../../modules/local/ucsc_fasplit'
include { TRF_CLEAN                } from './trf_clean'
include { MERGE_FASTQ              } from '../../modules/local/merge_fastq'
include { BOWTIE2_ALIGN            } from '../../modules/nf-core/modules/bowtie2/align/main'

workflow KNEAD_DATA {
    take:
    reads               //tuple val(meta), path(reads)
    bowtie2_index       //path bowtie2_index
    trimmomatic_adaptor //path adapter

    main:
    ch_version = Channel.empty()
    /*
     * Trimmomatic (trim adapters, sliding window, MINLEN)
     */
    TRIMMOMATIC(reads, trimmomatic_adaptor)
    ch_version = ch_version.mix(TRIMMOMATIC.out.versions.ifEmpty(null))

    /*
     * Run bowtie2 to remove the host reads
     */
    BOWTIE2_ALIGN(TRIMMOMATIC.out.paired, bowtie2_index, true)
    ch_version = ch_version.mix(BOWTIE2_ALIGN.out.versions.ifEmpty(null))

    /*
     * TRF (Trimm repetitive sequences)
     */
    //First step, convert the fastq to fasta
    //In this step, PE reads will flatten into SE, once TRF is done, the convert back
    SEQTK_SEQ(BOWTIE2_ALIGN.out.fastq.transpose())
    ch_version = ch_version.mix(SEQTK_SEQ.out.versions.ifEmpty(null))
    //Break big file into smaller one, splitFasta
    UCSC_FASPLIT(SEQTK_SEQ.out.reads)
    ch_version = ch_version.mix(UCSC_FASPLIT.out.versions.ifEmpty(null))
    //Run trf
    TRF_CLEAN(UCSC_FASPLIT.out.reads.transpose())
    ch_version = ch_version.mix(TRF_CLEAN.out.versions.ifEmpty(null))
    //Filter the trf results
    ch_trf = TRF_CLEAN.out.clean_reads.groupTuple()
    MERGE_FASTQ(ch_trf)

    emit:
    reads = MERGE_FASTQ.out.reads             // channel: [ meta,  fasta ]
    versions = ch_version                     // channel: [ versions.yml ]
}
