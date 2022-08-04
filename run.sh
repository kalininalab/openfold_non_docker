#!/bin/bash

set -e

usage() {
	echo ""
	echo "Please make sure all required parameters are given as described."
	echo "Required Parameters:"
	echo "-d <data_dir>         Directory of the database in the AlphaFold layout"
	echo "-f <fasta_dir>        Directory of the FASTA files, one sequence per file"
	echo "-c <conda_dir>        Directory of the anaconda installation"
	echo "-s <output_dir>       Directory where to store the folds of the proteins"
	echo ""
	echo "Semi-required Parameters (either -a or -o have to be given):"
	echo "-a <af_weight_file>   File with the weights for the AlphaFold model"
	echo "-o <model_name> <of_weight_dir>"
	echo "                      Name of the model to use (--config_preset)"
	echo "                      File with the weights for the OpenFold model"
	echo ""
	echo "Optional Parameters:"
	echo "--cpu                 Flag indicating to use CPU instead of default GPU"
	echo ""
	exit 1
}

alpha=0
open=0
data_dir=""
conda_dir=""
fasta_dir=""
save_dir=""
cpu=0

while [[ $# -gt 0 ]]; do 
	case $1 in
		-d)
			data_dir=$2
			shift
			shift
			;;
		-c)
			conda_dir=$2
			shift
			shift
			;;
		-f)
			fasta_dir=$2
			shift
			shift
			;;
		-s)
			save_dir=$2
			shift
			shift
			;;
		-a)
			alpha=1
			alpha_model=$2
			shift
			shift
			;;
		-o)
			open=1
			open_name=$2
			open_model=$3
			shift
			shift
			shift
			;;
		--cpu)
			cpu=1
			shift
			;;
		*)
			usage
			shift
			;;
	esac
done

echo $open_name
echo $open_model

if [[ $data_dir = "" ]]; then
	usage
fi

if [[ $conda_dir = "" ]]; then
	usage
fi

if [[ $fasta_dir = "" ]]; then
	usage
fi

if [[ $save_dir = "" ]]; then
	usage
fi

tmp=$((alpha + open))
if [ "$tmp" -eq "0" ]; then
	usage
fi

# Paths to the databases
uniref90_database_path="$data_dir/uniref90/uniref90.fasta"
mgnify_database_path="$data_dir/mgnify/mgy_clusters_2018_12.fa"
bfd_database_path="$data_dir/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
# small_bfd_database_path="$data_dir/small_bfd/bfd-first_non_consensus_sequences.fasta"
uniclust30_database_path="$data_dir/uniclust30/uniclust30_2018_08/uniclust30_2018_08"
pdb70_database_path="$data_dir/pdb70/pdb70"
template_mmcif_dir="$data_dir/pdb_mmcif/mmcif_files"

# Binary path (change me if required)
hhblits_binary_path="$conda_dir/envs/openfold_venv/bin/hhblits"
hhsearch_binary_path="$conda_dir/envs/openfold_venv/bin/hhsearch"
jackhmmer_binary_path="$conda_dir/envs/openfold_venv/bin/jackhmmer"
kalign_binary_path="$conda_dir/envs/openfold_venv/bin/kalign"

database_args="--uniref90_database_path $uniref90_database_path --mgnify_database_path $mgnify_database_path --pdb70_database_path $pdb70_database_path --uniclust30_database_path $uniclust30_database_path --bfd_database_path $bfd_database_path"
tool_args="--jackhmmer_binary_path $jackhmmer_binary_path --hhblits_binary_path $hhblits_binary_path --hhsearch_binary_path $hhsearch_binary_path --kalign_binary_path $kalign_binary_path"

if [ $alpha -eq 1 ]; then
	model_args="--jax_param_path $alpha_model"
else
	model_args="--config_preset $open_name --openfold_checkpoint_path $open_model"
fi

if [ $cpu -eq 1 ]; then
	cpu="cpu"
	arch_args="--model_device $cpu"
else
	cuda="cuda:0"
	arch_args="--model_device $cuda"
fi

output_arg="--output_dir $save_dir"

cmd="python openfold/run_pretrained_openfold.py $fasta_dir $template_mmcif_dir $output_arg $arch_args $database_args $tool_args $model_args"
# echo $cmd
$cmd

