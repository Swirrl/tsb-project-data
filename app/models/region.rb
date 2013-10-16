class Region
  include TsbResource

  rdf_type RDF::URI.new('http://statistics.data.gov.uk/def/statistical-geography')
  DATASET_SLUG = "regions"
  graph_uri "http://#{PublishMyData.local_domain}/graph/#{Region::DATASET_SLUG}"

end