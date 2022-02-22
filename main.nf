#!/usr/bin/env nextflow
/*
========================================================================================
    jianhong/shotgun
========================================================================================
    Github : https://github.com/jianhong/shotgun
    Website: https://nf-co.re/shotgun
    Slack  : https://nfcore.slack.com/channels/shotgun
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

params.fasta           = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.bowtie2_index   = WorkflowMain.getGenomeAttribute(params, 'bowtie2')
anno_readme            = WorkflowMain.getGenomeAttribute(params, 'readme')
// Save AWS IGenomes file containing annotation version
if (anno_readme && file(anno_readme).exists()) {
    file("${params.outdir}/genome/").mkdirs()
    file(anno_readme).copyTo("${params.outdir}/genome/")
}

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { SHOTGUN } from './workflows/shotgun'

//
// WORKFLOW: Run main jianhong/shotgun analysis pipeline
//
workflow NFCORE_SHOTGUN {
    SHOTGUN ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_SHOTGUN ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
