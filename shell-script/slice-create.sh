#!/bin//bash

if [ -z "$1" ]
then
    echo "Please input sst & sd in hex format!"
    exit
fi

if [ -d network-slice/$1 ]
then
    echo "Network Slice already exists"
    exit
fi

nsi="1"
sst=${1:2:2}
sd=${1:4}
id="$1"
bias=$(kubectl get subnets.kubeovn.io | grep -c free5gc-n4)
ue_ip=$(( 60 + bias ))
n3_ip=$(( 4 + bias ))
n4_ip=$(( 101 + bias ))

echo "Create Slice"
echo "nsi:"$nsi
echo "sst:"$sst
echo "sd :"$sd

cd network-slice
mkdir $id
cd $id

#
# create custom resource yaml
#

mkdir custom-resource

cat <<EOF > custom-resource/network-slice-cr.yaml
---
apiVersion: "nssmf.free5gc.com/v1"
kind: NetworkSlice
metadata:
  name: "$id"
spec:
  sst: "$sst"
  sd: "$sd"
  n4_cidr: "10.200.$n4_ip.0/24"
  ue_subnet: "60.$ue_ip.0.0/16"
  cpu: default
  memory: default
  bandwidth: default
EOF

#
# create smf yaml
#

mkdir smf-$id
mkdir smf-$id/base
mkdir smf-$id/base/config
cp -r ../../TLS smf-$id/base

cat <<EOF > smf-$id/base/config/smfcfg-$id.yaml
info:
  version: 1.0.0
  description: AMF initial local configuration

