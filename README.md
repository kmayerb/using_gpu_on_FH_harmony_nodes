# How to use GPUs responsibly on Fred Hutch harmony nodes

see also: https://sciwiki.fredhutch.org/scicomputing/compute_gpu/

## Step 1: login to the maestro cluster
ssh maestro

## start python configured for GPU use using module load


```
ml CUDA-Python/12.1.0-gfbf-2023a-CUDA-12.1.1
```

## create a virtual environment (cuda_py_121)

```
python -m venv ~/venvs/cuda_py_121
source ~/venvs/cuda_py_121/bin/activate
```
[! Note] Do this direcly after module loadD

## Install minimal packages for tcrdistgpu

```
python -m pip install --upgrade pip setuptools wheel
python -m pip install tqdm
python -m pip install cupy 
```
[! Important] CUPY TAKES ABOUT 20 MINUTES TO BUILD

## Run sbatch script

```
sbatch run_tgpu_test.sbatch
```


### Header of the sbatch script

Specifies the correct partition (harmony) and that we only need 1 GPU

```
#!/bin/bash
#SBATCH --job-name=tcrdistgpu_test
#SBATCH --partition=chorus
#SBATCH --gres=gpu:1
#SBATCH --time=0:05:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
```

### Check your progress 



```
(cuda_py_121) kmayerbl@maestro:~$ sbatch run_tgpu_test.sbatch
Submitted batch job 43562282
(cuda_py_121) kmayerbl@maestro:~$ squeue -u kmayerbl
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          43562282    chorus tcrdistg kmayerbl  R       0:07      1 harmony07
```



### Look at your jobs output

```
(cuda_py_121) kmayerbl@maestro:~$ more  tcrdistgpu_test_43562282.out
=== Job info ===
Wed Dec 17 13:55:34 PST 2025
harmony07
SLURM_JOB_ID=43562282
CUDA_VISIBLE_DEVICES=0
=== Python ===
/home/kmayerbl/venvs/cuda_py_121/bin/python
Python 3.11.3
=== nvidia-smi ===
Wed Dec 17 13:55:38 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.163.01             Driver Version: 550.163.01     CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA L40S                    Off |   00000000:01:00.0 Off |                    0 |
| N/A   32C    P8             34W /  350W |       1MiB /  46068MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
Successfully added '/fh/fast/gilbert_p/kmayerbl/TCRdist_GPU' to sys.path.
You can now import modules directly from this location.
Sucess
(20000, 4)
/fh/fast/gilbert_p/kmayerbl/TCRdist_GPU/tcrdistgpu
        ## Prep data for approximate TCRdist(140,ab) for combined chains AB
        ### Dropping Invalid Data: 0
        ### Encoding based on chains: ab:
        ### Computing Approximate TCRdist(140,ab):
MODE: cuda -- 2.42 seconds
After Burn-In
MODE: cuda -- 1.73 seconds
#####
Use CPU instead
/fh/fast/gilbert_p/kmayerbl/TCRdist_GPU/tcrdistgpu
        ### Encoding based on chains: ab:
        ### Computing Approximate TCRdist(140,ab):
MODE: cpu -- 62.54 seconds
```




