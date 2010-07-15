class OrganizationPuller 

  def initialize(shared_data)
    @orgs = shared_data
    parse_additional_info
  end

  def parse_additional_info
    @orgs.each do | org |
      org[:org_type] = "governmental"
      org.merge!( { :organization => { :name => "Seattle" } })
    end
  end

  def get_metadata
    @orgs
  end

end
