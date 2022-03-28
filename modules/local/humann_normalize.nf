process HUMANN_NORM {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::humann=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.0.1--pyh5e36f6f_0' :
        'quay.io/biocontainers/humann:3.0.1--pyh5e36f6f_0' }"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("${prefix}")                    , emit: norm
    path "versions.yml"                                   , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${tsv.toString().replaceAll('.tsv', '.norm')}.tsv"
    """
    #humann_config --update run_modes threads $task.cpus
    humann_renorm_table \\
        --input $tsv \\
        --output ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(humann --version | sed 's/humann //g')
    END_VERSIONS
    """
}
