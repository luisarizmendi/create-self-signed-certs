# create-self-signed-certs
Script to create self-signed certificates (both server and client)

## Example

```console
./create-self-signed-certs.sh -n myserver.domain.com -i 66.66.66.66 -r false -p pass
```

## Help output

```console
Syntax: ./create-self-signed-certs.sh [-n|-i|-r|-p]

options:
r     Remove CAcert and create a new one (default=true).
n     Server domain name (required).
i     Server IP address (required).
p     Password for importing/exporting the client PKCS#12 certificate.
```
