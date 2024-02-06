#!/bin/bash

## START PROGRAM ##

# Send a Byte with Moisture's ID
#echo TRANSFERING 0X01 TO I2C
i2ctransfer -y 1 w1@0x08 0x01


# Waits until GPIO14 gets HIGH
#echo WAITING GPIO RESPONSE
while raspi-gpio get 14 | grep -q "level=0"
        do
                #echo '.'
                sleep 0.01
        done

# Then reads the values and store it in a variable
#echo ASKING FOR VP4 DATA
data=$(i2ctransfer -y 1 r16@0x08)


#echo "Data: ${data[*]}"

# Split data in an array of bytes
splited=($(echo $data | tr ' ' '\n'))

# Iterate each 4 bytes
mod=4  # Modulus
ret="" # Returned values
for((i=0; i < ${#splited[@]}; i+=mod))
do
  toSend=""

  # Get 4 bytes in a row
  part=( "${splited[@]:i:mod}" )
  #echo "Part generated: ${part[*]}"

  # Those bytes are order in Little Endian
  for val in "${part[@]}"
  do
    # Toss '0x' from Byte
    val="${val#0x}"
    # Put bytes in reverse order
    toSend="$val$toSend"
  done
  #Add '0x' to final value
  toSend="0x$toSend"

  #echo "Values to send $toSend"

  # Convert to Decimal and divide by 1000
  toSend=$(printf '%.3f\n' "$(bc -l <<< "$((toSend))/1000")")

  if(( ${toSend%.*} > 4294960  ))
  then
        ./getVP.sh
        exit 1
  fi
# Save all values
  ret="$ret,$toSend"
  #echo "returned value $ret"
done


# Send to Big Program
echo "${ret:1}"

