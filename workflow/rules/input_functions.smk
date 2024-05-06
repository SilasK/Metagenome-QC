

pepfile: "sample_table_config.yaml"


sample_name_constraint = "[A-Za-z][A-Za-z0-9]+"
wildcard_constraints:
    sample=sample_name_constraint,


# pepschema: f"{snakemake_dir.parent}/config/sample_table_schema.yaml"


SAMPLES = pep.sample_table["sample_name"]

# checks
assert  pep.sample_table.index.str.match(sample_name_constraint).all(), "Not all sample names correspond to sample name criteria"
PAIRED = pep.sample_table.columns.str.contains("R2").any()

if PAIRED:
    FRACTIONS = ["R1", "R2"]
else:
    FRACTIONS = ["se"]


def get_raw_fastq(wildcards):
    headers = ["Reads_raw_" + f for f in FRACTIONS]
    fastq_dir = Path(config["fastq_dir"])

    return [fastq_dir / f for f in pep.sample_table.loc[wildcards.sample, headers]]


def get_quality_controlled_reads(wildcards):
    return expand(
        "QC/reads/{sample}_{fraction}.fastq.gz",
        fraction=FRACTIONS,
        sample=wildcards.sample,
    )


get_screen_input_fastq = get_quality_controlled_reads
