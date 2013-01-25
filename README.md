erlTalk
===========

Web Erlang and WebSocket based chat with rich UI. 

Installation

1) To get erlTalk work you need to install RabbitMQ server.

Then to enable RabbitMQ web console run:

sudo rabbitmq-plugins enable rabbitmq_management

sudo /etc/init.d/rabbitmq-server restart

After service restart go to http://127.0.0.1:15672/ and log in as guest/guest.
On "Admin" tab click "Virtual Hosts" and add a new virtual host "/chat".

Then give permissions for guest user:

rabbitmqctl.bat set_permissions -p /chat guest ".*" ".*" ".*"

2) MySQL server.

Create new database and then import it's structure:

mysql -u user -p dbname<data/chat.sql
