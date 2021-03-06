# Hipchat Notify 2.0
Hipchat notification with API 2.0 to be used with ICINGA/Nagios


## Table of Contents


> [*Table of Contents*](#table-of-contents)
>
> [*Author*](#author)
>
> [*Audience*](#audience)
>
> [*Introduction*](#introduction)
>
> [*Ruby Script*](#ruby-script)
>
> [*Script used on server*](#script-used-on-server)
>
> [*Service notification*](#service-notification)
>
> [*Host notification*](#host-notification)
>
> [*Change in command.conf for Icinga
> server*](#change-in-command.conf-for-icinga-server)
>
> [*Example notification*](#example-notification)
>
> [*Roadmap*](#roadmap)

# Author

Shubhamkr619@gmail.com

# Audience 


- System Engineers and operation engineers


# Introduction

Change the default mail notification of Icinga server to hipchat
notification using ruby code. This will allow a single place of
management of all the notification and alerts across organization. Let
that be service,host or business level alerts all can be managed and
monitored using hipchat and hubot will give certain advantage over
traditional alerting system.

1.  Proactive and reactive alerting

2.  Managed monitoring

3.  Single place of all the alerts

4.  Better communication and collaboration

5.  Integration with multiple tools in CI cycle

    *  Jenkins

    *  Chef

    *  Bitbucket/Github

    *  Jira

    *  Confluence …. Etc

As per plan once Elastalert is implemented Hipchat will support business
and revenue alerts, and hopefully with event based proactive/reactive
handling or issues.

# Ruby Script

Need to create a Ruby script in order to make sure that we can send
messages from a single server. Idea here is to be able to configure
icinga server to send message to custom user groups and Hipchat account.

We are going to use a Ruby gem called hipchat which will support API
version 2.0. In order for script to work we need to install 2 gems,

1.  Hipchat

2.  Trollop

  ----------------------------
  ```sh apt-get install ruby -y

  # gem install hipchat

  # gem install trollop
  ```
  ----------------------------

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ```ruby
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

  # gem install hipchat \# Configure CLI entries

  # gem install trollop \# configure commandline option parser

  module HipChat

  class NotifyRoomCli

  def initialize(api_token, room_name, msg, options={})

  defaults = { hipchat_options: {api_version: 'v2',server_url: 'https://api.hipchat.com'}, msg_options: {:notify =&gt; true}, excluded_envs: [], msg_prefix: ''}

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

  opt :message, "Use monkey mode" ,:type =&gt; :string \# flag --monkey, default false

  opt :name, "Monkey name", :type =&gt; :string \# string --name &lt;s&gt;, default nil

  opt :apitoken, "HIPCHAT API Token 2.0", :type=&gt; :string

  opt :roomname, "Room id from Hipchat", :type=&gt; :string

  opt :alerttype, "warning/critical/info", :type =&gt; :string

  end

  [ :message, :apitoken, :roomname].each do |key|

  Trollop::die "arguments required --\#{key}" unless opts[key]

  end

  hipchat=HipChat::NotifyRoomCli.new(opts[:apitoken],opts[:roomname],opts[:message],opts)

  hipchat.report

  rescue Errno::ENOENT =&gt; err

  abort "hip_chat_cli: \#{err.message}"

  end
  ```
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Script used on server
=====================

following is a script which should which we need to configure to use
this code with a icinga server

Service notification
--------------------

  --------------------------------------------------------------------------------------------------------------------------------------------------------------
  ```sh
  root@hubot0:/etc/icinga2/scripts\# cat hipchat-service-notification.sh

  #!/bin/sh

  template=\`cat &lt;&lt;TEMPLATE

  \*\*\*\*\* Icinga \*\*\*\*\*

  Notification Type: \$NOTIFICATIONTYPE

  Service: \$SERVICEDESC

  Host: \$HOSTALIAS

  Address: \$HOSTADDRESS

  State: \$SERVICESTATE

  Date/Time: \$LONGDATETIME

  Additional Info: \$SERVICEOUTPUT

  Comment: [\$NOTIFICATIONAUTHORNAME] \$NOTIFICATIONCOMMENT

  TEMPLATE

  \`

  \#/usr/bin/printf "%b" "\$template" | mail -s "\$NOTIFICATIONTYPE - \$HOSTDISPLAYNAME - \$SERVICEDISPLAYNAME is \$SERVICESTATE" \$USEREMAIL

  dir="\$(readlink -f \$(dirname \$0))"

  ruby \$dir/notify --message "\$(/usr/bin/printf "%b" "\$template")" --name icinga --apitoken "&lt;TOKEN&gt;" --roomname 2614946 --alerttype "\$SERVICESTATE"
  ```
  --------------------------------------------------------------------------------------------------------------------------------------------------------------

Host notification
-----------------

  -------------------------------------------------------------------------------------------------------------------------------------------------------
  ```sh
  #root@hubot0:/etc/icinga2/scripts\# cat mail-host-notification-hipchat.sh

  #!/bin/sh

  dir="\$(readlink -f \$(dirname \$0))"

  template=\`cat &lt;&lt;EOF

  HOST DOWN \$HOSTALIAS; Address: \$HOSTADDRESS; State: \$HOSTSTATE ; Date/Time: \$LONGDATETIME

  Additional Info: \$HOSTOUTPUT

  Comment: [\$NOTIFICATIONAUTHORNAME] \$NOTIFICATIONCOMMENT

  EOF

  \`

  ruby \$dir/notify --message "\$(/usr/bin/printf "%b" "\$template")" --name icinga --apitoken "&lt;TOKEN&gt;" --roomname 2614946 --alerttype "warning"

  root@hubot0:/etc/icinga2/scripts\#
  ```
  -------------------------------------------------------------------------------------------------------------------------------------------------------

Change in command.conf for Icinga server
========================================

This will change the Icinga server to support the hipchat adapter ,

  -----------------------------------------------------------------------------------
  ```sh
  root@hubot0:/etc/icinga2/scripts\# cat ../conf.d/commands.conf

  /\* Command objects \*/

  object NotificationCommand "mail-host-notification" {

  import "plugin-notification-command"

  command = [ SysconfDir + "/icinga2/scripts/mail-host-notification-hipchat.sh" ]

  env = {

  NOTIFICATIONTYPE = "\$notification.type\$"

  HOSTALIAS = "\$host.display_name\$"

  HOSTADDRESS = "\$address\$"

  HOSTSTATE = "\$host.state\$"

  LONGDATETIME = "\$icinga.long_date_time\$"

  HOSTOUTPUT = "\$host.output\$"

  NOTIFICATIONAUTHORNAME = "\$notification.author\$"

  NOTIFICATIONCOMMENT = "\$notification.comment\$"

  HOSTDISPLAYNAME = "\$host.display_name\$"

  USEREMAIL = "\$user.email\$"

  }

  }

  object NotificationCommand "mail-service-notification" {

  import "plugin-notification-command"

  command = [ SysconfDir + "/icinga2/scripts/hipchat-service-notification.sh" ]

  env = {

  NOTIFICATIONTYPE = "\$notification.type\$"

  SERVICEDESC = "\$service.name\$"

  HOSTALIAS = "\$host.display_name\$"

  HOSTADDRESS = "\$address\$"

  SERVICESTATE = "\$service.state\$"

  LONGDATETIME = "\$icinga.long_date_time\$"

  SERVICEOUTPUT = "\$service.output\$"

  NOTIFICATIONAUTHORNAME = "\$notification.author\$"

  NOTIFICATIONCOMMENT = "\$notification.comment\$"

  HOSTDISPLAYNAME = "\$host.display_name\$"

  SERVICEDISPLAYNAME = "\$service.display_name\$"

  USEREMAIL = "\$user.email\$"

  }

  }
  ```
  -----------------------------------------------------------------------------------

Example notification
====================

![](image1.png)


Roadmap
=======

1.  Add hipchat user for Icinga server

2.  Configure to talk to groups using token from user settings in
    > hipchat

3.  Change notification files and update token+room_ids

All these steps are required to make sure hubot can take actions on
events. For now hubot can not take actions if the user Hubot and
notifying user is matched. It is required to prevent race conditions.

