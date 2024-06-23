#!/bin/sh
#//*========================================================================
#// tucSPA
#// 
#//
#// tucSPA {start|stop|lock|reset|restart|telemetry|sync|restore}
#//
#// Master housekeeping firmware for the tucSPA remote station site
#// See accompanying README file for a description on how to use this code.
#// License:
#//   This program is free software: you can redistribute it and/or modify
#//   it under the terms of the GNU General Public License as published by
#//   the Free Software Foundation, either version 2 of the License, or
#//   (at your option) any later version.
#//
#//   This program is distributed in the hope that it will be useful,
#//   but WITHOUT ANY WARRANTY; without even the implied warranty of
#//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#//   GNU General Public License for more details.
#//
#//   You should have received a copy of the GNU General Public License
#//   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#//*========================================================================
#// lu7dz: initial load
#*----------------------------------------------------------------------------
#* Initialization
#* DO NOT RUN EITHER AS A rc.local script nor as a systemd controlled service
#*----------------------------------------------------------------------------

DPATH="/home/pi/Downloads/ngrok-stable-linux-arm"
LOCK="tucSPA.lck"
VERSION="1.0"
PROCLIST='ngrok' 
NMAX=1
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
#*--------------------------------------------------------------------------
#* putTelemetry 
#* Gather telemetry and assemble an information frame with it, log at Syslog
#*--------------------------------------------------------------------------

putTelemetry () {

STATE="Telemetry: T($(getTemp)C) V($(getVolt)V) Clk($(getClock)MHz) St($(getStatus)) CPU($(getCPU)%) DASD($(getDASD)%)" 
echo $STATE 2>&1 | tee | logger -i -t "tucSPA"

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

#+-----------------------------------------------------------------------------
#* Kill all processes related to the housekeeping service
#*-----------------------------------------------------------------------------
killProcess () {

   echo "killProcess()" | logger -i -t "tucSPA"
#*--- Scan process list looking for wspr (transmission)
   for j in $PROCLIST
   do
      S=`ps -ef | pgrep $j`
      for i in $S; do
         echo "Killing $j PID("$i")" 2>&1 | logger -i -t "tucSPA"  
         sudo kill $i 2>&1 | logger -i -t "tucSPA"
      done
   done

#*--- Scan process list looking for ngrok


   P=`sudo ps ax | awk '! /awk/ && /ngrok/ { print $1}'`
   N=0

   for line in $P; do
       if [ $line -ne $$ ] 
       then
          echo " Killing ngrok PID("$line")" 2>&1 | logger -i -t "tucSPA"
          sudo kill $line 2>&1 | logger -i -t "tucSPA"
       fi
   done
}

#*--------------------------------------------------------------------------
#* Main Logic
#*--------------------------------------------------------------------------

#*---- Find number of instances running
cd $DPATH
PIDL=$(sudo ps --no-headers -C ngrok | awk '! /awk/ && /ngrok/ { print $1}')

N=0
for line in $PIDL; do
    if [ $line -ne $$ ] 
    then
       N=$(( $N + 1 ))
    fi
done
echo "Number of instances detected ($N)" 2>&1 | tee | logger -i -t "tucSPA"
CPU=$(getCPU)

#*---- React to argument (see tucSPA for command options)

case $1 in
#*=========================================================================================================================
#*---- Start the beacon. Control if instances are running and avoid reentrancy
#*=========================================================================================================================
        telemetry)
               putTelemetry
               exit 0
        ;;
	start)

#*---- If locked leave

               if [ -f $DPATH$LOCK ]; then
                  echo "Process lock found, terminating" 2>&1 | logger -i -t "tucSPA"
                  exit 0
               fi

#*---- If already running record telemetry and leave

               if [ $N \> $NMAX ]; then
                  putTelemetry
                  exit 0
               fi

#*---- Mark the beginning of the execution

               echo "Starting  Ver "$VERSION" P("$N") PID("$$") CPU($CPU %)" 2>&1 | logger -i -t "tucSPA"

