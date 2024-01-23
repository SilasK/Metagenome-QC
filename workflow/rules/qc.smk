

rule initialize_qc:
    input:
        get_raw_fastq
    output:
        temp(
            out=temp(expand("Intermediate/qc/reads/raw/{{sample}}_{fraction}.fastq.gz", fraction=FRACTIONS))
        ),
        bhist="Intermediate/stats/raw/{sample}/base_histogramm.txt",
        qhist="Intermediate/stats/raw/{sample}/quality_histogramm.txt",
        gchist="Intermediate/stats/raw/{sample}/gc_hisogramm.txt",
        aqhist="Intermediate/stats/raw/{sample}/average_quality.txt",
        lhist="Intermediate/stats/raw/{sample}/length_histogramm.txt",
    log:
        "logs/qc/init/{sample}.log",
    priority: 80
    threads: config["threads_simple"]
    resources:
        mem_mb=config["mem_simple"]*1e3,
    params:
        command="reformat.sh",
        verifypaired=True,
        extra=config["importqc_params"],
        pigz=True,
        unpigz=True,
        overwrite=True

    conda:
        "%s/required_packages.yaml" % CONDAENV
    threads: config.get("simplejob_threads", 1)
    wrapper:
        "v3.3.5/bio/bbtools"




rule adapter_trimming:
    input:
        rules.initialize_qc.output.out
    output:
        out=temp(expand("Intermediate/qc/reads/adapter_trimmed/{{sample}}_{fraction}.fastq.gz", fraction=FRACTIONS))
        stats="Intermediate/stats/qc/{sample}/adapter_trimming_stats.txt",
    log:
        "logs/qc/trim_adapters/{sample}.log",
    threads: config["threads_simple"]
    resources:
        mem_mb=config["mem_simple"]*1e3,
    params:
        command="bbduk.sh",
        maxns=config["preprocess_max_ns"],
        ktrim="r ",
        k=23,
        mink=11,
        hdist=config["adapter_trimming_allow_substitutions"],
        trimpairsevenly=True,
        trimbyoverlap=True,
        ftm= 5 if config["is_illumina"] else 0
        verifypaired=True,
        ref=config["preprocess_adapters"],
        pigz=True,
        unpigz=True,
        prealloc=True,
        overwrite=True
    wrapper:
        "v3.3.5/bio/bbtools"


rule deduplicate_reads:
    input:
        rules.adapter_trimming.output.out
    output:
        temp(
            out=expand("Intermediate/qc/reads/deduplicated/{{sample}}_{fraction}.fastq.gz", fraction=FRACTIONS)
        ),
    log:
        "logs/qc/deduplicate/{sample}.log",
    params:
        command="clumpify.sh",
        dupesubs=config["duplicates_allow_substitutions"],
        overwrite=True,
        pigz=True,
        unpigz=True,
        dedupe=config["deduplicate_reads"],

    threads: config["threads"]
    resources:
        mem_mb=config["mem_large"]*1e3,
    wrapper:
        "v3.3.5/bio/bbtools"



rule quality_trimming:
    input:
        rules.deduplicate_reads.output.out,
    output:
        out=expand("QC/reads/{{sample}}_{fraction}.fastq.gz", fraction=FRACTIONS)
        stats="Intermediate/stats/qc/{sample}/phix_mapping_stats.txt",
        bhist="Intermediate/stats/qc/{sample}/base_histogramm.txt",
        qhist="Intermediate/stats/qc/{sample}/quality_histogramm.txt",
        gchist="Intermediate/stats/qc/{sample}/gc_hisogramm.txt",
        aqhist="Intermediate/stats/qc/{sample}/average_quality.txt",
        lhist="Intermediate/stats/qc/{sample}/length_histogramm.txt",
        khistout="Intermediate/stats/qc/{sample}/kmer_histogramm.txt",
        cardinalityout="Intermediate/stats/qc/{sample}/cardinality.txt",
        enthist="Intermediate/stats/qc/{sample}/entropy_histogramm.txt",
    log:
        "logs/qc/trim_quality/{sample}.log",
    threads: config["threads_simple"]
    resources:
        mem_mb=config["mem_simple"]*1e3,
    params:
        command="bbduk.sh",
        error_correction_pe=True,
        ref="phix,artefacts",
        k=31,
        entropytrim="rl",
        entropy=0.5,
        hdist=config["adapter_trimming_allow_substitutions"]
        qtrim="w",
        trimq=config["preprocess_minimum_base_quality"],
        minlength=config["preprocess_minimum_passing_read_length"],
        minavgquality=0=config["preprocess_average_base_quality"],
        gcbins="auto",
        pigz=True,
        unpigz=True,
        prealloc=True,
        overwrite=True
    wrapper:
        "v3.3.5/bio/bbtools"



