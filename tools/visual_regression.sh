#!/bin/bash
# This script runs a visual regression test on all the images
# generated by the VexFlow tests.
#
# Prerequisites: librsvg, ImageMagick
#    * ImageMagick's SVG parsing is broken, which is why we use librsvg.
#
# On OSX:   $ brew install librsvg imagemagick
# On Linux: $ apt-get install librsvg2-dev librsvg2-bin imagemagick
#
# Usage:
#
#  First generate the SVG images from the tests into build/images.
#
#    $ ./tools/generate_svg_images.js
#
#  Run the regression tests against the blessed images in tests/blessed.
#
#    $ ./tools/visual_regression.js [test_prefix]
#
#  Check build/images/diff/results.txt for results. This file is sorted
#  by PHASH difference (most different files on top.) The composite diff
#  images for failed tests (i.e., PHASH > 1.0) are stored in build/images/diff.
#
#  If you are satisfied with the differences, copy *.svg from build/images
#  into tests/blessed, and submit your change.

# PNG viewer on OSX. Switch this to whatever your system uses.
# VIEWER=open

# Show images over this PHASH threshold. This is probably too low, but
# a good first pass.
THRESHOLD=0.01

# Directories. You might want to change BASE, if you're running from a
# different working directory.
BASE=.
BLESSED=$BASE/build/images/blessed
CURRENT=$BASE/build/images/current
DIFF=$BASE/build/images/diff

# All results are stored here.
RESULTS=$DIFF/results.txt
WARNINGS=$DIFF/warnings.txt

mkdir -p $DIFF
if [ -e "$RESULTS" ]
then
  rm $DIFF/*
fi
touch $RESULTS
touch $RESULTS.pass
touch $RESULTS.fail
touch $WARNINGS

# If no prefix is provided, test all images.
if [ "$1" == "" ]
then
  files=*.svg
else
  files=$1*.svg
fi

if [ "`basename $PWD`" == "tools" ]
then
  echo Please run this script from the VexFlow base directory.
  exit 1
fi

# Number of simultaneous jobs
nproc=$(sysctl -n hw.physicalcpu 2> /dev/null || nproc)
if [ -n "$NPROC" ]; then
  nproc=$NPROC
fi

total=`ls -l $BLESSED/$files | wc -l | sed 's/[[:space:]]//g'`

echo "Running $total tests with threshold $THRESHOLD..."

function ProgressBar {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

function diff_image() {
  local image=$1
  local name=`basename $image .svg`
  local blessed=$BLESSED/$name.svg
  local current=$CURRENT/$name.svg
  local diff=$current-temp

  if [ ! -e "$current" ]
  then
    echo "Warning: $name.svg missing in $CURRENT." >$diff.warn
    return
  fi

  if [ ! -e "$blessed" ]
  then
    return
  fi

  # Generate PNG images from SVG
  rsvg-convert $blessed >$diff-a.png
  rsvg-convert $current >$diff-b.png

  # Calculate the difference metric and store the composite diff image.
  local hash=`compare -metric PHASH -highlight-color '#ff000050' $diff-b.png $diff-a.png $diff-diff.png 2>&1`

  isGT=`echo "$hash > $THRESHOLD" | bc -l`
  if [ "$isGT" == "1" ]
  then
    # Add the result to results.text
    echo $name $hash >$diff.fail
    # Threshold exceeded, save the diff and the original, current
    cp $diff-diff.png $DIFF/$name.png
    cp $diff-a.png $DIFF/$name'_'Blessed.png
    cp $diff-b.png $DIFF/$name'_'Current.png
    echo
    echo "Test: $name"
    echo "  PHASH value exceeds threshold: $hash > $THRESHOLD"
    echo "  Image diff stored in $DIFF/$name.png"
    # $VIEWER "$diff-diff.png" "$diff-a.png" "$diff-b.png"
    # echo 'Hit return to process next image...'
    # read
  else
    echo $name $hash >$diff.pass
  fi
  rm -f $diff-a.png $diff-b.png $diff-diff.png
}

function wait_jobs () {
  local n=$1
  while [[ "$(jobs -r | wc -l)" -ge "$n" ]] ; do
     # echo ===================================== && jobs -lr
     # wait the oldest job.
     local pid_to_wait=`jobs -rp | head -1`
     # echo wait $pid_to_wait
     wait $pid_to_wait  &> /dev/null
  done
}

count=0
for image in $CURRENT/$files
do
  count=$((count + 1))
  ProgressBar ${count} ${total}
  wait_jobs $nproc
  diff_image $image &
done
wait

cat $CURRENT/*.warn 1>$WARNINGS 2>/dev/null
rm -f $CURRENT/*.warn

## Check for files newly built that are not yet blessed.
for image in $CURRENT/$files
do
  name=`basename $image .svg`
  blessed=$BLESSED/$name.svg
  current=$CURRENT/$name.svg

  if [ ! -e "$blessed" ]
  then
    echo "  Warning: $name.svg missing in $BLESSED." >>$WARNINGS
  fi
done

num_warnings=`cat $WARNINGS | wc -l`

cat $CURRENT/*.fail 1>$RESULTS.fail 2>/dev/null
num_fails=`cat $RESULTS.fail | wc -l`
rm -f  $CURRENT/*.fail

# Sort results by PHASH
sort -r -n -k 2 $RESULTS.fail >$RESULTS
sort -r -n -k 2 $CURRENT/*.pass 1>>$RESULTS 2>/dev/null
rm -f $CURRENT/*.pass $RESULTS.fail $RESULTS.pass

echo
echo Results stored in $DIFF/results.txt
echo All images with a difference over threshold, $THRESHOLD, are
echo available in $DIFF, sorted by perceptual hash.
echo

if [ "$num_warnings" -gt 0 ]
then
  echo
  echo "You have $num_warnings warning(s):"
  cat $WARNINGS
fi

if [ "$num_fails" -gt 0 ]
then
  echo "You have $num_fails fail(s):"
  head -n $num_fails $RESULTS
else
  echo "Success - All diffs under threshold!"
fi
