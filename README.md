# CARLA Dataset Collection

You can **directly use the released dataset from Hugging Face** without running CARLA:  
https://huggingface.co/datasets/Ruoyao/physense_carla_dataset

This repo provides steps/scripts to dump the synthetic dataset used in **PhySense** from CARLA via the CARLA PythonAPI (useful if you want to reproduce the dataset or generate new data).

## Contents

- `run.sh` — launches the data collection pipeline under your CARLA environment
- `dump_syn_traffic.py` — Python script that connects to CARLA and dumps synthetic traffic data
- `webdataset_convert.py` — *(optional)* convert dumped data into WebDataset shards

## Dataset & Paper

This dataset is released as part of **PhySense (CCS '24)**:

- **PhySense:** *Defending Physically Realizable Attacks for Autonomous Systems via Consistency Reasoning*  
  https://doi.org/10.1145/3658644.3690236

## Requirements

- **CARLA 0.9.15** (required)

Install CARLA 0.9.15 following the official instructions from the release page:  
https://github.com/carla-simulator/carla/releases/tag/0.9.15

> This setup assumes you use the `CARLA_0.9.15` directory layout from the official release.

## Setup

1. **Install CARLA 0.9.15**
   - Follow the installation steps from the link above.

2. **Copy scripts into CARLA PythonAPI**
   - Place the repo files into:
     ```
     CARLA_0.9.15/PythonAPI/
     ```
   - After copying, you should have:
     ```
     CARLA_0.9.15/
       PythonAPI/
         run.sh
         dump_syn_traffic.py
         webdataset_convert.py
         ...
     ```

3. **Set the dataset output directory**
   - Open `run.sh` and update `DATASET_DIR` to where you want the dataset saved, e.g.
     ```bash
     DATASET_DIR=/path/to/your/dataset/output
     ```

4. **Run data collection inside the CARLA environment**
   - Make `run.sh` executable (if needed):
     ```bash
     chmod +x run.sh
     ```
   - From `CARLA_0.9.15/PythonAPI`, run:
     ```bash
     ./run.sh
     ```

## Optional: Convert to WebDataset

If you want to convert the dumped dataset into **WebDataset** format (`.tar` shards), use `webdataset_convert.py`.

1. Install the dependency:
   ```bash
   pip install webdataset
   ```

2. Edit `webdataset_convert.py`:
   - Set `SRC` to the directory containing the dumped dataset
   - Set `OUT` to the target output directory for the WebDataset shards

3. Run the conversion:
   ```bash
   python webdataset_convert.py
   ```

## Notes / Tips

- If you use a virtual environment or conda environment for CARLA PythonAPI, activate it **before** running `run.sh`.

## Troubleshooting

- **`ModuleNotFoundError: carla`**
  - You’re likely not running under the CARLA PythonAPI environment or your `PYTHONPATH` is not set to CARLA’s PythonAPI.
  - Run `run.sh` from `CARLA_0.9.15/PythonAPI` and ensure your CARLA Python dependencies are installed.