//
// Uncompress and prepare reference genome files
//

include { GUNZIP as GUNZIP_FASTA   } from '../../modules/nf-core/modules/gunzip/main'
include { METAPHLAN_INSTALL        } from '../../modules/local/metaphlan_install_database'
include { KAIJU_INSTALL            } from '../../modules/local/kaiju_install_database'
include { KRAKEN2_INSTALL          } from '../../modules/local/kraken_install_database'
include { HUMANN_INSTALL
    as HUMANN_INSTALL_NUCLEOTIDE   } from '../../modules/local/humann_install_database'
include { HUMANN_INSTALL
    as HUMANN_INSTALL_PROTEIN      } from '../../modules/local/humann_install_database'
include { BOWTIE2_BUILD            } from '../../modules/nf-core/modules/bowtie2/build/main'

workflow PREPARE_GENOME {
    main:
    ch_version = Channel.empty()
    /*
     * Uncompress genome fasta file if required
     */
    if (params.fasta.endsWith('.gz')) {
        GUNZIP_FASTA ( [[id:'fasta'], file("${params.fasta}", checkIfExists: true)] )
        ch_fasta = GUNZIP_FASTA.out.gunzip.map{it[1]}
    } else {
        ch_fasta = file(params.fasta)
    }

    /*
     * Uncompress Bowtie2 index or generate from scratch if required
     */
    ch_bw2_index = Channel.empty()
    if (params.bowtie2_index){
        ch_bw2_index = Channel.value(file(params.bowtie2_index))
    }else{
        ch_bw2_index = BOWTIE2_BUILD ( ch_fasta ).index
        ch_version = ch_version.mix(BOWTIE2_BUILD.out.versions.ifEmpty(null))
    }

    /*
     * install metaphlan database
     */
    ch_metaphlan_db = Channel.empty()
    if(params.metaphlan_db){
        ch_metaphlan_db = Channel.value(file(params.metaphlan_db))
    }else{
        if(!params.skip_metaphlan){
            ch_metaphlan_db = METAPHLAN_INSTALL().metaphlan_db
            ch_version = ch_version.mix(METAPHLAN_INSTALL.out.versions.ifEmpty(null))
        }
    }

    /*
     * install Kaiju database
     */
    ch_kaiju_db = Channel.empty()
    if(!params.skip_kaiju){
        if(params.kaiju_db){
            ch_kaiju_db = KAIJU_INSTALL(file(params.kaiju_db)).kaiji_db
        }
    }

    /*
     * install Kraken2 database
     */
    ch_kraken_db = Channel.empty()
    if(!params.skip_kraken2){
        if(params.kraken2_db){
            ch_kraken_db = Channel.value(file(params.kraken2_db))
        }else{
            ch_kraken_db = KRAKEN2_INSTALL().kraken2_db
        }
    }

    /*
     * install humann database
     */
    ch_humann_dna_db = Channel.empty()
    ch_humann_pro_db = Channel.empty()
    if(!params.skip_humann){
        if(params.humann_dna_db){
            ch_humann_dna_db = Channel.value(file(params.humann_dna_db))
        }else{
            ch_humann_dna_db = HUMANN_INSTALL_NUCLEOTIDE().humann_db
        }
        if(params.humann_pro_db){
            ch_humann_pro_db = Channel.value(file(params.humann_pro_db))
        }else{
            ch_humann_pro_db = HUMANN_INSTALL_PROTEIN().humann_db
        }
    }

    emit:
    fasta = ch_fasta                          // channel: [ fasta ]
    bowtie2_index = ch_bw2_index              // channel: [ [bw2 index] ]
    metaphlan_db = ch_metaphlan_db            // channel: [ [metaphlan_db] ]
    kaiju_db = ch_kaiju_db                    // channel: [ fmi, [dmp] ]
    kraken2_db = ch_kraken_db                 // channel: [ [kraken2_db] ]
    humann_dna_db = ch_humann_dna_db          // channel: [ [humann_db] ]
    humann_pro_db = ch_humann_pro_db          // channel: [ [humann_db] ]
    versions = ch_version                     // channel: [ versions.yml ]
}
