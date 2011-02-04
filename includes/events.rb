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

  class Events
 
    ##
    # Create the events data structure.
    
    def initialize
      @events = Hash.new
    end

    # Register a new event with callback. The parameters are the event for which
    # we are registering (such as :join), the sender of the function call (used
    # as the callback function name owner) and the name of the function to use
    # as callback.

    def register(event, sender, func)
      $log.debug 'events', "#{sender.class}.#{func} registered for event: #{event}"
      @events[event] = Array.new unless @events.has_key? event

      @events[event] << EventCallback.new(sender, func)
    end

    ##
    # Fire the callback for the given event. Optionally, one or more additional
    # parameters may be included to be passed to the callback function. If the
    # function doesn't accept the given number of parameters, an exception may
    # be thrown.

    def event(event, *args)
      if @events.has_key? event
        $log.debug 'events', "Event fired: #{event}"
        @events[event].each { |c| c.run(args) }
      else
        $log.debug 'events', "Attempted to fire event with no recipients: #{event}"
      end
    end

  end #class EVents

  class EventCallback
    attr_reader :obj, :func
    
    ##
    # Create a new event callback object. The parameters include the object
    # that owns the function we will call, and the name of the function (string)

    def initialize(obj, func)
      @obj = obj
      @func = func
    end

    def run(args)
      $log.debug 'events', "Running event for #{obj}.#{func}"
      eval ("@obj.#{@func}#{"(args)" unless args.length == 0}")
    end
  end #class EventCallback

end #module Modulus
