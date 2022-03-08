process CENTRIFUGE_INSTALL {
    label 'process_high'

    conda (params.enable_conda ? "bioconda::centrifuge=1.0.4_beta" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/centrifuge:1.0.4_beta--py36pl526he941832_2' :
        'quay.io/biocontainers/centrifuge:1.0.4_beta--py36pl526he941832_2' }"

    output:
    path "$prefix"                                       , emit: centrifuge_db
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "db_centrifuge"
    """
    centrifuge-download -o taxonomy taxonomy
    centrifuge-download -o library $args refseq > seqid2taxid.map
    cat library/*/*.fna > input-sequences.fna
    ## build centrifuge index with 4 threads
    centrifuge-build -p $task.cpus \\
        --conversion-table seqid2taxid.map \\
        --taxonomy-tree taxonomy/nodes.dmp \\
        --name-table taxonomy/names.dmp \\
        input-sequences.fna $prefix/nt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        centrifuge: \$(echo \$(centrifuge --version 2>&1) | sed 's/centrifuge //g; s/Copyright.*\$//g')
    END_VERSIONS
    """
}
