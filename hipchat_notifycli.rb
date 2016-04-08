#!/usr/bin/env ruby

require 'hipchat'
require 'trollop'


#
# Provides a hipchat notifier with minimal requirements. 
# Post the nofication to room
#
# Docs: http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers
#
# Install - add the following to your client.rb:
# apt-get install ruby
# apt-get install ruby-dev
# gem install hipchat # Configure CLI entries
# gem install trollop # configure commandline option parser


module HipChat
  class NotifyRoomCli 

    def initialize(api_token, room_name, msg, options={})

      defaults = { hipchat_options: {api_version: 'v2',server_url: 'https://api.hipchat.com'}, msg_options: {:notify => true}, excluded_envs: [], msg_prefix: ''}
      options = defaults.merge(options)
      @api_token = api_token
      @room_name = room_name
      @msg = msg
      @hipchat_options = options[:hipchat_options]
      @msg_options = options[:msg_options]
      @msg_prefix = options[:msg_prefix]
      @excluded_envs = options[:excluded_envs]
      @to_user=options[:name]
      case 
      when options[:alerttype].match(/warning/i)
        @color = 'yellow'
      when options[:alerttype].match(/critical/i)
        @color = 'red'
      when options[:alerttype].match(/info/i)
        @color = 'green'
      end if options[:alerttype]
    end

    def report
      if @msg
        @msg_options[:color]=(@color || 'yellow')
        client = HipChat::Client.new(@api_token, @hipchat_options)
        client[@room_name].send(@to_user, [@msg_prefix, @msg].join(' '), @msg_options)
      end
    end

  end
end

begin
  opts = Trollop::options do
    opt :message, "Use monkey mode"  ,:type => :string                  # flag --monkey, default false
    opt :name, "Monkey name", :type => :string        # string --name <s>, default nil
    opt :apitoken, "HIPCHAT API Token 2.0", :type=> :string
    opt :roomname, "Room id from Hipchat", :type=> :string
    opt :alerttype, "warning/critical/info", :type => :string

  end
  [ :message, :apitoken, :roomname].each do |key|
    Trollop::die "arguments required --#{key}" unless opts[key]
  end
  hipchat=HipChat::NotifyRoomCli.new(opts[:apitoken],opts[:roomname],opts[:message],opts)
  hipchat.report
rescue Errno::ENOENT => err
  abort "hip_chat_cli: #{err.message}"
end
