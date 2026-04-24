# openbao
* currently this cookbook is for showoffs and copypaste into production code, it cannot be applyed as is without others it depends on.

# stupidly lazy cookbook for openbao raft cluster.
it requires around of two chef-client runs to get tls cluster with internal pki.
* 1st will create cluster without tls on each node.
  this run initializes cluster and pki.
 make sure you unseal other nodes before 2nd run.
* 2nd will restart services with tls enabled.
* 3rd may needed sometimes if it fails make 4rd and so on. Pure magic. Idk why vault doesn't expose raft status when unsealed :(.

did with it 3-4 clusters from scratch, not ideal but better than handjob.

