require File.dirname(__FILE__) + '/output'
require File.dirname(__FILE__) + '/puller'

gem 'kronos', '>= 0.1.6'
require 'kronos'
require 'uri'

class SourcePuller 
  U = DataCatalog::ImporterFramework::Utility

  def initialize(uri, force_fetch)
    @metadata_master = []
    @base           = "http://data.seattle.gov/"
    @force_fetch    = force_fetch
    @page_number    = 1
    @base_uri       = uri
    @next           = uri
    @index_html     = Output.file '/../cache/raw/source/index.html'
    parse_all_pages
  end

  protected

  def parse_all_pages
    parse_page(@base_uri + "&page=19")
    #metadata = parse_page(@next) while @next
  end

  def parse_page(url)
    filized_url = url.gsub("http://","")
    filized_url = filized_url.scan(/.*?\//).first
    filized_url.chop!
    output_file = Output.file '/../cache/raw/source/' + filized_url
    doc = U.parse_html_from_file_or_uri(url, output_file, 
                                             :force_fetch => @force_fetch)

    set_next(doc)

    rows = doc.xpath("//li//div[@class='itemActionContainer']//ul")
    rows.each do | row |
      li_tag = row.css("li").first
      a_tag = li_tag.css("a").first
      link = a_tag["href"]
      parse_single_source(link)
    end
  end

  def set_next(document)
    pages = document.xpath("//div[@class='pagination']")
    last_link = pages.css("a").last
    @page_number += 1
    debugger
    if last_link.inner_text == "Next"
      @next = @base_uri + "&page=#{@page_number}"
    else
      @next = nil
    end
  end

  def parse_single_source(uri)
    
  end

  def get_metadata
	  table_rows = doc.xpath("//table//tr")

	  metadata = []
	  table_rows.delete(table_rows[0])
	  table_rows.each do | row |
		  formats = { :downloads => {}, :source => {} }
		  cells = row.css("td")

      format_cells = 2..5
      format_cells.each do | x |
        add_format(formats, cells[x].inner_text, cells[x])
      end

		metadata << {
			:title        => cells[0].inner_text,
			:description  => U.multi_line_clean(cells[1].inner_text),
			:formats      => formats
		}
	  end
	metadata
  end

	def parse_metadata(metadata)
    source = metadata[:formats][:source]
		m = {
        :title        => metadata[:title],
        :description  => metadata[:description],
        :source_type  => "dataset",
        :catalog_name => "utah.gov",
        :catalog_url  => @base_uri,
        :url          => source[:source_url],
        :frequency    => "unknown"
		  }
    downloads = []
    metadata[:formats][:downloads].each do | key, value |
			downloads << { :url => value[:href], :format => key }
    end

    m[:organization] = { :url  => source[:source_url],
                         :name => source[:source_org] }

    m[:downloads] = downloads
    m
	end

  private 

  def add_format(formats, label, node)
	  a_tag = node.css("a").first
	  if a_tag
		  link = a_tag["href"]

		  #strip http:// out to make the next regex simpler
		  plain_link = link.gsub("http://", "")
		  #Only go to the first /
		  source_link = plain_link.scan(/.*?\//).first
		  	
		  formats[:source][:source_url] = "http://" + source_link.chop!
		  formats[:source][:source_org] = source_link

      #Add http:// back in
      link = "http://" + plain_link 
		  formats[:downloads][label] = { :href => link }

	  end
  end

end
