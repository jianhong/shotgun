process BRACKEN {
    tag 'process_low'
    label 'error_ignore'

    conda (params.enable_conda ? "bioconda::bracken=2.6.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bracken:2.6.1--py39h7cff6ad_2' :
        'quay.io/biocontainers/bracken:2.6.1--py39h7cff6ad_2' }"

    input:
    tuple val(meta), path(kraken2_report), path(kmer_distrib)
    path reference_db

    output:
    path "${prefix}_*"                                   , emit: bracken
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    bracken -d ${reference_db} \\
        -i $kraken2_report \\
        -o ${prefix}_bracken \\
        -r ${meta.reads_length} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bracken: 2.6.1
    END_VERSIONS
    """
}
