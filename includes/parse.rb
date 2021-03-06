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

  class Parser

    ##
    # Create a new parser object.
    #
    # The only parmeter is a list of valid commands (message types) that may be
    # parsed by this class.

    def initialize(cmdList)
      @cmdList = cmdList
    end

    ##
    # Parse a raw line that has arrived from the IRC server.
    #
    # During parsing, we will determine what type of message this is, who caused
    # it to be sent, where it is going, and whatever else is relevant.
    #
    # Once this information has been determined, we feed it to the protocol's
    # parser. If the message is a server PING meant to check for us being alive,
    # we'll answer it here (we wouldn't want to keep the server waiting too
    # long, would we?) before passing the data to the protocol parser.

    def parse(line)

      line = line.strip

      # No sense in parsing an empty line.
      return if line.length == 0

      origin = ""
      cmd = ""
      lineArr = line.split(" ")

      if line[0] == ":"
        # First bit is going to be a source of some kind!
        origin = lineArr[0][1..lineArr[0].length-1]
        cmd = lineArr[1]
        cmdName = @cmdList[cmd]

        if cmdName == nil
          $log.warning 'parse', "Received unknown message type #{cmd} from server."
          puts "--> #{origin} sent unknown cmd #{cmd} (#{line})"
          return
        else

          line[0] = ""
          msg = ""
          if line.include? ":"
            #splt = line.split(":")
            #msg = splt[1..splt.length-1].join(" ")
            msg = line[line.index(":")+1..line.length-1]
          else
            msg = line
          end

          origin = OriginInfo.new(line, origin, lineArr[2], msg, cmdName)
          #puts "--> #{origin} sent #{cmdName} (#{line})"
        end
      else
        cmd = lineArr[0]
        cmdName = @cmdList[cmd]

        origin = OriginInfo.new(line, origin, lineArr[1], cmd, cmdName)
        #puts "->> unknown sent (#{line})"
      end

      if origin.type == :ping
        Modulus.link.sendPong(origin)
      end

      puts "#{origin}"
      Modulus.link.parse(origin)
    end

    ##
    # This function originally took care of the entire parsing and protocol
    # parsing deal, but now just hands the message off to the core's function
    # to run hooks.
    # 
    # The only parameter is an origin info object.

    def work(origin)
      $log.debug 'parser', "Doing work on #{origin}"
      Modulus.runHooks(origin)
    end

    ##
    # If we got a NICK message, we'll figure out what to do with it in this
    # function.
    #
    # The only parameter is the ogiin info object for the message that 
    # triggered the call.
    #
    # In here, we'll figure out if this is a new user connecting to IRC or if
    # it is someone changing nicks.

    def handleNick(origin)
      # Have the protocol handler figure out how to make it a user object since
      # nobody follows 2813 just right.
      # TODO: Move part of this to protocol handler
      if origin.arr.length == 4
        #nick cahnge
        Modulus.users.changeNick(origin.source, origin.arr[2], origin.arr[3])
      else
        user = Modulus.link.createUser(origin)
        $log.debug "parser", "Added user #{user.nick}!#{user.username}@#{user.hostname} (#{user.svid} / #{user.timestamp}) after receiving NICK."

        # Add the user to whatever this is.
        Modulus.users.addUser(user)
      end

      self.work(origin)
    end

    ##
    # This is triggered by the protocol parser when we receive a KILL command.
    # 
    # The only parameter is the origin info object for the message that
    # triggered the call.
    #
    # If the KILL is meant for one of our services, we'll go ahead and tell the
    # IRC server that the client just connected again. If it is not, then we'll
    # just delete our record for the killed user.

    def handleKill(origin)
      if Modulus.clients.isMyClient? origin.target
        Modulus.clients.connect origin.target
      else
        Modulus.users.delete origin.target
      end

      self.work(origin)
    end

    def handleKick(origin)
      self.handleOther origin
    end

    ##
    # This function also calls core's run commands function.

    def handlePrivmsg(origin)
      Modulus.runCmds(origin)
      self.handleOther origin
    end

    ##
    # This function also calls core's run commands function.

    def handleNotice(origin)
      Modulus.runCmds(origin)
      self.handleOther origin
    end

    ##
    # Delete the associated user from our user list.

    def handleQuit(origin)
      Modulus.users.delete origin.target
      self.work(origin)
    end

    def handleJoin(origin)
      $log.debug "parser", "Handling join for #{origin.source} -> #{origin.message}"
      self.handleOther origin
    end

    def handlePart(origin)
      self.handleOther origin

    end

    def handleMode(origin)
      self.handleOther origin

    end

    def handleServer(origin)
      self.handleOther origin

    end

    def handleServerQuit(origin)
      self.handleOther origin

    end

    ##
    # Pass this to the parser work function.

    def handleOther(origin)
      self.work(origin)
    end

  end #class 

end #module Modulus
