process KRAKEN2_RUN {
    tag 'process_high'
    tag 'process_high_memory'
    tag 'error_retry'

    conda (params.enable_conda ? "bioconda::kraken2=2.1.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken2:2.1.2--pl5321h7d875b9_1' :
        'quay.io/biocontainers/kraken2:2.1.2--pl5321h7d875b9_1' }"

    input:
    tuple val(meta), path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}_kraken2_mpa.txt")   , emit: kraken2_mpa
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def paired = meta.single_end? '' : '--paired'
    """
    kraken2 \\
        --db ${reference_db} \\
        --threads $task.cpus \\
        --report ${prefix}_kraken2_report \\
        $args \\
        $paried \\
        $reads
    ## convert Kraken2 report files to metaphlan-style files
    kreport2mpa.py \\
        --report ${prefix}_kraken2_report \\
        --output ${prefix}_kraken2_mpa.txt \\
        --display-header

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version | sed 's/Kraken version //g')
    END_VERSIONS
    """
}
