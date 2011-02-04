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

  class Pseudoclient

    attr_reader :nick, :realName, :services

    ##
    # Create a new pseudoclient object. The paramters are the nick and the
    # gecos to use for the client. No data is sent over the link — this just
    # adds the client to our lists and creates the appropriate structures.
    
    def initialize(nick, realName)
      @nick = nick
      @realName = realName
      @channels = Array.new
    end

    ##
    # Send the pseudoclient to the configured log chan, if there is one.

    def joinLogChan
      logChan = Modulus.config.getOption("Core", "log_channel")

      if logChan != nil
        self.addChannel logChan
      end
    end

    ##
    # Add a channel to this client's list, and join it to the channel.

    def addChannel(channel)
      @channels << channel
      Modulus.link.joinChannel(@nick, channel)
    end

    ##
    # Remove a channel from this client's list, and part it from the channel.

    def removeChannel(channel)
      @channels.delete channel
      Modulus.link.partChannel(@nick, channel)
    end

    ##
    # Join all channels in this client's list.

    def joinAllChannels
      @channels.each { |c|
        Modulus.link.joinChannel(@nick, c)
      }
    end

    ##
    # Send the command to the IRC server to create the client (usually NICK).

    def connect
      Modulus.link.createClient(@nick, @realName)
    end

    ##
    # Send the command to the IRC server to destroy the client. Optionally, a
    # quit message may be included. The default is to leave the reason empty.

    def disconnect(reason="")
      Modulus.link.destroyClient(@nick, reason)
    end

  end #class Pseudoclient

end #module Modulus
