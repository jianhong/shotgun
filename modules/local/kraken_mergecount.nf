process KRAKEN2_MERGE {
    label 'process_low'

    conda (params.enable_conda ? "bioconda::kraken2=2.1.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken2:2.1.2--pl5321h7d875b9_1' :
        'quay.io/biocontainers/kraken2:2.1.2--pl5321h7d875b9_1' }"

    input:
    path kraken2_mpa
    path combine_mpa

    output:
    path "${prefix}_kraken.txt"                          , emit: kraken2_mpa
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "merged"
    """
    python ${combine_mpa} \\
        --input $kraken2_mpa \\
        --output ${prefix}_kraken.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(echo \$(kraken2 --version 2>&1) | sed 's/Kraken version //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
