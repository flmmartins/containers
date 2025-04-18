ui            = true
disable_mlock = true
cluster_addr  = "https://127.0.0.1:8201" #required - this allows Vault to assign an address to the node ID at join time 
api_addr      = "https://127.0.0.1:8200" #required - cluster ip nodes should use when joining

storage "raft" {
  path = "/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable   = 1
}