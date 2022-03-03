process METAPHLAN_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::metaphlan=3.0.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:3.0.14--pyhb7b1952_0' :
        'quay.io/biocontainers/metaphlan:3.0.14--pyhb7b1952_0' }"

    input:
    tuple val(meta), path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}_metaphlan.txt")     , emit: counts
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    metaphlan \\
        $reads \\
        --nproc $task.cpus \\
        --bowtie2db $reference_db \\
        -o ${prefix}_metaphlan.txt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version | sed 's/MetaPhlAn version //g')
    END_VERSIONS
    """
}
