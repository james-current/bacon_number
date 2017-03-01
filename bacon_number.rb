require 'faraday'
require 'faraday_middleware'
require 'set'

# input: a Wikipedia title, it can contain '_'s or not (so that it's easy to copy form the end of a url)
# output: how many degrees of separation between the input title and Kevin Bacon
def bacon_number(start: 'Kevin Bacon')
  title = clean_input start
  breadth_first_search title
end

# Replace '_' with ' '
def clean_input(input)
  input.gsub('_', ' ')
end

# Quick and dirty breadth first search
# input: a Wikipedia title that has spaces, not _
# output: how many hops separate the input title and Kevin Bacon
def breadth_first_search(title)
  # use a set so that we don't visit the same url twice (or more)
  visited = Set.new
  # using an array because the ruby queue looks like it's used for threading
  to_visit = []
  target= 'Kevin Bacon'
  level = 0

  to_visit.push title
  last_on_level = title

  conn = get_connection

  # loop until there are no urls to visit
  until to_visit.empty? || level == 7
    current = to_visit.shift
    return level if current == target

    # I am currently not including continues here, so if more than 500 links are returned the optimal path may not be found
    resp = conn.get('api.php', action: 'query', titles: current, prop: 'links', format: 'json', pllimit: 'max')
    links = resp.body['query']['pages'].first().last()['links']
    links.each do |link|
      unless visited.include? link['title']
        visited.add link['title']
        to_visit.push link['title']
      end
    end
    if current == last_on_level
      last_on_level = to_visit.last
      level += 1
    end
  end
  'Maximum level (7) reached'
end

# Get a connection to a given url
def get_connection
  url = 'https://en.wikipedia.org/w/'

  Faraday.new(url: url) do |faraday|
    faraday.adapter Faraday.default_adapter
    faraday.response :json
  end
end
