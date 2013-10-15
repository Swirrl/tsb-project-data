class Organization

  include TsbResource

  rdf_type Vocabulary::TSBDEF.Organization

  # TODO: check what predicate Companies House uses to link company to number
  field :company_number, Vocabulary::TSBDEF.companyNumber

  # links
  linked_to :leads_projects, Vocabulary::TSBDEF.isLeaderOf, class_name: 'Project', multivalued: true
  linked_to :participates_in_projects, Vocabulary::TSBDEF.participatesIn, class_name: 'Project', multivalued: true
  linked_to :site, Vocabulary::ORG.hasSite, class_name: 'Site'
  linked_to :legal_entity_form, Vocabulary::TSBDEF.legalEntityForm
  linked_to :enterprise_size, Vocabulary::TSBDEF.enterpriseSize
  linked_to :sic_class, Vocabulary::TSBDEF.standardIndustrialClassification, class_name: 'SicClass', multivalued: true

  def offer_cost_sum
    grants.resources.sum(&:offer_cost).to_f
  end

  def offer_grant_sum
    grants.resources.sum(&:offer_grant).to_f
  end

  def payments_to_date_sum
    grants.resources.sum(&:payments_to_date).to_f
  end

  def grants
    Grant.where("?uri <#{Vocabulary::TSBDEF.paidTo}> <#{self.uri}>")
  end

end