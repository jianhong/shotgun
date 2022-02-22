process KAIJU2TABLE {
    tag 'process_low'

    conda (params.enable_conda ? "bioconda::kaiju=1.8.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kaiju:1.8.2--h2e03b76_0' :
        'quay.io/biocontainers/kaiju:1.8.2--h2e03b76_0' }"

    input:
    path kaiju_outs
    path reference_db

    output:
    path "${prefix}_kaiju.tsv"                           , emit: summary
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "merged"
    """
    kaiju2table  \\
        -t nodes.dmp -n names.dmp \\
        $args \\
        -o ${prefix}_kaiju.tsv
        $kaiju_outs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaiju: \$(echo \$(kaiju -h 2>&1) | sed 's/Kaiju //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
