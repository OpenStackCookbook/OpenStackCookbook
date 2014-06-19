export DEBIAN_FRONTEND=noninteractive
# Install OpenLDAP
echo -e " \
slapd    slapd/internal/generated_adminpw    openstack
slapd    slapd/password2    openstack
slapd    slapd/internal/adminpw    openstack
slapd    slapd/password1    openstack
" | sudo debconf-set-selections

sudo aptitude --without-recommends install slapd ldap-utils

# Check that it's working
sudo slapcat 

# Configure some generic users / groups

