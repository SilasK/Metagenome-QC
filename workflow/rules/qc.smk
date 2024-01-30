

rule adapter_trimming:
    input:
        get_raw_fastq,
    output:
        out=temp(
            expand(
                "Intermediate/qc/reads/adapter_trimmed/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
        bhist="Intermediate/stats/raw/{sample}/base_histogram.txt",
        qhist="Intermediate/stats/raw/{sample}/quality_histogram.txt",
        gchist="Intermediate/stats/raw/{sample}/gc_hisogramm.txt",  #*histogram
        aqhist="Intermediate/stats/raw/{sample}/average_quality.txt",
        lhist="Intermediate/stats/raw/{sample}/length_histogram.txt",
        stats="Intermediate/stats/qc/{sample}/adapter_trimming_stats.txt",
    log:
        "logs/qc/trim_adapters/{sample}.log",
    benchmark:
        "log/benchmark/trim_adapters/{sample}.tsv"
    threads: config["threads_simple"]
    resources:
        mem_mb=config["mem_simple"] * 1000,
        time_min=config["time_short"] * 60,
    params:
        command="bbduk.sh",
        literal=config["literal_adapters"],
        # verifypaired=True,
        iupacToN=True,
        touppercase=True,
        qout=33,
        #addslash=True,
        maxns=config["preprocess_max_ns"],
        ktrim="r ",
        k=23,
        mink=11,
        hdist=config["adapter_trimming_allow_substitutions"],
        trimpairsevenly=True,
        trimbyoverlap=True,
        ftm=5 if config["trim_modulo"] else 0,
        ref=config["adapters"],
        json=True,
        pigz=True,
        unpigz=True,
        prealloc=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


rule deduplicate_reads:
    input:
        rules.adapter_trimming.output.out,
    output:
        out=temp(
            expand(
                "Intermediate/qc/reads/deduplicated/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
    log:
        "logs/qc/deduplicate/{sample}.log",
    benchmark:
        "log/benchmark/deduplicate_reads/{sample}.tsv"
    params:
        command="clumpify.sh",
        dupesubs=config["duplicates_allow_substitutions"],
        overwrite=True,
        pigz=True,
        unpigz=True,
        dedupe=config["deduplicate_reads"],
    threads: config["threads"]
    resources:
        mem_mb=config["mem_large"] * 1000,
        time_min=config["time_short"] * 60,
    wrapper:
        BBTOOLS_WRAPPER


rule quality_trimming:
    input:
        rules.deduplicate_reads.output.out,
    output:
        out=temp(
            expand(
                "Intermediate/qc/reads/trimmed/{{sample}}_{fraction}.fastq.gz",
                fraction=FRACTIONS,
            )
        ),
        stats="Intermediate/stats/qc/{sample}/phix_mapping_stats.txt",
        bhist="Intermediate/stats/qc/{sample}/base_profile.txt",
        qhist="Intermediate/stats/qc/{sample}/quality_profile.txt",
        bqhist="Intermediate/stats/qc/{sample}/quality_boxplots.txt",
        gchist="Intermediate/stats/qc/{sample}/gc_histogram.txt",
        aqhist="Intermediate/stats/qc/{sample}/average_quality.txt",
        lhist="Intermediate/stats/qc/{sample}/length_histogram.txt",
        khist="Intermediate/stats/qc/{sample}/kmer_histogram.txt",
        enthist="Intermediate/stats/qc/{sample}/entropy_histogram.txt",
    log:
        "logs/qc/trim_quality/{sample}.log",
    threads: config["threads"]
    resources:
        mem_mb=config["mem_default"] * 1000,
        time_min=config["time_long"] * 60,
    benchmark:
        "log/benchmark/quality_trimming/{sample}.tsv"
    params:
        command="bbduk.sh",
        extra=config["trim_extra"],
        ecco=True,
        ref="phix",
        k=31,
        entropytrim="rl",
        entropy=0.5,
        hdist=config["adapter_trimming_allow_substitutions"],
        qtrim="rl",
        trimq=config["preprocess_minimum_base_quality"],
        minlength=config["preprocess_minimum_passing_read_length"],
        minavgquality=config["preprocess_average_base_quality"],
        cardinalityout=True,
        ordered=True,
        json=True,
        pigz=True,
        unpigz=True,
        prealloc=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


#### Reporting


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
        mem_mb=config["mem_simple"] * 1000,
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

if False:
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
        threads: config["threads_simple"]
        resources:
            mem_mb=config["mem_simple"] * 1000,
        params:
            command="bbduk.sh",
            cardinality=True,
            gcbins="auto",
            json=True,
            unpigz=True,
            overwrite=True,
        wrapper:
            BBTOOLS_WRAPPER
