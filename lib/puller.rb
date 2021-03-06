require File.dirname(__FILE__) + '/output'
require File.dirname(__FILE__) + '/source_puller'
require File.dirname(__FILE__) + '/organization_puller'

gem 'datacatalog-importer', '>= 0.2.0'
require 'datacatalog-importer'

class Puller

  U = DataCatalog::ImporterFramework::Utility
  I = DataCatalog::ImporterFramework
  
  FETCH_DELAY = 0.1
  FORCE_FETCH = true 
  
  #Pull the initial data down and save it locally, parsed in easily readable form.
  def initialize(handler)
    @source_uri = "http://data.seattle.gov/api/views"
    @source_data_file = Output.file '/../cache/raw/source/index.yml'
    @organization_data_file = Output.file '/../cache/raw/organization/index.yml'
    @catalog_url = "http://data.seattle.gov/#type=all"

    @handler = handler
    source = SourcePuller.new(@source_uri)

    @source_metadata = source.get_metadata
    U.write_yaml(@source_data_file, @source_metadata) # for easy viewing later

    shared_org_data = source.get_org_data
    organization = OrganizationPuller.new(shared_org_data)

    @organization_metadata = organization.get_metadata
    U.write_yaml(@organization_data_file, @organization_metadata)
  end

  def run
    shared_data = {
      :catalog_name => "Seattle Data Catalog",
      :catalog_url  => @catalog_url,
    }
    @source_metadata.each do |s|
      @handler.source(s.merge(shared_data))
    end

    @organization_metadata.each do |o|
      @handler.organization(o.merge(shared_data))
    end
  end


end
