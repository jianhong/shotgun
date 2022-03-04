process CENTRIFUGE_INSTALL {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::centrifuge=1.0.4_beta" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/centrifuge:1.0.4_beta--py36pl526he941832_2' :
        'quay.io/biocontainers/centrifuge:1.0.4_beta--py36pl526he941832_2' }"

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
