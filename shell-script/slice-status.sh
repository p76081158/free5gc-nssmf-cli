
#!/bin/bash

status=$(kubectl -n free5gc get pod -o wide | grep free5gc-amf)
echo $status
