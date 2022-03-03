process KNEADDATA_COUNT {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39 bioconda::trf=4.09.1 bioconda::bowtie2=2.4.4 bioconda::samtools=1.14 bioconda::fastqc=0.11.9 bioconda::kneaddata=0.10.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0' :
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(kneaddata)

    output:
    tuple val(meta), path("*_counts.tsv"), emit: counts
    path "versions.yml"                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    kneaddata_read_count_table \\
        $args \\
        --input $kneaddata \\
        --output ${prefix}_counts.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(kneaddata --version | sed 's/kneaddata //')
    END_VERSIONS
    """
}
