#!/usr/bin/env bash

cd '/Applications/Houdini/Houdini17.0.416/Frameworks/Houdini.framework/Versions/Current/Resources'; source ./houdini_setup; cd -

# ---------------------- #
# Setup render variables #
# ---------------------- #
echo "Filename: $0"
echo "Process ID: $$"
echo "-------------------------------"
echo "Passed argument 1: $1"
echo "Passed argument 2: $2"
echo "Passed argument 3: $3"
echo "Passed argument 4: $4"

if [ "$#" -eq  "0" ]
  then
    echo "No arguments supplied"
    export DIR="/Volumes/CalDigit T3 6TB/Fishing With Dynamite/Anim 4 Share of Stock/"
    export hip_file="Anim 4 model 04.hip"
    export batchStartFrame=133
    export batchEndFrame=724
    export burn_timecode=N
  else
    echo "Using passed file"
    export DIR="$(dirname "$1")"
    export hip_file="$(basename "$1")"
    export batchStartFrame=$2
    export batchEndFrame=$3
    export burn_timecode=$4
fi
echo "Hip directory: $DIR"
echo "hip file: $hip_file"
export rop_path="/out/Redshift_ROP1"

export batchsize=100
export increment=2
export threads=12
export GPU="01"

echo -e "\n\n\n****\n\n\n"

export outputdir="$DIR/render/"
outputextension=".exr"

mostrecent=$(ls -tc "$outputdir" | head -2 | grep -i ".*.$outputextension$")
echo -e "--- BULKRENDER:  The most recently rendered $outputextension image in the output dir ($outputdir) is:\n\n$mostrecent\n"

mkdir -p "$outputdir"
open "$outputdir"
echo "$outputdir"

cd ~/Documents/GitHub/redshift_houdini_bulk_render

echo "now starting redshift_render.command"
# ------------------------------------ #
# Make a series of frame ranges here   #
# ------------------------------------ #

# have 2nd GPU start 1 frame after first GPU
startframe2=$(($batchStartFrame + 1))
# The actual render loops -----
source redshift_render.command $batchStartFrame $batchEndFrame "$hip_file" "$rop_path" $increment 10 & \
sleep 25; source redshift_render.command $startframe2 $batchEndFrame "$hip_file" "$rop_path" $increment 01

# Batch complete
echo "BULKRENDER: Now ending redshift_render.command"
