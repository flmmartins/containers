# Run

```
docker-compose up -d
```

Open the UI: `http://localhost:8200/`

That will provide instructions on how to initialise. Use key share and threshold 1

It's not possible to use `-dev` which initialiase automatically because we are using raft storage.

# Using Vault from Host machine

Export and do checks
```
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=xxxx

vault status
vault operator raft list-peers
```

