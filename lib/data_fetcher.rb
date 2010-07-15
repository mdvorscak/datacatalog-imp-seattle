require File.dirname(__FILE__) + '/output'

class DataFetcher

  include HTTParty
  U = DataCatalog::ImporterFramework::Utility

  def initialize(url)
    @url = url
    @output_file = Output.file '/../cache/raw/source/data.yml'
  end

  def fetch_json
    metadata = self.class.get(@url)
    U.write_yaml(@output_file, metadata)
    metadata
  end
 
end
