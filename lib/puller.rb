gem 'datacatalog-importer', '>= 0.2.0'
require 'datacatalog-importer'

class Puller

  U = DataCatalog::ImporterFramework::Utility
  I = DataCatalog::ImporterFramework
  
  FETCH_DELAY = 0.1
  FORCE_FETCH = true 
  
  #Pull the initial data down and save it locally, parsed in easily readable form.
  def initialize(handler)
    @source_uri = "http://data.seattle.gov/#type=all"
    @source_data = Output.dir '/../cache/raw/source/index.yml'
    @handler = handler
    source = SourcePuller.new(@source_uri)
    document = U.parse_html_from_file_or_uri(@base_uri, @index_html, 
                                             :force_fetch => FORCE_FETCH)

    @source_metadata = source.get_metadata
    U.write_yaml(@source_data, @source_metadata) # for easy viewing later
  end

  def run

  end


end
