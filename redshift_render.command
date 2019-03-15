#!/usr/bin/env bash

echo -e "==========  Now entering RSRender script ===============\n\n"

cd '/Applications/Houdini/Houdini17.0.416/Frameworks/Houdini.framework/Versions/Current/Resources'; source ./houdini_setup; cd -

echo "Filename: $0"
echo "Process ID: $$"
echo "-------------------------------"

echo -e "\n\n\n1***"
export startFrame="$1"
export endFrame="$2"
export hip_file=$3
export rop_path=$4
export increment=$5
export GPU=$6

export videostart=$batchStartFrame

difference=$(expr "$endFrame" - "$startFrame")
groups=$(expr "$difference" / "$batchsize")
echo "processing $difference frames into $groups groups of $batchsize"
# cycle thorugh each group and echo the frame start and endFrame

#What to show in terminal window
search1="scene extraction time .*sec"
search2="render started for .*\d"
search3="available memory: .*\d"
search4="Rendering frame .*\d..."
search5="ROP node .* sec"
search6="CURRENTLY"
#grep -i -E --line-buffered "$search1|$search2|$search3|$search4|$search5|$search6"

echo "=================================================================="

# ------------------------------------------------ #
# show various frame ranges that will be processed #
# ------------------------------------------------ #

for i in $(eval echo {0..$groups})
do
  rangeoffset="$(expr "$i" \* "$batchsize")"
  rangeStart="$(expr "$startFrame" + "$rangeoffset")"
  rangeEnd="$(expr "$startFrame" + "$rangeoffset" + "$batchsize" - "1")"
  batchnum="$(expr "$i" + "1")"
  if [ "$rangeEnd" -gt "$endFrame" ] #clamp to end frame of range
  then
    rangeEnd=$endFrame
  fi
  echo "RSRENDER: batch $batchnum: Start: $rangeStart End: $rangeEnd"
done

# ---------------------------- #
# main frame batch render loop #
# ---------------------------- #

echo "**** BREAK ****"
for i in $(eval echo {0..$groups})
do
  rangeoffset="$(expr "$i" \* "$batchsize")"
  rangeStart="$(expr "$startFrame" + "$rangeoffset")"
  rangeEnd="$(expr "$startFrame" + "$rangeoffset" + "$batchsize" - "1")"
  if [ "$rangeEnd" -gt "$endFrame" ] #clamp to end frame of range
  then
    rangeEnd=$endFrame
  fi

  batchnum="$(expr "$i" + "1")"

  echo "===================== Begin Rendering Batch $batchnum ====================="

  # ---------------------------------------------------- #
  # When a batch is done send an email message to myself #
  # ---------------------------------------------------- #

  MESSAGE="***$hip_file*** $rop_path frames:$rangeStart-$rangeEnd batch $batchnum GPU $GPU"
  #MESSAGE="***$rop_path*** frames:$startFrame-$endFrame batch $batchnum"
  RECIPIENT="jonah@jonahtobias.com"
  SUBJECT="Completed batch $batchnum"
  printf -v paddedframe "%04d" $rangeEnd
  inputfilename="Scene21_$paddedframe.exr"
  #echo "Texting '$MESSAGE' to '$RECIPIENT'"


  # ------------------------------- #
  # change terminal title bar (OSX) #
  # ------------------------------- #

  echo -n -e "\033]0;***$rop_path*** frames:$rangeStart-$rangeEnd batch $batchnum GPU $GPU\007"

  # ---------------------------------------------- #
  # send render command and Filter terminal output #
  # ---------------------------------------------- #
  command="hbatch '$DIR/$hip_file' -j $threads -c 'Redshift_setGPU -s $GPU;render -f $rangeStart $rangeEnd -i $increment -s $rop_path -V1;quit();'"
echo -e "************** Executing Hbatch *********\n\n"
echo "redshift_render: $command"
  eval $command #| grep -i  "Render"
echo -e "************** Batch $batchnum complete *********\n\n"

# -------------------------------------------------- #
# email self last frame from the just finished batch #
# -------------------------------------------------- #

echo -e "************** redshift_render -- email self last frame from batch *******\n\n"
echo -e "redshift_render: Emailing self $outputdir$mostrecent\n\n"
  #outputdir="/Volumes/CalDigit T3 6TB/Fishing With Dynamite/Character Shareholder/render/HQ/"
  inputextension=".exr"
  outputextension=".jpg"

  mostrecent=$(ls -tc "$outputdir" | head -2 | grep -i ".*.$inputextension$")
  echo -e "redshift_render: --- The most recently rendered $inputextension image in the output dir ($outputdir) is: $mostrecent \n\n"

  echo -e "redshift_render: About to convert $outputdir$mostrecent to a $outputextension"
      convert  "$outputdir$mostrecent" -colorspace RGB +repage -define exr:color-type=Y -resize 30% -colorspace sRGB "$outputdir$mostrecent$outputextension" && osascript applescriptemail.scpt "$MESSAGE" "$outputdir$mostrecent$outputextension"
done
