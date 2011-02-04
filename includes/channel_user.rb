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

  class ChannelUser

    attr_reader :nick, :modes

    ##
    # Create a new channel user object. The only parameter is the user's nick.
    # An empty modes array is initialized.

    def initialize(nick)
      @nick = nick
      @modes = Array.new
    end

    ##
    # Apply updates to single modes. The parameters are plus (if true, add the
    # mode to the list; if false, remove it) and the mode being modified.

    def modeChange(plus, mode)
      $log.debug 'channeluser', "Updating modes for #{nick}: #{plus ? "+" : "-"}#{mode}"
      plus ? @modes << mode : (@modes.delete mode if @modes.include? mode)
    end

  end #class ChannelUser

end #module Modulus
