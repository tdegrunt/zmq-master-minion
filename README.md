# ZMQ Master Minion

Proof of concept in Ruby.

## Prerequisites

	brew install zmq # Should install ZMQ 3
	gem install ffi-rzmq

## Running


	ruby master.rb
	ruby minion.rb 1
	ruby minion.rb 2
	ruby cli.rb ping 1234
	
	