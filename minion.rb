require 'ffi-rzmq'
require 'msgpack'

def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack) }
    true
  end
end

class Minion
  attr_reader :id
  def initialize(id)
    @id = id
  end

  def connect
    @ctx = ZMQ::Context.create(1)

    # Commands from master
    @sub_sock = @ctx.socket(ZMQ::SUB)
    error_check(@sub_sock.setsockopt(ZMQ::LINGER, 1))
    rc = @sub_sock.setsockopt(ZMQ::SUBSCRIBE,'ping')
    error_check(rc)
    rc = @sub_sock.connect('tcp://127.0.0.1:2200')
    error_check(rc)

    # Answers to master
    @push_sock = @ctx.socket(ZMQ::PUSH)
    error_check(@push_sock.setsockopt(ZMQ::LINGER, 1))
    error_check(@push_sock.connect('tcp://127.0.0.1:2201'))
  end

  def serve
    loop do
      # Since our messages are coming in multiple parts, we have to
      # check for that here
      topic = ''
      rc = @sub_sock.recv_string(topic)
      break if error_check(rc)
      body = ''
      rc = @sub_sock.recv_string(body) if @sub_sock.more_parts?
      break if error_check(rc)

      puts "S#{id}: I received a message! The topic was '#{topic}'"
      puts "S#{id}: The body of the message was '#{body}'"

      error_check(@push_sock.send_string("pong: S#{id} - #{body}"))

    end
  end

  def close
    error_check(@sub_sock.close)
    ctx.terminate
  end
end

m = Minion.new ARGV[0]
m.connect
m.serve
m.close

