#    Modulus IRC Services
#    Copyright (C) 2010  Modulus IRC Services Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

module Modulus

  class ProtocolAbstractionMixin

    attr_reader :channelModes, :channelModePrefixes, :channelPrefixes, :userModes, :operModes, :channelUserModes

    ##
    # Put a raw string in the send queue.

    def send_raw(str)
      @sendq << str
    end

    ##
    # Start a thread to read from the IRC link socket. Received messages are
    # passed to the parser which is created here.

    def startRecvThread
      @readThread = Thread.new {

        #while not Modulus.quitting
        # TODO: Reconnections!

          $log.debug "protocol", "Socket reader thread started."
          @parser = Modulus::Parser.new(@cmdList)

          while line = @socket.gets.chomp
            #TODO: Parse this, hand it off to something else.
            #puts "<-- #{line}"
            begin
              @parser.parse line
            rescue => e
              $log.error 'protocol', "There was an error parsing an incoming message [#{line}]: #{e}"
            end 
          end

          $log.info "protocol", "Connection to the server has been lost."

        #end

        $log.debug "protocol", "Socket reader thread ending."

      }
    end

    ##
    # Start the thread that will take messages from the send queue and feed them
    # to the socket.

    def startSendThread
      @sendThread = Thread.new {

        $log.debug "protocol", "Socket send thread started."

        while str = @sendq.pop
          puts "SENT --> #{str}"
          @socket.puts str

          # TODO: Make this less retarded. We sleep here so that other threads
          # can still work while we process a large send queue. That way, if,
          # for instance, a member of staff requests a very long list, we can
          # continue to handle user requests while the data is fed to the
          # socket.
          sleep 0.001
        end

        $log.debug "protocol", "Socket send thread stopping."
      }

    end
  end #class ProtocolAbstraction

end #module Modululs
