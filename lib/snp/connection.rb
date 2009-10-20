module SNP
  class Connection < EM::Connection
    is :loggable
    
    SEPERATOR = "\r\n".freeze

    class_inheritable_accessor :actions
    self.actions = {}

    def self.on_action(name, &blk)
      method_name = :"handle_action_#{name}"
      self.actions[name.to_s] = method_name
      define_method(method_name, &blk)
    end

    def initialize(*args)
      @buffer = BufferedTokenizer.new(SEPERATOR)
    end
    
    def receive_data(data)
      @buffer.extract(data).each { |c| receive_message(c) }
    end
    
    def send_message(raw_part_text)
      send_data "#{raw_part_text}#{SEPERATOR}"
    end
    
    def handle_action(name, data)
      method_name = self.actions[name]
      return unless method_name.present? && respond_to?(method_name)
      begin
        send(method_name, data) 
      rescue Exception => e
        logger.error "Exception #{e.class.name} processing action (#{name}):"
        logger.error "Message: #{e.message}"
        logger.error "Backtrace:"
        e.backtrace.each { |line| logger.error "--> #{line}" }
      end
    end
    
    def perform_action(name, data = {})
      send_message(Yajl::Encoder.encode({
        "action" => name.to_s,
        "data"   => data.stringify_keys
      }))
    end
    
    protected
    
    def receive_message(message)
      processed = Yajl::Parser.parse(message)
      return unless processed.is_a?(Hash)
      action, data = processed["action"], processed["data"]
      return unless action.is_a?(String) || data.is_a?(Hash)
      handle_action(action, data)
    rescue Yajl::ParseError => e
      logger.warn "Error parsing incoming message"
    end
    
  end
end