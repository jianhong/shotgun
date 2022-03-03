process KNEADDATA {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39 bioconda::trf=4.09.1 bioconda::bowtie2=2.4.4 bioconda::samtools=1.14 bioconda::fastqc=0.11.9 bioconda::kneaddata=0.10.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0' :
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reads)
    path reference_db

    output:
    tuple val(meta), path("${prefix}")                  , emit: kneaddata
    tuple val(meta), path("${prefix}/*_kneaddata.fastq"), emit: reads
    tuple val(meta), path("${prefix}/*_kneaddata_paired_{1,2}.fastq"), optional:true, emit: pairs
    path "versions.yml"                                 , emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def inputs = meta.single_end ? "--input $reads" : "--input ${reads[0]} --input ${reads[1]}"
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    trim_path=\$(python -c 'import os.path; import shutil; print(os.path.dirname(os.path.realpath(shutil.which("trimmomatic"))))')
    echo \$trim_path
    kneaddata \\
        $args \\
        $inputs \\
        --output $prefix \\
        --reference-db $reference_db \\
        --threads $task.cpus \\
        --trimmomatic \$trim_path

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(kneaddata --version | sed 's/kneaddata //')
    END_VERSIONS
    """
}
