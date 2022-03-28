process MOTUS_MERGE {
    label 'process_low'
    label 'error_ignore'

    conda (params.enable_conda ? "bioconda::motus=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/motus:3.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/motus:3.0.1--pyhdfd78af_0' }"

    input:
    path motus_outs
    path reference_db

    output:
    path "${prefix}_motus.out"                           , emit: merged_out
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "merged"
    """
    motus merge \\
        -i "${motus_outs.join(',').trim()}" \\
        -t $task.cpus \\
        -db ${reference_db} \\
        $args \\
        -o ${prefix}_motus.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mOTUs: \$(grep motus ${reference_db}/db_mOTU_versions | sed 's/motus\\t//g')
    END_VERSIONS
    """
}
