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

  class Module

    attr_reader :name, :description, :author, :version

    ## 
    # Initialize a new module object. Not to be confugused with Ruby modules,
    # this refers to Modulus modules, such as NickServ.
    #
    # Parameters include the name of the module, a brief description of the
    # module, the author of the module, adn the version of the module.
    #
    # A hash table of module commands is initialized here.

    def initialize(name, description, author, version)
      @name = name
      @description = description
      @author = author
      @version = version
      @commands = Hash.new
    end

    ##
    # Add a command to the module.
    #
    # Parameters include a command object and an array of triggers.

    def addCommand(command, triggers)
      @commands[trigger] = Hash.new unless @commands.has_key? trigger

      triggers.each { |trigger|
        if @commands[trigger].has_key? command.commandText
          $log.warning 'module', "Command #{command.commandText} registered twice. Overwriting."
        end

        @comamands[trigger][command.commandText] = command
        $log.debug 'module', "Command #{command.commandText} added."
      }
    end

    ##
    # Check if this module has a command for the given trigger and then of the
    # given name.

    def hasCommand?(command, trigger)
      if @commands.has_key? trigger
        return @commands[trigger].has_key? command
      end
      return false
    end

    ##
    # If this module has the given command, return it.

    def getCommand(command, trigger)
      if self.hasCommand? command, trigger
        return @commands[trigger][command]
      end
      return false
    end

  end #class 

end #module Modulus
