
module XMLRPC
  class RackServer < BasicServer
    def initialize(request, class_delim = ".")
      @request = request
      super(class_delim)
    end

    def serve
      return error_response(405, "Method Not Allowed") unless @request.post?
      return error_response(400, "Bad Request") unless %r|text/xml| =~ @request.content_type
      return error_response(411, "Length Required") unless @request.content_length.to_i > 0
      data = ""
      @request.body.read(nil, data)
      return error_response(400, "Bad Request") if data.nil? or data.size != @request.content_length.to_i
      Hiki::Response.new(process(data), 200, "Content-Type" => "text/xml; charset=utf-8")
    end

    private

    def error_response(status, message = "")
      error = "#{status} #{message}"
      body=<<-BODY
        <html>
          <head>
            <title>#{error}</title>
          </head>
          <body>
            <h1>#{error}</h1>
            <p>Unexpected error occured while processing XML-RPC request!</p>
          </body>
        </html>
      BODY
      Hiki::Response.new(body, status, "Content-Type" => "text/html")
    end

  end
end
