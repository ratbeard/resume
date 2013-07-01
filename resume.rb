require 'pp'
require 'rubygems' # for pdf/reader inside prawn
# prawn gem is old:
$LOAD_PATH.unshift('~/code/prawn/lib')
require 'prawn'

module Resume
  Experience = Struct.new(:company, :role, :time, :location, :summary, :points)
  FILE = 'Mike_Frawley_resume'
  
  def self.convert
    reader = Reader.new(FILE + '.txt')
    Writer.new(FILE + '.pdf', reader)
    `open #{FILE + '.pdf'}`
  end
  
  class Reader
    def initialize(filename)
      @filename = filename
      @str = File.read(filename)
      @experiences = []
      parse(@str)
    end
    attr_accessor :str
    
    attr_reader :name, :phone, :email, :website, :groups, :experiences
    attr_reader :intro, :education
    
    def parse(str)
      # get the '~ ~ ~ ...' experience line seperator:
      experience_delimeter = str[/^([\s~]+)$\n/, 1]
      
      # get top resume, and array of experiences:
      about_me, *experiences = str.split(experience_delimeter)
      
      # parse sections:
      @top = parse_top(about_me)
      @experiences = parse_experiences(experiences)
    end
    
    # quick and dirty for now:
    def parse_top(top)
      @name, @website, @email, @phone, _, intro1, intro2, _, edu1, edu2, edu3 = top.split("\n")
      
      @intro = [intro1, intro2].join(" ")
      @education = [edu1, edu2, edu3].join("\n")
      
      [@intro, @education].each {|s| 
        s.gsub!(/^\w+:/, '')
      }
      
      # groups = rest.join("\n").split(/^(?=\w+:)/)
      # @groups = groups[1..-1] # remove empty first line and experience:
      # # groups = rest.join("\n").split(/\w+:\s+/)
      # puts rest.join("\n")
      # pp groups
      # pp groups.length
      
      # rest.each do |line|
      #   next if line.empty?
      #   if line =~ /^(\w+):\s+(.*?)$/
      #     puts $1, $2, '', ''
      #     name, lines = $1.downcase, [$2]
      #     instance_variable_set("@#{name}", lines)
      #   else # multi-line
      #     puts ':)'
      #   end
      # end
    end
    
    def parse_experiences(experiences)
      many_spaces = /\s{5,}/
      experiences.map do |experience|
        meta, summary, points = experience.strip.split("\n\n")
        
        # extract metadata about the job
        role_and_time, company_and_location = meta.split("\n")
        role, time = role_and_time.split(many_spaces)
        company, location = company_and_location.split(many_spaces)
        
        # cleanup summary and experience points
        summary = cleanup(summary)
        points = points.split(/-\s/)[1..-1].map {|point| cleanup(point)} if points
        
        Experience.new(company, role, time, location, summary, points)
      end
    end
    
    # Remove newlines
    # Remove multiple spaces, not following a period
    def cleanup(str)
      str.
        gsub(/\n/, ' ').
        gsub(/\s{2,}/, ' ').
        gsub(/\.\s/, '.  ')
    end
  end
  
  
  # Write pdf to file
  class Writer
    def initialize(filename, data)
      @filename, @data = filename, data
      pdf = PDF.new(:margin => [36, 72]) { @data = data }
      pdf.render_file(filename)
    end
  end
  
  
  # Heres my resume, as a pdf
  class PDF < Prawn::Document
    attr_accessor :data
    
    # def initialize(*)
    #   super :margin_left => 500
    # end
    
    def render
      font_size 10
      fill_color "222222"
      stroke_color "999999"
      # font "/System/Library/Fonts/HelveticaNeue.dfont"
      
      render_top
      render_experiences
      
      super
    end
    
    def render_top
      # top
      y = cursor
      text @data.name, :align => :left, :size => 18
      text @data.website, :align => :left,  :size => 12
      move_cursor_to y
      move_down 3
      text @data.email, :align => :right, :size => 10
      text @data.phone, :align => :right, :size => 10
      move_down 12
      
      left_width = 70
      right_width = bounds.width - left_width
      
      # quick and dirty, just make some blank lines for now:
      table([
        [nil, nil],
        [nil, nil],
        [nil, nil],
        ['About:', @data.intro],
        ['Education:', @data.education],
        # ['Experience:', nil],
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [nil, nil]
      ], :column_widths => [left_width, right_width], :cell_style => {:borders => [], :padding => 1})
      move_down 5
    end
    
    def render_experiences
      @data.experiences.each {|e| render_experience(e) }
    end
          
    def render_experience(experience)
      return unless experience
      # Start a new page, if the amount of space left on this page is an arbitrary number:
      bounds.move_past_bottom if cursor < 100
      
      stroke_horizontal_rule
      move_down 15
      
      edges_text(experience.role, experience.time)
      edges_text(experience.company, experience.location)
      move_down 10

      indent 0 do      
        text experience.summary
        move_down 5
      
        experience.points.each do |point|
          bullet(point)
        end
      end

      move_down 15
    end
    
    def nbsp(count=1)
      Prawn::Text::NBSP * count
    end
    
    def bullet(text)
      bullet_width = 10
      table(
        [["#{nbsp}•#{nbsp}", text]], 
        :column_widths => [bullet_width, bounds.width - bullet_width], 
        :cell_style => {:borders => [], :padding => [2,0,0,0]})
    end
    
    # draw left and right aligned text on the same line
    def edges_text(left_aligned_text, right_aligned_text)
      y = cursor
      text left_aligned_text, :align => :left
      move_cursor_to y
      text right_aligned_text, :align => :right
    end
  end
end


if $0 == __FILE__
  Resume.convert
end
