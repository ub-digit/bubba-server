module Requests
  module JsonHelpers
    def json
      unless @last_response_body === response.body
        @json = nil
      end
      @last_response_body = response.body
      @json ||= JSON.parse(response.body)
    end
  end
end

class Time
  class << self
    alias :old_now :now
  end
  def self.now
    @@spec_forced_time ||= nil
    if @@spec_forced_time
      return @@spec_forced_time
    end
    old_now
  end

  def self.spec_force_time(timestamp)
    @@spec_forced_time ||= nil
    @@spec_forced_time = timestamp
  end

  def self.spec_reset_forced_time
    @@spec_forced_time ||= nil
    @@spec_forced_time = nil
  end
end
