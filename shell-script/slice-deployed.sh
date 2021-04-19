
#!/bin/bash

deployed=$(kubectl get networkslice | awk '$1 ~ /[0-9]/ { print $1 }')

echo $deployed