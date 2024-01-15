

rule initialize_qc:
    input:
        get_raw_fastq,
    output:
        temp(
            expand(
                "Intermediate/qc/raw/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
    priority: 80
    log:
        "logs/qc/{sample}/init_qc.log",
    threads: config["threads"]
    resources:
        mem=config["mem_default"],
    params:
        command="reformat.sh",
        overwrite=True,
        verifypaired=True,
        extra=config["importqc_params"],
    wrapper:
        "master/bio/bbtools"


rule deduplicate:
    input:
        rules.initialize_qc.output,
    output:
        temp(
            expand(
                "Intermediate/qc/deduplicated/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
    log:
        "logs/qc/{sample}/deduplicate.log",
    threads: config["threads"]
    resources:
        mem=config["mem_default"],
    params:
        command="clumpify.sh",
        overwrite=True,
        dedupe=True,
        pigz=True,
        unpigz=True,
    wrapper:
        "master/bio/bbtools"


rule fastp:
    input:
        sample=rules.deduplicate.output,
    output:
        trimmed=temp(
            expand(
                "Intermediate/qc/trimmed/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
        html="Intermediate/reports/trimming/{sample}.html",
        json="Intermediate/reports/trimming/{sample}.json",
    log:
        "logs/qc/{sample}/trimming.log",
    params:
        extra=f"--qualified_quality_phred {config['trim_base_phred']} "
        f" --cut_mean_quality {config['trim_mean_quality']} "
        f" --length_required {config['trim_min_length']} "
        " --cut_front "
        " --cut_tail "
        " --low_complexity_filter"
        " --detect_adapter_for_pe"
        " --correction "
        " --dont_eval_duplication ",
        # by overlappping
        #" --dedup" # interfered by cut_front and cut_tail
    threads: config["threads_simple"]
    wrapper:
        "v3.3.3/bio/fastp"


rule multiqc_fastp:
    input:
        expand("Intermediate/reports/trimming/{sample}.json", sample=SAMPLES),
    output:
        "reports/trimming/multiqc.html",
        directory("reports/trimming/multiqc_data"),
    params:
        extra="--data-dir",
    log:
        "logs/multiqc.log",
    threads: 1
    resources:
        mem=config["mem_simple"],
    wrapper:
        "v3.3.3/bio/multiqc"
