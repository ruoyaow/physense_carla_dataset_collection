import os
import webdataset as wds

SRC = "/path/to/raw/dataset"     # contains Town01_Opt/...
OUT = "/path/to/output/dir"   # output directory
os.makedirs(OUT, exist_ok=True)

def iter_leaf_folders(root):
    # yields folders that contain data files
    for dirpath, _, filenames in os.walk(root):
        if any(fn.endswith(".png") for fn in filenames):
            yield dirpath, filenames

pattern = os.path.join(OUT, "physense_carla_dataset-%06d.tar")

with wds.ShardWriter(pattern, maxsize=1_000_000_000) as sink:  # ~1GB shards
    for dirpath, filenames in iter_leaf_folders(SRC):
        pngs = {fn[:-4] for fn in filenames if fn.endswith(".png")}
        jsons = {fn[:-5] for fn in filenames if fn.endswith(".json")}
        keys = sorted(pngs & jsons)

        # make a stable prefix from the relative folder name
        rel = os.path.relpath(dirpath, SRC).replace(os.sep, "_")

        for k in keys:
            png_path = os.path.join(dirpath, k + ".png")
            js_path  = os.path.join(dirpath, k + ".json")

            with open(png_path, "rb") as f:
                img_bytes = f.read()
            with open(js_path, "rb") as f:
                meta_bytes = f.read()

            sample_key = f"{rel}_{k}"  # avoids collisions across folders

            sink.write({
                "__key__": sample_key,
                "png": img_bytes,
                "json": meta_bytes,
            })
