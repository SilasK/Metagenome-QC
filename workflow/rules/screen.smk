


rule generate_sketch:
    input:
        unpack(get_input_fastq),
    output:
        "Intermediate/screen/sketches/{sample}.sketch.gz",
    log:
        "logs/screen/make_sketch/{sample}.log",
    threads: 1
    resources:
        mem=config["mem_simple"],
    params:
        command="bbsketch.sh",
        samplerate=0.5,
        minkeycount=2,
        blacklist="nt",
        ssu=False,
        name0="{sample}",
        depth=True,
        overwrite=True
    wrapper:
        BBTOOLS_WRAPPER


rule compare_sketch:
    input:
        expand(rules.generate_sketch.output, sample=SAMPLES),
    output:
        "QC/screen/sketch_comparison.tsv.gz",
    priority: 100
    log:
        "logs/screen/compare_sketch.log",
    threads: 1
    resources:
        mem=config["mem_default"],
    params:
        command="comparesketch.sh",
        extra="alltoall",
        format=3,
        records=5000,
        overwrite=True
    wrapper:
        BBTOOLS_WRAPPER
       

rule send_sketch:
    input:
        rules.generate_sketch.output
    output:
        "Intermediate/screen/results/{sample}.tsv"
    log:
        "logs/screen/send_sketch.log",
    threads: 1
    resources:
        mem=config["mem_simple"],
    params:
        command="sendsketch.sh",
        printdepth2=True,
        level=2,
        printqfname=True,
        printvolume=True,
        color=False,
        overwrite=True
    wrapper:
        BBTOOLS_WRAPPER
       

