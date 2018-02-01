# encoding: utf-8
require 'docx'

def open_docx(path)
  Docx::Document.open path
end

def doc
  open_docx ARGV[0]
end

# Extract every text from the paragraph
def get_text(p)
  p.xpath(".//text()").map(&:to_s).join('')
end

def get_content(p)
  output = p.node.xpath(".//w:t")
             .map{|node|
    (if node.previous_sibling and \
      node.previous_sibling.name == "rPr" and \
      node.previous_sibling.xpath("./w:b").length > 0
      ## Search for bold tag
      "<b>#{get_text(node)}</b>"
    else
      get_text node
    end)
  }.to_a.join('')
  output
end

# Not implemented yet :p
def split_sentence(p_text)
end

=begin
Find the depth of given paragraph using the indentation and existence of bullet
styles.
Range of returning depth: 0 .. 8
=end
def get_depth(p)
  if not p.node.xpath(".//w:pStyle").length > 0
    0
  else
    levels = p.node.xpath(".//w:ilvl")
    # not a bullet
    if levels.length == 0
      0
    else
      indent = levels.first.values.first.to_i
      indent + 1
    end
  end
end

# 4 spaces per one deep
def indentation(depth)
  " " * 4 * depth
end

def tag(_tag, classnames)
  if classnames.length > 0
    "<#{_tag} class=\"#{classnames.join(' ')}\">"
  else
    "<#{_tag}>"
  end
end

# ul tag
def start_tag(depth)
  indentation(depth).to_s + "<ul>\n"
end

# ul end tag
def end_tag(depth)
  indentation(depth).to_s + "</ul>\n"
end

def enclose_with(depth, tag, content)
  id = indentation(depth).to_s
  idid = indentation(depth + 1).to_s
  "#{id}<#{tag}>\n"\
  "#{idid}#{content}\n"\
  "#{id}</#{tag}>\n"
end

def enclose_paragraph(depth, content)
  if depth > 0
    enclose_with depth, "li", content
  else
    enclose_with depth, "p", "<span class=\"c_weight\">#{content}</span>"
  end
end

$romanian_numeral = /^[IVX]+\./
def pipe_output(paragraphs)
  stack = [0]
  # pipe result to stdout
  paragraphs.each {|text_struct|
    text = text_struct[1] #  html text
    plain = text_struct[2] # plain text
    if $romanian_numeral.match(plain)
      text = "<span class=\"c_color1\">#{text}</span>"
    end
    paragraph_depth = text_struct[0]
    previous_depth = stack.last
    puts (case previous_depth <=> paragraph_depth
          when -1 # more deeper
            stack.push(paragraph_depth)
            # return start tags
            (previous_depth...paragraph_depth)
              .map{|dep| start_tag dep }
              .join('')
          when 1 # more shallower
            stack = stack.take_while {|x| x < paragraph_depth}
            stack.push paragraph_depth
            (stack.last...previous_depth)
              .to_a.reverse
              .map{|dep| end_tag dep }
              .join('')
          else ""
          end) + \
         enclose_paragraph(paragraph_depth, text)
  }
end

def main(args)

  pars = open_docx(args[0]).paragraphs
           .map{|p| [get_depth(p), get_content(p), get_text(p.node)]}
           .reject{|t| t[2].length == 0}  # leave meaningful texts only

  lang_converter = /^\[Summary.+(English|Korean)\]/i
  require 'ostruct'
  lang_classes = OpenStruct.new(english: "c_family_e",
                                korean: "c_family_k")

  # drop anything before language tag
  until [] == pars = pars.drop_while{|t| not lang_converter.match t[2]} do
    lang_id = lang_converter.match(pars.first[2])[1].downcase
    # drop language tag
    pars = pars.drop(1)
    puts tag("div", [lang_classes[lang_id]])
    pipe_output pars.take_while{|t| not lang_converter.match t[2]}
    puts tag("/div", [])
  end
end

main(ARGV)
