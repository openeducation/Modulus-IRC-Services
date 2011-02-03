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

  ##
  # When Modulus starts, this is the first thing that runs at the end of the
  # main launcher.

  def Modulus.start(config)
    # Module attribute accessors.

    Modulus.mattr_accessor :events, :clients, :serviceModules, :users, :hooks, :cmdHooks, :messageHooks, :scheduler, :hostname, :name, :config

    @@config = config

    # We want to go ahead and load the logger early since we'll want to record
    # the load process. Config has to be loaded before this since it will affect
    # where logs go and how verbose they are.

    $log = Modulus::Log.new(config)
    $log.info "core", "#{NAME} version #{VERSION} is starting."


    # Lots of classes to instantiate.
    # It probably wouldn't hurt to have this event-driven, but we'll at least
    # need to keep the event class here for that to work.

    @@events = Modulus::Events.new

    @@clients = Modulus::Clients.new
    @@serviceModules = Modulus::ServiceModules.new
    @@users = Modulus::Users.new
    @@channels = Modulus::Channels.new

    # Classes are ready. Now we need some hash tables for runtime data, like
    # hooks. These will probably go away before beta since everything will be
    # driven by the Events class.

    @@hooks = Hash.new
    @@cmdHooks = Hash.new
    @@messageHooks = Hash.new

    # The scheduler gets started now that everything is instantiated and tables
    # are ready. We're using a third-party library for this. Why reinvent it?

    @@scheduler = Rufus::Scheduler.start_new
    
    # Let's go ahead and pull some config values into the class since we'll
    # probably need to use them quite a bit.

    @@hostname = config.getOption("Core", "services_hostname")
    @@name = config.getOption("Core", "services_name")

    # Important config values are in memory, classes are ready, and tables are
    # instantiated. Since we're event-driven, we'll need to register some
    # events that will run in the core code.

    # When we're done connecting to whatever database we're configured to use,
    # we have to make sure it is ready for use and has tables we need.
    @@events.register(:database_connected, self, "prepDatabase")

    # Help is currently controlled by the core. Presumably, almost all modules
    # will have commands or other features that might require some explanation
    # for end users or network staff. It is therefore reasonable that we include
    # help as part of the core code, rather than as a module.
    #
    # In order for help to work, we have to intercept all PRIVMSGs and NOTICES
    # as events to see if they are requests for help or information.
    @@events.register(:privmsg, self, "doHelp")
    @@events.register(:notice, self, "doHelp")

    # We also have to intercept PRIVMSGs to check if they are fantasy commands.
    @@events.register(:privmsg, self, "fantasy")

    # Now it's time to load our modules. This will likely be moved off to its
    # own file at some point, but for now we do it here. Modules are stored in
    # the modules directory, each inside their own directory. There can be many
    # files for each module. Right now, we're loading all of them here. What we
    # should do, though, is just load main.rb and let it take care of including
    # other files as needed.
    #
    # We might need to change this to make it more friendly to dynamic module
    # reloading, but that's probably something that will happen when we move it
    # to another file.
    Dir["./modules/*"].each { |servDir|
      servName = File.basename servDir
      $log.debug "core", "Attemping to load module #{servName}."

      Dir["#{servDir}/*.rb"].each { |file|
        load(file)
      }

      eval("#{servName}.new")
    }

    # Start the database. This will connect us, open a file, or whatever has to
    # be done for the selected database, and then fire the event.
    Modulus.startDB()

    # Next, we'll need to load the appropriate file for the IRC server protocol
    # we're configured to use. These are kept in the protocol directory. We'll
    # first check if the file exists, then load it. No checks are made here if
    # the file contains everything it needs to.
    protocol = config.getOption('Network', 'link_protocol')

    $log.debug "core", "Checking for protocol handler for #{protocol}."

    if File.exists? "protocols/#{protocol}.rb"
      $log.debug "core", "Handler exists."
    else
      $log.fatal "core", "No handler exists for #{protocol}."
      $stderr.puts "Fatal Error: Could not find the handler for link protocol #{protocol}."
      exit -1
    end

    load("protocols/#{protocol}.rb")

    # This will instantiate the classes and whatnot needed for communication
    # with the IRC server. We'll keep this in @@link and use that for sending
    # commands and messages to IRC.
    @@link = Modulus::ProtocolAbstraction.new

    # Now that we're connected to the IRC server, we need to hook ourselves to
    # process signals so we can cleanly quit or rehash when asked.
    trap("INT"){ @@link.closeConnection() }
    trap("TERM"){ @@link.closeConnection() }
    trap("KILL"){ exit } # Kill (signal 9) is pretty hardcore. Just exit!

    trap("HUP", "IGNORE") # TODO: Rehash.

    # We're going to need at least one way to talk to IRC users, so let's
    # create the Global user first thing.
    @@clients.addClient('Global', "Global Noticer")

    # Let's start connecting! This is synchronous, but ends with the listener
    # loop thread being returned once connection is complete.
    $log.debug "core", "Connecting."
    thread = startConnectionThread

    @@clients.joinLogChan

    $log.info "core", "IRC Services has started successfully."

    # TODO: Don't sleep. Fire an event when sync is done!
    sleep 0.5
    @@events.event(:done_connecting)

    # Right now, we're going to keep running in the foreground. Before we go to
    # beta, we'll want to fork to the background instead.
    thread.join
  end

  ##
  # Send a message to the user that sent the given origin.

  def Modulus.reply(origin, message)
    if message.empty?
      $log.warning "core", "Attempted to send an empty message to #{origin.target} (#{origin.source})"
      return
    end

    if @@link.isChannel? origin.target
      # TODO: Make this come from the actual service that sent it!
      message.split("\n").each { |msg|
        @@link.sendPrivmsg("Global", origin.target, msg)
      }
    else
      message.split("\n").each { |msg|
        @@link.sendNotice(origin.target, origin.source, msg)
      }
    end
  end

  ##
  # Run hooks and message hooks for a given origin type.

  def Modulus.runHooks(origin)
    @@events.event(origin.type, origin)

    if @@hooks.has_key? origin.type

    $log.debug "core", "Running all hooks of type #{origin.type}"

      @@hooks[origin.type].each { |hook|
        hook.run(origin)
      }
    end

    if @@messageHooks.has_key? origin.target
      if @@messageHooks[origin.target].has_key? origin.type

        $log.debug "core", "Running all message hooks of type #{origin.type}"

        @@messageHooks[origin.target][origin.type].each { |hook|
          hook.run(origin)
        }
      end
    end
  end

  ##
  # Run hooks for the given command, if the command is sent privately and is
  # sent to a user that can receive commands, and the message contains a command

  def Modulus.runCmds(cmdOrigin)
    return if @@link.isChannel? cmdOrigin.target

    if @@cmdHooks.has_key? cmdOrigin.target
      if @@cmdHooks[cmdOrigin.target].has_key? cmdOrigin.cmd

        $log.debug "core", "Running all command hooks for #{cmdOrigin.cmd}"

        @@cmdHooks[cmdOrigin.target][cmdOrigin.cmd].run(cmdOrigin)
      end
    end
  end

  ##
  # Check to see if a channel message is a fantasy command. If so, run the
  # appropriate function.

  def Modulus.fantasy(origin)
    origin = origin[0]
    return unless @@link.isChannel? origin.target

    prefix = @@config.getOption('Core', 'fantasy_prefix')

    if prefix == nil
      return
    end

    if prefix.length == 0
      return
    end

    $log.debug 'core', "Checking for fantasy prefix (#{prefix})"

    unless origin.cmd.start_with? prefix
      return
    end

    command = origin.cmd.upcase[prefix.length..origin.message.length-prefix.length]

    $log.debug 'core', "Got what looks like a fantasy command: #{command}"

    @@cmdHooks.keys.each { |receiver|
      @@serviceModules.modules.keys.each { |mod| 
        next unless @@channels.channels.has_key? origin.target

        $log.debug 'core', "Checking if #{mod} is in #{origin.target}"

        if @@channels.channels[origin.target].users.has_key? mod
          unless @@cmdHooks.has_key? mod
            $log.debug 'core', "No commands for present module."
            next
          end

          unless @@cmdHooks[mod].has_key? command
            $log.debug 'core', "Present module does not have this command."
            next
          end

          unless @@cmdHooks[mod][command].allowFantasy
            $log.debug 'core', "This command is not enabled for fantasy use."
            next
          end

          $log.debug 'core', "Definitely a fantasy command. Running: #{origin}"

          @@cmdHooks[mod][command].run(origin)
          return
        else
          $log.debug 'core', "#{mod} is not in the channel. Skipping."
          next
        end
      }
    }
  end

  def Modulus.addService(name, modClass, description)
    @@serviceModules.addService(name, modClass, description)
  end

  def Modulus.addCmd(modClass, receiver, cmdStr, funcName, shortHelp, longHelp="", allowFantasy=false)
    cmdStr.upcase!
    @@cmdHooks[receiver] = Hash.new unless @@cmdHooks.has_key? receiver
    #@cmdHooks[receiver][cmdStr] = Array.new unless @cmdHooks[receiver].has_key? cmdStr

    $log.debug "core", "Adding command hook: #{cmdStr} for #{modClass.class}"

    hook = Command.new(modClass, funcName, cmdStr, shortHelp, longHelp, allowFantasy)

    #@cmdHooks[receiver][cmdStr] << hook
    @@cmdHooks[receiver][cmdStr] = hook
  end

  def Modulus.addMessageHook(modClass, funcName, hookType, receiver)
    @@messageHooks[receiver] = Hash.new unless @@messageHooks.has_key? receiver
    @@messageHooks[receiver][hookType] = Array.new unless @@messageHooks[receiver].has_key? hookType

    $log.debug "core", "Adding message hook: type #{hookType} for #{modClass.class}"

    hook = Hook.new(modClass, funcName)

    @@messageHooks[receiver][hookType] << hook
  end

  def Modulus.addHook(modClass, funcName, hookType)
    @@hooks[hookType] = Array.new unless @@hooks.has_key? hookType
    $log.debug "core", "Adding hook: type #{hookType} for #{modClass.class}"

    hook = Hook.new(modClass, funcName)

    @@hooks[hookType] << hook
  end

  def Modulus.startConnectionThread
    @@link.connect(@@clients.clients.values)
  end

  def Modulus.prepDatabase
    unless ReservedNick.table_exists?
      ActiveRecord::Schema.define do
        create_table :reserved_nicks do |t|
          t.string :nick, :null => false
          t.string :module, :null => false
          t.datetime :dateAdded
        end
      end
    end

    unless Account.table_exists?
      ActiveRecord::Schema.define do
        create_table :accounts do |t|
          t.string :username, :null => false
          t.string :email, :null => false
          t.string :password, :null => false
          t.datetime :dateRegistered, :null => false
          t.datetime :dateConnected
          t.datetime :dateDisconnected
          t.string :lastQuitMessage
          t.boolean :suspended, :default => false
          t.text :notes
          t.boolean :noexpire, :default => false
          t.boolean :verified, :default => false
        end
      end
    end
  end
end #module Modulus
