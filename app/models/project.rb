class Project

  include TsbResource # some common (RDF-related) stuff
  include ProjectSearch # for elastic search
  extend ProjectCsv

  rdf_type Vocabulary::TSBDEF.Project

  # literals (label comes from tsb resource)
  field :description, Vocabulary::DCTERMS.description
  field :project_number, Vocabulary::TSBDEF.projectNumber
  field :modified, Vocabulary::DCTERMS.modified, datatype: RDF::XSD.dateTime

  # links
#  linked_to :leader, Vocabulary::TSBDEF.hasLeader, class_name: 'Organization' # gone: all just participants now.

  # Note a grant is paid to one org for one project
  linked_to :supported_by, Vocabulary::TSBDEF.supportedBy, class_name: 'Grant', multivalued: true
  linked_to :participants, Vocabulary::TSBDEF.hasParticipant, class_name: 'Organization', multivalued: true

  #  linked_to :competition, Vocabulary::TSBDEF.competition (gone - used to link to priority area)
  linked_to :area_budget_holder, Vocabulary::TSBDEF.areaBudgetHolder, class_name: 'AreaBudgetHolder'
  linked_to :project_status, Vocabulary::TSBDEF.projectStatus, class_name: 'ProjectStatus'
  linked_to :duration, Vocabulary::TSBDEF.projectDuration, class_name: 'ProjectDuration'
  linked_to :cost_category, Vocabulary::TSBDEF.costCategory


  def ordered_participants
    Organization.find_by_sparql("
      SELECT (sum(?offer_cost) as ?total_cost) ?uri WHERE {
        GRAPH <#{Organization.get_graph_uri}> {
          ?uri <#{Vocabulary::TSBDEF.participatesIn}> <#{self.uri.to_s}> .
          <#{self.uri.to_s}> <#{Vocabulary::TSBDEF.supportedBy}> ?grant .
          ?grant <#{Vocabulary::TSBDEF.paidTo}> ?uri .
          ?grant <#{Vocabulary::TSBDEF.offerCost}> ?offer_cost .
        }
      }

      GROUP BY(?uri)
      ORDER By DESC(?total_cost)
    ")
  end

  def offer_cost_sum
    supported_by.sum(&:offer_cost).to_f
  end

  def offer_grant_sum
    supported_by.sum(&:offer_grant).to_f
  end

  # def payments_to_date_sum
  #   supported_by.sum(&:payments_to_date).to_f
  # end

  def offer_cost_sum_for_organization(organization)
    grants_for_organization(organization).resources.sum(&:offer_cost).to_f
  end

  def offer_grant_sum_for_organization(organization)
    grants_for_organization(organization).resources.sum(&:offer_grant).to_f
  end

  # def payments_to_date_sum_for_organization(organization)
  #   grants_for_organization(organization).resources.sum(&:payments_to_date).to_f
  # end

  def grants_for_organization(organization)
    Grant
      .where("?uri <#{Vocabulary::TSBDEF.supports}> <#{self.uri.to_s}>")
      .where("?uri <#{Vocabulary::TSBDEF.paidTo}> <#{organization.uri.to_s}>")
  end

  def max_offer_cost
    supported_by.collect(&:offer_cost).max
  end


end