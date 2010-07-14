require File.dirname(__FILE__) + '/output'
require File.dirname(__FILE__) + '/puller'
require File.dirname(__FILE__) + '/data_fetcher'

require 'uri'

class Time
  def to_hash
    { 
      :year  => self.year,
      :month => self.month,
      :day   => self.day,
    }
  end
end

class SourcePuller 
  U = DataCatalog::ImporterFramework::Utility

  def initialize(uri)
    @metadata_master = []
    @org_data_master = []
    @base_uri        = uri
    @base            = 'http://data.seattle.gov/'
  end

  def get_metadata
    df = DataFetcher.new(@base_uri)
    unformatted_metadata = df.fetch_json
    format_metadata(unformatted_metadata)
  end

  def format_metadata(metadata)
    metadata.each do | data |
      org_type = data["category"]
      title = data["name"]
      id = data["id"]
      url = @base + org_type + "/" + title.gsub(" ", "-") + "/" + id
      release_date = Time.at(data["createdAt"])
      cc_license = data["license"]

      if cc_license
        license = cc_license["name"]
        license_url = cc_license["termsLink"]
      else
        license = "Public Domain"
        license_url = nil
      end

      m = {
        :title        => title,
        :source_type  => "dataset",
        :catalog_name => "Seattle Data Catalog",
        :catalog_url  => @base_uri,
        :url          => url,
        :released     => release_date.to_hash,
        :license     => license,
        :frequency    => "unknown",
      }

      m[:license_url] = license_url if license_url

      org_name = data["owner"]["displayName"]
      org_url = @base + "profile/" + org_name.gsub(" ","-") + "/" + data["owner"]["id"]
      org_data = {
        :home_url => org_url,
        :name     => org_name,
      }

      description = data["description"]
      m[:description] = U.multi_line_clean(description) if description

      m[:organization] = org_data

      add_org_to_master(org_data, org_type)

      download_types = ["csv", "pdf", "xls", "xml", "xlsl", "json"]
      downloads = []
      download_types.each do | download_type |
        url = "http://data.seattle.gov/views/#{id}/rows.#{download_type}?accessType=DOWNLOAD"
        downloads << {
          :url => url,
          :format => download_type.upcase,
        }
      end
      m[:downloads] = downloads

      #Custom fields
      tags = data["tags"]
      add_to_custom(m, "tags", "tags for the record", "Array", tags) if tags
      last_modified = Time.at(data["viewLastModified"])
      add_to_custom(m, "last modified", 
                    "Last time the record was modified", "Hash", 
                    last_modified.to_hash)
      @metadata_master << m
    end
    @metadata_master
  end

  def get_org_data
    @org_data_master
  end

  private

  def add_to_custom(metadata, label, description, type, value)
    if metadata[:custom].nil?
      metadata[:custom] = {}
    end
    num = metadata[:custom].size.to_s
    metadata[:custom][num] = { :label => label,
                               :description => description,
                               :type  => type, :value => value}
  end

  def add_org_to_master(org_data, org_type)
    already_exists = @org_data_master.find do | data | 
      data[:home_url] == org_data[:home_url]
    end
    
    unless already_exists
      @org_data_master << org_data.merge({ :org_type => org_type }) 
    end
  end

end
