process HUMANN_RUN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::humann=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.0.1--pyh5e36f6f_0' :
        'quay.io/biocontainers/humann:3.0.1--pyh5e36f6f_0' }"

    input:
    tuple val(meta), path(reads)
    path humann_dna_db
    path humann_pro_db

    output:
    tuple val(meta), path("${prefix}")                    , emit: output
    tuple val(meta), path("${prefix}/*_genefamilies.tsv") , emit: genefamilies
    tuple val(meta), path("${prefix}/*_pathcoverage.tsv") , emit: pathcoverage
    tuple val(meta), path("${prefix}/*_pathabundance.tsv"), emit: pathabundance
    path "versions.yml"                                   , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann_config --update run_modes threads $task.cpus
    humann \\
        --input $reads \\
        --output ${prefix} \\
        --threads $task.cpus \\
        --nucleotide-database $humann_dna_db \\
        --protein-database $humann_pro_db \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(humann --version | sed 's/humann //g')
    END_VERSIONS
    """
}
