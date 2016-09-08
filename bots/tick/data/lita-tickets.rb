require 'slack-ruby-client'

module Lita
  module Handlers
    class Teams < Handler
      TEAM_NAME = /[a-z0-9_]+/
      
      # Permissions
      # ^^^^^^^^^^^
      # admin        - teams administrator
      # team_manager - manager of a particular team
      # team_member  - member of a particular team
      # none         - no permissions

      # Team Management
      # ^^^^^^^^^^^^^^^
      # create <name> team - admin
      # delete <name> team - admin
      # remove <name> team - admin
      # list teams         - none
      route(/^\s*create (?<team>#{TEAM_NAME}) team$/,:create_team,command: true,help: { 'create <name> team' => 'create a team' })
      route(/^\s*(?:delete|remove) (?<team>#{TEAM_NAME}) team$/,:delete_team,command: true,help: { 'delete <name> team' => 'delete a team' })
      route(/^\s*list teams$/,:list_teams,command: true,help: { 'list teams' => 'list all teams' })

      # Team Member Management
      # ^^^^^^^^^^^^^^^^^^^^^^
      # <name> team add <member> [as manager]              - admin,manager,member
      # <name> team ooo <member> from <date> until <date>  - admin,manager,member
      # <name> team assign next ticket                     - admin,manager,member
      # <name> team info                                   - none
      route(/^\s*(?<team>#{TEAM_NAME}) team add (?<member>)/)


      def get_teams_array()
        begin
          teams = MultiJson.load(redis.get('teams'))
        rescue
          teams = []
          redis.set('teams',MultiJson.dump(teams))
        end

        teams
      end

      def get_team(name)
        begin
          team = MultiJson.load(redis.get("team/#{name}"))
        rescue
          team = {}
          team = redis.set("team/#{name}",MultiJson.dump(team))
        end
        team
      end

      def create_team(response)
        who = response.user.mention_name
        # TODO: verify user is allowed to make this call
        #
        # perms = get_user_permissions(user)
        # if perms.contains? :admin
        
        team = response.match_data['team']
        user = response.match_data['user']
        puts "#{who}: add team #{team} #{user}"

        teams = get_teams_array
        unless teams.include? team
          teams << team
          redis.set('teams',MultiJson.dump(teams))

          udata = {
            'skips' => 0,
            'active' => 1,
            'backup' => 0,
            'ooo' => [],
          }
          tdata = { 'users' => { user => udata } }
          redis.set("team/#{team}",MultiJson.dump(tdata))
        end
        response.reply("team #{team} added!")
      end

      def list_teams(response)
        who = response.user.mention_name
        puts "#{who}: list teams"

        msg = ""
        teams =  get_teams_array

        msg = "Teams:\n"
        teams.each { |team| msg += "• #{team}\n" }
        response.reply(msg)
      end

      # Team Management
      #
      # add <user> to team <team>, add <user> <team>
      # remove <user> from team <team> , remove <user> <team> 
      # create <team> <users>
      # destroy <team>
      # list teams
      # stats <team>
      #
      # Ticket Management
      #
      # assign to <team> - assign to team
      # assign to <team> <user> - assign to specific user on team
      #
      #
      # find and replace any references to Footprints tickets with links directly to the ticket
    end

    Lita.register_handler(TicketQueueManager)
  end
end
