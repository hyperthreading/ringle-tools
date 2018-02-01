# coding: utf-8
original = File.read("./original.txt")

def simple_word(w)
  w.gsub(/[^\w]+/, '').downcase
end

def json_read
  require "json"
  file = File.read("./test.json")
  json = JSON.parse(file)
  json["results"].map{|m|
    m["alternatives"][0]["timestamps"]
  }.flatten(1)
end


offset = 0
range = 3
default_range = 3
window_size = 1
watson_split = json_read
original.split(' ').each {|word|
  to_search = watson_split[offset...(offset+range)]

  found = false
  to_search.each_with_index { |watsondata, idx|
    watsonword = watsondata[0]
    if simple_word(watsonword) == simple_word(word)
      offset += (idx + 1)
      found = true
      puts "[#{watsondata[1]}] #{word} "

      break
    end
  }
  if not found
    estimated = watson_split[offset + (range - default_range)][1].to_s
    puts "?[#{estimated}]#{word} "
    range += window_size
  else
    range = default_range
  end
  
}
 
#real = read read read a ...
#wats = read lead read a ...
# results
# alternatives[0]
# > transcript
# > timestamps




