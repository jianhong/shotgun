process KAIJU_RUN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::kaiju=1.8.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kaiju:1.8.2--h2e03b76_0' :
        'quay.io/biocontainers/kaiju:1.8.2--h2e03b76_0' }"

    input:
    tuple val(meta), path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}_kaiju.out")         , emit: kaiju_out
    tuple val(meta), path("${prefix}_kaiju.out.krona")   , emit: krona_input
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def inputs = meta.single_end ? "-i $reads" : "-i ${reads[0]} -i ${reads[1]}"
    """
    kaiju -t nodes.dmp -f kaiju_db_*.fmi \\
        $inputs \\
        -o ${prefix}_kaiju.out \\
        -z $task.cpus \\
        $args

    kaiju2krona -t nodes.dmp -n names.dmp \\
        -i ${prefix}_kaiju.out -o ${prefix}_kaiju.out.krona

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaiju: \$(echo \$(kaiju -h 2>&1) | sed 's/Kaiju //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
