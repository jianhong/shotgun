process KRONA {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::krona=2.8.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krona:2.8.1--pl5321hdfd78af_1' :
        'quay.io/biocontainers/krona:2.8.1--pl5321hdfd78af_1' }"

    input:
    tuple val(meta), path(krona_out)

    output:
    tuple val(meta), path("${prefix}_krona.html")        , emit: summary
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    ktImportText  \\
        -o ${prefix}_krona.html \\
        $krona_out,${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        krona: \$(krona -version)
    END_VERSIONS
    """
}
