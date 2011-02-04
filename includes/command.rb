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

  class Command

    attr_reader :commandText, :shortDesc, :longDesc, :allowFantasy

    ##
    # Create a new command object. This is called when the hook is being
    # created and will use all of the same parameters.

    def initialize(sender, funcName, commandText, shortDesc, longDesc, allowFantasy)
      @owner = sender
      @commandText = commandText
      @shortDesc = shortDesc
      @longDesc = longDesc
      @funcName = funcName
      @allowFantasy = allowFantasy
    end

    ##
    # Run the command. The only parameter is the origin info that triggered the
    # command.

    def run(origin)
      $log.debug 'command', "Running command #{@commandText} for #{origin.source}"
      eval("@owner.#{@funcName}(origin)")
    end

  end #class Command

end #module Modulus
