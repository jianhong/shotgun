process KRAKEN2_INSTALL {
    tag 'process_high'
    tag 'process_high_memory'
    tag 'error_retry'

    conda (params.enable_conda ? "bioconda::kraken2=2.1.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraken2:2.1.2--pl5321h7d875b9_1' :
        'quay.io/biocontainers/kraken2:2.1.2--pl5321h7d875b9_1' }"

    output:
    path "KRAKEN2_DB"                                    , emit: kraken2_db
    path "versions.yml"                                  , emit: versions

    script:
    def args   = task.ext.args ?: ''
    """
    kraken2_path=\$(perl -MCwd=abs_path -le 'print abs_path(shift)' \$(which kraken2))
    kraken2_path=\$(dirname \$kraken2_path)
    echo \$kraken2_path
    # patch kraken2
    mkdir bin
    cp -r \$kraken2_path bin
    sed -i -e 's/\\^ftp:/\\^https:/' bin/rsync_from_ncbi.pl
    sed -i -e 's/mv x assembly/mv -f x assembly/' bin/download_genomic_library.sh
    export PATH=\${PWD}/bin:\$PATH
    if [ "${args}" == "--standard" ]; then
        bin/kraken2-build \\
            --standard \\
            --db KRAKEN2_DB \\
            --threads $task.cpus
    else
        bin/kraken2-build \\
            --download-taxonomy \\
            --db KRAKEN2_DB \\
            --threads $task.cpus
        dbs=($args)
        for i in \$dbs
        do
            kraken2-build \\
                --download-library \$i \\
                --db KRAKEN2_DB \\
                --threads $task.cpus
        done
        kraken2-build --build \\
            --db KRAKEN2_DB \\
            --threads $task.cpus
        kraken2-build --clean \\
            --db KRAKEN2_DB \\
            --threads $task.cpus
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version | sed 's/Kraken version //g')
    END_VERSIONS
    """
}
