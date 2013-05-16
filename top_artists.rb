#!/usr/bin/ruby
require 'lastfm'
require 'json'
require 'set'
require './env'

if ARGV.length != 1
    puts "Usage: ./#{$PROGRAM_NAME} username"
    exit(0)
end

lastfm = Lastfm.new(LAST_FM_KEY, LAST_FM_SECRET)
top_artists = lastfm.user.get_top_artists(:user => ARGV[0], :limit => 10)

ta = {}

top_artists.each do |artist|
  ta[artist['name']] = artist['rank'].to_i - 1
end

conns = []
all_tags = {}
genres = {}

s = Set.new
top_artists_count = top_artists.length

top_artists.each.with_index(1) do |artist, index|
  puts "#{index} of #{top_artists_count}: Processing #{artist['name']}"
  # tags
  tags = lastfm.artist.get_top_tags(:artist => artist['name'])
  all_tags[artist['name']] = tags[0]['name']
  s.add(tags[0]['name'])

  # similarities
  # note: similarities are not symmetrical according to last.fm
  similar = lastfm.artist.get_similar(:artist => artist['name'], :mbid => artist['mbid'])
  similar.each do |sim_art|
    unless sim_art['match'].to_f < 0.2 || ta[sim_art['name']].nil?
      foo = {"source"=>ta[artist['name']], "target" => ta[sim_art['name']], "match" => sim_art['match'] }
      conns.push(foo)
    end
  end
end

s.each_with_index.map { |x,i| genres[x] = i }

# puts "ta: #{ta}"
# puts "conns:#{conns}"
# puts "tags:#{all_tags}"
# puts "genres:#{genres}"

all_tags.keys.each do |k|
  top_artists[ta[k]]['color'] = genres[all_tags[k]]
end

color_genres = genres.map { |k,n| { "genre" => k, "color" => n} }

top_artists_hash = {'nodes' => top_artists, 'links' => conns, 'genres' => color_genres}

File.open('top_artists.json', 'w') {|f| f.write(JSON.pretty_generate(top_artists_hash))}
