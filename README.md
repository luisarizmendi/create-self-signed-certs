# create-self-signed-certs
Script to create self-signed certificates (both server and client)

## Example

```console
./create-self-signed-certs.sh -n myserver.domain.com -i 66.66.66.66
```

## Help output

```console
Syntax: ./create-self-signed-certs.sh [-n|-i|-k]

options:
k     Keep old CAcert (it does not create a new one).
n     Server domain name (required).
i     Server IP address (required).
```
