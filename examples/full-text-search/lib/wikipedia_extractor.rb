require 'nokogiri'

class WikipediaExtractor
  def initialize(listener)
    @listener = listener
  end

  def extract(input)
    extractor = Extractor.new(@listener)
    parser = Nokogiri::XML::SAX::Parser.new(extractor)
    parser.parse(input)
  end

  class Extractor
    def initialize(listener)
      @listener = listener
      @name_stack = []
      @text_stack = []
    end

    ###
    # Called when document starts parsing
    def start_document
    end

    ###
    # Called when document ends parsing
    def end_document
    end

    ###
    # Called at the beginning of an element
    # +name+ is the name of the tag with +attrs+ as attributes
    def start_element(name, attrs=[])
      @name_stack << name
      @text_stack << ""
    end

    ###
    # Called at the end of an element
    # +name+ is the tag name
    def end_element(name)
      case @name_stack.join(".")
      when "mediawiki.page.title"
        @listener.title(@text_stack.last)
      when "mediawiki.page.revision.timestamp"
        @listener.timestamp(Time.parse(@text_stack.last))
      when "mediawiki.page.revision.text"
        @listener.content(@text_stack.last)
      end
      @name_stack.pop
      @text_stack.pop
    end

    ###
    # Characters read between a tag
    # +string+ contains the character data
    def characters(string)
      elements_without_interested_text = [
                                          "mediawiki", "siteinfo", "case",
                                          "namespaces", "revisions",
                                          "contributor",
                                         ]
      return if elements_without_interested_text.include?(@name_stack.last)
      @text_stack.last << string
    end

    ###
    # Called when comments are encountered
    # +string+ contains the comment data
    def comment(string)
    end

    ###
    # Called on document warnings
    # +string+ contains the warning
    def warning(string)
    end

    ###
    # Called on document errors
    # +string+ contains the error
    def error(string)
    end

    ###
    # Called when cdata blocks are found
    # +string+ contains the cdata content
    def cdata_block(string)
    end
  end
end
