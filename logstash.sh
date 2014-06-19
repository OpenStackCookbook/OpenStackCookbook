sudo apt-get install unzip python-software-properties software-properties-common -y

sudo add-apt-repository ppa:webupd8team/java
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
echo 'deb http://packages.elasticsearch.org/elasticsearch/1.1/debian stable main' | sudo tee /etc/apt/sources.list.d/elasticsearch.list
echo 'deb http://packages.elasticsearch.org/logstash/1.4/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash.list

sudo apt-get update

# state that you accepted the license
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
 
# install Oracle Java 7
sudo apt-get -q -y install oracle-java7-installer
 
# update environment variable
sudo bash -c "echo JAVA_HOME=/usr/lib/jvm/java-7-oracle/ >> /etc/environment"

# Install Elasticsearch & Set to start on boot:
sudo apt-get install -y elasticsearch=1.1.1
sudo service elasticsearch start
sudo update-rc.d elasticsearch defaults 95 10

# Install Kibana
cd ~; wget http://download.elasticsearch.org/kibana/kibana/kibana-latest.zip
unzip kibana-latest.zip

sudo mkdir -p /var/www/kibana
sudo cp -R ~/kibana-latest/* /var/www/kibana/

sudo cat > /etc/apache2/conf-enabled/kibana.conf <<EOF
Alias /kibana /var/www/kibana
<Directory /var/www/kibana>
  Order allow,deny
  Allow from all
</Directory>
EOF

sudo service apache2 restart

# Install logstash
sudo apt-get install -y logstash=1.4.1-1-bd507eb

# Configure Logstash to listen for syslog
sudo cat > /etc/logstash/conf.d/10-syslog.conf <<EOF
input {
  tcp {
    port => 9000
    type => syslog
  }
  udp {
    port => 9000
    type => syslog
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}

output {
  elasticsearch { host => localhost }
  stdout { codec => rubydebug }
}
EOF

service logstash restart

# Configure rsyslog to puke into logstash
sudo echo "*.*         @@localhost:9000" >> /etc/rsyslog.d/50-default.conf
sudo service rsyslog restart
