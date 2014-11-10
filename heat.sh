#!/bin/bash
# heat.sh

# Authors: Kevin Jackson (@itarchitectkev)

# Source in common env vars
. /vagrant/common.sh

# Install Heat Things
sudo apt-get -y install heat-api heat-api-cfn heat-engine

MYSQL_ROOT_PASS=openstack
MYSQL_HEAT_PASS=openstack
mysql -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE heat;'
mysql -uroot -p$MYSQL_ROOT_PASS -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$MYSQL_HEAT_PASS';"

# Configure Heat

HEAT_CONF=/etc/heat/heat.conf
cat > $HEAT_CONF <<EOF
[DEFAULT]

#
# Options defined in heat.api.middleware.ssl
#

# The HTTP Header that will be used to determine which the
# original request protocol scheme was, even if it was removed
# by an SSL terminator proxy. (string value)
#secure_proxy_ssl_header=X-Forwarded-Proto


#
# Options defined in heat.common.config
#

# The default user for new instances. This option is
# deprecated and will be removed in the Juno release. If it's
# empty, Heat will use the default user set up with your cloud
# image (for OS::Nova::Server) or 'ec2-user' (for
# AWS::EC2::Instance). (string value)
#instance_user=ec2-user

# Driver to use for controlling instances. (string value)
#instance_driver=heat.engine.nova

# List of directories to search for plug-ins. (list value)
#plugin_dirs=/usr/lib64/heat,/usr/lib/heat

# The directory to search for environment files. (string
# value)
#environment_dir=/etc/heat/environment.d

# Select deferred auth method, stored password or trusts.
# (string value)
#deferred_auth_method=password

# Subset of trustor roles to be delegated to heat. (list
# value)
#trusts_delegated_roles=heat_stack_owner

# Maximum resources allowed per top-level stack. (integer
# value)
#max_resources_per_stack=1000

# Maximum number of stacks any one tenant may have active at
# one time. (integer value)
#max_stacks_per_tenant=100

# Controls how many events will be pruned whenever a  stack's
# events exceed max_events_per_stack. Set this lower to keep
# more events at the expense of more frequent purges. (integer
# value)
#event_purge_batch_size=10

# Maximum events that will be available per stack. Older
# events will be deleted when this is reached. Set to 0 for
# unlimited events per stack. (integer value)
#max_events_per_stack=1000

# Timeout in seconds for stack action (ie. create or update).
# (integer value)
#stack_action_timeout=3600

# RPC timeout for the engine liveness check that is used for
# stack locking. (integer value)
#engine_life_check_timeout=2

# onready allows you to send a notification when the heat
# processes are ready to serve.  This is either a module with
# the notify() method or a shell command.  To enable
# notifications with systemd, one may use the 'systemd-notify
# --ready' shell command or the 'heat.common.systemd'
# notification module. (string value)
#onready=<None>

# Name of the engine node. This can be an opaque identifier.
# It is not necessarily a hostname, FQDN, or IP address.
# (string value)
#host=heat

# Seconds between running periodic tasks. (integer value)
#periodic_interval=60

# URL of the Heat metadata server. (string value)
#heat_metadata_server_url=

# URL of the Heat waitcondition server. (string value)
#heat_waitcondition_server_url=

# URL of the Heat CloudWatch server. (string value)
#heat_watch_server_url=

# Instance connection to CFN/CW API via https. (string value)
#instance_connection_is_secure=0

# Instance connection to CFN/CW API validate certs if SSL is
# used. (string value)
#instance_connection_https_validate_certificates=1

# Default region name used to get services endpoints. (string
# value)
#region_name_for_services=<None>

# Keystone role for heat template-defined users. (string
# value)
#heat_stack_user_role=heat_stack_user

# Keystone domain ID which contains heat template-defined
# users. (string value)
#stack_user_domain=<None>

# Keystone username, a user with roles sufficient to manage
# users and projects in the stack_user_domain. (string value)
#stack_domain_admin=<None>

# Keystone password for stack_domain_admin user. (string
# value)
#stack_domain_admin_password=<None>

# Maximum raw byte size of any template. (integer value)
#max_template_size=524288

# Maximum depth allowed when using nested stacks. (integer
# value)
#max_nested_stack_depth=3


#
# Options defined in heat.common.crypt
#

# Encryption key used for authentication info in database.
# (string value)
#auth_encryption_key=notgood but just long enough i think


#
# Options defined in heat.common.heat_keystoneclient
#

# Fully qualified class name to use as a keystone backend.
# (string value)
#keystone_backend=heat.common.heat_keystoneclient.KeystoneClientV3


