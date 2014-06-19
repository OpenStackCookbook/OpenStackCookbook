export DEBIAN_FRONTEND=noninteractive
# Install OpenLDAP
echo -e " \
slapd    slapd/internal/generated_adminpw    password	openstack
slapd    slapd/password2    password	openstack
slapd    slapd/internal/adminpw    password	openstack
slapd    slapd/password1    password	openstack
" | sudo debconf-set-selections

sudo apt-get install -y slapd ldap-utils

# Check that it's working
sudo slapcat 

# Configure some generic users / groups

