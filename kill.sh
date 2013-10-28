echo "Killing environment, keeping proxy"
vagrant status 2>1 | grep virtualbox | egrep -v "proxy" | awk '/running/ {print $1}' | while read VM; do vagrant destroy -f $VM; done
