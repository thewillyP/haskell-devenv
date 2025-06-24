#!/bin/bash
LOG_DIR=$1
SIF_PATH=$2
OVERLAY_PATH=$3
SSH_USER=$4
BUILD_JOB_ID=$5
VNC_PASSWORD=$6
IMAGE=$7
TMP_DIR=$8

# Dependency
if [ -n "$BUILD_JOB_ID" ]; then
    SLURM_DEPENDENCY="#SBATCH --dependency=afterok:$BUILD_JOB_ID"
else
    SLURM_DEPENDENCY=""
fi

# Submit SLURM job
sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=run_${IMAGE}
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=24G
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=8
${SLURM_DEPENDENCY}
#SBATCH --output=${LOG_DIR}/run-${IMAGE}-%j.out
#SBATCH --error=${LOG_DIR}/run-${IMAGE}-%j.err

singularity run --containall --cleanenv --no-home \\
  --overlay ${OVERLAY_PATH}:rw \\
  --env VNC_PASSWORD=${VNC_PASSWORD} \\
  --bind /home/${SSH_USER}/.ssh \\
  --bind /home/${SSH_USER}/dev/asteroids:/home/${SSH_USER}/asteroids \\
  --bind ${TMP_DIR}:/tmp \\
  ${SIF_PATH}
EOF