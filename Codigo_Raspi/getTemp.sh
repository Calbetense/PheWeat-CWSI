 
#!/bin/bash

# Constants
T1=0x11
T2=0x15
T3=0x09

        # Functions Declaration
# Get Temperature from bytes recibed (Air temperature)
# If the value is invalid, repeat the reading
# @param 1: lsb mlx_a
# @param 2: mbs mlx_a
# @param 3: Sensor Address
processTa () {
        # Discard '0x' of the first byte recibed
        lbs=$(echo $1 | tr -d '0x')
        # Concat in little endian
        ta=$2$lbs
        # Calculate temperature in ºC
        ta=$(bc -l <<< "scale=2;$((ta))/50 - 273.15")
        check=0$ta
        if(( ${check%.*} > 100 )) || (( ${check%.*} < -20 ));then
                t=$(getTa $3)
                echo $(processTa $t)
                return
        fi
        echo $ta
}

# Get Temperature from bytes recibed (Object Temperature)
# If the value is invalid, repeat the reading
# @param 1: lsb mlx_a
# @param 2: mbs mlx_a
# @param 3: Sensor Address
processTo () {
        # Discard '0x' of the first byte recibed
        lbs=$(echo $1 | tr -d '0x')
        # Concat in little endian
        ta=$2$lbs
        # Calculate temperature in ºC
        ta=$(bc -l <<< "scale=2;$((ta))/50 - 273.15")
        check=0$ta
        if(( ${check%.*} > 100 )) || (( ${check%.*} < -20 ));then
                t=$(getTo $3)
                echo $(processTo $t)
                return
        fi
        echo $ta
}

# Take air temperature of mlx sensor
#@param 1: Sensor address
getTa () {
        res=$(i2ctransfer -y 1 w1@$1 0x06 r2)
        if [ $? -eq 0 ]; then
                echo $res
        else
                getTa $1
        fi
}

# Take object temperature of mlx sensor
#@param 1: Sensor address
getTo () {
        res=$(i2ctransfer -y 1 w1@$1 0x07 r2)
        if [ $? -eq 0 ]; then
                echo $res
        else
                getTo $1
        fi
}

# Ask for i2c temperature data
mlx1_a=$(getTa $T1)
mlx1_o=$(getTo $T1)

mlx2_a=$(getTa $T2)
mlx2_o=$(getTo $T2)

mlx3_a=$(getTa $T3)
mlx3_o=$(getTo $T3)

# Get temperatures
ta1=$(processTa $mlx1_a $T1)
#echo "ta1 $ta1 addr $T1"
ta2=$(processTa $mlx2_a $T2)
#echo "ta2 " $ta2
ta3=$(processTa $mlx3_a $T3)
#echo "ta3 " $ta3
to1=$(processTo $mlx1_o $T1)
#echo "to1 " $to1
to2=$(processTo $mlx2_o $T2)
#echo "to2 " $to2
to3=$(processTo $mlx3_o $T3)
#echo "to3 " $to3

# Calculate Index TODO: put sensors in real order (c, ul, ll) - Add "printf" to put the leading 0 of decimal
cwsi=$(printf '%.2f\n' "$(bc -l <<< "($to1 - $to2)/($to3 - $to2 )")")

# Send to Big Program
echo "$cwsi,$ta1,$to1,$ta2,$ta3,$to3,$to2"