configuration:
  smfName: SMF
  sbi:
    scheme: http
    registerIPv4: free5gc-smf-$id # IP used to register to NRF
    bindingIPv4: 0.0.0.0  # IP used to bind the service
    port: 8000
    tls:
      key: free5gc/support/TLS/smf.key
      pem: free5gc/support/TLS/smf.pem
  serviceNameList:
    - nsmf-pdusession
    - nsmf-event-exposure
    - nsmf-oam
  snssaiInfos:
    - sNssai:
        sst: $((16#$sst))
        sd: $sd
      dnnInfos:
        - dnn: internet
          dns:
            ipv4: 8.8.8.8
            ipv6: 2001:4860:4860::8888
          ueSubnet: 60.$ue_ip.0.0/16
  pfcp:
    addr: 10.200.$n4_ip.20
  userplane_information:
    up_nodes:
      gNB1:
        type: AN
        an_ip: 192.168.72.3
      AnchorUPF1:
        type: UPF
        node_id: 10.200.$n4_ip.101 # the IP/FQDN of N4 interface on this UPF (PFCP)
        sNssaiUpfInfos:
          - sNssai:
              sst: $((16#$sst))
              sd: $sd
            dnnUpfInfoList:
              - dnn: internet
        interfaces:
          - interfaceType: N3
            endpoints: # the IP address of this N3/N9 interface on this UPF
              - 10.200.100.$n3_ip
            networkInstance: internet
          - interfaceType: N9
            endpoints: # the IP address of this N3/N9 interface on this UPF
              - 10.200.$n4_ip.101
            networkInstance: internet
    links:
      - A: gNB1
        B: AnchorUPF1
  dnn:
    internet:
      dns:
        ipv4: 8.8.8.8
        ipv6: 2001:4860:4860::8888
  ue_subnet: 60.$ue_ip.0.0/16
  nrfUri: http://free5gc-nrf:8000
  ulcl: false

logger:
  SMF:
    debugLevel: info
    ReportCaller: false
  NAS:
    debugLevel: info
    ReportCaller: false
  NGAP:
    debugLevel: info
    ReportCaller: false
  Aper:
    debugLevel: info
    ReportCaller: false
  PathUtil:
    debugLevel: info
    ReportCaller: false
  OpenApi:
    debugLevel: info
    ReportCaller: false
  PFCP:
    debugLevel: info
    ReportCaller: false
EOF

cat <<EOF > smf-$id/base/config/uerouting.yaml
info:
  version: 1.0.0
  description: Routing information for UE

ueRoutingInfo: # the list of UE routing information
  - SUPI: imsi-2089300007487 # Subscription Permanent Identifier of the UE
    AN: 192.168.72.3 # the IP address of RAN (gNB)
    PathList: # the pre-config paths for this SUPI
      - DestinationIP: 60.60.0.100 # the destination IP address on Data Network (DN)
        # the order of UPF nodes in this path. We use the UPF's name to represent each UPF node.
        # The UPF's name should be consistent with smfcfg.yaml
        UPF: !!seq
          - BranchingUPF
          - AnchorUPF1

      - DestinationIP: 60.60.0.101 # the destination IP address on Data Network (DN)
        # the order of UPF nodes in this path. We use the UPF's name to represent each UPF node.
        # The UPF's name should be consistent with smfcfg.yaml
        UPF: !!seq
          - BranchingUPF
          - AnchorUPF2

  - SUPI: imsi-2089300007486 # Subscription Permanent Identifier of the UE
    AN: 10.200.200.102 # the IP address of RAN
    PathList: # the pre-config paths for this SUPI
      - DestinationIP: 10.10.0.10 # the destination IP address on Data Network (DN)
        # the order of UPF nodes in this path. We use the UPF's name to represent each UPF node.
        # The UPF's name should be consistent with smfcfg.yaml
        UPF: !!seq
          - BranchingUPF
          - AnchorUPF1

      - DestinationIP: 10.10.0.11 # the destination IP address on Data Network (DN)
        # the order of UPF nodes in this path. We use the UPF's name to represent each UPF node.
        # The UPF's name should be consistent with smfcfg.yaml
        UPF: !!seq
          - BranchingUPF
          - AnchorUPF2
EOF

cat <<EOF > smf-$id/base/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: free5gc
resources:
  - smf-$id-sa.yaml
  - smf-$id-rbac.yaml
  - smf-$id-service.yaml
  - smf-$id-deployment.yaml

# declare Secret from a secretGenerator
secretGenerator:
- name: free5gc-smf-$id-tls-secret
  namespace: free5gc
  files:
  - TLS/smf.pem
  - TLS/smf.key
  type: "Opaque"
generatorOptions:
  disableNameSuffixHash: true

# declare ConfigMap from a ConfigMapGenerator
configMapGenerator:
- name: free5gc-smf-$id-config
  namespace: free5gc
  files:
    - smfcfg.yaml=config/smfcfg-$id.yaml
    - config/uerouting.yaml
EOF

cat <<EOF > smf-$id/base/smf-$id-sa.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: free5gc-smf-$id-sa
EOF

cat <<EOF > smf-$id/base/smf-$id-rbac.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: free5gc-smf-$id-rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: free5gc-smf-$id-sa
EOF

cat <<EOF > smf-$id/base/smf-$id-service.yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: free5gc-smf-$id
  name: free5gc-smf-$id
spec:
  type: ClusterIP
  ports:
  - name: free5gc-sbi
    port: 8000
    protocol: TCP
    targetPort: 8000
  - name: free5gc-n4-$id
    port: 8805
    protocol: UDP
    targetPort: 8805
  selector:
    app: free5gc-smf-$id
EOF

cat <<EOF > smf-$id/base/smf-$id-deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: free5gc-smf-$id
  labels:
    app: free5gc-smf-$id
    nsi: "$nsi"        # Network Slice Instance of three networks (RAN,TN,CN)
    sst: "$sst"       # Slice/Service Type (1 byte uinteger, range: 0~255)
    sd: "$sd"    # Slice Differentiator (3 bytes hex string, range: 000000~FFFFFF)
spec:
  replicas: 1
  selector:
    matchLabels:
      app: free5gc-smf-$id
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: free5gc-smf-$id
        nsi: "$nsi"        # Network Slice Instance of three networks (RAN,TN,CN)
        sst: "$sst"       # Slice/Service Type (1 byte uinteger, range: 0~255)
        sd: "$sd"    # Slice Differentiator (3 bytes hex string, range: 000000~FFFFFF)
      annotations:
        k8s.v1.cni.cncf.io/networks: free5gc-n4-$id
        free5gc-n4-$id.free5gc.ovn.kubernetes.io/logical_switch: free5gc-n4-$id
        free5gc-n4-$id.free5gc.ovn.kubernetes.io/ip_address: 10.200.$n4_ip.20
    spec:
      securityContext:
        runAsUser: 0
        runAsGroup: 0
      containers:
        - name: free5gc-smf
          image: black842679513/free5gc-smf:v3.0.5
          imagePullPolicy: IfNotPresent
          # imagePullPolicy: Always
          securityContext:
            privileged: false
          volumeMounts:
            - name: free5gc-smf-$id-config
              mountPath: /free5gc/config
            - name: free5gc-smf-$id-cert
              mountPath: /free5gc/support/TLS
          ports:
            - containerPort: 8000
              name: if-sbi
              protocol: TCP
            - containerPort: 8805
              name: if-n4
              protocol: UDP
        - name: tcpdump
          image: corfr/tcpdump
          imagePullPolicy: IfNotPresent
          command:
            - /bin/sleep
            - infinity
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccountName: free5gc-smf-$id-sa
      terminationGracePeriodSeconds: 30
      volumes:
        - name: free5gc-smf-$id-cert
          secret:
            secretName: free5gc-smf-$id-tls-secret
        - name: free5gc-smf-$id-config
          configMap:
            name: free5gc-smf-$id-config
EOF

#
# create upf yaml
#

mkdir upf-$id
mkdir upf-$id/base
mkdir upf-$id/base/config
mkdir upf-$id/overlays

cat <<EOF > upf-$id/base/config/upfcfg-$id.yaml
info:
  version: 1.0.0
  description: UPF configuration

configuration:
  # debugLevel: panic|fatal|error|warn|info|debug|trace
  debugLevel: info

  pfcp:
    - addr: 10.200.$n4_ip.101

  gtpu:
    - addr: 10.200.100.$n3_ip
    # [optional] gtpu.name
    # - name: upf.5gc.nctu.me
    # [optional] gtpu.ifname
    # - ifname: gtpif

  dnn_list:
    - dnn: internet
      cidr: 60.$ue_ip.0.0/16
      # [optional] apn_list[*].natifname
      # natifname: eth0
EOF

cat <<EOF > upf-$id/base/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: free5gc
resources:
  - upf-$id-sa.yaml
  - upf-$id-rbac.yaml
  - upf-$id-service.yaml
  - upf-$id-deployment.yaml

# declare ConfigMap from a ConfigMapGenerator
configMapGenerator:
- name: free5gc-upf-$id-config
  namespace: free5gc
  files:
    - upfcfg.yaml=config/upfcfg-$id.yaml
EOF

cat <<EOF > upf-$id/base/upf-$id-sa.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: free5gc-upf-$id-sa
EOF

cat <<EOF > upf-$id/base/upf-$id-rbac.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: free5gc-upf-$id-rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: free5gc-upf-$id-sa
EOF

cat <<EOF > upf-$id/base/upf-$id-service.yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: free5gc-upf-$id
  name: free5gc-upf-$id
spec:
  type: ClusterIP
  ports:
  - name: free5gc-upf-$id-n3
    port: 2152
    protocol: UDP
    targetPort: 2152
  - name: free5gc-upf-$id-n4
    port:  8805
    protocol: UDP
    targetPort: 8805
  selector:
    app: free5gc-upf-$id
EOF

cat <<EOF > upf-$id/base/upf-$id-deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: free5gc-upf-$id
  labels:
    app: free5gc-upf-$id
    nsi: "$nsi"        # Network Slice Instance of three networks (RAN,TN,CN)
    sst: "$sst"       # Slice/Service Type (1 byte uinteger, range: 0~255)
    sd: "$sd"    # Slice Differentiator (3 bytes hex string, range: 000000~FFFFFF)
spec:
  replicas: 1
  selector:
    matchLabels:
      app: free5gc-upf-$id
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: free5gc-upf-$id
        nsi: "$nsi"        # Network Slice Instance of three networks (RAN,TN,CN)
        sst: "$sst"       # Slice/Service Type (1 byte uinteger, range: 0~255)
        sd: "$sd"    # Slice Differentiator (3 bytes hex string, range: 000000~FFFFFF)
      annotations:
        k8s.v1.cni.cncf.io/networks: free5gc-n3, free5gc-n4-$id
        free5gc-n3.free5gc.ovn.kubernetes.io/logical_switch: free5gc-n3
        free5gc-n3.free5gc.ovn.kubernetes.io/ip_address: 10.200.100.$n3_ip
        free5gc-n4-$id.free5gc.ovn.kubernetes.io/logical_switch: free5gc-n4-$id
        free5gc-n4-$id.free5gc.ovn.kubernetes.io/ip_address: 10.200.$n4_ip.101
    spec:
      securityContext:
        runAsUser: 0
        runAsGroup: 0
      containers:
        - name: free5gc-upf
          image: black842679513/free5gc-upf:v3.0.5
          imagePullPolicy: IfNotPresent
          # imagePullPolicy: Always
          securityContext:
            privileged: false
            # add network capabilities
            capabilities:
              add: ["NET_ADMIN", "NET_RAW", "NET_BIND_SERVICE", "SYS_TIME"]
          volumeMounts:
            - name: free5gc-upf-$id-config
              mountPath: /free5gc/config
              # read host linux tun/tap packets
           # - name: tun-dev-dir
           #   mountPath: /dev/net/tun
          ports:
            - containerPort: 2152
              name: if-n3
              protocol: UDP
            - containerPort: 8805
              name: if-n4
              protocol: UDP
        - name: tcpdump
          image: corfr/tcpdump
          securityContext:
            privileged: true
          command:
            - /bin/sh
            - -c
            - |
              sysctl -w net.ipv4.ip_forward=1
              apk update
              apk add iptables
              iptables -t nat -A POSTROUTING -s 60.$ue_ip.0.0/16 ! -o upfgtp -j MASQUERADE
              sleep infinity
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccountName: free5gc-upf-$id-sa
      terminationGracePeriodSeconds: 30
      volumes:
        - name: free5gc-upf-$id-config
          configMap:
            name: free5gc-upf-$id-config
       # - name: tun-dev-dir
       #   hostPath:
       #     path: /dev/net/tun
EOF

#
# create n4 subnet yaml
#

mkdir subnet

cat <<EOF > subnet/free5gc-n4-$id.yaml
---
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: free5gc-n4-$id
  labels:
    nsi: "$nsi"        # Network Slice Instance of three networks (RAN,TN,CN)
    sst: "$sst"       # Slice/Service Type (1 byte uinteger, range: 0~255)
    sd: "$sd"    # Slice Differentiator (3 bytes hex string, range: 000000~FFFFFF)
spec:
  protocol: IPv4
  cidrBlock: 10.200.$n4_ip.0/24
  gateway: 10.200.$n4_ip.1
  excludeIps:
  - 10.200.$n4_ip.0..10.200.$n4_ip.10
EOF

#
# create n4 network-attachment-definition yaml
#

mkdir network-attachment-definition

cat <<EOF > network-attachment-definition/free5gc-n4-$id.yaml
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: free5gc-n4-$id
  namespace: free5gc
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "kube-ovn",
      "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
      "provider": "free5gc-n4-$id.free5gc.ovn"
    }'
EOF

#
# create SFC vpn
#

mkdir vpn

#cat <<EOF > vpn/

#EOF
