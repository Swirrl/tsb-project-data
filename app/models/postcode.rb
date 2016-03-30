class Postcode
  include TsbResource

  field :lat, Vocabulary::GEO.lat, datatype: RDF::XSD.decimal
  field :long, Vocabulary::GEO.long, datatype: RDF::XSD.decimal
  field :district, Vocabulary::OSGEO.district, is_uri: true
  
end