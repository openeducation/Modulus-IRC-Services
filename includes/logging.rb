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

  class Log

    attr_reader :logger

    require 'logger'

    DISABLED = 10
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    FATAL = 4

    ##
    # Create a new logger object. The configuration object is the only
    # parameter and is used during initializiation.
    #
    # If the configured log directory does not exist, attempt to create it, or
    # die trying (fatal error).
    #
    # If a log channel is configured, we'll use that for on-protocol logging.

    def initialize(config)
      logdir = config.getOption('Core', 'log_location')
      @logChannel = config.getOption('Core', 'log_channel')

      @chatVerbosity = self.verbToNum(config.getOption('Core', 'log_channel_verbosity')) # Logging to log chan

      unless Dir.exists? logdir
        begin    
          Dir.mkdir logdir
        rescue => e
          $stderr.puts "Fatal error: Cannot create log directory #{logdir}:"
          $stderr.puts "#{e}"
          $stderr.puts "#{e.backtrace}"
        end
      end
      @logger = Logger.new("./logs/services.log", config.getOption('Core', 'log_rotation_period'))
      self.setFileVerbosity(config.getOption('Core', 'log_verbosity')) # Logging to services.log

      self.info "logger", "Logging started."
    end

    ##
    # Convert the verbosity setting in config to one of our constants for easier
    # coding.

    def verbToNum(verbosity)
      case verbosity.downcase
        when "debug"
          return DEBUG
        when "info"
          return INFO
        when "warning"
          return WARN
        when "error"
          return ERROR
        when "fatal"
          return FATAL
      end
      return DISABLED
    end

    ##
    # Set the severity for the Logger log file using the given verbosity.
    # This function expects a string, not one of our constants.

    def setFileVerbosity(verbosity)
      case verbosity.downcase
        when "debug"
          @logger.sev_threshold = Logger::DEBUG
        when "info"
          @logger.sev_threshold = Logger::INFO
        when "warning"
          @logger.sev_threshold = Logger::WARN
        when "error"
          @logger.sev_threshold = Logger::ERROR
        when "fatal"
          @logger.sev_threshold = Logger::FATAL
      end
      @logger.sev_threshold = Logger::DEBUG
    end

    ##
    # Send the log message to IRC on the log channel, if configured.
    #
    # The parameters are the serverity (one of our constants) and the log
    # message.
    #
    # If no log channel is configured or the link is not active, abort.

    def logToChannel(severity, msg)
      begin
        return if @logChannel == nil or Modulus.link == nil

        if @chatVerbosity <= severity
          Modulus.link.sendPrivmsg("Global", @logChannel, msg)
        end
      rescue
        # Must not be working right now...
      end
    end

    ##
    # Log a message as DEBUG.

    def debug(section, str)
      @logger.debug(section) { str }
      self.logToChannel(DEBUG, "DEBUG [#{section}] #{str}")
    end

    ##
    # Log a message as INFO.

    def info(section, str)
      @logger.info(section) { str }
      self.logToChannel(INFO, "INFO [#{section}] #{str}")
    end

    ##
    # Log a message as WARNING.

    def warning(section, str)
      @logger.warn(section) { str }
      self.logToChannel(WARN, "WARNING [#{section}] #{str}")
    end

    ##
    # Log a message as ERROR.

    def error(section, str)
      @logger.error(section) { str }
      self.logToChannel(ERROR, "ERROR [#{section}] #{str}")
    end

    ##
    # Log a message as FATAL. This should only be called just before Modulus
    # exits.

    def fatal(section, str)
      @logger.fatal(section) { str }
      self.logToChannel(FATAL, "FATAL [#{section}] #{str}")
    end

    ##
    # Close the Logger log file.

    def close
      @logger.close
    end

  end #class Logger

end #module Modulus
