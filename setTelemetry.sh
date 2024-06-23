#!/bin/sh
#*-------------------------------------------------------------------------
#* setTelemetry
#* Measure and put telemetry
#*-------------------------------------------------------------------------
#*-------------------------------------------------------------------------
#* getCPU
#* Get CPU load 
#*--------------- Requires apt-get install sysstat
#*-------------------------------------------------------------------------
getCPU () {

sar 1 3 | grep "Media:" | while read a ; do
 echo $a | awk '{print $3 + $4 + $5 + $6 + $7}';
done
}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getCPU () {
sar 1 3 | grep "Media:" | while read a ; do
 echo $a | awk '{print $3 + $4 + $5 + $6 + $7}';
done
}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getTemp () {

TEMP=$(vcgencmd measure_temp)
echo $TEMP | cut -f2 -d"=" | cut -f1 -d"'"

}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getVolt () {

VOLT=$(vcgencmd measure_volts | cut -f2 -d"=" | cut -f1 -d"V" )
VOLT=$(python -c "print ('%.2f' % ($VOLT*1.0))" )
echo $VOLT 

}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getClock () {

CLOCK=$(vcgencmd measure_clock arm | cut -f2 -d"=")
FX=$(python -c "print float($CLOCK)/1000000")
echo $FX

}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getStatus () {

STATUS=$(vcgencmd get_throttled)
echo $STATUS | cut -f2 -d"="

}
#+-----------------------------------------------------------------------------
#* Get telemetry from all major sub-systems
#*-----------------------------------------------------------------------------
getDASD () {
sudo df -k | grep "/dev/root" | awk '{ print $5 ; }' | cut -f1 -d"%"
}

#*--------------------------------------------------------------------------
#* putTelemetry 
#* Gather telemetry and assemble an information frame with it, log at Syslog
#*--------------------------------------------------------------------------

STATE="T($(getTemp)°C) V($(getVolt)V) Clk($(getClock)MHz) St($(getStatus)) CPU($(getCPU)%) DASD($(getDASD)%)" 
echo $STATE | logger -i -t "TLM"
echo $STATE 


