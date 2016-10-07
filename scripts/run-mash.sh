#!/bin/bash

set -u

# 
# Argument defaults
# 
BIN="$( readlink -f -- "${0%/*}" )"
if [ -f $BIN ]; then
  BIN=$(dirname $BIN)
fi
export PATH=$BIN:$PATH

ALIAS_FILE=""
EUC_DIST_PERCENT=0.1
IN_DIR=""
METADATA_FILE=""
NUM_GBME_SCANS="50000"
OUT_DIR="$BIN/mash-out"
SAMPLE_DIST=1000
BAR="# ----------------------"

#
# Functions
#
function lc() {
  wc -l $1 | cut -d ' ' -f 1
}

function HELP() {
  printf "Usage:\n  %s -i IN_DIR -o OUT_DIR\n\n" $(basename $0)

  echo "Required Arguments:"
  echo " -i IN_DIR (FASTA files)"
  echo 
  echo "Options"
  echo " -a ALIAS_FILE (none)"
  echo " -e EUC_DIST_PERCENT ($EUC_DIST_PERCENT)"
  echo " -o OUT_DIR ($OUT_DIR)"
  echo " -l FILES_LIST (none)"
  echo " -m METADATA_FILE (none)"
  echo " -s SAMPLE_DIST ($SAMPLE_DIST)"
  echo
  exit 0
}

if [[ $# == 0 ]]; then
  HELP
fi

#
# Setup
#
PROG=$(basename "$0" ".sh")

echo $BAR
echo "Invocation: $0 $@"

#
# Get args
#
while getopts :a:e:i:l:m:o:s:h OPT; do
  case $OPT in
    a)
      ALIAS_FILE="$OPTARG"
      ;;
    e)
      EUC_DIST_PERCENT="$OPTARG"
      ;;
    i)
      IN_DIR="$OPTARG"
      ;;
    h)
      HELP
      ;;
    m)
      METADATA_FILE="$OPTARG"
      ;;
    n)
      NUM_GBME_SCANS="$OPTARG"
      ;;
    o)
      OUT_DIR="$OPTARG"
      ;;
    s)
      SAMPLE_DIST="$OPTARG"
      ;;
    h)
      HELP
      ;;
    o)
      OUT_DIR="$OPTARG"
      ;;
    s)
      SAMPLE_DIST="$OPTARG"
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      exit 1
      ;;
    \?)
      echo "Error: Invalid option: -${OPTARG:-""}"
      exit 1
  esac
done

#
# Check args
#
if [[ ${#IN_DIR} -lt 1 ]]; then
  echo "Error: No IN_DIR specified."
  exit 1
fi

if [[ ${#OUT_DIR} -lt 1 ]]; then
  echo "Error: No OUT_DIR specified."
  exit 1
fi

if [[ ! -d $IN_DIR ]]; then
  echo "Error: IN_DIR \"$IN_DIR\" does not exist."
  exit 1
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

# 
# Find input files
# 
FASTA_FILES=$(mktemp)
find $IN_DIR -type f > $FASTA_FILES
NUM_FILES=$(lc $FASTA_FILES)

if [ $NUM_FILES -lt 1 ]; then
  echo "Error: Found no files in IN_DIR \"$IN_DIR\""
  exit 1
fi

echo $BAR                       
echo Settings for run:          
echo "IN_DIR     $IN_DIR" 
echo "OUT_DIR       $OUT_DIR"   
echo $BAR                       
echo "Will process $NUM_FILES FASTA files"
cat -n $FASTA_FILES

#
# Sketch files
#
SKETCH_DIR="$OUT_DIR/sketches"
if [[ ! -d $SKETCH_DIR ]]; then
  mkdir -p $SKETCH_DIR
fi

i=0
while read FILE; do
  let i++
  BASENAME=$(basename $FILE)
  SKETCH=$SKETCH_DIR/$BASENAME 

  printf "%3d: %s\n" $i $BASENAME

  if [[ -s "${SKETCH}.msh" ]]; then
    echo "SKETCH \"$SKETCH\" exists, skipping."
  else
    mash sketch -p 12 -o $SKETCH $FILE
  fi
done < $FASTA_FILES
rm $FASTA_FILES

SKETCHES=$(mktemp)
find $SKETCH_DIR -type f -name \*.msh > $SKETCHES

#
# Paste
#
ALL=$OUT_DIR/all
if [[ -e $ALL.msh ]]; then
  rm $ALL.msh
fi

#
# Make SNA dir
#
SNA_DIR="$OUT_DIR/sna"
if [[ ! -d $SNA_DIR ]]; then
  mkdir -p $SNA_DIR
fi

mash paste -l $ALL $SKETCHES
ALL=$ALL.msh
DISTANCE_MATRIX="$SNA_DIR/dist.tab"
mash dist -t $ALL $ALL > $DISTANCE_MATRIX
rm $ALL

#
# Handle metadata (optional)
#
if [[ -e $METADATA_FILE ]]; then
  echo ">>> make-metadata-dir.pl"
  META_DIR="$OUT_DIR/meta"
  make-metadata-dir.pl -f $METADATA_FILE -d $META_DIR --eucdistper $EUC_DIST_PERCENT --sampledist $SAMPLE_DIST
fi

ALIAS_FILE_ARG=""
if [[ ${#ALIAS_FILE} -gt 0 ]]; then
  ALIAS_FILE_ARG="-a $ALIAS_FILE"
fi

# this will create the inverted matrix

echo ">>> viz.r"
$BIN/viz.r -f "$DISTANCE_MATRIX" -o "$SNA_DIR" $ALIAS_FILE_ARG

MATRIX="$SNA_DIR/matrix.tab"

if [[ ! -s "$MATRIX" ]]; then
  echo "viz.R failed to create \"$MATRIX\"" 
  exit 1
fi

echo ">>> sna.r"
$BIN/sna.r -o "$OUT_DIR/sna" -f "$MATRIX" -n $NUM_GBME_SCANS $ALIAS_FILE_ARG

for FILE in Z Rplots.pdf gbme.out; do
  if [[ -e "$SNA_DIR/$FILE" ]]; then
    rm "$SNA_DIR/$FILE"
  fi
done

echo Done.
