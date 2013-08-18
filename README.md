WebSocket Chat
====================

Server
---------------------
First, install the 'em-websocket' gem.

Assuming you have RVM and bundler, open the server directory and run:

    bundle install

Alternatively, just:

    gem install em-websocket


Then run the server with two arguments, the hostname and the port to be run on:

    ruby server/chat_server.rb localhost 3210


Client
---------------------
Simply open client/chat_client.html in your browser of choice (so long as it supports WebSockets).

Enter the server address (e.g. ws://localhost:3210) into the 'Server' field and click 'Connect'.
