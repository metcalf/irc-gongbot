module IRCGongbot
  class Gongbot
    # Create an instance of the IRC bot without connecting
    # Params:
    # +thaum+:: Thaum instance from the Ponder IRC library
    # +mqtt_host+:: Hostname of the MQTT server (e.g. "m2m.eclipse.org")
    # +mqtt_port+:: Port of the MQTT server (e.g. 1883)
    # +topic_root+:: Root topic where gongs are publishing (e.g. "/foo/bar")
    def initialize(thaum, main_channel, mqtt_host, mqtt_port, topic_root)
      @last_ping_user = nil

      @thaum = thaum
      @main_channel = main_channel
      @mqtt_config = {
        :host => mqtt_host,
        :port => mqtt_port,
        :topic_root => topic_root
      }

      configure_irc
    end

    # Connect to MQTT broker and IRC server and block while serving
    def run!
      EventMachine.run do
        @mqtt_connection = EventMachine.connect(
          @mqtt_config[:host], @mqtt_config[:port],
          MQTTConnection, @mqtt_config
          )

        @mqtt_connection.receive_callback { |m| mqtt_message(m) }

        EventMachine::PeriodicTimer.new(60*60*3) do
          @last_ping_user = nil
          if @mqtt_connection.state == :connected
            $stderr.puts('Sending periodic ping')
            @mqtt_connection.send_ping
          else
            $stderr.puts('MQTT is disconnected')
          end
        end

        @thaum.connect do
          @thaum.join(@main_channel)
        end
      end
    end

    private

    def mqtt_message(message)
      name = message.topic.split('/')[-2]
      if message.payload == 'released'
        @thaum.message(@main_channel, "Gonnnggg! (#{name})")
      elsif message.payload == 'ping'
        if @thaum.connected
          msg = 'pong'
        else
          msg = 'noirc'
        end

        $stderr.puts("INFO: Received ping, sending response: #{msg}.")

        @mqtt_connection.publish("#{@mqtt_config[:topic_root]}/gongbot/button", msg)
      elsif message.payload == 'pong'
        $stderr.puts("Received pong from #{name}")
        @thaum.message(@last_ping_user, "#{name}: pong") if @last_ping_user
      end
    end

    def configure_irc
      @thaum.on :query, /\Aping/ do |e|
        @thaum.message(e[:user], 'pong')
        @last_ping_user = e[:user]
        @mqtt_connection.send_ping
      end
    end
  end
end
