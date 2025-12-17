
# Using Micromamba for Python Environments on Hutch HPC

## Overview
Previously, we used **microconda**, but due to licensing changes, that is no longer viable on the cluster. The recommended alternative is **micromamba**, a lightweight and fast package manager compatible with conda environments.

This guide walks you through:
- Installing micromamba
- Configuring channels
- Creating and activating environments
- Running pipelines
- Submitting jobs to Hutch HPC via SLURM

---

## 1. Login to Rhino
Connect to the Hutch HPC cluster:

```bash
ssh rhino01
```

---

## 2. Install Micromamba
Run the following command and accept all defaults:

```bash
curl -L micro.mamba.pm/install.sh
```

---

## 3. Configure Conda Channels
Create or edit your `~/.condarc` file to avoid downloading packages from Anaconda:

```yaml
channels:
  - conda-forge
  - bioconda
  - pypi
show_channel_urls: true
auto_activate_base: false
channel_alias: https://conda-forge.fredhutch.org
```

**Read more:** [https://conda-forge.fredhutch.org](https://conda-forge.fredhutch.org)

---

## 4. Create a Test Environment
Example:

```bash
micromamba create -n pandas311 -c conda-forge python=3.11 numpy pandas ipython
micromamba activate pandas311
```

Verify:

```bash
ipython
```

Expected output:

```
Python 3.11.x | packaged by conda-forge
```

---

## 5. Create Environments for Projects
For example, to run the **clumping pipeline**:

```bash
micromamba create -n clump311 -c conda-forge python=3.11 numpy pandas scikit-learn scipy
micromamba activate clump311
```

---

## 6. Install and Run Clumping
Clone the repository:

```bash
git clone https://github.com/sschattgen/clumping.git
cd clumping
```

Install the package:

```bash
pip install -e .
```

Compile C++ tools:

```bash
cd tcrdist_cpp && make
```

Run the pipeline:

```bash
python scripts/run_pipeline.py   --paired_data_tsv_file <path-to-tsv>   --organism human   --outfile_prefix <output-prefix>   --all
```

---

## 7. Persistent Setup
If `micromamba` is not recognized after reconnecting, add its initialization to `~/.bashrc`:

```bash
# Example
eval "$(micromamba shell hook --shell=bash)"
```

---

## 8. Submitting Jobs on Hutch HPC
**Do NOT run large jobs (>48GB memory or >4 CPUs) directly on Rhino.** Use SLURM or `grabnode`.

### Sample SLURM Script
Create `test.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=test_write
#SBATCH --output=test_write.out
#SBATCH --error=test_write.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=10G
#SBATCH --time=00:05:00

# Load environment
source ~/.bashrc
micromamba activate clump311

# Print job info
echo "Job started on $(hostname) at $(date)"
echo "Using $SLURM_CPUS_PER_TASK CPUs and $SLURM_MEM_PER_NODE memory"

# Simple test
echo "Hello from SLURM job on $(hostname)" > testfile.txt
ls -lh testfile.txt

echo "Job finished at $(date)"
```

Submit:

```bash
sbatch test.sh
```

Monitor:

```bash
squeue -u <your-username>
```

---

## Resources
- [Fred Hutch SciWiki: Compute Jobs](https://sciwiki.fredhutch.org/scicomputing/compute_jobs/)
- [SLURM Quick Reference](https://slurm.schedmd.com/pdfs/summary.pdf)

---

### Tips
- Use `grabnode` for interactive sessions with large resources.
- For massive jobs, consult Scicomp for account details and best practices.
