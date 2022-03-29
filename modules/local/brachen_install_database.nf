process BRACKEN_INSTALL {
    tag 'process_medium'
    label 'error_ignore'
    label 'process_high_memory'

    conda (params.enable_conda ? "bioconda::bracken=2.6.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bracken:2.6.1--py39h7cff6ad_2' :
        'quay.io/biocontainers/bracken:2.6.1--py39h7cff6ad_2' }"

    input:
    tuple val(meta), path(kraken2_report)
    path reference_db

    output:
    path "${reference_db}/*mers.kmer_distrib", emit: kmer_distrib
    path "versions.yml", emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "metaphlan_db"
    """
    ## check the nearest databaseKmers.kmer_distrib
    kmer=\$((${meta.reads_length}/50*50))
    if [ ! -f ${reference_db}/database${meta.reads_length}mers.kmer_distrib ]; then
    bracken-build -d ${reference_db} \\
        -k \${kmer} \\
        -l ${meta.reads_length} \\
        -t $task.cpus
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bracken: 2.6.1
    END_VERSIONS
    """
}
