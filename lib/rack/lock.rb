require 'thread'
require 'rack/body_proxy'

module Rack
  # Rack::Lock locks every request inside a mutex, so that every request
  # will effectively be executed synchronously.
  class Lock
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
        response = @app.call(env.merge(RACK_MULTITHREAD => false))
        returned = response << BodyProxy.new(response.pop) { unlock.resume }
      ensure
        unlock.resume unless returned
      end
    end
  end
end
