require "activeresource_keepalive/version"
require "active_resource"

module ActiveResource

  class Base
    class << self
      # Sets whether or not to use keep-alive connections.
      def keepalive=(keepalive)
        @connection = nil
        @keepalive = keepalive
      end

      # Gets whether or not to use keep-alive connections.
      def keepalive
        if defined?(@keepalive)
          @keepalive
        elsif superclass != Object && superclass.keepalive
          superclass.keepalive
        end
      end

      def connection(refresh = false)
        if defined?(@connection) || superclass == Object
          @connection = Connection.new(site, format) if refresh || @connection.nil?
          @connection.proxy = proxy if proxy
          @connection.user = user if user
          @connection.password = password if password
          @connection.auth_type = auth_type if auth_type
          @connection.timeout = timeout if timeout
          @connection.ssl_options = ssl_options if ssl_options
          @connection.keepalive = keepalive if keepalive
          @connection
        else
          superclass.connection
        end
      end

    end
  end

  class Connection
    attr_reader :keepalive

    class << self
      def connection_for(site, proxy, keepalive = false)
        @@connections ||= {}
        return unless keepalive
        if proxy.nil?
          @@connections["#{site.host}:#{site.port}"]
        else
          @@connections["#{site.host}:#{site.port}:#{proxy.host}:#{proxy.port}"]
        end
      end

      def new_connection(site, proxy)
        puts "new connection"
        if proxy.nil?
          @@connections["#{site.host}:#{site.port}"] = Net::HTTP.new(site.host, site.port)
        else
          @@connections["#{site.host}:#{site.port}:#{proxy.host}:#{proxy.port}"] = Net::HTTP.new(site.host, site.port, proxy.host, proxy.port, proxy.user, proxy.password)
        end
      end
    end

    # Sets whether or not to use keep-alive connections.
    def keepalive=(keepalive)
      @keepalive = keepalive
    end

    # Executes a GET request.
    # Used to get (find) resources.
    def get(path, headers = {})
      req = Net::HTTP::Get.new(path, build_request_headers(headers, :get, self.site.merge(path)))
      with_auth { format.decode(request(:get, path, req).body) }
    end

    # Executes a DELETE request (see HTTP protocol documentation if unfamiliar).
    # Used to delete resources.
    def delete(path, headers = {})
      req = Net::HTTP::Delete.new(path, build_request_headers(headers, :delete, self.site.merge(path)))
      with_auth { request(:delete, path, req) }
    end

    # Executes a PUT request (see HTTP protocol documentation if unfamiliar).
    # Used to update resources.
    def put(path, body = '', headers = {})
      req = Net::HTTP::Put.new(path, build_request_headers(headers, :put, self.site.merge(path)))
      req.body = body.to_s
      with_auth { request(:put, path, req) }
    end

    # Executes a POST request.
    # Used to create new resources.
    def post(path, body = '', headers = {})
      req = Net::HTTP::Post.new(path, build_request_headers(headers, :post, self.site.merge(path)))
      req.body = body.to_s
      with_auth { request(:post, path, req) }
    end

    # Executes a HEAD request.
    # Used to obtain meta-information about resources, such as whether they exist and their size (via response headers).
    def head(path, headers = {})
      req = Net::HTTP::Head.new(path, build_request_headers(headers, :head, self.site.merge(path)))
      with_auth { request(:head, path, req) }
    end

    private
    # Makes a request to the remote service.
    def request(method, path, req)
      result = ActiveSupport::Notifications.instrument("request.active_resource") do |payload|
        payload[:method]      = method
        payload[:request_uri] = "#{site.scheme}://#{site.host}:#{site.port}#{path}"
        payload[:result]      = http.request(req)
      end
      handle_response(result)
    rescue Timeout::Error => e
      raise TimeoutError.new(e.message)
    rescue OpenSSL::SSL::SSLError => e
      raise SSLError.new(e.message)
    end

    # Creates new Net::HTTP instance for communication with the
    # remote service and resources.
    def http
      if connection = self.class.connection_for(@site, @proxy, @keepalive)
        connection
      else
        configure_http(new_http)
      end
    end

    def new_http
      self.class.new_connection(@site, @proxy)
    end

  end

end