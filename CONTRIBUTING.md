# Contributing

## Overview

This documents explains the processes and practices recommended for contributing enhancements to
this snap.

- Generally, before developing enhancements to this snap, you should consider [opening an issue
  ](https://github.com/canonical/opensearch-snap/issues) explaining your use case.
- Familiarizing yourself with the [Snapcraft](https://snapcraft.io/docs)
  will help you a lot when working on new features or bug fixes.
- Please help us out in ensuring easy to review branches by rebasing your pull request branch onto
  the `main` branch. This also avoids merge commits and creates a linear Git commit history.

### Environment set up

Clone this repository:
```shell
git clone https://github.com/canonical/opensearch-snap.git
cd opensearch-snap/
```

```shell
# install requirements
sudo snap install snapcraft --classic
sudo snap install lxd

# configure lxd
sudo adduser $USER lxd
newgrp lxd
lxd init --auto
lxc network set lxdbr0 ipv6.address none

# create the snap and install it
snapcraft --use-lxd
sudo snap install --dangerous opensearch_<$SNAPCRAFT_PROJECT_VERSION>_amd64.snap
```

## Developing

### Project Version
To change the project version do the following steps:
1. Update the `version` field on the `snapcraft.yaml`.
2. [Download](https://opensearch.org/downloads.html) the `tarball` from the project.
3. Check if `jvm.options`, `opensearch.yml` and other configurations files has new parameters and update on `bin/helpers/config/<CONFIG_FILE>`, if necessary.
4. Update the `source-checksum` using the command:
```shell
md5sum opensearch-$SNAPCRAFT_PROJECT_VERSION-linux-x64.tar.gz
```

## Publishing process
After the PR is merged, the snap will be available on the `edge` [channel](https://snapcraft.io/docs/channels). After checking the stability, owners of the snap might promote to `beta`, `candidate` or `stable` release.

## Canonical Contributor Agreement
Canonical welcomes contributions to the Charmed OpenSearch Operator. Please check out our [contributor agreement](https://ubuntu.com/legal/contributors) if you're interested in contributing to the solution.
