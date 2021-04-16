
#!/bin/bash

msg1=${1} #First Parameter
msg2=${2} #Second Parameter

concatString=$msg1"$msg2" #Concatenated String
concatString2="$msg1$msg2"

echo $concatString 
echo $concatString2

bias=$(kubectl get subnets.kubeovn.io | grep -c free5gc-n3)
num=$((101 + bias))

test="01"

echo $((16#$test))
