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

  class User

    attr_accessor :nick, :svid, :username, :hostname, :channels, :timestamp, :modes, :loggedIn, :vhost, :modes

    ##
    # Create a new user object.
    #
    # Parameters are the nick, svid (logged in user name), user name, host name,
    # and timestamp for the user.

    def initialize(nick, svid, username, hostname, timestamp)
      #TODO: SVID is not the right thing to use here.
      @nick = nick
      @svid = svid
      @username = username
      @hostname = hostname
      @timestamp = timestamp
      @modes = Array.new
      @vhost = ""
      if svid != '*'
        self.logIn(svid)
      else
        @loggedIn = false
      end
    end

    ##
    # Check whether or not the user is logged in.

    def logged_in?
      @loggedIn
    end

    ##
    # Called when a MODE message is received for this user. Updates the array
    # of modes by parsing the mode update string to find +/- changes.
    #
    # Parameter is the mode change string (*not* an origin info object).

    def modes(modes)
      plus = true

      modes.each_char { |c|
        if c == "+"
          plus = true
        elsif c == "-"
          plus = false
        else
          if plus
            @modes << c
          else
            @modes.delete(c) if @modes.include? c
          end
        end
      }
      $log.debug 'user', "Updated modes for #{nick}: #{@modes.join(", ")}"
    end

    ##
    # Log this user in with the given user name. Marks the user as logged in
    # but does not send anything to the IRC server.

    def logIn(username)
      #TODO: Make this send stuff to the server. We shouldn't be handling that
      # in the modules. In fact, it should be done in the protocol handler,
      # since it won't be the same for each!
      $log.debug 'user', "User at nick #{@nick} has logged in as #{username}"
      @svid = username
      @loggedIn = true
      Modulus.events.event(:logged_in, self)
    end

    ##
    # Check if this user's modes include any that are listed in the protocol
    # class's list of operator modes.

    def is_oper?
      @modes.each { |mode|
        if Modulus.link.operModes.include? mode
          return true
        end      
      }
      return false
    end

    ##
    # Check if any of the user modes indicate the user is a services admin
    # or higher, according to the modes listed in the protocol class's list.

    def is_services_admin?
      # TODO: This probably won't work for all protocols. Will it? Maybe we need
      # to do like Anope and just keep our own list of services admins. Dunno!
      @modes.each { |mode|

        mode = Modulus.link.userModes[mode]
        if mode == :services_admin or mode == :network_admin or mode == :co_admin or mode == :server_admin
          return true
        end      
      }
      return false
    end

  end #class User
end #module Modulus
