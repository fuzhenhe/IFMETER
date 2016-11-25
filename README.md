# ifmeter
Bash Script for Monitoring Interface Bandwidth Usage

root@ceph:~# ./ifmeter_v1.1.sh -h
Command Parameter Usage:
  -k : display unit as KB per second. 
  -m : display unit as MB per second. 
  -s : display statistic of TX/RX bytes.
  -o=<file path> :
      output records to <file path>.
  -i=<name> :
      show <interface name> only. (regular expression)
  -t=<seconds> :
      exit after <seconds>.
  -q=<size> :
      set queue size for keeping bandwidth data.
      10 by default


root@ceph:~# ./ifmeter_v1.1.sh
Interface       Receive(Bytes/s)     Transmit(Bytes/s)
=====================================================
lo              72.000               72.000              
ens10           15.000               0.000               
ens4            15.000               0.000               
ens3            698.000              861.000             

2016-11-25:17:08:09
