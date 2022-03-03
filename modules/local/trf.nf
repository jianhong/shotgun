process TRF {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::trf=4.09.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trf:4.09.1--h779adbc_1' :
        'quay.io/biocontainers/trf:4.09.1--h779adbc_1' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.lst")     , emit: clean_name
    tuple val(meta), path("*.dat")     , emit: dat
    path "versions.yml"                , emit: versions

    script:
    def args   = task.ext.args   ?: '2 7 7 80 10 50 500 -h -ngs'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    trf \\
        $reads \\
        $args \\
        > ${prefix}.dat

    sed -n '/^>/p' ${prefix}.dat | sed -e 's/^.//' > rm.names
    sed -n '/^>/p' $reads | sed -e 's/^.//' > all.names
    comm -23 all.names rm.names > ${reads}.lst

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trf: \$(trf -v)
    END_VERSIONS
    """
}
