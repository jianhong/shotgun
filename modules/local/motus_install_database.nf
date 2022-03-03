process MOTUS_INSTALL {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::motus=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/motus:3.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/motus:3.0.1--pyhdfd78af_0' }"

    output:
    path "$prefix"                                       , emit: motus_db
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "db_mOTU"
    """
    motus downloadDB \\
        -t $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaiju: \$(echo \$(kaiju -h 2>&1) | sed 's/Kaiju //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
