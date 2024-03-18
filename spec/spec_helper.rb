
#
# Specifying Xel
#
# Fri Sep 25 13:24:56 JST 2015
#

require 'json'
require 'webrick'

require 'ferrum'


module Helpers

  TEST_WEB_PORT= 9091

  def make_browser(js_files)

    re_start_web_server

    system('rm spec/www/*.html')

    ts = Time.now.strftime('%Y%m%dT%H%M%S')
    test_file = "xel_test_#{ts}.html"
    test_path = File.join(Dir.pwd, 'spec/www', test_file)

    File.open(test_path, 'wb') do |f|
      f.puts %{
        <html>
          <head>
            <title>test #{ts}</title> }
      js_files.each do |path|
        next if path.match?(/^#/)
        system("cp #{path} spec/www/#{File.basename(path)}")
        f.puts("<script src='#{File.basename(path)}'></script>")
      end
      f.puts %{
          </head>
          <body>
            <b>XEL</b>
            <script>
              var f = function() { window.__ready = true; };
              if (document.readyState != 'loading') f();
              else document.addEventListener('DOMContentLoaded', f);
            </script>
          </body>
        </html> }
    end
#puts ">>>\n" + File.read(test_path) + "\n<<<"
      #
      # if there is something wrong use `make tserve` and look
      # at the Chrome development console!

    opts = {}

    opts[:headless] = (ENV['HEADLESS'] != 'false')
    if opts[:headless]
      opts[:xvfb] = true
      opts[:headless] = false
    end
    opts[:timeout] = 15
    #opts[:process_timeout] = 15
    #opts[:browser_options] = { 'allow-file-access-from-files': nil } # :-(

    b = Ferrum::Browser.new(opts)
    b.go_to("http://127.0.0.1:#{TEST_WEB_PORT}/#{test_file}")
    28.times do
      begin
        b.evaluate(%{
          window.document.body.innerHTML && (window.__ready === true);
        })
        break
      rescue
        sleep 0.14
      end
    end

    class << b

      def eval(s)

        evaluate(s.strip)
      end

      def wrap_and_evaluate(s)

        evaluate(%{ function() { #{s} }(); })
      end
      alias ewal wrap_and_evaluate
    end

    b
  end

  protected


  def re_start_web_server

    $test_web_server ||=
      begin

        server = WEBrick::HTTPServer.new(
          Port: TEST_WEB_PORT, DocumentRoot: File.join(Dir.pwd, 'spec/www'),
          Logger: WEBrick::Log.new('/dev/null'), AccessLog: [])
            #
        Thread.new do
          server.start
        rescue IOError => err
          #puts "$test_web_server down " + err.inspect
        end
            #
        14.times do
          u = URI.parse("http://127.0.0.1:#{TEST_WEB_PORT}/spec/test.htm")
          r = Net::HTTP.start(u.host, u.port) { |http| http.get(u.path) }
          break if r.code == '200'
        end

        server
      end
  end

#  def js_eval(s)
#
#    $browser ||=
#      begin
#
#        opts = {}
#
#        opts[:headless] = (ENV['HEADLESS'] != 'false')
#        if opts[:headless]
#          opts[:xvfb] = true
#          opts[:headless] = false
#        end
#        opts[:timeout] = 15
#        #opts[:process_timeout] = 15
#
#        b = Ferrum::Browser.new(opts)
#      end
#
#    r = $browser.evaluate("JSON.stringify((function() {#{s};})())");
#
#    begin
#      r = JSON.parse(r)
#    rescue
#      fail RuntimeError.new(r)
#    end if r.is_a?(String)
#
#    r = r.strip if r.is_a?(String)
#
#    r
#  end
end

RSpec.configure do |c|

  #
  # it, they, so, ...

  c.alias_example_to(:they)
  c.alias_example_to(:so)

  #
  # helpers

  c.include(Helpers)
end

