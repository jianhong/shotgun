def VERSION = '377' // Version information not provided by tool on CLI

process UCSC_FASPLIT {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ucsc-fasplit=377" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-fasplit:377--ha8a8165_3' :
        'quay.io/biocontainers/ucsc-fasplit:377--ha8a8165_3' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fa")      , emit: reads
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: 'sequence'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    faSplit \\
        $args \\
        $reads \\
        $task.cpus \\
        ${reads}.sub

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """
}
