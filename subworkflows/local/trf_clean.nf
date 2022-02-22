//
// clean reads by trf
//

include { TRF                      } from '../../modules/local/trf'
include { SEQTK_SUBSEQ             } from '../../modules/nf-core/modules/seqtk/subseq/main'

workflow TRF_CLEAN {
    take:
    reads               //tuple val(meta), path(reads)

    main:
    ch_version = Channel.empty()
    //Run trf
    TRF(reads)
    ch_version = ch_version.mix(TRF.out.versions.ifEmpty(null))
    //Filter the trf results
    ch_reads = reads.join(TRF.out.clean_name)
    //ch_reads.view()
    SEQTK_SUBSEQ(ch_reads)
    ch_version = ch_version.mix(SEQTK_SUBSEQ.out.versions.ifEmpty(null))

    /*
     * Run bowtie2 to remove the host reads
     */

    emit:
    clean_reads=SEQTK_SUBSEQ.out.sequences    // channel: [ meat, fasta ]
    versions = ch_version                     // channel: [ versions.yml ]
}
