set -e

# Print how to use this tool
usage() {
        echo ""
        echo "Please make sure all required parameters are given."
        echo "Usage: $0 <OPTIONS>"
	echo "Partially required params: At least one of -a and -o have to be set."
	echo "-a                 Flag indicating to download alphafold weights"
	echo "-o                 Flag indicating to download openfold weights"
        echo "Optional Parameters:"
        echo "-p <params_dir>    Absolute path to the params directory (where to store the params) [default: ./params/[a|o]f_params/]"
        echo ""
        exit 1
}

af_w=0
of_w=0
params_dir=""

# parse args from commandline
while [[ $# -gt 0 ]]; do
        case $1 in
        -p)
                params_dir=$2
		shift
		shift
		;;
        -a)
                af_w=1
		shift
	        ;;
        -o)
                of_w=1
		shift
		;;
	*)
		usage
		shift
		;;
        esac
done

tmp=$((af_w + of_w))
if [ "$tmp" -eq "0" ]; then
	usage
fi

# Check if curl, wget, unzip and tar command line utilities are available
check_cmd_line_utility(){
    cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Command line utility '$cmd' could not be found. Please install."
        exit 1
    fi    
}

check_cmd_line_utility "wget"
check_cmd_line_utility "unzip"
check_cmd_line_utility "tar"
check_cmd_line_utility "curl"

# install aws utils in case openfold should be used
if [ $of_w -eq 1 ]; then
	# Install AWS - Checked
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip -qq awscliv2.zip
	./aws/install -i ./aws/ -b ./aws/
	rm awscliv2.zip
fi

# Install Openfold Code
git clone "https://github.com/aqlaboratory/openfold"
cd openfold
conda env create --file environment.yml
$HOME/anaconda3/envs/openfold_venv/bin/pip install .
wget -P "openfold/resources" "https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt"

if [ $af_w -eq 1 ]; then
	if [[ $params_dir = "" ]] ; then
		af_dir="params/af_params"
	else
		af_dir="$params_dir/af_params"
	fi
	mkdir -p "$af_dir"
	wget -P "$af_dir" "https://storage.googleapis.com/alphafold/alphafold_params_2022-01-19.tar"
	tar --extract --verbose --file "$af_dir/alphafold_params_2022-01-19.tar" --directory="$af_dir" --preserve-permissions
	rm "$af_dir/alphafold_params_2022-01-19.tar"
fi

if [ $of_w -eq 1 ]; then
	if [[ $params_dir = "" ]] ; then
		of_dir="params/of_params"
	else
		of_dir="$params_dir/of_params"
	fi
	mkdir -p "$of_dir"
	./aws/v2/2.7.21/bin/aws s3 cp --no-sign-request --region "us-east-1" "s3://openfold/openfold_params" "$of_dir" --recursive
fi
