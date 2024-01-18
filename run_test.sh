# /usr/bin/env bash

snakemake -d test -j1 --use-conda --configfile test/test_config.yaml --conda-prefix ~/Documents/Debugging/conda_envs