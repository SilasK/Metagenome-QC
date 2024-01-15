def get_raw_fastq(wildcards):
    return expand(
        "/Users/silas/Documents/test_reads/{sample}_{fraction}.fastq.gz",
        fraction=["R1", "R2"],
        **wildcards
    )
