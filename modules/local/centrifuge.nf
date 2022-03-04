process CENTRIFUGE_RUN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::centrifuge=1.0.4_beta" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/centrifuge:1.0.4_beta--py36pl526he941832_2' :
        'quay.io/biocontainers/centrifuge:1.0.4_beta--py36pl526he941832_2' }"

    input:
    tuple val(meta), path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}_centrifuge.out")    , emit: centrifuge_out
    tuple val(meta), path("${prefix}_centrifuge.report") , emit: centrifuge_report
    tuple val(meta), path("${prefix}_kraken_like.report"), emit: kraken_like_report
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def inputs = meta.single_end ? "-U $reads" : "-1 ${reads[0]} -2 ${reads[1]}"
    """
    centrifuge $args \\
        -x $reference_db \\
        --threads $task.cpus \\
        $inputs \\
        --report-file ${prefix}_centrifuge.report \\
        -S ${prefix}_centrifuge.out

    centrifuge-kreport \\
        -x $reference_db \\
        ${prefix}_centrifuge.out > \\
        ${prefix}_kraken_like.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        centrifuge: \$(echo \$(centrifuge --version 2>&1) | sed 's/centrifuge //g; s/Copyright.*\$//g)
    END_VERSIONS
    """
}
