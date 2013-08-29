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

class Commander
  def initialize()
  end

  def connect
    @ctx = ZMQ::Context.create(1)

    # Commands to master
    @req_sock = @ctx.socket(ZMQ::REQ)
    error_check(@req_sock.setsockopt(ZMQ::LINGER, 1))
    error_check(@req_sock.connect('tcp://127.0.0.1:2202'))
  end

  def do(command)
  	@req_sock.send_string(command)
  	answer = ''
  	@req_sock.recv_string(answer)
  	puts answer
  end

  def close
    error_check(@req_sock.close)
    @ctx.terminate
  end
end

m = Commander.new
m.connect
m.do ARGV.join(' ')
m.close

