# local-path-provisioner

Dynamic local storage for OKD worker nodes.

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
oc apply -f manifests/
oc adm policy add-scc-to-user privileged system:serviceaccount:local-path-storage:local-path-provisioner-service-account
```

## StorageClasses

| Name | ReclaimPolicy | Default |
|------|---------------|---------|
| local-path-retain | Retain | yes |
| local-path | Delete | no |

## Path on nodes

`/var/local-path-provisioner` (workers only)