#
# Options defined in heat.common.wsgi
#

# Maximum raw byte size of JSON request body. Should be larger
# than max_template_size. (integer value)
#max_json_body_size=1048576


#
# Options defined in heat.db.api
#

# The backend to use for db. (string value)
#db_backend=sqlalchemy


#
# Options defined in heat.engine.clients
#

# Fully qualified class name to use as a client backend.
# (string value)
#cloud_backend=heat.engine.clients.OpenStackClients


#
# Options defined in heat.engine.resources.loadbalancer
#

# Custom template for the built-in loadbalancer nested stack.
# (string value)
#loadbalancer_template=<None>


#
# Options defined in heat.openstack.common.db.sqlalchemy.session
#

# the filename to use with sqlite (string value)
#sqlite_db=heat.sqlite

# If true, use synchronous mode for sqlite (boolean value)
#sqlite_synchronous=true


#
# Options defined in heat.openstack.common.eventlet_backdoor
#

# Enable eventlet backdoor.  Acceptable values are 0, <port>,
# and <start>:<end>, where 0 results in listening on a random
# tcp port number; <port> results in listening on the
# specified port number (and not enabling backdoor if that
# port is in use); and <start>:<end> results in listening on
# the smallest unused port number within the specified range
# of port numbers.  The chosen port is displayed in the
# service's log file. (string value)
#backdoor_port=<None>


#
# Options defined in heat.openstack.common.lockutils
#

# Whether to disable inter-process locks (boolean value)
#disable_process_locking=false

# Directory to use for lock files. (string value)
#lock_path=<None>


#
# Options defined in heat.openstack.common.log
#

# Print debugging output (set logging level to DEBUG instead
# of default WARNING level). (boolean value)
#debug=false

# Print more verbose output (set logging level to INFO instead
# of default WARNING level). (boolean value)
#verbose=false

# Log output to standard error (boolean value)
#use_stderr=true

# format string to use for log messages with context (string
# value)
#logging_context_format_string=%(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s

# format string to use for log messages without context
# (string value)
#logging_default_format_string=%(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s

# data to append to log format when level is DEBUG (string
# value)
#logging_debug_format_suffix=%(funcName)s %(pathname)s:%(lineno)d

# prefix each line of exception output with this format
# (string value)
#logging_exception_prefix=%(asctime)s.%(msecs)03d %(process)d TRACE %(name)s %(instance)s

# list of logger=LEVEL pairs (list value)
#default_log_levels=amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN

# publish error events (boolean value)
#publish_errors=false

# make deprecations fatal (boolean value)
#fatal_deprecations=false

# If an instance is passed with the log message, format it
# like this (string value)
#instance_format="[instance: %(uuid)s] "

# If an instance UUID is passed with the log message, format
# it like this (string value)
#instance_uuid_format="[instance: %(uuid)s] "

# The name of logging configuration file. It does not disable
# existing loggers, but just appends specified logging
# configuration to any other existing logging options. Please
# see the Python logging module documentation for details on
# logging configuration files. (string value)
# Deprecated group/name - [DEFAULT]/log_config
#log_config_append=<None>

# DEPRECATED. A logging.Formatter log message format string
# which may use any of the available logging.LogRecord
# attributes. This option is deprecated.  Please use
# logging_context_format_string and
# logging_default_format_string instead. (string value)
#log_format=<None>

# Format string for %%(asctime)s in log records. Default:
# %(default)s (string value)
#log_date_format=%Y-%m-%d %H:%M:%S

# (Optional) Name of log file to output to. If no default is
# set, logging will go to stdout. (string value)
# Deprecated group/name - [DEFAULT]/logfile
#log_file=<None>

# (Optional) The base directory used for relative --log-file
# paths (string value)
# Deprecated group/name - [DEFAULT]/logdir
#log_dir=<None>

# Use syslog for logging. (boolean value)
#use_syslog=false

# syslog facility to receive log lines (string value)
#syslog_log_facility=LOG_USER


#
# Options defined in heat.openstack.common.notifier.api
#

# Driver or drivers to handle sending notifications (multi
# valued)
#notification_driver=

# Default notification level for outgoing notifications
# (string value)
#default_notification_level=INFO

# Default publisher_id for outgoing notifications (string
# value)
#default_publisher_id=<None>


#
# Options defined in heat.openstack.common.notifier.list_notifier
#

# List of drivers to send notifications (multi valued)
#list_notifier_drivers=heat.openstack.common.notifier.no_op_notifier


#
# Options defined in heat.openstack.common.notifier.rpc_notifier
#

