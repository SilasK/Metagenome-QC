

def get_raw_reads(wildcards):




rule fastp:
    input:
        sample=["reads/pe/{sample}.1.fastq", "reads/pe/{sample}.2.fastq"]
    output:
        trimmed=["trimmed/pe/{sample}.1.fastq", "trimmed/pe/{sample}.2.fastq"],
#        unpaired="trimmed/pe/{sample}.singletons.fastq",
        html="report/pe/{sample}.html",
        json="report/pe/{sample}.json"
    log:
        "logs/fastp/pe/{sample}.log"
    params:
        extra=  "--qualified_quality_phred {config[trim_base_phred]} "
                " --cut_mean_quality {config[trim_mean_quality]} "
                " --length_required {config[trim_min_length]} "
                " --cut_front "
                " --cut_tail "
                " --low_complexity_filter"
                " --detect_adapter_for_pe"
                " --correction " # by overlappping
                " --dedup" # interfered by cut_front and cut_tail

    threads: config["threads_simple"]
    wrapper:
        "v3.3.3/bio/fastp"