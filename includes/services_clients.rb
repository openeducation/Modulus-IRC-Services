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

  class Clients

    attr_reader :clients

    ##
    # Create a new services clients object.

    def initialize
      @clients = Hash.new
    end

    ##
    # Create a new pseudoclient and add it to our list. No data is sent to the
    # IRC server here.
    #
    # Parameters are the nick of the client and the gecos.

    def addClient(nick, realName)
      @clients[nick] = Pseudoclient.new(nick, realName)
    end

    ##
    # Return the hash table of clients.

    def getAll
      return @clients
    end

    ##
    # Disconnect each client one at a time.

    def disconnectClients
      @clients.each { |client|
        client.disconnect
      }
    end

    ##
    # Check if the given nick is one of the pseudoclients that belongs to
    # Modulus.

    def isMyClient?(nick)
      @clients.has_key? nick
    end

    ##
    # If configured, all pseudoclients are sent to the log channel.

    def joinLogChan
      $log.debug "clients", "Sending all connected pseudoclients to the log channel, if it is configured."
      @clients.values.each { |client| client.joinLogChan }
    end

    ##
    # All pesudoclients are "connected" to IRC. This should probably never be
    # called: Clients are created before connect and sent during sync, then
    # usually connected as they are created after that. Calling this may result
    # in some duplicates.

    def connectAll
      @clients.keys.each { |nick| self.connect(nick) }
    end

    ##
    # "Connect" the given pseudoclient to IRC, if it is in our clients table.

    def connect(nick)
      return false unless self.isMyClient? nick

      $log.debug "clients", "Attempting to connect #{nick}"
      @clients[nick].connect
      @clients[nick].joinAllChannels
      
    end

  end #class 

end #module Modulus
