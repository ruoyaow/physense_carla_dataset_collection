#!/usr/bin/env bash
set -euo pipefail

CARLA_CMD="../CarlaUE4.sh" 
# Change DATASET_DIR to your target directory for dataset collection
DATASET_DIR="/path/to/dataset"
mkdir -p logs

format_time() {
    local T=$1
    local H=$(( T / 3600 ))
    local M=$(( (T % 3600) / 60 ))
    local S=$(( T % 60 ))

    if (( H > 0 )); then
        printf "%02dh:%02dm:%02ds" "$H" "$M" "$S"
    else
        printf "%02dm:%02ds" "$M" "$S"
    fi
}


run_for_map() {
    local MAP_NAME="$1"
    local WEATHER_NAME="$2"
    local SEED="$3"
    local SEEDW="$4"
    local ADDITIONAL_NAME="$5"
    
    echo "======================================="
    echo "Starting CarlaUE4 for map: $MAP_NAME with weather: $WEATHER_NAME"
    echo "======================================="
    
    echo "Launching CarlaUE4..."
    $CARLA_CMD > "logs/carla_launch.log" 2>&1 &
    
    echo "Waiting 10 seconds for CarlaUE4 to finish loading..."
    sleep 10

    echo "Running: python util/config.py --map $MAP_NAME --weather $WEATHER_NAME"
    python util/config.py --map "$MAP_NAME"
    python util/config.py --reload-map
    python util/config.py --weather "$WEATHER_NAME"
    sleep 1

    echo "Running: python dump_syn_traffic.py --path $DATASET_DIR --map $MAP_NAME --weather ${ADDITIONAL_NAME}_${WEATHER_NAME} --seed $SEED --seedw $SEEDW"
    python dump_syn_traffic.py --path "$DATASET_DIR" --map "$MAP_NAME" --weather "${ADDITIONAL_NAME}_${WEATHER_NAME}" --seed "$SEED" --seedw "$SEEDW"

    echo "Completed data collection for map: $MAP_NAME with weather: $WEATHER_NAME, killing CarlaUE4 process."

    pkill -f 'UE4'
    sleep 1
    pkill -f 'UE4'
}

WEATHER_LIST=("ClearNight" "ClearNoon" "ClearSunset" "CloudyNight" "CloudyNoon" "CloudySunset" "MidRainSunset" "MidRainyNight" "MidRainyNoon" "WetNight" "WetNoon" "WetSunset")
MAP_LIST=("Town01_Opt" "Town02_Opt" "Town04_Opt" "Town05_Opt" "Town06" "Town07")

RUNS_NUM=2000
START_SEED=42
START_SEEDW=24

RUNNED_NUM=0
START_TS=$(date +%s)

for ((i=0; i<RUNS_NUM; i++)); do
    MAP_INDEX=$(( i % ${#MAP_LIST[@]} ))
    for ((j=0; j<${#WEATHER_LIST[@]}; j++)); do
        map="${MAP_LIST[$MAP_INDEX]}"
        weather="${WEATHER_LIST[$j]}"
        
        run_for_map "$map" "$weather" $((START_SEED + RUNNED_NUM)) $((START_SEEDW + RUNNED_NUM)) "$RUNNED_NUM" >> "logs/script_${map}_${RUNNED_NUM}_${weather}.log" 2>&1
        # If process crashed, modify these lines to resume collection
        # if (( RUNNED_NUM >= 1904 )); then
        #     run_for_map "$map" "$weather" $((START_SEED + RUNNED_NUM)) $((START_SEEDW + RUNNED_NUM)) "$RUNNED_NUM" >> "logs/script_${map}_${RUNNED_NUM}_${weather}.log" 2>&1
        # fi


        RUNNED_NUM=$(( RUNNED_NUM + 1 ))

        # progress in percent (integer)
        percent=$(( RUNNED_NUM * 100 / RUNS_NUM ))

        # time bookkeeping
        now=$(date +%s)
        elapsed=$(( now - START_TS ))

        if (( RUNNED_NUM > 0 )); then
            remaining=$(( RUNS_NUM - RUNNED_NUM ))
            # avoid division by zero; integer math only
            if (( RUNNED_NUM > 0 )); then
                eta_seconds=$(( elapsed * remaining / RUNNED_NUM ))
            else
                eta_seconds=0
            fi
        else
            eta_seconds=0
        fi

        elapsed_str=$(format_time "$elapsed")
        eta_str=$(format_time "$eta_seconds")

        printf "\r[%4d/%4d] %3d%%  elapsed=%s  eta=%s  map=%s  weather=%s seed=%d seedw=%d" \
            "$RUNNED_NUM" "$RUNS_NUM" "$percent" \
            "$elapsed_str" "$eta_str" \
            "$map" "$weather" $((START_SEED + RUNNED_NUM - 1)) $((START_SEEDW + RUNNED_NUM - 1))

        if [ "$RUNNED_NUM" -ge "$RUNS_NUM" ]; then
            break
        fi
    done
    if [ "$RUNNED_NUM" -ge "$RUNS_NUM" ]; then
        break
    fi
done

echo
echo "All done."

