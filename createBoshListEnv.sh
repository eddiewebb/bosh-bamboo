
# rhis is just the commands from bosh-lite install guide modified for my local paths.

bosh create-env ~/Development/bosh-deployment/bosh.yml \
  --state ~/Development/bosh-deployment/state.json \
  -o ~/Development/bosh-deployment/virtualbox/cpi.yml \
  -o ~/Development/bosh-deployment/virtualbox/outbound-network.yml \
  -o ~/Development/bosh-deployment/bosh-lite.yml \
  -o ~/Development/bosh-deployment/bosh-lite-runc.yml \
  -o ~/Development/bosh-deployment/jumpbox-user.yml \
  --vars-store ~/Development/bosh-deployment/creds.yml \
  -v director_name="Bosh Lite Director" \
  -v internal_ip=192.168.50.6 \
  -v internal_gw=192.168.50.1 \
  -v internal_cidr=192.168.50.0/24 \
  -v outbound_network_name=NatNetwork

bosh alias-env vbox -e 192.168.50.6 --ca-cert <(bosh int ~/Development/bosh-deployment/creds.yml --path /director_ssl/ca)
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int ~/Development/bosh-deployment/creds.yml --path /admin_password`
