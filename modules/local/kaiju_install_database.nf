process KAIJU_INSTALL {
    tag 'process_low'

    conda (params.enable_conda ? "bioconda::kaiju=1.8.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kaiju:1.8.2--h2e03b76_0' :
        'quay.io/biocontainers/kaiju:1.8.2--h2e03b76_0' }"

    input:
    path tgz

    output:
    path "*.{fmi,dmp}"                                   , emit: kaiji_db
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    """
    tar --strip-components=1 -xf $tgz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaiju: \$(echo \$(kaiju -h 2>&1) | sed 's/Kaiju //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
