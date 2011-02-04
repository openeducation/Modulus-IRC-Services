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

  class Channels

    attr_reader :channels

    ##
    # Create the channels data structure. We'll create the hash table for
    # channels and register relevant events: join and mode.
    
    def initialize
      @channels = Hash.new
      Modulus.events.register(:join, self, "on_join")
      Modulus.events.register(:mode, self, "on_mode")
    end

    ##
    # Called by the join event.
    #
    # Creates a new channel object if one does not
    # exist and then calls that channel's join function with the nick that is
    # joining.

    def on_join(origin)
      origin = origin[0]

      unless @channels.has_key? origin.message
        @channels[origin.message] = Channel.new(origin.message)
      end

      @channels[origin.message].join origin.source
    end

    ##
    # Almost identical to on_join, but for use by Modulus modules. When a
    # service joins a channel, no JOIN message is received. So to keep a
    # record of it, we must add it ourselves.
    #
    # Parameters are the nick joining and the channel being joined.
    #
    # If the given channel does not yet exist, create it.

    def mod_join(nick, channel)
      unless @channels.has_key? channel
        @channels[channel] = Channel.new(channel)
      end

      @channels[channel].join nick
    end

    ##
    # Called by the mode event.
    #
    # This only takes an origin info as a parameter. We'll try to figure out
    # how the MODE message is formatted and pass it along to the channel object
    # with things in the proper places.

    def on_mode(origin)
      origin = origin[0]
      return unless Modulus.link.isChannel? origin.target

      if @channels.has_key? origin.target

        # TODO: Make sure this is good for other protocols. Only tested for
        # Unreal3.2

        last = (origin.arr.length == 5 ? 4 : origin.arr.length - 1)
        $log.debug 'channels', "Last position for parameters: #{last} Length: #{origin.arr.length} Origin: #{origin}"
        @channels[origin.target].modes(origin.arr[3], origin.arr[4..last])
      end
    end

    ##
    # Check if the given nick is a channel operator or better for the given
    # channel. The actual work is done in the relevant channel object, if it
    # exists.

    def is_op?(nick, channel)
      if @channels.has_key? channel
        return @channels[channel].is_op? nick
      end

      return false
    end

  end #class 

end #module Modulus