# AMQP topic used for OpenStack notifications (list value)
#notification_topics=notifications


#
# Options defined in heat.openstack.common.policy
#

# JSON file containing policy (string value)
#policy_file=policy.json

# Rule enforced when requested rule is not found (string
# value)
#policy_default_rule=default


#
# Options defined in heat.openstack.common.rpc
#

# The messaging module to use, defaults to kombu. (string
# value)
#rpc_backend=heat.openstack.common.rpc.impl_kombu

# Size of RPC thread pool (integer value)
#rpc_thread_pool_size=64

# Size of RPC connection pool (integer value)
#rpc_conn_pool_size=30

# Seconds to wait for a response from call or multicall
# (integer value)
#rpc_response_timeout=60

# Seconds to wait before a cast expires (TTL). Only supported
# by impl_zmq. (integer value)
#rpc_cast_timeout=30

# Modules of exceptions that are permitted to be recreated
# upon receiving exception data from an rpc call. (list value)
#allowed_rpc_exception_modules=nova.exception,cinder.exception,exceptions

# If passed, use a fake RabbitMQ provider (boolean value)
#fake_rabbit=false

# AMQP exchange to connect to if using RabbitMQ or Qpid
# (string value)
#control_exchange=heat


#
# Options defined in heat.openstack.common.rpc.amqp
#

# Use durable queues in amqp. (boolean value)
# Deprecated group/name - [DEFAULT]/rabbit_durable_queues
#amqp_durable_queues=false

# Auto-delete queues in amqp. (boolean value)
#amqp_auto_delete=false


#
# Options defined in heat.openstack.common.rpc.impl_kombu
#

rabbit_host=172.16.0.200
rabbit_port=5672
rabbit_userid=guest
rabbit_password=guest
rabbit_virtual_host=/
rabbit_ha_queues=false



[auth_password]

#
# Options defined in heat.common.config
#

# Allow orchestration of multiple clouds. (boolean value)
#multi_cloud=false

# Allowed keystone endpoints for auth_uri when multi_cloud is
# enabled. At least one endpoint needs to be specified. (list
# value)
#allowed_auth_uris=


[clients]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_ceilometer]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_cinder]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_heat]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false

# Optional heat url in format like
# http://0.0.0.0:8004/v1/%(tenant_id)s. (string value)
#url=<None>


[clients_keystone]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_neutron]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_nova]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_swift]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[clients_trove]

#
# Options defined in heat.common.config
#

# Type of endpoint in Identity service catalog to use for
# communication with the OpenStack service. (string value)
#endpoint_type=publicURL

# Optional CA cert file to use in SSL connections. (string
# value)
#ca_file=<None>

# Optional PEM-formatted certificate chain file. (string
# value)
#cert_file=<None>

# Optional PEM-formatted file that contains the private key.
# (string value)
#key_file=<None>

# If set, then the server's certificate will not be verified.
# (boolean value)
#insecure=false


[database]
backend=sqlalchemy
connection = mysql://heat:${MYSQL_HEAT_PASS}@${MYSQL_HOST}/heat


[ec2authtoken]

#
# Options defined in heat.api.aws.ec2token
#

# Authentication Endpoint URI. (string value)
#auth_uri=<None>

# Allow orchestration of multiple clouds. (boolean value)
#multi_cloud=false

# Allowed keystone endpoints for auth_uri when multi_cloud is
# enabled. At least one endpoint needs to be specified. (list
# value)
#allowed_auth_uris=


[heat_api]

#
# Options defined in heat.common.wsgi
#

# Address to bind the server. Useful when selecting a
# particular network interface. (string value)
#bind_host=0.0.0.0

# The port on which the server will listen. (integer value)
#bind_port=8004

# Number of backlog requests to configure the socket with.
# (integer value)
#backlog=4096

# Location of the SSL certificate file to use for SSL mode.
# (string value)
#cert_file=<None>

# Location of the SSL key file to use for enabling SSL mode.
# (string value)
#key_file=<None>

# Number of workers for Heat service. (integer value)
#workers=0

# Maximum line size of message headers to be accepted.
# max_header_line may need to be increased when using large
# tokens (typically those generated by the Keystone v3 API
# with big service catalogs). (integer value)
#max_header_line=16384


[heat_api_cfn]

#
# Options defined in heat.common.wsgi
#

# Address to bind the server. Useful when selecting a
# particular network interface. (string value)
#bind_host=0.0.0.0

# The port on which the server will listen. (integer value)
#bind_port=8000

# Number of backlog requests to configure the socket with.
# (integer value)
#backlog=4096

