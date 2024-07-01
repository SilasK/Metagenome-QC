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
    threads: config["threads_default"]
    resources:
        mem=config["mem_default"],
    params:
        command="reformat.sh",
        overwrite=True,
        verifypaired=True,
        extra=config["importqc_params"],
    wrapper:
        BBTOOLS_WRAPPER




rule quality_trimming:
    input:
        sample= rules.initialize_qc.output,
    output:
        trimmed=temp(
            expand(
                "Intermediate/qc/reads/trimmed/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
        html="Intermediate/reports/quality_trimming/{sample}.html",
        json="Intermediate/reports/quality_trimming/{sample}.json",
    log:
        "logs/qc/quality_trimming/{sample}.log",
    params:
        extra=f"--qualified_quality_phred {config['trim_base_phred']} "
        " --dedup "
        " --dup_calc_accuracy 5 "
        f" --length_required {config['trim_min_length']} "
        " --low_complexity_filter"
        " --detect_adapter_for_pe "
        " --correction "
        " --overrepresentation_analysis "
        " --cut_tail "
        " --cut_front "
        '--report_title "Quality trimming" '
        f" --cut_mean_quality {config['trim_mean_quality']} "
        f" {config['quality_trim_extra']} ",
    threads: config["threads_default"]
    benchmark:
        "logs/benchmark/quality_trimming/{sample}.tsv"
    resources:
        mem_mb=config["mem_default"] * 1024,
    wrapper:
        "v3.3.3/bio/fastp"


rule multiqc_fastp:
    input:
        expand(rules.quality_trimming.output.json, sample=SAMPLES),
    output:
        "reports/quality_trimming/multiqc.html",
        directory("reports/quality_trimming/multiqc_data"),
    params:
        extra="--data-dir --fn_as_s_name ",
    log:
        "logs/multiqc/quality_trimming.log",
    threads: 1
    resources:
        mem_mb=config["mem_simple"] * 1024,
    wrapper:
        "v3.3.3/bio/multiqc"

### Reporting 

rule calculate_insert_size:
    input:
        get_quality_controlled_reads,
    output:
        ihist="Intermediate/stats/qc/{sample}/insert_sizes.txt",
    log:
        "logs/qc/insert_size/{sample}.log",
    benchmark:
        "log/benchmark/calculate_insert_size/{sample}.tsv"
    threads: config["threads_default"]
    resources:
        mem_mb=config["mem_default"] * 1024,
    params:
        command="bbmerge.sh",
        extend2=50,
        k=62,
        iterations=3,
        extra="loose",
        mininsert0=25,
        minoverlap0=8,
        prealloc=True,
        prefilter=True,
        merge=False,
        minprob=0.8,
        pigz=True,
        unpigz=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


rule reporting_qc:
    input:
        get_quality_controlled_reads,
    output:
        bhist="Intermediate/stats/qc/{sample}/base_profile.txt",
        qhist="Intermediate/stats/qc/{sample}/quality_profile.txt",
        bqhist="Intermediate/stats/qc/{sample}/quality_boxplots.txt",
        gchist="Intermediate/stats/qc/{sample}/gc_histogram.txt",
        aqhist="Intermediate/stats/qc/{sample}/average_quality.txt",
        lhist="Intermediate/stats/qc/{sample}/length_histogram.txt",
        khist="Intermediate/stats/qc/{sample}/kmer_histogram.txt",
        cardinality="Intermediate/stats/qc/{sample}/cardinality.txt",
        enthist="Intermediate/stats/qc/{sample}/entropy_histogram.txt",
    log:
        "logs/qc/reporting_qc/{sample}.log",
    benchmark:
        "log/benchmark/reporting_qc/{sample}.tsv"
    threads: config["threads_default"]
    resources:
        mem_mb=config["mem_default"] * 1000,
    params:
        command="bbduk.sh",
        gcbins="auto",
        json=True,
        unpigz=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER