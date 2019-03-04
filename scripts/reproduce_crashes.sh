#!/bin/sh

Usage() {
	cat <<EOF
Usage:
	$(basename $0) [OPTIONS]

	Options:
		-h
			this help message
		-s
			adb serial number
		-i
			crash collections directory
		-a
			Android source top directory
EOF

	exit 1
}

ANDROID_TOP="."
INPUT=collections
GDB_FILE=/tmp/gdb.script
ANDROID_DATA_TMP=/data/local/tmp
GDB_LOG=/tmp/uniq_gdb_bt
FINAL_LOG=/tmp/final_log
rm -rf $GDB_LOG $FINAL_LOG

while getopts "hs:a:i:" o; do
	case "$o" in
		a) ANDROID_TOP="$OPTARG";;
		h) Usage;;
		s) SERIAL_NUMBER="$OPTARG";;
		i) INPUT="$OPTARG";;
	esac
done
shift $((OPTIND-1))

if [ "$SERIAL_NUMBER" != "" ]; then
	adb -s $SERIAL_NUMBER shell su root "sh -c \"echo 0 > /proc/sys/kernel/randomize_va_space\""
	adb -s $SERIAL_NUMBER shell su root "rm -rf $ANDROID_DATA_TMP/$(basename $INPUT)"
	adb -s $SERIAL_NUMBER shell mkdir $ANDROID_DATA_TMP/$(basename $INPUT)
	adb -s $SERIAL_NUMBER push $INPUT $ANDROID_DATA_TMP
fi

if [ "$SERIAL_NUMBER" != "" ]; then
# Remove normal exited corpus
for i in $(adb -s $SERIAL_NUMBER shell su root ls $ANDROID_DATA_TMP/$(basename $INPUT)); do
	adb -s $SERIAL_NUMBER shell su root "sh -c \"export LD_LIBRARY_PATH=$ANDROID_DATA_TMP; $ANDROID_DATA_TMP/afl-mmparser $ANDROID_DATA_TMP/$(basename $INPUT)/$i && [ "$?" == "0" ] && rm -rf $ANDROID_DATA_TMP/$(basename $INPUT)/$i;\"" 1>/dev/null 2>/dev/null
done

# exploitable abnormal exited corpus
for i in $(adb -s $SERIAL_NUMBER shell su root ls $ANDROID_DATA_TMP/$(basename $INPUT)); do
	echo "==== $i ====" | tee -a $GDB_LOG
	echo "source ~/workspace/exploitable/exploitable/exploitable.py" > $GDB_FILE
	echo "file $ANDROID_TOP/out/target/product/generic_x86_64/obj/EXECUTABLES/afl-mmparser_intermediates/LINKED/afl-mmparser" >> $GDB_FILE
	echo "target remote :1234" >> $GDB_FILE
	echo "c" >> $GDB_FILE
	echo "bt" >> $GDB_FILE
	echo "exploitable" >> $GDB_FILE
	echo "quit" >> $GDB_FILE

	adb -s $SERIAL_NUMBER shell su root "sh -c \"export LD_LIBRARY_PATH=$ANDROID_DATA_TMP; gdbserver64 :1234 $ANDROID_DATA_TMP/afl-mmparser $ANDROID_DATA_TMP/$(basename $INPUT)/$i\"" 1>/dev/null 2>/dev/null &
	sleep 1
	gdb -q < $GDB_FILE 2>&1 1>>$GDB_LOG
	echo
	sleep 1
done
fi

rm -rf $GDB_FILE

python3 $(dirname $0)/parse_gdb_crash_log.py $GDB_LOG | tee $FINAL_LOG

echo
echo "==================== Final crash reports ===================="
cat $FINAL_LOG

rm -rf $GDB_LOG $FINAL_LOG
