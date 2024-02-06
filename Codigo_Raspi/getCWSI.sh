#!/bin/bash

# This program send to execute both sensors in parallel

# Run the VP-4 sensor's program
vp=$(./getVP.sh&)

# Run MLX sensor's program
# Timeout to prevent infinite loop
mlx=$(timeout 3s ./getTemp.sh&)
# Wait until both scripts are done
wait


while [[ -z "$mlx" ]]; do
   mlx=$(timeout 7s ./getTemp.sh)
done


# To get rid of error msgs in response, get only the last line
mlx=$(echo $mlx | tail -n1)

# Put all together
echo "$mlx,$vp"

