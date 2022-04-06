<img src="https://opensearch.org/assets/img/opensearch-logo-themed.svg" height="64px">

# OpenSearch-Snap
This is the snap for OpenSearch. It works on Ubuntu, Fedora, Debian, and other major Linux :penguin: distributions. This snap creates a single-node cluster that is **not production ready**. Consider using the [opensearch-operator](https://github.com/canonical/opensearch-operator) to have an out of the box :gift: experience.

## Install
```shell
sudo snap install opensearch
```
[Don't have snapd installed?](https://snapcraft.io/docs/core/install)

## Configuration
The cluster can be configured by editing `jvm.options` and `opensearch.yml` at `/var/snap/opensearch/common/config`. Check the [OpenSearch documentation](https://opensearch.org/docs/latest) for more details.

## Security Plugin
By default, the security plugin is disabled. If you want to enable it (indicated for production environments), [create](https://opensearch.org/docs/latest/security-plugin/configuration/generate-certificates/) your [certificates](https://opensearch.org/docs/latest/security-plugin/configuration/tls/) and make the necessary changes on `opensearch.yml` file. To apply the changes, use the following command:

```
sudo sudo opensearch.security
```

**Note**: This command doesn't create a [backup](https://opensearch.org/docs/latest/security-plugin/configuration/security-admin/#backup-restore-and-migrate) and will **overwrite** one or more portions of `.opendistro_security` index.
