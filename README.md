<img src="https://opensearch.org/assets/img/opensearch-logo-themed.svg" height="64px"><br><br>

<a href="https://snapcraft.io/opensearch">
  <img alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg" />
</a><br><br>

# OpenSearch-Snap
This is the snap for OpenSearch. It works on Ubuntu, Fedora, Debian, and other major Linux :penguin: distributions. This snap creates a single-node cluster that is **not production ready**. Consider using the [opensearch-operator](https://github.com/canonical/opensearch-operator) to have an out of the box :gift: experience.

## Install
```shell
sudo snap install opensearch
```
[Don't have snapd installed?](https://snapcraft.io/docs/core/install)

## Configuration
The `install` hook will create all the folders necessary for logs, data and config if they don't exist. The service will start with the following default configurations:

`opensearch.yml`
* cluster.name: opensearch
* node.name: node-1
* path.data: /var/snap/opensearch/common/data
* path.logs: /var/snap/opensearch/common/logs
* http.port: 9200
* discovery.type: single-node
* plugins.security.disabled: true

`jvm.options`
* -Xms1g
* -Xmx1g
* -XX:ErrorFile=/var/snap/opensearch/common/logs/hs_err_pid%p.log
* 9-:-Xlog:gc*,gc+age=trace,safepoint:file=/var/snap/opensearch/common/logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m

The cluster can be configured by editing `jvm.options` and `opensearch.yml` at `/var/snap/opensearch/common/config`. Check the [OpenSearch documentation](https://opensearch.org/docs/latest) for more details.

## Security Plugin
By default, the security plugin is disabled. If you want to enable it (indicated for production environments), [create](https://opensearch.org/docs/latest/security-plugin/configuration/generate-certificates/) your [certificates](https://opensearch.org/docs/latest/security-plugin/configuration/tls/) and make the necessary changes on `opensearch.yml` file. To apply the changes, use the following command:

```
sudo sudo opensearch.security
```

**Note**: This command doesn't create a [backup](https://opensearch.org/docs/latest/security-plugin/configuration/security-admin/#backup-restore-and-migrate) and will **overwrite** one or more portions of `.opendistro_security` index.

## Contributing
Please see the [Snapcraft docs](https://snapcraft.io/docs) for guidelines on enhancements to this
snap following best practice guidelines, and
[CONTRIBUTING.md](https://github.com/canonical/opensearch-snap/blob/main/CONTRIBUTING.md) for developer
guidance.

## License
Opensearch-Snap is free software, distributed under the Apache Software License, version 2.0. See [LICENSE](https://github.com/canonical/opensearch-snap/blob/main/LICENSE) for more information.
