module Lita
  module Handlers
    class Cmdb < Handler
      config :itop_rest_endpoint
      config :itop_user
      config :itop_pass

      # respond to contact queries
      route(
        /^contacts\ get\ (?<service_id>[a-zA-Z0-9\-]+)(\s+(?<contact_type>[a-z]+))?$/,
        :get_contacts,
        command: true,
        help: {
          'contacts get <service id> <contact type>' => 'Returns contact information for service id'
        },
      )

      # respond to sla queries
      route(
        /^sla\ (?<service_id>[a-zA-Z0-9\-]+)$/,
        :get_sla,
        command: true,
        help: {
          'sla <service id>' => "Returns SLA for service id"
        },
      )
     
      def get_sla(response)
        service_id = response.match_data['service_id']
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
            sla == 'extended' if sla == ''
          end 
        end

        if sla == ''
          response.reply("unable to determine sla for #{service_id}")
        else
          response.reply("#{service_id} has #{sla} support")
        end
      end

      def get_contacts(response)
        response.reply("Contact listing is unavailable at this time... for realz.")
        return

        sid = response.match_data['service_id']
        type = case response.match_data['contact_type']
        when 'billing'
          "Billing Contact"
        when 'technical'
          "Technical Contact"
        when 'owner'
          "Functional Owner"
        when nil
          "Technical Contact"
        else
          "UNKNOWN"
        end

        if type == "UNKNOWN"
          response.reply("Unknown contact type #{response.match_data['contact_type']}")
          return
        else
          response.reply("Looking up contacts for #{sid}/#{type}")
        end

        query = [
          "SELECT Person AS p",
          "JOIN lnkPersonToTeam AS l1 ON l1.person_id=p.id",
          "JOIN Team AS t ON l1.team_id=t.id",
          "JOIN lnkContactToFunctionalCI AS l2 ON l2.contact_id=t.id",
          "JOIN VirtualMachine AS v ON l2.functionalci_id=v.id",
          "WHERE v.name REGEXP '^#{sid}$'",
          "AND t.name LIKE '#{type}'"
        ].join(' ')

        data = {
          'operation' => 'core/get',
          'class' => 'Person',
          'key' => query,
          'output_fields' => 'email',
        }

        http_res = query_itop(data)

        res = MultiJson.load(http_res.body)
        people = []
        
        response.reply("Got: #{http_res.body}")
        res['objects'].each { |person,data| people << data['fields']['email'] }
	people.uniq!
 
        reply = ""
        if people.length > 0
          reply = "Contacts for service id #{service_id} are #{people.join(', ')}"
        else
          reply = "No contacts found for #{service_id}"
        end

        response.reply(reply)
      end

      private
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
