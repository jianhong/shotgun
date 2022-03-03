process HUMANN_INSTALL {
    label 'process_high'

    conda (params.enable_conda ? "bioconda::humann=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.0.1--pyh5e36f6f_0' :
        'quay.io/biocontainers/humann:3.0.1--pyh5e36f6f_0' }"

    output:
    path "${prefix}/*"                                    , emit: humann_db
    path "versions.yml"                                   , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "HUMAnN_DB"
    """
    humann_config --update run_modes threads $task.cpus
    humann_databases \\
        $args \\
        $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(humann --version | sed 's/humann //g')
    END_VERSIONS
    """
}
