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
[! Note] CUPY TAKES ABOUT 20 MINUTES TO BUILD

## Run sbatch script

```
sbatch run_tgpu_test.sbatch
```



