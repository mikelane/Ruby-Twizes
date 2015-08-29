require 'tweetstream'
require 'yaml'

# Load the Twitter API oauth key information from a file. Keep the info off github!
config_info = Psych.load_file('config.yaml')
config_info = Psych.load(config_info)

# Configure the TweetStream API
TweetStream.configure do |config|
  config.consumer_key       = config_info['consumer_key']
  config.consumer_secret    = config_info['consumer_secret']
  config.oauth_token        = config_info['oauth_token']
  config.oauth_token_secret = config_info['oauth_token_secret']
  config.auth_method        = :oauth
end

# The hash is used to store tweet ids that have already been retweeted. This prevents
# retweeting something more than once.
retweets = Hash.new         # Create an empty hash
req_len = 100               # The length the hash must be before it gets written to a file
len_increment = 100         # The amount to increment the hash length by after dumping it to a file
file = 'retweets-log.yml'   # The name of the logging file.
# @todo open and parse an existing log file if one exists. Allow the hash to persist between sessions.
# @todo initialize the req_len to the length of the existing hash if one is found.


# Use 'track' to track a list of single-word keywords
# Find all tweets that contain the words retweet OR RT
TweetStream::Client.new.track('retweet', 'RT') do |status|
  # If the tweet is a retweet, find and store the original tweet.
  original_tweet = status.retweeted_status

  # If we found an original tweet...
  unless original_tweet.nil?

    # If the hash does not contain the original tweet id...
    if retweets[original_tweet.id].nil?

      # If the original tweet id contains the string "win "
      if original_tweet.text.downcase.include? 'win '

        # @todo change this to actually retweet. Currently, print out the tweet for testing
        puts "Retweet: #{original_tweet.text}"

        # Detect a follow requirement
        # @todo change this to actually follow. Currently, print out the username to follow
        # @todo implement a queue to deal with Twitter follow limits.
        puts "Follow:  [@#{original_tweet.user.screen_name}]" if original_tweet.text.downcase.include? "follow"

        # Add the tweet id to the hash, initialized to value 1
        retweets[original_tweet.id] = 1
      end

      # If the has already has the tweet id...
    else
      # Output message for testing.
      puts 'Already Retweeted!'
      # Increment the value. This keeps track of how many times an original has been retweeted.
      retweets[original_tweet.id] += 1
    end

    # Once the hash gets a certain size, dump it to a file as YAML.
    if retweets.length > req_len
      obj = YAML::dump(retweets)
      File.open(file, 'w') { |f| f.write obj.to_yaml }
      req_len += len_increment # Increment the required length
    end
  end
end