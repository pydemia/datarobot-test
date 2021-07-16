# Uploads actuals generated by predictions directly to DataRobot MLOps

##--------------------------------------------------------
# Verify environment

if [[ -z ${MLOPS_SERVICE_URL} ]]; then
    echo "MLOPS_SERVICE_URL needs to be set."
    exit 1
fi

if [[ -z ${MLOPS_API_TOKEN} ]]; then
    echo "MLOPS_API_TOKEN needs to be set."
    exit 1
fi

##--------------------------------------------------------

usage()
{
    echo "usage: $0 [-f file ] | [-h]"
    echo "optional arguments:"
    echo "-f      file that contains actuals with association ids"
    echo "-h      prints this help"
}

ACTUALS_FILE="actuals.csv"

while [ "$1" != "" ]; do
    case $1 in
        -f | --file )           shift
                                ACTUALS_FILE=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [[ ! -f ${ACTUALS_FILE} ]]; then
    echo "${ACTUALS_FILE} does not exist. Please run run_example.sh"
    exit 1
fi

if [ -f deployment_out.txt ]; then
  deployment_id=$(grep "Deployment ID" deployment_out.txt | sed 's/^.*ID //')
  echo deployment_id $deployment_id
  export MLOPS_DEPLOYMENT_ID=$deployment_id
fi

echo ""
echo "Uploading actuals to DataRobot MLOps..."
ARGS="--url ${MLOPS_SERVICE_URL} --token ${MLOPS_API_TOKEN}"
ARGS="${ARGS} --deployment-id ${MLOPS_DEPLOYMENT_ID} --csv-filename ${ACTUALS_FILE}"
python ../../../tools/upload_actuals.py ${ARGS}
echo "Upload completed. Check accuracy tab in UI"