import os


kraken_db_files = ["hash.k2d", "opts.k2d", "taxo.k2d"]


def get_kraken_db_path(wildcards):
    "depending on wildcard 'db_name'"


def get_kraken_db_files(wildcards):
    "depending on wildcard 'db_name'"
    return expand(
        "{path}/{file}", path=get_kraken_db_path(wildcards), file=kraken_db_files
    )


def calculate_kraken_memory(wildcards, overhead=7000):
    "Calculate db size of kraken db. in MB"
    "depending on wildcard 'db_name' "

    db_size_bytes = sum(os.path.getsize(f) for f in get_kraken_db_files(wildcards))

    return db_size_bytes // 1024**2 + 1 + overhead


rule kraken:
    input:
        reads=expand(
            "Intermediate/qc/trimmed/{{sample}}_{fraction}.fastq.gz",
            fraction=FRACTIONS,
        ),
        db=get_kraken_db_path,
        db_files=get_kraken_db_files,
    output:
        report="Intermediate/reports/decontamination/{sample}.txt",
        clean=expand(
            "QC/reads/{{sample}}_{fraction}.fastq.gz",
            fraction=FRACTIONS,
        ),
    log:
        "log/qc/decontamination/{sample}.log",
    conda:
        "../envs/kraken.yaml"
    params:
        paired="--paired",
        outdir=lambda wc, output: Path(output.clean[0]).parent,
    resources:
        mem_mb=calculate_kraken_memory,
    threads: config["threads"]
    shell:
        " kraken2 "
        "--db {input.db} "
        " {params.extra} "
        " --threads {threads} "
        " --output - "
        " --report {output.report} "
        " --unclassified-out {params.outdir}/{sample}_R#.fastq "
        " {params.paired} "
        " {input.reads} "
        " 2> {log} "
