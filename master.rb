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

class Master
  def initialize
  end
  def connect
    @ctx = ZMQ::Context.create(1)

    # Commands to minions
    @pub_sock = @ctx.socket(ZMQ::PUB)
    error_check(@pub_sock.setsockopt(ZMQ::LINGER, 1))
    error_check(@pub_sock.bind('tcp://127.0.0.1:2200'))

    # Answers from minions
    @pull_sock = @ctx.socket(ZMQ::PULL)
    error_check(@pull_sock.setsockopt(ZMQ::LINGER, 1))
    error_check(@pull_sock.bind('tcp://127.0.0.1:2201'))

    # Replies to commands to master
    @rep_sock = @ctx.socket(ZMQ::REP)
    error_check(@rep_sock.setsockopt(ZMQ::LINGER, 1))
    error_check(@rep_sock.bind('tcp://127.0.0.1:2202'))

  end

  def serve

    # Answer thread
    Thread.new do
      loop do
        input_str=''
        rc = @pull_sock.recv_string(input_str)
        error_check(rc)
        puts "#{input_str}"
      end
    end

    # Command thread
    Thread.new do

      loop do

        cmd = ''
        error_check(@rep_sock.recv_string(cmd))

        topic = cmd.split[0]
        body = cmd.split[1..-1].join(' ')

        rc = @pub_sock.send_string(topic, ZMQ::SNDMORE)     #Topic
        break if error_check(rc)
        rc = @pub_sock.send_string(body)           #Body
        break if error_check(rc)

        @rep_sock.send_string("#{topic} #{body}")

      end

    end.join
  end

  def close
    error_check(@pub_sock.close)
    @ctx.terminate
  end
end

m = Master.new
m.connect
m.serve
m.close

