# Digital Ocean api - Copy a volume
Docker image for [jq](http://stedolan.github.io/jq/) based on [alpine linux](https://alpinelinux.org/) image, just over 4MB in size.

This image also contains [curl](https://curl.haxx.se/) to make HTTP requests.

## Usage

```bash
$ docker run --rm dave08/do-volume-copy volume-name region [volume-copy-name]
```
