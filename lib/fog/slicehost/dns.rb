module Fog
  module Slicehost
    class DNS < Fog::Service

      requires :slicehost_password
      recognizes :host, :port, :scheme, :persistent

      model_path 'fog/slicehost/models/dns'
      model       :record
      collection  :records
      model       :zone
      collection  :zones

      request_path 'fog/slicehost/requests/dns'
      request :create_record
      request :create_zone
      request :delete_record
      request :delete_zone
      request :get_record
      request :get_records
      request :get_zone
      request :get_zones

      class Mock

        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {}
          end
        end

        def self.reset_data(keys=data.keys)
          for key in [*keys]
            data.delete(key)
          end
        end

        def initialize(options={})
          @slicehost_password = options[:slicehost_password]
          @data = self.class.data[@slicehost_password]
        end

      end

      class Real

        def initialize(options={})
          @slicehost_password = options[:slicehost_password]
          @host   = options[:host]    || "api.slicehost.com"
          @port   = options[:port]    || 443
          @scheme = options[:scheme]  || 'https'
          @connection = Fog::Connection.new("#{@scheme}://#{@host}:#{@port}", options[:persistent])
        end

        def reload
          @connection.reset
        end

        def request(params)
          params[:headers] ||= {}
          params[:headers].merge!({
            'Authorization' => "Basic #{Base64.encode64(@slicehost_password).delete("\r\n")}"
          })
          case params[:method]
          when 'DELETE', 'GET', 'HEAD'
            params[:headers]['Accept'] = 'application/xml'
          when 'POST', 'PUT'
            params[:headers]['Content-Type'] = 'application/xml'
          end

          begin
            response = @connection.request(params.merge!({:host => @host}))
          rescue Excon::Errors::HTTPStatusError => error
            raise case error
            when Excon::Errors::NotFound
              Fog::Slicehost::DNS::NotFound.slurp(error)
            else
              error
            end
          end

          response
        end

      end
    end
  end
end