# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Clavem
  # A class to handle oAuth callbacks on the browser via HTTP.
  class Server < EM::Connection
    include EM::HttpServer

    # The template to send to the browser.
    TEMPLATE = <<-EOTEMPLATE
<html>
  <head>
    <title>Clavem</title>
    <script type="text/javascript"> close_window = (function(){ window.open("", "_self", ""); window.close(); })(); </script>
  </head>
  <body><h4>%s</h4></body>
</html>
    EOTEMPLATE

    # Creates a new server.
    #
    # @param authorizer [Authorizer] The authorizer of this server.
    def initialize(authorizer)
      @authorizer = authorizer
    end

    # Save the token and sends a response back to the user.
    def process_http_request
      # Handle the token
      token = @authorizer.response_handler.call(CGI::parse(@http_query_string))
      if token then
        @authorizer.token = token
        @authorizer.status = :succeeded
      else
        @authorizer.status = :denied
      end

      # Build the request
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type("text/html")
      response.content = TEMPLATE % [@authorizer.i18n.template]
      response.send_response

      # Stop after serving the request.
      EM.add_timer(0.1) { EM.stop }
    end
  end
end