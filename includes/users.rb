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

  class Users

    ##
    # Create our users object. Initialize the data structures we'll use, here.
    # We also register for relevant events: sethost and mode.

    def initialize
      @nicks = Hash.new # Nick => ESVID
      @users = Hash.new # ESVID => User Object

      # TODO: We also need to register for and handle other events, such as
      # swhois.

      Modulus.events.register(:sethost, self, "on_set_host")
      Modulus.events.register(:mode, self, "on_mode")
    end

    ##
    # Add a new user to the tables. Duplicates will result in overwrites.

    def addUser(user)
      # TODO: Fix possible race condition?
      if @nicks.has_key? user.nick
        $log.warning 'users', "Duplicate nick being added to internal list: #{user.nick}. Overwriting."
      end

      # TODO: This is sort of bad. What if the same user logs in from two
      # locations?
      if @users.has_key? user.svid
        $log.warning 'users', "Duplicate SVID being added to internal list: #{user.svid}. Overwriting."
      end

      @nicks[user.nick] = user.svid
      @users[user.svid] = user
    end

    ##
    # Called by sethost event. Used to update the user's vhost, but does not
    # update the actual host name since we might need that for bans or
    # something.

    def on_set_host(origin)
      origin = origin[0]
      user = self.find(origin.source)
      user.vhost = origin.target
    end

    ##
    # Called by the mode event. If this turns out to be for a channel abort.
    # Otherwise, go ahead and find the user and then call the modes function for
    # it.

    def on_mode(origin)
      origin = origin[0]
      return if Modulus.link.isChannel? origin.target

      $log.debug 'users', "Doing modes for #{origin.target}"

      user = self.find(origin.target)
      return if user == nil

      user.modes(origin.message)
    end

    ##
    # Log in the give user/nick with the given user name. No data is sent to
    # the IRC server.

    def logIn(ind, svid)
      #TODO: Make sure the network supports ESVID
      user = self.find(ind)
      user.svid = svid
      user.loggedIn = true
    end

    ##
    # Log out the given nick/user. No data is sent to the IRC server.

    def logOut(ind)
      #TODO: Make sure the network supports ESVID
      user = self.find(ind)
      user.svid = '*'
      user.loggedIn = false
    end

    ##
    # Change the nick for the given user. This is probably called by the nick
    # event when a nick change is taking place.

    def changeNick(ind, newNick, newTimestamp)
      user = self.find(ind)

      if user == nil
        $log.error "user", "While performing a nick change, user #{ind} could not be found."
        return
      end

      user.nick = newNick
      user.timestamp = newTimestamp
    end

    ##
    # Change the user name for the given user.
    # (nick!USER@host)

    def changeUsername(ind, newUser)
      user = self.find(ind)
      user.username = newUser
    end

    ##
    # Change the host name for the given user. This is different from changing
    # the vhost.

    def changeHostname(ind, newHost)
      user = self.find(ind)
      user.hostname = newHost
    end

    ##
    # Change the modes for the given user. This is an explicit change, not a
    # parser for mode strings.

    def changeModes(ind, newModes)
      user = self.find(ind)
      user.modes = newModes
    end

    ##
    # Set a new SVID (logged in user name) for the given user.

    def changeSVID(ind, newSVID)
      user = self.find(ind)
      user.svid = newSVID
    end

    ##
    # Find the user object for the given nick or user name.

    def find(ind)
      if @nicks.has_key? ind
        self.findByNick(ind)
      else
        self.findBySVID(ind)
      end
    end

    def findByNick(nick)
      @users[@nicks[nick]]
    end

    def findBySVID(svid)
      @users[svid]
    end

    ##
    # Delete the user object for the given nick or user name.

    def delete(ind)
      if @nicks.has_key? ind
        self.delByNick(ind)
      else
        self.delBySVID(ind)
      end
    end

    def delBySVID(svid)
      @nicks.delete @users[svid].nick
      @users.delete svid
    end

    def delByNick(nick)
      @users.delete @nicks[nick]
      @nicks.delete nick
    end

  end #class Users

end #module Modulus