# Location of the SSL certificate file to use for SSL mode.
# (string value)
#cert_file=<None>

# Location of the SSL key file to use for enabling SSL mode.
# (string value)
#key_file=<None>

# Number of workers for Heat service. (integer value)
#workers=0

# Maximum line size of message headers to be accepted.
# max_header_line may need to be increased when using large
# tokens (typically those generated by the Keystone v3 API
# with big service catalogs). (integer value)
#max_header_line=16384


[heat_api_cloudwatch]

#
# Options defined in heat.common.wsgi
#

# Address to bind the server. Useful when selecting a
# particular network interface. (string value)
#bind_host=0.0.0.0

# The port on which the server will listen. (integer value)
#bind_port=8003

# Number of backlog requests to configure the socket with.
# (integer value)
#backlog=4096

# Location of the SSL certificate file to use for SSL mode.
# (string value)
#cert_file=<None>

# Location of the SSL key file to use for enabling SSL mode.
# (string value)
#key_file=<None>

# Number of workers for Heat service. (integer value)
#workers=0

# Maximum line size of message headers to be accepted.
# max_header_line may need to be increased when using large
# tokens (typically those generated by the Keystone v3 API
# with big service catalogs.) (integer value)
#max_header_line=16384


[keystone_authtoken]
service_protocol = http
service_host = ${CONTROLLER_HOST}
service_port = 5000
auth_host = ${CONTROLLER_HOST}
auth_port = 35357
auth_protocol = http
auth_uri = http://${CONTROLLER_HOST}:35357/
admin_tenant_name = service
admin_user = heat
admin_password = heat

# Single shared secret with the Keystone configuration used
# for bootstrapping a Keystone installation, or otherwise
# bypassing the normal authentication process. (string value)
admin_token=ADMIN

[matchmaker_redis]

#
# Options defined in heat.openstack.common.rpc.matchmaker_redis
#

# Host to locate redis (string value)
#host=127.0.0.1

# Use this port to connect to redis host. (integer value)
#port=6379

# Password for Redis server. (optional) (string value)
#password=<None>


[matchmaker_ring]

#
# Options defined in heat.openstack.common.rpc.matchmaker_ring
#

# Matchmaker ring file (JSON) (string value)
# Deprecated group/name - [DEFAULT]/matchmaker_ringfile
#ringfile=/etc/oslo/matchmaker_ring.json


[paste_deploy]

#
# Options defined in heat.common.config
#

# The flavor to use. (string value)
#flavor=<None>

# The API paste config file to use. (string value)
#api_paste_config=api-paste.ini


[revision]

#
# Options defined in heat.common.config
#

# Heat build revision. If you would prefer to manage your
# build revision separately, you can move this section to a
# different file and add it as another config option. (string
# value)
#heat_revision=unknown


[rpc_notifier2]

#
# Options defined in heat.openstack.common.notifier.rpc_notifier2
#

# AMQP topic(s) used for OpenStack notifications (list value)
#topics=notifications


[ssl]

#
# Options defined in heat.openstack.common.sslutils
#

# CA certificate file to use to verify connecting clients
# (string value)
#ca_file=<None>

# Certificate file to use when starting the server securely
# (string value)
#cert_file=<None>

# Private key file to use when starting the server securely
# (string value)
#key_file=<None>

EOF

# /etc/heat/heat.conf

heat-manage db_sync

keystone user-create --name=heat --pass=heat --email=heat@localhost
keystone user-role-add --user=heat --tenant=service --role=admin

keystone service-create --name=heat --type=orchestration --description="Heat Orchestration API"

ORCHESTRATION_SERVICE_ID=$(keystone service-list | awk '/\ orchestration\ / {print $2}')

keystone endpoint-create \
  --region regionOne \
  --service-id=${ORCHESTRATION_SERVICE_ID} \
  --publicurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s \
  --internalurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s \
  --adminurl=http://${CONTROLLER_HOST}:8004/v1/$\(tenant_id\)s

keystone service-create --name=heat-cfn --type=cloudformation --description="Heat CloudFormation API"

CLOUDFORMATION_SERVICE_ID=$(keystone service-list | awk '/\ cloudformation\ / {print $2}')

keystone endpoint-create \
  --region regionOne \
  --service-id=${CLOUDFORMATION_SERVICE_ID} \
  --publicurl=http://${CONTROLLER_HOST}:8000/v1/ \
  --internalurl=http://${CONTROLLER_HOST}:8000/v1 \
  --adminurl=http://${CONTROLLER_HOST}:8000/v1

service heat-api restart
service heat-api-cfn restart
service heat-engine restart
