#!/system/bin/sh

Usage() {
  cat <<EOF

USAGE:
  $(basename $0) [OPTIONS]

  Options:
    -f
      afl_fuzz path, default ./afl_fuzz
    -b
      target binary path, required
    -j
      parallel jobs, default 1
    -m
      memory limit, default 50MB
    -t
      timeout, default 50ms
                -x
                        dict
    -h
      this help message
EOF

  exit 1
}

FUZZ="./afl-fuzz"
JOBS=1
MEMORY=50
TIMEOUT=50
INPUT=cases
timestamp=$(date +%Y%m%d-%H%M%S)
OUT="findings/$timestamp"

while getopts "hf:b:j:m:t:x:i:" o; do
  case "$o" in
    f) FUZZ="$OPTARG";;
    b) BINARY="$OPTARG";;
    j) JOBS="$OPTARG";;
    m) MEMORY="$OPTARG";;
    t) TIMEOUT="$OPTARG";;
    i) INPUT="$OPTARG";;
    x) DICT="$OPTARG";;
    h) Usage;;
  esac
done
shift $((OPTIND-1))

if [ "$BINARY" == "" ]; then
  echo "Missing option -b"
  Usage
fi

mkdir -p $OUT
chmod a+xr findings

if [[ $JOBS -gt 1 ]]; then
  for i in $(seq 1 $(expr $JOBS - 1)); do
    if [ "$DICT" != "" ]; then
      exec $FUZZ -i $INPUT -o $OUT -x $DICT -m $MEMORY -t $TIMEOUT -S s$i -- $BINARY @@ > $OUT/log-s$i &
    else
      exec $FUZZ -i $INPUT -o $OUT -m $MEMORY -t $TIMEOUT -S s$i -- $BINARY @@ > $OUT/log-s$i &
    fi
  done
  if [ "$DICT" != "" ]; then
    exec $FUZZ -i $INPUT -o $OUT -x $DICT -m $MEMORY -t $TIMEOUT -M master -- $BINARY @@
  else
    exec $FUZZ -i $INPUT -o $OUT -m $MEMORY -t $TIMEOUT -M master -- $BINARY @@
  fi
else
  if [ "$DICT" != "" ]; then
    exec $FUZZ -i $INPUT -o $OUT -x $DICT -m $MEMORY -t $TIMEOUT -- $BINARY @@
  else
    exec $FUZZ -i $INPUT -o $OUT -m $MEMORY -t $TIMEOUT -- $BINARY @@
  fi
fi
