require 'thread'
require 'rack/body_proxy'

module Rack
  class Lock
    FLAG = 'rack.multithread'.freeze

    def initialize(app, mutex = Mutex.new)
      @app, @mutex = app, mutex
    end

    def call(env)
      @mutex.lock
      unlock = Fiber.new do
        Fiber.yield @mutex.unlock
        Fiber.yield @mutex while true
      end
      begin
        response = @app.call(env.merge(FLAG => false))
        returned = response << BodyProxy.new(response.pop) { unlock.resume }
      ensure
        unlock.resume unless returned
      end
    end
  end
end
