# Puppet config for UKI-SOUTHGRID-BRIS-HEP
## site information
This site uses the `site::site_info` hiera hash to distribute site-specific
information facts across the site. The hash is usually defined in `hieradata/common.yaml`
which is used by all nodes. Currently it sets the site GOCDB name, the CMS VO
specific name and a baseline for benchmark results. The latter is useful to
normalise benchmark results for accounting. 
As an example, if the site baseline for the `hepspec06` is `10` and the node a
job runs on has a benchmark result of `20`, a scaling factor of `2.0` will be
used for the accounting.

These values can be useful when creating profiles for the middleware (e.g. `htcondor`, `arc_ce`).

## node information
This site uses the `site::node_info` hiera hash to distribute node-specific facts across the site. 
The hash is usually defined in the node yaml (`hieradata/nodes/*yaml`) and currently helps to set
the cluster, the group, the specific role of the node as well as benchmark results.
```
site::node_info:
  cluster: hadoop
  group: htcondor
  role: htcondor_worker
  hepspec06: 1
  specfp2000: 250
  specint2000: 250
```
`cluster`, `group` and `role` values are furthermore used in `hiera` to determine the exact hierarchy.
The site hierarchy is defined in the `hiera.yaml` file. The `role` entry is used to specify the
node's role (set of profiles & parameters).
