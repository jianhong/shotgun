process METAPHLAN_MERGE {
    label 'process_low'

    conda (params.enable_conda ? "bioconda::metaphlan=3.0.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:3.0.14--pyhb7b1952_0' :
        'quay.io/biocontainers/metaphlan:3.0.14--pyhb7b1952_0' }"

    input:
    path profiles

    output:
    path "${prefix}_metaphlan.txt"                       , emit: metaphlan
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "merged"
    """
    merge_metaphlan_tables.py  \\
        $profiles \\
        > ${prefix}_metaphlan.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version | sed 's/MetaPhlAn version //g')
    END_VERSIONS
    """
}
