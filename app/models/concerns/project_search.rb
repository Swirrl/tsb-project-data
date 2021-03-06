module ProjectSearch
  extend ActiveSupport::Concern

  included do
    include Tire::Model::Search

    # check the mapping with
    # curl http://localhost:9200/projects/_mapping
    tire.mapping do

      # from project
      indexes :uri, type: 'string', analyzer: 'keyword' # this is the same as what will be in id, but index this field for convenince too.
      indexes :label, type: 'string', analyzer: 'snowball', :boost => 10
      indexes :label_unanalyzed_downcase, type: 'string', analyzer: 'keyword'
      indexes :start_date, type: 'date'
      indexes :end_date, type: 'date'
      indexes :status_uri, type: 'string', analyzer: 'keyword'
      indexes :status_label, type: 'string', analyzer: 'keyword'
      indexes :modified, type: 'date'
      indexes :cost_category_label, type: 'string'

      indexes :description, type: 'string', analyzer: 'snowball'

      # from project's grants
      indexes :total_offer_grant, type: 'integer'
      indexes :total_offer_cost, type: 'integer'

      # from lead org
      # indexes :leader_uri, type: 'string', analyzer: 'keyword'
      # indexes :leader_label, type: 'string', analyzer: 'snowball', :boost => 5

      # from participants (could be many)
      indexes :participant_uris, type: 'string', analyzer: 'keyword'
      indexes :participant_labels, type: 'string', analyzer: 'snowball'
      indexes :participant_company_numbers, type: 'string', analyzer: 'keyword'
      indexes :participant_legal_entity_form_labels, type: 'string', analyzer: 'keyword'


      indexes :participant_size_uris, type: 'string', analyzer: 'keyword'
      indexes :participant_size_labels, type: 'string', analyzer: 'keyword'

      indexes :participant_sic_section_uris, type: 'string', analyzer: 'keyword'
      indexes :participant_sic_section_labels, type: 'string', analyzer: 'keyword'

      # from participants' sites (could be many)
      indexes :participant_locations, type: 'geo_point'
      indexes :region_uris, type: 'string', analyzer: 'keyword'
      indexes :region_labels, type: 'string', analyzer: 'keyword'

      # # competition
      # indexes :competition_uri, type: 'string', analyzer: 'keyword'
      # indexes :competition_label, type: 'string', analyzer: 'keyword'

      # # competition's budget (priority area)
      # indexes :priority_area_uri, type: 'string', analyzer: 'keyword'
      # indexes :priority_area_label, type: 'string', analyzer: 'keyword'

      # # competition's product
      # indexes :product_uri, type: 'string', analyzer: 'keyword'
      # indexes :product_label, type: 'string', analyzer: 'keyword'

    end
  end

  def id
    uri.to_s
  end

  # generates an index document, from an in-memory hash of all resources
  def index_doc(resources_hash)

    # pre-load some objects from teh resources hash
    @duration_object = resources_hash[self.duration_uri]
    @grant_objects = self.supported_by_uris.map {|grant_uri| resources_hash[grant_uri] }
    @lead_org_object = resources_hash[self.leader_uri]
    @participant_objects = self.participants_uris.map {|org_uri| resources_hash[org_uri] }
    # @site_objects = @participant_objects.map {|p| resources_hash[p.site_uri] }
    # @competition_object ||= resources_hash[self.competition_uri]

    # Everything else wont be in the resources hash - we will look up from DB. Queries will be cached tho.

    doc = to_hash({_id: self.uri.to_s, type: 'project'})
  end

  def to_hash(doc={})
    doc
      .merge(project_index_fields)
      .merge(duration_index_fields)
      .merge(grant_index_fields)
      .merge(participant_index_fields)
      .merge(participant_size_index_fields)
      .merge(participant_sic_class_index_fields)
      .merge(participant_site_index_fields)
      .merge(participant_legal_entity_form_index_fields)
      .merge(participant_region_index_fields)
      # .merge(competition_index_fields)
      # .merge(priority_area_index_fields)
      # .merge(product_index_fields)

           # .merge(lead_org_index_fields)
  end

  private

  def project_index_fields
    {
      uri: uri.to_s,
      label: label,
      label_unanalyzed_downcase: label.downcase,
      status_uri: project_status_uri.to_s,
      status_label: project_status.label, # needs a lookup, but after first few will be cached.
      description: description,
      cost_category_label: (cost_category.label.to_s rescue nil),
    }
  end

  def duration_index_fields
    @duration_object ||= self.duration
    {
      start_date: @duration_object.start.iso8601,
      end_date: @duration_object.end.iso8601
    }
  end

  # def lead_org_index_fields
  #   @lead_org_object ||= self.leader
  #   {
  #      leader_uri: self.leader_uri.to_s,
  #      leader_label: (@lead_org_object.label rescue nil)
  #   }
  # end

  def grant_index_fields
    @grant_objects ||= self.supported_by

    latest_grant_date = @grant_objects.map{ |g| g.modified }.max

    {
       modified: (latest_grant_date > modified)? latest_grant_date : modified,
       total_offer_grant: @grant_objects.map {|g| g.offer_grant }.inject {|sum,x| sum + x },
       total_offer_cost: @grant_objects.map {|g| g.offer_cost }.inject {|sum,x| sum + x }
    }
  end

  def participant_index_fields
    @participant_objects ||= self.participants
    {
      participant_uris: @participant_objects.map { |p| p.uri.to_s },
      participant_labels: @participant_objects.map { |p| p.label },
      participant_company_numbers: @participant_objects.map { |p| p.company_number },
    }
  end

  def participant_legal_entity_form_index_fields
    @participant_objects ||= self.participants
    {
      participant_legal_entity_form_labels: @participant_objects.map { |p| p.legal_entity_form.label rescue nil }
    }
  end

  # ones below here will always need DB lookups from the supporting data, but will be cached.

  def participant_size_index_fields
    @participant_objects ||= self.participants
    {
      participant_size_uris: @participant_objects.map { |p| p.enterprise_size_uri.to_s },
      participant_size_labels: @participant_objects.map { |p| p.enterprise_size.label rescue nil },
    }
  end

  def participant_sic_class_index_fields
    @participant_objects ||= self.participants
    {
      participant_sic_section_uris: ( @participant_objects.map {|p| p.sic_classes.map{ |c| c.sic_section_uri.to_s } } rescue nil ),
      participant_sic_section_labels: ( @participant_objects.map {|p| p.sic_classes.map { |c| c.sic_section.label } } rescue nil )
    }
  end

  def participant_site_index_fields
    @site_objects ||= @participant_objects.map {|p| p.site }
    {
      participant_locations: @participant_objects.select{ |p| (p.has_lat_long?) }.map{ |p| "#{p.lat},#{p.long}"  }
    }
  end

  def participant_region_index_fields
    @participant_objects ||= self.participants
    @site_objects ||= @participant_objects.map {|p| p.site } # will already be set if doing a bulk load.
    @region_objects = @site_objects.map { |s| s.region }
    {
      region_uris: @site_objects.map {|s| s.region_uri.to_s },
      region_labels: @region_objects.map {|r| r.label rescue nil},
    }
  end

  # def competition_index_fields
  #   @competition_object ||= self.competition
  #   {
  #     competition_uri: self.competition_uri.to_s,
  #     competition_label: (@competition_object.label rescue nil)
  #   }
  # end

  def priority_area_index_fields
    @competition_object ||= self.competition

    if @competition_object
      @priority_area_object ||= @competition_object.priority_area
      {
        priority_area_uri: @competition_object.priority_area_uri.to_s,
        priority_area_label: (@priority_area_object.label rescue nil)
      }
    else
      {}
    end
  end

  def product_index_fields
    @competition_object ||= self.competition

    if @competition_object
      @product_object ||= @competition_object.product
      {
        product_uri: @competition_object.product_uri.to_s,
        product_label: (@product_object.label rescue nil)
      }
    else
      {}
    end
  end



end