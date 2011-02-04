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

  class Channel

    attr_reader :name, :topic, :modes, :bans, :users

    ##
    # Record the existence of a new channel. The only parameter is the channel
    # name. Data structures for related data are initialized empty.
    
    def initialize(name)
      @name = name
      @topic = ""
      @modes = Hash.new
      @bans = Array.new
      @users = Hash.new
    end

    ##
    # Add a nick to this channel's list of users. The user will be stored by
    # nick as a ChannelUser object inside @users. This is accessible by the
    # read-only accessor users.

    def join(nick)
      @users[nick] = ChannelUser.new(nick)
      $log.debug 'channel', "User #{nick} has joined #{@name}."
    end

    ##
    # Called when a new topic is set for this channel.

    def topic(topic)
      @topic = topic
      # TODO: Fire an event here?
    end

    ##
    # When new modes are set for the channel, this is called. The parameters are
    # the modes and any parameters included with them. The protocol's list of
    # channel user modes is used here to determine which modes can be applied
    # to users. The channel modes list determines which can have paramters. The
    # rest of the modes are stored alone.

    def modes(modes, params)
      plus = true

      paramModes = Array.new

      pos = 0

      # Let's break the mode string down one character at a time.
      modes.each_char { |c|
        if c == "+"
          plus = true
        elsif c == "-"
          plus = false
        else

          # Is it a channel mode that can apply to a user? (such as +o)
          if Modulus.link.channelUserModes.has_key? c
            if @users.has_key? params[pos]
              @users[params[pos]].modeChange(plus, Modulus.link.channelUserModes[c])
              $log.debug 'channel', "params: #{params} paramModes: #{paramModes}"
            else
              $log.warning 'channel', "Could not find nick #{params[pos]} in channel user list for #{@name} when doing mode change."
            end
            pos += 1

          # It can't apply to a user. Let's only accept it if it is in the
          # list of modes, anyway.
          elsif Modulus.link.channelModes.has_key? c

            # Can this mode have a parameter? (such as +k key)
            if Modulus.link.channelModes[c]
              param = params[pos]
              pos += 1
            else
              param = nil
            end

            $log.debug 'channel', "mode key: #{c} mode value: #{param}"

            if plus
              @modes[c] = param
            else
              @modes.delete(c) if @modes.has_key? c
            end
          end
        end
      }

      $log.debug 'channel', "Updated modes for #{@name}"
    end

    ##
    # Check if the given nick is a channel operator (or better, depenending
    # on IRCD.)
    
    def is_op?(nick)
      if @users.has_key? nick
        modes = @users[nick].modes
        return (modes.include? :op or modes.include? :protected or modes.include? :owner)
      end

      return false
    end


  end #class Channel

end #module Modulus
