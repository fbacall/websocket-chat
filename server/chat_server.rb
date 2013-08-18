require 'rubygems'
require 'em-websocket'

class User
  attr_reader :websocket, :colour
  attr_accessor :name
  
  def initialize(websocket, name, colour)
    @websocket = websocket
    @name = name
    @colour = colour
  end

  def send(msg)
    @websocket.send(msg)
  end
  
  def disconnect(msg)
    send(msg)
    @websocket.close 
  end

  # This should probably be done on the client...
  def tag
    "<span class=\"username #{colour}\">#{name}</span>"
  end

end

class ChatServer

  @@socket_count = 0

  def initialize(host, port)
    @host = host #ARGV[0]
    @port = port #ARGV[1].to_i
    @connected_users = []
    @state = :disconnected
  end

  def run
    EM.run do
      @state = :connected
      EM::WebSocket.run(:host => @host, :port => @port, :debug => false) do |ws|
        user = nil
        socket_id = @@socket_count += 1
        ws.onopen do |handshake|
          puts "WebSocket #{socket_id} opened: #{{:path => handshake.path, :query => handshake.query, :origin => handshake.origin}}"
          user = User.new(ws, handshake.query["name"], handshake.query["colour"])
          connect_user(user)
        end
        ws.onmessage do |msg|
          parse(user, msg)
        end
        ws.onclose do
          disconnect_user(user)
          puts "WebSocket #{socket_id} closed"
        end
        ws.onerror do |e|
          puts "Error: #{e.message}"
          e.backtrace.each {|b| puts "    #{b}"}
        end
      end
    end
  end

  private  

  # Handle user input
  def parse(user, msg)
    # Sanitise!
    msg.gsub!('<','&lt;')
    msg.gsub!('>','&gt;')
    # Emote
    if msg.start_with?('/me')
      broadcast "#{user.tag} #{msg.split(' ',2).last}"
    # Private message
    elsif msg.start_with?('/msg')
      target, msg = msg.split(' ',3)[1..2]
      if recipient = @connected_users.find {|u| u.name == target}
        recipient.send("<i>From #{user.tag}: #{msg}</i>")
        user.send("<i>To #{user.tag}: #{msg}</i>")
      else
        user.send("'#{target}' is not connected.")
      end
	  # List users
    elsif msg.start_with?('/list')
      user.send("Connected users: " + @connected_users.map {|u| u.tag}.join(", "))
    # Chat
    else
      broadcast "#{user.tag}: #{msg}"
    end
  end

  # Handle user connection
  def connect_user(user)
    unless user.name =~ /[A-Za-z0-9_]+/
      user.disconnect("Invalid name. Please use only alphanumeric characters and underscores.")
    end

    # Make sure all names are unique.
    num = 1
    desired_name = user.name
    other_users = @connected_users - [user]
    while other_users.any?{|u| u.name == user.name} do
      user.name = "#{desired_name}(#{num+=1})"
    end
    
    unless user.colour =~ /[A-Za-z0-9_]+/
      user.disconnect("Invalid colour choice.")
    end
    
    @connected_users << user
    broadcast "#{user.tag} has joined."
    user.send "Welcome #{user.name}! #{other_users.size} other user#{(other_users.size) == 1 ? '' : 's'} chatting."
  end

  def disconnect_user(user)
    @connected_users.delete(user)
    broadcast "#{user.tag} has left."
  end
  
  def broadcast(msg)
    @connected_users.each {|u| u.send(msg)}
  end

end

ChatServer.new(ARGV[0] || "0.0.0.0", ARGV[1] || '3005').run