#*---- Infinite loop processing the main ngrok port forwarding

               count=0
               while [ true ];  do

#*---- Collect and register telemetry

                  n=$(( $count % $EVERY ))
                  echo "Cycle ($count of $EVERY) n($n)" 2>&1 | logger -i -t "tucSPA"

#*---- Update monitoring slot

                 count=$(( $count + 1 ))
                 if [ $count -eq $EVERY ]; then
                    count=0
                 fi

               done
               echo "Port forward error abnormally terminated [$count/$EVERY]" 2>&1 | logger -i -t "tucSPA"

      	;;
#*=====================================================================================================================
#*---- Stop the beacon if an instance is found running
#*=====================================================================================================================
	stop)

               if [ $N \> $NMAX ]; then
                  echo "Port forwarding being stop" 2>&1 | logger -i -t "tucSPA"
                  killProcess 
               else
                  echo "No port forward daemon found, exit" 2>&1 | logger -i -t "tucSPA"
               fi
               exit 0
  	       ;;

#*=====================================================================================================================
#*---- Restart or  force-reload by stop and start (Miscellaneous operation functions)
#*=====================================================================================================================
	restart|force-reload)
                echo "Forcing reload" 2>&1 | logger -i -t "tucSPA"
                sudo $0 stop  2>&1 | logger -i -t "tucSPA"
                sudo $0 start 2>&1 | logger -i -t "tucSPA"
  		;;
#*---- Another alias to restart

	try-restart)
                echo "Trying to restart" 2>&1 | logger -i -t "tucSPA"
		if sudo $0 status >/dev/null; then
		   sudo $0 restart
		else
		   exit 0
		fi
		;;
#*---- Yet another alias to restart

	reload)
		sudo $0 restart
                exit 3
		;;
#*====================================================================================================
#*---- Stop the beacon and create a special lock file which will prevent further launches until reset
#*====================================================================================================
        lock)
                echo "Port forward lock established" 2>&1 | logger -i -t "tucSPA"
                sudo touch $DPATH$LOCK 2>&1 | logger -i -t "tucSPA"
                sudo $0 stop
                exit 4
                ;;
#*====================================================================================================
#*---- Erase the lock file and launch
#*====================================================================================================
        reset)
                echo "Port forward lock removed" 2>&1 | logger -i -t "tucSPA"
                sudo rm -r $DPATH$LOCK 2>&1 | logger -i -t "tucSPA"
                exit 3
                ;;
#*====================================================================================================
#*---- Marks log with special label (i.e. a change in the beacon)
#*====================================================================================================
	checkpoint)
                echo "tucSPA Log checkpoint" 2>&1 | logger -i -t "tucSPA"
                exit 0
                ;;


#*====================================================================================================
#*---- beacon status
#*====================================================================================================
	status)
                echo "tucSPA Process List Status N($N) NMAX($NMAX) Proc($PROCLIST)" 2>&1 | tee | logger -i -t "tucSPA"
                if [ "$N" -ge  "$NMAX" ]; then

#*---- instances of associated processes


                   echo "Process List" 2>&1 | logger -i -t "tucSPA"
                   for j in $PROCLIST
                   do
                     S=`ps -ef | pgrep $j`
                     for i in $S; do
                       echo "   --- $j PID("$i")" 2> /dev/null | tee | logger -i -t "tucSPA"
                     done
                   done

#*---- instances of ngrok forwarding PID

                  P=`sudo ps ax | awk '! /awk/ && /.\/ngrok/ { print $1}'`
                  N=0
                  for line in $P; do
                     if [ $line -ne $$ ] 
                     then
                         echo "   --- ngrok PID("$line")" 2> /dev/null | tee | logger -i -t "tucSPA"
                     fi
                  done
                else
                  echo "No daemon found, exit" 2> /dev/null | tee | logger -i -t "tucSPA"
		  exit 0
		fi

		;;
#*----- else, just a help message

	*)
		echo "Usage: $0 {start|stop|lock|reset|telemetry|restart|try-restart|checkpoint|force-reload|status}"
		exit 2
		;;
esac
