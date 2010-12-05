#    Modulus IRC Services
#    Copyright (C) 2010  Modulus IRC Services Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

module Modulus

  class ProtocolAbstraction

    require 'socket'

    def initialize(config)
      @config = config
    end

    def connect
      $log.debug "protocol-unreal32", "Starting connection to IRC server."
      host = @config.getOption('Network', 'link_address')
      port = @config.getOption('Network', 'link_port')
      bindAddr = @config.getOption('Network', 'bind_address')
      bindPort = @config.getOption('Network', 'bind_port')

      socket = TCPSocket.new(host, port, bindAddr, bindPort)
      thread = self.startReaderThread(socket)

      socket.puts "PASS :#{@config.getOption('Network', 'link_password')}"

      socket.puts "PROTOCTL :TOKEN NICKIP CLK SJ3 VHP"
      socket.puts "SERVER #{@config.getOption('Network', 'services_hostname')} 1 :U2309-0 #{@config.getOption('Network', 'services_name')}"
      socket.puts "ES"
      socket.puts "AO 0 #{Time.now.to_i} 2309 * 0 0 0 :#{@config.getOption('Network', 'network_name')}"

      return thread
    end

    def startReaderThread(socket)
      @readThread = Thread.new {

        $log.debug "protocol-unreal32", "Socket reader thread started."

        while line = socket.gets
            puts line
        end
      }
    end

    def closeConnection
      
    end

  end #class ProtocolAbstraction

end #module Modulus
