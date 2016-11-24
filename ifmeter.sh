#!/bin/bash
# version 1.1
# author Yu-Jung Cheng

#set -o nounset
set -o errexit


######################################################################
# default setting
######################################################################

QUEUE_SIZE=10
UNIT_DIVISION=1
UNIT_STRING="(Bytes/s)"
OUTPUT_FILE=""
INTERFACE=""
DURATION=0
STATISTIC=false
SLEEP_INTERVAL=0.99  # second

######################################################################
# declaration
######################################################################

declare -A BYTES_TRANSMIT
declare -A BYTES_RECEIVE
declare -A INTERFACE_NAME


######################################################################
# function
######################################################################

function print_help_message() {
  echo "Command Parameter Usage:"
  echo "  -k : display unit as KB per second. "
  echo "  -m : display unit as MB per second. "
  echo "  -s : display statistic of TX/RX bytes."
  echo "  -o=<file path> :"
  echo "      output records to <file path>."
  echo "  -i=<name> :"
  echo "      show <interface name> only. (regular expression)"
  echo "  -t=<seconds> :"
  echo "      exit after <seconds>."
  echo "  -q=<size> :"
  echo "      set queue size for keeping bandwidth data."
  echo "      $QUEUE_SIZE by default"
}

# output name, rx byte, rx packet, tx byte, tx packet
function get_net_data() {
  local grep_interface=${INTERFACE}

  net_bytes=`cat /proc/net/dev | \
            grep -v "Inter-\|face" | \
            grep "${grep_interface}" | \
            sed 's/:/ /g' | \
            awk '{print $1,$2,$3,$10,$11}'`
  echo "$net_bytes"
}

function put_net_data() {
  INTERFACE_NAME[$i,$j]=${net_data_array[$j]}
  BYTES_RECEIVE[$i,$j]=${net_data_array[$j+1]}
  BYTES_TRANSMIT[$i,$j]=${net_data_array[$j+3]}
}

function get_space() {
  stringLength=`expr length $1`
  spaceNeed=`expr $2 - $stringLength`
  spaceString=`seq 1 $spaceNeed | sed 's/.*/ /' | tr -d '\n'`
  echo "${spaceString}"
}

function convert_bw_unit() {
  echo `printf "%20.3f" $(echo "scale=3;$1/$UNIT_DIVISION"|bc)`;
}

function parser_argument() {

  for argument in "$@"
  do
    case $argument in
      -[k])
        UNIT_DIVISION=1024
        UNIT_STRING="(KB/s)   "
        ;;
      -[m])
        UNIT_DIVISION=1048576
        UNIT_STRING="(MB/s)   "
        ;;
      -[h])
        print_help_message
        exit
        ;;
      -[s])
        STATISTIC=true
        ;;
      -i=*)
        INTERFACE=${argument##-i=}
        ;;
      -o=*)
        OUTPUT_FILE=${argument##-o=}
        > $OUTPUT_FILE
        ;;
      -t=*)
        DURATION=${argument##-t=}
        if [[ $DURATION != ?(-)+([0-9]) || $DURATION == 0 ]]; then
          echo "Invalid duration value! ($DURATION)"
          exit
        fi

        ;;
      -q=*)
        QUEUE_SIZE=${argument##-q=}
        if [[ $QUEUE_SIZE != ?(-)+([0-9]) || $QUEUE_SIZE == 0 ]]; then
          echo "Invalid queue size! ($QUEUE_SIZE)"
          exit
        fi
        ;;
      *)
        echo "Unknow argument! ($argument)"
        exit
        ;;
    esac
  done
}

######################################################################
# main script execution
######################################################################

parser_argument "$@"
begin_timestamp=`date +%s`

for ((i=0; i<$QUEUE_SIZE; i=i+1))
do
  net_data=$(get_net_data)
  net_data_array=(${net_data// / })
  for ((j=0; j<${#net_data_array[@]}; j=j+5))
  do
    put_net_data $net_data_array $i $j
  done
done


for ((i=0; i<$QUEUE_SIZE; i=i+1))
do
  clear
  echo "Interface       Receive$UNIT_STRING     Transmit$UNIT_STRING"
  echo "====================================================="

  time=`date +%Y-%m-%d:%H:%M:%S`

  net_data=$(get_net_data)
  net_data_array=(${net_data// / })

  for ((j=0; j<${#net_data_array[@]}; j=j+5))
  do
    put_net_data $net_data_array $i $j

    f=$(($i+1))
    if [ $f -eq $QUEUE_SIZE ] ; then
      f=0;
    fi

    ifname=${INTERFACE_NAME[$i,$j]}
    rx=$(((${BYTES_RECEIVE[$i,$j]}-${BYTES_RECEIVE[$f,$j]})/$QUEUE_SIZE))
    tx=$(((${BYTES_TRANSMIT[$i,$j]}-${BYTES_TRANSMIT[$f,$j]})/$QUEUE_SIZE))

    rx=`printf "%20.3f" $(echo "scale=3;$rx/$UNIT_DIVISION"|bc)`;
    tx=`printf "%20.3f" $(echo "scale=3;$tx/$UNIT_DIVISION"|bc)`;

    rx=${rx// /}
    tx=${tx// /}

    printf "%-15s %-20s %-20s\n" $ifname $rx $tx

    if [[ $OUTPUT_FILE != "" ]]; then
      echo $time $ifname $rx $tx >> $OUTPUT_FILE
    fi
  done

  if [[ $DURATION != 0 ]]; then
    current_timestamp=`date +%s`
    time_passed=$((current_timestamp - begin_timestamp))
    if [[ $time_passed -ge $DURATION ]]; then
      echo -e "\nExit at $time"
      exit
    fi
    time=$time", exit after $((DURATION - time_passed)) seconds."
  fi

  echo -e "\n$time"
  sleep ${SLEEP_INTERVAL}

  if [ $i -eq $((${QUEUE_SIZE}-1)) ]; then
    i=-1
  fi

done
