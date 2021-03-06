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

  class Hook

    ##
    # Create a new hook object. Parameters are this object's parent, the class
    # that owns the book, and the name of the function that should be called
    # when the hook is run.

    def initialize(parent, modClass, func)
      @parent = parent
      @modClass = modClass
      @func = func
    end

    ##
    # Run the hook by calling the owning class with the function name given
    # when the hook was created. The origin that triggered the hook is the only
    # parameter.

    def run(origin)
      $log.debug 'hook', "Running hooks for #{origin}"
      eval("@modClass.#{@func}(origin)")
    end

  end #class Hook

end #module Modulus
