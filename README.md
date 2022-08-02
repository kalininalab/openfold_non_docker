# Openfold Non Docker Setup
OpenFold non-docker setup

## Installation

First, you need to install anaconda (miniconda and mamba are fine as well, I'll stick to conda in the following). For a detailed instruction on how to install conda, please refer to their [website](https://docs.anaconda.com/anaconda/install/). In the inference part we furthermore assume that anaconda3 is installed in the home directory.

The following steps are also covered in install.sh. For information on how to use this, please refer to it's help (./install.sh -h).

We will install everything without sudo rights into a folder called `openfold`:

```shell
mkdir openfold
cd openfold
```

### Setup Conda Environment

Create a conda environment and install some necessary packages

```shell
conda create --name openfold python=3.7
conda activate openfold
conda install -y -q -c conda-forge -c bioconda kalign=2.04 hhsuite=3.3.0
pip install -q ml-collections==0.1.0 PyYAML==5.4.1 biopython==1.79
```

### Access AWS

This is only needed if you plan to use the retrained OpenFold parameters. This model also works with the original AlphaFold parameters, so this step is optional.

```shell
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -qq awscliv2.zip
./install -i ./ -b ./
rm awscliv2.zip
```
The executable `aws` file is located in `./v2/2.7.20/bin/`.

### Install OpenFold

```shell
git clone https://github.com/aqlaboratory/openfold
cd openfold
conda env create --file environment.yml
conda activate openfold_venv
pip install ./
conda install -c conda-forge openmm=7.5.1 pdbfixer=1.7
cd openfold/resources
wget https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt
cd ../../..
```

### Download the weights

#### AlphaFold parameters
```shell
mkdir -p params/af_params
cd params/af_params
wget https://storage.googleapis.com/alphafold/alphafold_params_2022-01-19.tar
tar --extract --verbose --file alphafold_params_2022-01-19.tar --preserve-permissions
cd ../..
```

#### OpenFold Weights

To be able to execute the following lines of code, you need to follow the AWS steps above.

```shell
...
```

## Inference

For inference with OpenFold, please also refer to the according setion in the OpenFold [Readme](https://github.com/aqlaboratory/openfold#inference) file. In the examples, we assume `anaconda3` is installed in the home directory. If this is not the case, the according paths have to be changed.

### Inference from AlphaFold weights

```shell
python openfold/run_pretrained_openfold.py \
  fastas \
  data/pdb_mmcif/mmcif_files/ \
  --output_dir ./ \
  --model_device "cuda:0" \
  --uniref90_database_path data/uniref90/uniref90.fasta \
  --mgnify_database_path data/mgnify/mgy_clusters_2018_12.fa \
  --pdb70_database_path data/pdb70/pdb70 \
  --uniclust30_database_path data/uniclust30/uniclust30_2018_08/uniclust30_2018_08 \
  --bfd_database_path data/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt_ \
  --jackhmmer_binary_path ~/anaconda3/envs/openfold_venv/bin/jackhmmer \
  --hhblits_binary_path ~/anaconda3/envs/openfold_venv/bin/hhblits \
  --hhsearch_binary_path ~/anaconda3/envs/openfold_venv/bin/hhsearch \
  --kalign_binary_path ~/anaconda3/envs/openfold_venv/bin/kalign \
  --jax_param_path params/af_params/params_model_4.npz
```

### Inference from OpenFold weights

```shell
python openfold/run_pretrained_openfold.py \
  fastas \
  data/pdb_mmcif/mmcif_files/ \
  --output_dir ./ \
  --model_device "cuda:0" \
  --uniref90_database_path data/uniref90/uniref90.fasta \
  --mgnify_database_path data/mgnify/mgy_clusters_2018_12.fa \
  --pdb70_database_path data/pdb70/pdb70 \
  --uniclust30_database_path data/uniclust30/uniclust30_2018_08/uniclust30_2018_08 \
  --bfd_database_path data/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt_ \
  --jackhmmer_binary_path ~/anaconda3/envs/openfold_venv/bin/jackhmmer \
  --hhblits_binary_path ~/anaconda3/envs/openfold_venv/bin/hhblits \
  --hhsearch_binary_path ~/anaconda3/envs/openfold_venv/bin/hhsearch \
  --kalign_binary_path ~/anaconda3/envs/openfold_venv/bin/kalign \
  --config_preset "model_1_ptm" \
  --openfold_checkpoint_path params/of_params/finetuning_ptm_2.pt
```










