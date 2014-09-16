module IRCGongbot
  class MQTTConnection < EventMachine::MQTT::ClientConnection
    def initialize(opts)
      @opts = opts
    end

    def post_init
      super
      chan = "#{@opts[:topic_root]}/+/button"

      $stderr.puts("INFO: MQTT Connected. Subscribing to `#{chan}`.")
      subscribe(chan)
    end

    def send_ping
      publish("#{@opts[:topic_root]}/gongbot/button", 'ping')
    end

    def unbind
      timer.cancel if timer
      unless state == :disconnecting
        $stderr.puts('WARN: Connection lost trying again in 20 seconds')
        EventMachine::Timer.new(20) do
          # Hackish way to reset the deferred and prevent subscribe from calling early
          @deferred_status = :unknown

          reconnect(@opts[:host], @opts[:port])
          post_init
        end
      end
      @state = :disconnected
    end
  end
end
