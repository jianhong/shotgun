process MERGE_FASTQ {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz")                  , emit: reads
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [ "${meta.single_end}" = "true" ]; then
        cat $reads > ${prefix}.fastq.gz
    else
        cat *.unmapped_1.fastq.gz.* > ${prefix}_R1.fastq.gz
        cat *.unmapped_2.fastq.gz.* > ${prefix}_R2.fastq.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
