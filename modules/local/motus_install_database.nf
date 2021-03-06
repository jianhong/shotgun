process MOTUS_INSTALL {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::motus=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/motus:3.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/motus:3.0.1--pyhdfd78af_0' }"

    input:
    path motus_download

    output:
    path "$prefix"                                       , emit: motus_db
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "db_mOTU"
    """
    cp $motus_download dwdDB.py
    python dwdDB.py \\
        -t $task.cpus
    if [ "$prefix" != "db_mOTU" ]; then
        mv db_mOTU $prefix
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mOTUs: \$(grep motus ${prefix}/db_mOTU_versions | sed 's/motus\\t//g')
    END_VERSIONS
    """
}
