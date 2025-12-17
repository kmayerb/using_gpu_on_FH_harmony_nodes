#!/bin/bash
#SBATCH --job-name=tcrdistgpu_test
#SBATCH --partition=chorus
#SBATCH --gres=gpu:1
#SBATCH --time=0:05:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

set -euo pipefail

echo "=== Job info ==="
date
hostname
echo "SLURM_JOB_ID=$SLURM_JOB_ID"
echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-unset}"

ml purge
ml CUDA-Python/12.1.0-gfbf-2023a-CUDA-12.1.1

source ~/venvs/cuda_py_121/bin/activate

echo "=== Python ==="
which python
python -V

echo "=== nvidia-smi ==="
nvidia-smi || true

python - <<'PY'
import sys
import numpy as np
sys.path.append('/fh/fast/gilbert_p/kmayerbl/TCRdist_GPU')
print(f"Successfully added '/fh/fast/gilbert_p/kmayerbl/TCRdist_GPU' to sys.path.")
print("You can now import modules directly from this location.")
import pandas as pd
from tcrdistgpu.distance import TCRgpu
print("Sucess")

df = pd.read_csv('https://raw.githubusercontent.com/kmayerb/tcrdist3/refs/heads/master/dash_human.csv')
df = df.groupby(['j_a_gene','j_b_gene','v_a_gene','v_b_gene','cdr3_a_aa','cdr3_b_aa','subject','epitope']).count().sort_values('clone_id',ascending=False).reset_index(drop=False)

df = pd.read_csv('https://raw.githubusercontent.com/kmayerb/tcrdistgpu/refs/heads/main/data/tmp_tcr.tsv', sep="\t")
df = df.rename(columns={'va': 'v_a_gene','vb': 'v_b_gene', 'cdr3a': 'cdr3_a_aa', 'cdr3b': 'cdr3_b_aa'})
print(df.shape)

# DEFINE PARAMETERS
chain = "ab"
max_dist = 140

data = df.copy()
# Create TCRgpu object
tg = TCRgpu(mode='cuda',  # If you only have a cpu set mode to "cpu"
            chunk_size=100,  # Limit rows processed at once to prevent RAM overflow
            cdr3a_col='cdr3_a_aa',
            cdr3b_col='cdr3_b_aa',
            va_col='v_a_gene',
            vb_col='v_b_gene')

"""
THIS JUST ENSURES INPUT IS CLEANED
# DATA MUST BE CLEAN - THIS MEANS ALL TRAV,TRBV must be recognizable and both CDR3(A,B) MUST BE VALID
"""
if chain == "a":
  print(f"\t## Prep data for approximate TCRdist({max_dist},{chain}) for chain A")
elif chain == "b":
  print(f"\t## Prep data for approximate TCRdist({max_dist},{chain}) for chain B" )
elif chain == "ab":
  print(f"\t## Prep data for approximate TCRdist({max_dist},{chain}) for combined chains AB")
else:
  raise ValueError("Invalid chain option")

def _valid_cdr3(cdr3):
    """ Return True iff all amino acids are part of standard amino acid list"""
    if not isinstance(cdr3, str):
        return False
    else:
        amino_acids = ['A', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y']
        valid = np.all([aa in amino_acids for aa in cdr3])
        if len(cdr3) < 5:
          valid = False
        return valid

mask = pd.Series(True, index=df.index)
if "a" in chain:
  ix_va = df["v_a_gene"].isin(tg.params_vec.keys())
  ix_3a = df["cdr3_a_aa"].apply(_valid_cdr3)
  mask &= ix_va & ix_3a
if "b" in chain:
  ix_vb = df["v_b_gene"].isin(tg.params_vec.keys())
  ix_3b = df["cdr3_b_aa"].apply(_valid_cdr3)
  mask &= ix_vb & ix_3b
data = df[mask].reset_index(drop=True)
print("\t### Dropping Invalid Data:", df.shape[0] - data.shape[0])

print(f"\t### Encoding based on chains: {chain}:")
if chain == "a":
  encoding = tg.encode_tcrs_a(data)
if chain == "b":
  encoding = tg.encode_tcrs_b(data)
if chain == "ab":
  encoding = tg.encode_tcrs(data)
print(f"\t### Computing Approximate TCRdist({max_dist},{chain}):")

csr_dists_max_dist = tg.compute_csr_experimental(encoding, encoding, max_dist=max_dist)
print("After Burn-In")
csr_dists_max_dist = tg.compute_csr_experimental(encoding, encoding, max_dist=max_dist)

tg.mode = 'cpu'

print("#####")
print("Use CPU instead")
tg = TCRgpu(mode='cpu',  # If you only have a cpu set mode to "cpu"
            chunk_size=100,  # Limit rows processed at once to prevent RAM overflow
            cdr3a_col='cdr3_a_aa',
            cdr3b_col='cdr3_b_aa',
            va_col='v_a_gene',
            vb_col='v_b_gene')

print(f"\t### Encoding based on chains: {chain}:")
if chain == "a":
  encoding = tg.encode_tcrs_a(data)
if chain == "b":
  encoding = tg.encode_tcrs_b(data)
if chain == "ab":
  encoding = tg.encode_tcrs(data)
print(f"\t### Computing Approximate TCRdist({max_dist},{chain}):")
csr_dists_max_dist = tg.compute_csr_experimental(encoding, encoding, max_dist=max_dist)
PY
