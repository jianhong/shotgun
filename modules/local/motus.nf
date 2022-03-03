process MOTUS_RUN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::motus=3.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/motus:3.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/motus:3.0.1--pyhdfd78af_0' }"

    input:
    tuple path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}_motus.out")         , emit: motus_out
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def inputs = meta.single_end ? "-s $reads" : "-f ${reads[0]} -r ${reads[1]}"
    """
    motus profile \\
        $inputs \\
        -t $task.cpus \\
        -n ${prefix} \\
        -db ${reference_db} \\
        $args \\
        -o ${prefix}_motus.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaiju: \$(echo \$(kaiju -h 2>&1) | sed 's/Kaiju //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
