


rule generate_sketch:
    input:
        get_screen_input_fastq,
    output:
        "Intermediate/screen/sketches/{sample}.sketch.gz",
    log:
        "logs/screen/make_sketch/{sample}.log",
    threads: 1
    resources:
        mem=config["mem_simple"],
    params:
        command="bbsketch.sh",
        processSSU=False,
        samplerate=0.5,  # sample halve of the file
        minkeycount=2,
        blacklist="nt",
        name0="{sample}",
        depth=True,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


rule compare_sketch:
    input:
        flag=expand(rules.generate_sketch.output, sample=SAMPLES),
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
        extra=lambda wc, input: f"alltoall {input.flag}",
        format=3,
        records=5000,
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


rule send_sketch:
    input:
        rules.generate_sketch.output,
    output:
        "Intermediate/screen/results/{sample}.tsv",
    log:
        "logs/screen/send_sketch/{sample}.log",
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
        overwrite=True,
    wrapper:
        BBTOOLS_WRAPPER


rule screen:
    input:
        expand(rules.send_sketch.output, sample=SAMPLES),
        "QC/screen/sketch_comparison.tsv.gz",
