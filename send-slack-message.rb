
require 'net/http'
require 'net/https'
require 'json'
 
# Buildbot to send a direct message to the given user when their build passes or fails.
#
# Author: Scott Bishop
# Date: 3/25/2015
#
# USAGE: ruby send-slack-message.rb [is_pull_request: boolean] [build passed: boolean] [username: string] [build_link: string] [slack_webhook_url: string] [channel (optional): string] [plan name (optional): string]
# Ex. ruby send-slack-message.rb "true" "true" "scott.bishop" "https://bamboo.com/PULLREQUEST-6227" "https://hooks.slack.com/services/........." "#android" "Master"
def send_slack_message
  begin
    is_pull_request = ARGV[0]
  	build_passed = ARGV[1]
    user = ARGV[2]
    build_link = ARGV[3]
    slack_webhook_url = ARGV[4]
    channel = nil

    if is_pull_request == "true"
       if build_passed == "true"
            pretext = "Hey @#{user}, your pull request build just passed!"
            color = "#7CD197"
            fallback = "Hey @#{user}, your pull request build just passed. Go check it out here: #{build_link}"
        else
            pretext = "Oh no!! @#{user}, your pull request build failed!"
            color = "#B0171F"
            fallback = "Oh no!! @#{user}, your pull request build failed. Diagnose the issue here: #{build_link}"
        end 
    else
        # Channel override for generic build plans that are not for pull requests
        if ARGV.length > 5
            channel = ARGV[5]
            plan_name = ARGV[6]
            if build_passed == "true"
                pretext = "Hey team, #{plan_name} passed!"
                color = "#7CD197"
                fallback = "Hey team, #{plan_name} just had a passing build! Check it out here: #{build_link}"
            else
                pretext = "Oh no!! #{plan_name} just failed!"
                color = "#B0171F"
                fallback = "Oh no! #{plan_name} just failed! Diagnose the issue here: #{build_link}"
            end
        end
    end

    unless channel.nil?
        # channel must contain # as the first character 
        channel_or_user = channel
    else
        channel_or_user = '@' + user
    end
    
    puts "Sending message to user: #{channel_or_user} with message: #{pretext}"

  	uri = URI(slack_webhook_url)

    # Create client
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    dict = {
    	:channel => "#{channel_or_user}",
    	:username => "Buildbot",
        :icon_emoji => ":bamboo_atlassian:",
        :attachments => [ 
            {
              :fallback => "#{fallback}",
              :pretext => "#{pretext}",
              :title => "#{build_link}",
              :title_link => "#{build_link}",
              :color => "#{color}"
            }
        ]
    }
    body = JSON.dump(dict)

    # Create Request
    req =  Net::HTTP::Post.new(uri)
    # Add headers
    req.add_field "Content-Type", "application/json"
    # Set header and body
    req.body = body

    # Fetch Request
    res = http.request(req)
    puts "Response HTTP Status Code: #{res.code}"
    puts "Response HTTP Response Body: #{res.body}"
  rescue StandardError => e
	puts "HTTP Request failed (#{e.message})"
  end
end

send_slack_message
