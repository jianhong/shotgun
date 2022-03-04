/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowShotgun.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta, params.bowtie2_index ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
if (params.kreport2mpa) { ch_kreport2mpa = file(params.kreport2mpa) } else { exit 1, 'kreport2mpa not specified!' }
if (params.combine_mpa) { ch_combine_mpa = file(params.combine_mpa) } else { exit 1, 'combine_mpa not specified!' }
/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { PREPARE_GENOME              } from '../subworkflows/local/prepare_genome'
include { KNEAD_DATA                  } from '../subworkflows/local/kneaddata'
include { METAPHLAN                   } from '../subworkflows/local/metaphlan'
include { KAIJU                       } from '../subworkflows/local/kaiju'
include { KRAKEN2                     } from '../subworkflows/local/kraken'
include { HUMANN                      } from '../subworkflows/local/humann'
include { MOTUS                       } from '../subworkflows/local/motus'
/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CAT_FASTQ                   } from '../modules/nf-core/modules/cat/fastq/main'
include { FASTQC                      } from '../modules/nf-core/modules/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow SHOTGUN {
    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    //
    // SUBWORKFLOW: Prepare genome
    //
    PREPARE_GENOME()
    ch_versions = ch_versions.mix(PREPARE_GENOME.out.versions.ifEmpty(null))

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    ).reads
    .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            if(meta.single_end){
                meta.reads_length = WorkflowShotgun.getReadsLength(fastq)
            }else{
                meta.reads_length = WorkflowShotgun.getReadsLength(fastq[0])
            }
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq }
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Concatenate FastQ files from same sample if required
    //
    CAT_FASTQ (
        ch_fastq.multiple
    )
    .reads
    .mix(ch_fastq.single)
    .set { ch_cat_fastq }
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions.first().ifEmpty(null))

    //
    // MODULE: Run FastQC
    //
    if(!params.skip_fastqc){
        FASTQC (
            INPUT_CHECK.out.reads
        )
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    }

    //
    // MODULE: Clean data
    //
    KNEAD_DATA(ch_cat_fastq, PREPARE_GENOME.out.bowtie2_index)
    ch_versions = ch_versions.mix(KNEAD_DATA.out.versions)
    if(params.use_single_kneaddata){
        ch_knead_data = KNEAD_DATA.out.reads.map{
                            meta, reads ->
                                meta.single_end = true
                                [meta, reads]
                        }
    }else{
        ch_knead_data = KNEAD_DATA.out.reads
                            .mix(KNEAD_DATA.out.pairs)
                            .filter{
                                it[0].single_end ?: it[1].size() == 2
                            }
    }

    //
    // MODULE: Metaphlan
    //
    if(!params.skip_metaphlan){
        METAPHLAN(KNEAD_DATA.out.reads, PREPARE_GENOME.out.metaphlan_db)
        ch_versions = ch_versions.mix(KNEAD_DATA.out.versions)
    }

    //
    // MODULE: kaiju
    //
    if(!params.skip_kaiju){
        KAIJU(ch_knead_data, PREPARE_GENOME.out.kaiju_db)
        ch_versions = ch_versions.mix(KAIJU.out.versions)
    }

    //
    // MODULE: kraken2
    //
    if(!params.skip_kraken2){
        KRAKEN2(
            ch_knead_data,
            PREPARE_GENOME.out.kraken2_db,
            ch_kreport2mpa,
            ch_combine_mpa)
        ch_versions = ch_versions.mix(KRAKEN2.out.versions)
    }

    //
    // MODULE: humann3
    //
    if(!params.skip_humann){
        HUMANN( KNEAD_DATA.out.reads,
                PREPARE_GENOME.out.humann_dna_db,
                PREPARE_GENOME.out.humann_pro_db)
        ch_versions = ch_versions.mix(HUMANN.out.versions)
    }

    //
    // MODULE: Centrifuge
    //
    //if(!params.skip_centrifuge){
    //    CENTRIFUGE( ch_knead_data,
    //            PREPARE_GENOME.out.humann_dna_db,
    //            PREPARE_GENOME.out.humann_pro_db)
    //    ch_versions = ch_versions.mix(CENTRIFUGE.out.versions)
    //}

    //
    // MODULE: mOTUs
    //
    if(!params.skip_motus){
        MOTUS(ch_knead_data, PREPARE_GENOME.out.motus_db)
        ch_versions = ch_versions.mix(MOTUS.out.versions)
    }

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowShotgun.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
