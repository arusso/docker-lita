module Lita
  module Handlers
    class Cmdb < Handler
      config :itop_rest_endpoint
      config :itop_user
      config :itop_pass

      CONTACT_TYPES = [ 'technical', 'owner', 'billing' ]
      CONTACT_ALIASES = { 'authorized' => [ 'technical', 'owner' ], 'all' => CONTACT_TYPES }
      CONTACT_TYPES_REGEX = /(?<contact_type>#{CONTACT_TYPES.join('|')})/
      CONTACT_ALIASES_REGEX = /(?<contact_alias>#{CONTACT_ALIASES.keys.join('|')})/
      CONTACT_TYPES_ALIASES_REGEX = /(?:#{[ CONTACT_TYPES_REGEX, CONTACT_ALIASES_REGEX].join('|')})/

      SERVICE_ID_REGEX = /(?<service_id>[a-zA-Z0-9\-\_]+)/

      route(
        /^(?:get\ )?contacts\ (?:for\ )?(?:host\ )?#{SERVICE_ID_REGEX}\ ?(of\ )?(type\ )?#{CONTACT_TYPES_ALIASES_REGEX}?$/,
	:get_contacts,
	command: true,
	help: {
          '[get] contacts [for host] <service_id> [[of type ] <contact_type>]' => 'Lookup contacts for the given service id. You can optionally specify a contact type. Types are: all, authorized (owner + technical, default), billing, owner, technical',
          'contacts <service_id> [<contact_type>]' => 'Shorthand notation for contact lookup',
        },
      )

      route(
        /^(?:get\ )?sla\ (?:for\ |of\ )?(?:host\ |service\ id\ )?#{SERVICE_ID_REGEX}$/,
        :get_sla,
        command: true,
        help: {
          '[get] sla [for host] <service_id>' => "Returns SLA for service id",
          'sla <service_id>' => 'Shorthand notation for SLA lookup',
        },
      )

      route(
        /^add\ contacts\ (?:for\ )?(?:host\ )?(?<service_id>[a-zA-Z0-9\-\_]+)\ (?:of\ )?(?:type\ )?(?<contact_type>#{CONTACT_TYPES_REGEX})\ (?<contacts_raw>.*)$/,
        :add_contacts,
        command: true,
        help: {
          'add contacts [for host] <service_id> [of type] <contact_type> <contact> [contact ...]' => 'add one or more contacts to a service id',
        },
      )
     
      def get_sla(response)
        service_id = response.match_data['service_id']
        puts "#{response.user.mention_name} << get_sla(service_id: #{service_id})"
        query = [ 'SELECT SLA AS s',
              'JOIN lnkCustomerContractToService AS l1',
              'ON l1.sla_id=s.id',
              'JOIN Contract AS c',
              'ON l1.customercontract_id=c.id',
              'JOIN lnkCustomerContractToFunctionalCI AS l2',
              'ON l2.customercontract_id = c.id',
              'JOIN VirtualMachine AS v',
              'ON l2.functionalci_id=v.id',
              "WHERE v.name REGEXP '^#{service_id}$'" ].join(' ')
        data = {
          'operation' => 'core/get',
          'class' => 'SLA',
          'key' => query,
          'output_fields' => 'name',
        }
        http_res = query_itop(data)
        
        res = MultiJson.load(http_res.body)
        sla = ''
        res['objects'].each do |slak,data|
          if data['fields']['name'] == 'Standard OS Support'
            sla = 'standard' if sla == ''
          elsif data['fields']['name'] == 'Extended OS Support'
            sla = 'extended'
          end 
        end

        log_msg="#{response.user.mention_name} >> sla is "
        if sla == ''
          log_msg+= "unknown"
          response.reply("unable to determine sla for #{service_id}")
        else
          log_msg+= "#{sla}"
          response.reply("#{service_id} has #{sla} support")
        end
        puts log_msg
      end

      def get_contacts(response)
        sid = response.match_data['service_id']
        ctype = response.match_data['contact_type']
        calias = response.match_data['contact_alias']
        puts "#{response.user.mention_name} << get_contacts(service_id: #{sid}, contact_type: #{ctype}, contact_alias: #{calias})"
        contact_types = []

        if ctype.nil? and ( calias.nil? or calias == 'all' )
          contact_types = CONTACT_TYPES
        elsif calias.nil? and ! ctype.nil?
          contact_types = [ ctype ]
        elsif ctype.nil?
          # handle any aliases here
          case calias
          when 'authorized'
            contact_types = CONTACT_TYPES.select { |itm| itm != 'billing' } 
          else
            response.send("Unknown contact type alias #{calias}")
            return
          end
        else
          response.send("I am unable to process your request")
          return
        end

        contacts = {}
        contact_types.each do |type|
          contacts_of_type = get_contacts_for_service_id_of_type(sid,type)
          contacts_of_type.each do |id,info|
            if contacts[id].nil?
              contacts[id] = info
              contacts[id]['type'] = type
            else
              contacts[id]['type'] += ",#{type}"
            end
          end
        end

        if contacts.size > 0
          reply = "Contacts for service id *#{sid}*:\n"
          contacts.each { |id,info| reply += " • #{info['email']} (#{info['type']})\n" }
        else
          reply = "No #{contact_types.join('/')} contacts found for #{sid}" 
        end
        puts "#{response.user.mention_name} >> found #{contacts.size} contacts"
        response.reply(reply)
      end

      private
      def get_contacts_for_service_id_of_type(service_id, type)
        query = [
          "SELECT Person AS p",
          "JOIN lnkPersonToTeam AS l1 ON l1.person_id=p.id",
          "JOIN Team AS t ON l1.team_id=t.id",
          "JOIN lnkContactToFunctionalCI AS l2 ON l2.contact_id=t.id",
          "JOIN VirtualMachine AS v ON l2.functionalci_id=v.id",
          "WHERE v.name REGEXP '^#{service_id}$'",
          "AND l1.role_name LIKE '%#{type}%'"
        ].join(' ')
        data = {
          'operation' => 'core/get',
          'class' => 'Person',
          'key' => query,
          'output_fields' => 'email,employee_number,friendlyname',
        }
        http_res = query_itop(data)
        res = MultiJson.load(http_res.body)
        people = {}
        
        res['objects'].each do |person,data|
          continue if data['fields']['employee_number'].nil?
          people[data['fields']['employee_number']]= {
            'email' => data['fields']['email'],
            'full_name' => data['fields']['friendlyname'],
          }
        end unless res['objects'].nil?
        people
      end

      def query_itop(data)
        json_data = MultiJson.dump(data)
        conn = Faraday::Connection.new
        conn.basic_auth(config.itop_user, config.itop_pass)
        conn.params['version'] = '1.0'
        conn.params['json_data'] = json_data

        conn.post(config.itop_rest_endpoint)
      end
    end

    Lita.register_handler(Cmdb)
  end
end
