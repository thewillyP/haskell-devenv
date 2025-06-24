#!/bin/bash
SCRATCH_DIR=$1
OVERLAY_PATH=$2
SIF_PATH=$3
DOCKER_URL=$4
LOG_DIR=$5
IMAGE=$6
OVERLAY_TYPE=$7

sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=build_${IMAGE}
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=10
#SBATCH --output=${LOG_DIR}/build-${IMAGE}-%j.out
#SBATCH --error=${LOG_DIR}/build-${IMAGE}-%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=${SSH_USER}@nyu.edu

mkdir -p ${SCRATCH_DIR}/images
cp -rp /scratch/work/public/overlay-fs-ext3/${OVERLAY_TYPE}.gz ${OVERLAY_PATH}.gz
gunzip -f ${OVERLAY_PATH}.gz
singularity build --force ${SIF_PATH} ${DOCKER_URL}
EOF