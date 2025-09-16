cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: s3-models-pv
spec:
  capacity:
    storage: 1200Gi # ignored, required
  accessModes:
    - ReadOnlyMany # supported options: ReadWriteMany / ReadOnlyMany
  storageClassName: "" # Required for static provisioning
  claimRef: # To ensure no other PVCs can claim this PV
    namespace: default # Namespace is required even though it's in "default" namespace.
    name: s3-pvc # Name of your PVC
  mountOptions:
    - allow-delete
    - region ap-south-1
  csi:
    driver: s3.csi.aws.com # required
    volumeHandle: s3-csi-driver-volume # Must be unique
    volumeAttributes:
      bucketName: s3-csi-bucket-name
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-models-pvc
spec:
  accessModes:
    - ReadOnlyMany # Supported options: ReadWriteMany / ReadOnlyMany
  storageClassName: "" # Required for static provisioning
  resources:
    requests:
      storage: 1200Gi # Ignored, required
  volumeName: s3-models-pv # Name of your PV
EOF
