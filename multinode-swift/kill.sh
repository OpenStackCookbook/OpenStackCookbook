#echo "Killing environment, keeping proxy"
#vagrant status 2>1 | grep running | egrep -v "proxy" | awk '/running/ {print $1}' | while read VM; do vagrant destroy -f $VM; done
echo "Killing environment"
vagrant status 2>1 | awk '/running/ {print $1}' | while read VM; do vagrant destroy -f $VM; done
