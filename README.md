Fulcrum Container Image Build
=============================

## Documentation

- https://github.com/cculianu/Fulcrum
- https://fulcrumserver.org

## Build

```
$ docker build --file Containerfile .
```

## Usage

All configuration is provided by environment variables matching configuration keys. See [fulcrum-example.conf](./fulcrum-example.conf) and [Containerfile](./Containerfile#L63-L78)

```
$ docker run -it --rm --volume ./data:/data:rw --tmpfs /tmp --read-only --publish 127.0.0.1:50001:50001/tcp --env bitcoind=bitcoind.internal:8332 ghcr.io/jmanero/fulcrum:latest
```
