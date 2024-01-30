# rule initialize_qc:
#     input:
#         get_raw_fastq,
#     output:
#         temp(
#             expand(
#                 "Intermediate/qc/raw/{{sample}}_{fraction}.fastq.gz",
#                 fraction=FRACTIONS,
#             )
#         ),
#     priority: 80
#     log:
#         "logs/qc/{sample}/init_qc.log",
#     threads: config["threads"]
#     resources:
#         mem=config["mem_default"],
#     params:
#         command="reformat.sh",
#         overwrite=True,
#         verifypaired=True,
#         extra=config["importqc_params"],
#     wrapper:
#         "master/bio/bbtools"



rule adapter_trimming:
    input:
        sample=get_raw_fastq,
    output:
        trimmed=temp(expand(
            "Intermediate/qc/reads/deduplicated/{{sample}}_{fraction}.fastq.gz",
            fraction=FRACTIONS,
        )),
        html="Intermediate/reports/adapter_trimming/{sample}.html",
        json="Intermediate/reports/adapter_trimming/{sample}.json",
    log:
        "logs/qc/{sample}/trimming.log",
    params:
        extra=f"--qualified_quality_phred 5 "
        " --length_required 31 "        
        " --cut_tail "
        " --detect_adapter_for_pe "
        " --correction "
        " --cut_tail "
        " --cut_tail_mean_quality 5 "
        " --dedup "
        " --dup_calc_accuracy 5 "
        '--report_title "Adapter trimming & Deduplication" '
        " config[adapter_trimming_extra] "
    threads: config["threads"]
    benchmark:
        "logs/benchmark/adapter_trimming/{sample}.tsv"
    resources:
        mem_mb=config["mem_default"]*1024,
    wrapper:
        "v3.3.3/bio/fastp"





rule quality_trimming:
    input:
        sample=expand(
            "Intermediate/qc/reads/deduplicated/{{sample}}_{fraction}.fastq.gz",
            fraction=FRACTIONS,
        ),
    output:
        trimmed=temp(expand(
            "Intermediate/qc/reads/trimmed/{{sample}}_{fraction}.fastq.gz",
            fraction=FRACTIONS,
        )),
        html="Intermediate/reports/quality_trimming/{sample}.html",
        json="Intermediate/reports/quality_trimming/{sample}.json",
    log:
        "logs/qc/{sample}/trimming.log",
    params:
        extra=f"--qualified_quality_phred {config['trim_base_phred']} "
        " --disable_adapter_trimming "
        " --disable_trim_poly_g "
        " --dont_eval_duplication "
        f" --length_required {config['trim_min_length']} "
        " --low_complexity_filter"
        " --cut_tail "
        " --cut_front "
        '--report_title "Quality trimming" '
        f" --cut_mean_quality {config['trim_mean_quality']} "
        " {config[quality_trim_extra]} "
        # interfered cut_tail
    threads: config["threads"]
    benchmark:
        "logs/benchmark/quality_trimming/{sample}.tsv"
    resources:
        mem_mb=config["mem_simple"]*1024,
    wrapper:
        "v3.3.3/bio/fastp"










rule multiqc_fastp:
    input:
        expand("Intermediate/reports/{{stage}}/{sample}.json", sample=SAMPLES),
    output:
        "reports/{stage}/multiqc.html",
        directory("reports/{stage}/multiqc_data"),
    params:
        extra="--data-dir",
    log:
        "logs/multiqc/{stage}.log",
    threads: 1
    resources:
        mem_mb=config["mem_simple"]*1024,
    wrapper:
        "v3.3.3/bio/multiqc"




rule calculate_insert_size:
    input:
        get_quality_controlled_reads,
    output:
        ihist="Intermediate/stats/qc/{sample}/insert_sizes.txt",
    log:
        "logs/qc/insert_size/{sample}.log",
    benchmark:
        "log/benchmark/calculate_insert_size/{sample}.tsv"
    threads: config["threads_simple"]
    resources:
        mem_mb=config["mem_simple"] * 1024,
    params:
        command="bbmerge.sh",
        extend2=50,
        k=62,
        iterations=3,
        extra="loose",
        mininsert0=25,
        minoverlap0=8,
        realloc=True,
        prefilter=True,
        merge=False,
        minprob=0.8,
        pigz=True,
        unpigz=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER