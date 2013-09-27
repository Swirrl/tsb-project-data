class Address

  include TsbResource

  rdf_type Vocabulary::VCARD.Address

  # literals
  field :label, RDF::RDFS.label
  field :street_address, Vocabulary::VCARD['street-address']
  field :locality, Vocabulary::VCARD.locality
  field :county, Vocabulary::VCARD.region
  field :postcode, Vocabulary::VCARD['postal-code']

end