# /usr/bin/env bash



cp -v config/template_config.yaml test/test_config.yaml
snakemake -d test -j1 --use-conda --configfile test/test_config.yaml \
--conda-prefix ~/Documents/Debugging/conda_envs \
$@