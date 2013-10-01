module Import
  module RowToRdf

    require 'digest'
    require 'cgi'

    REGIONS = {
      "East Midlands" => "http://data.statistics.gov.uk/id/statistical-geography/E12000004",
      "West Midlands" => "http://data.statistics.gov.uk/id/statistical-geography/E12000005",
      "South West" => "http://data.statistics.gov.uk/id/statistical-geography/E12000009",
      "South East" => "http://data.statistics.gov.uk/id/statistical-geography/E12000008",
      "North West" => "http://data.statistics.gov.uk/id/statistical-geography/E12000002",
      "North East" => "http://data.statistics.gov.uk/id/statistical-geography/E12000001",
      "East of England" => "http://data.statistics.gov.uk/id/statistical-geography/E12000006",
      "Yorkshire and The Humber" => "http://data.statistics.gov.uk/id/statistical-geography/E12000003",
      "London" => "http://data.statistics.gov.uk/id/statistical-geography/E12000007",
      "Northern Ireland" => "http://data.statistics.gov.uk/id/statistical-geography/N92000002",
      "Scotland" => "http://data.statistics.gov.uk/id/statistical-geography/S92000003",
      "Wales" => "http://data.statistics.gov.uk/id/statistical-geography/W92000004"
    }

    def row2rdf(resources,row,sic_hash)

      ##### Project #####
      # uri: use TSBProjectNumber
      proj_num = row["TSBProjectNumber"].to_i.to_s
      project_uri = Vocabulary::TSB["project/#{proj_num}"]
      # if this project already exists, then don't do it again
      if resources[project_uri]
        p = resources[project_uri]
      else
        p = Project.new(project_uri)
        # add to resources hash
        resources[project_uri] = p
        project_title = row["ProjectTitle"]
        p.label = project_title
        description = row["PublicDescription"]
        # clean up description - replace double line breaks with space chars.
        description.gsub!(/\n\n/,' ')
        p.description = description
        p.project_number = proj_num
        status = row["ProjectStatus"]
        status_uri = Vocabulary::TSBDEF["concept/project-status/#{urlify(status)}"]
        p.project_status_uri = status_uri
        duration_uri = Vocabulary::TSB["project/#{proj_num}/duration"]
        d = ProjectDuration.new(duration_uri)
        p.duration = d
        resources[duration_uri] = d
        d.label = "Duration of project #{proj_num}"
        ## TO DO - sort out date formatting
        t1 = row["StartDate"]
        t2 = row["ProjectEndDate"]
        d.start  = t1.strftime('%Y-%m-%d')
        d.end = t2.strftime('%Y-%m-%d')
        costcat = row["CostCategoryType"]
        if ["Industrial","Academic"].include?(costcat)
          cc_uri = Vocabulary::TSBDEF["concept/cost-category/#{urlify(costcat)}"]
          cc = CostCategory.new(cc_uri)
          p.cost_category = cc
        end

      end





      ##### Organization ####
      # uri: use company number if it exists.
      # if no company number, then use urlified name
      org_name = row["ParticipantName"]
      urlified_org_name = urlify(org_name)
      org_number = row["CompanyRegNo"]
      org_slug = nil
      if org_number
        org_slug = org_number.to_s

        # normalise the format
        # replace any spaces with '-'
        org_slug.gsub!(/ /,'-')
        #  add leading zeroes if necessary
        unless org_slug.starts_with?('RC')
          while org_slug.length < 8
            org_slug = "0" + org_slug
          end

        end
      elsif org_number == "Exempt Charity"
        org_slug = urlified_org_name
      elsif org_number == "NHS Hospital"
        org_slug = urlified_org_name
      else  # no company num at all
        org_slug = urlified_org_name
      end

      org_uri = Vocabulary::TSB["organization/#{org_slug}"]

      # if org exists, don't do it again
      if resources[org_uri]
        o = resources[org_uri]
      else
        o = Organization.new(org_uri)
        # add to resources hash
        resources[org_uri] = o
        o.label = org_name
        o.company_number = org_number
        # for now, ignore the case where an org might have two addresses - just use the first one
        site_uri = Vocabulary::TSB["organization/#{org_slug}/site"]
        address_uri = Vocabulary::TSB["organization/#{org_slug}/address"]

        # will only do site and address once for each org
        s = Site.new(site_uri)
        o.site = s
        a = Address.new(address_uri)
        s.label = "Site of #{org_name}"
        s.address = a

        resources[site_uri] = s
        resources[address_uri] = a

        # clean up the address cell of the spreadsheet, removing line breaks
        address = row["Address"]
        cleaned_address = address.gsub(/\n/,', ')
        a.street_address = cleaned_address
        a.locality = row["Town"]
        a.county = row["County"]
        a.postcode = row["Postcode"]

        region = row["Validated Region"].strip
        region_uri = REGIONS[region]
        if region_uri
          r = Region.new(region_uri)
          s.region = r
        else
          puts "nil region #{region}"
        end



        # postcode - connect to OS URI - what should the subject be? the organization? the site?
        postcode = row["Postcode"].gsub(/ /,'') # remove spaces
        pc_uri = Vocabulary::OSPC[postcode]

        s.postcode = pc_uri

        # Look up location and district for OS postcode and connect to site.
        query = "SELECT ?lat ?long ?district_gss WHERE {
          <#{pc_uri}> <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat .
          <#{pc_uri}> <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long .
          <#{pc_uri}> <http://data.ordnancesurvey.co.uk/ontology/postcode/district> ?os_district .
          ?os_district <http://www.w3.org/2002/07/owl#sameAs> ?district_gss
        }"

        encoded_query = CGI::escape(query)
        query_url = "http://opendatacommunities.org/sparql.json?query=" + encoded_query + "&api_key=346ead3fc7282de4827f2a5cf408b089"
        response = JSON.parse(RestClient.get query_url)
        result = response["results"]["bindings"][0]
        lat = result["lat"]["value"] if result && result["lat"]
        long = result["long"]["value"] if result && result["long"]
        district = result["district_gss"]["value"] if result && result["district_gss"]
        s.lat = lat if lat
        s.long = long if long
        s.district = district if district
        #puts "#{lat || 'nil'} #{long || 'nil'}"
        # legal entity form and enterprise size
        esize = row["EnterpriseSize"]
        if esize
          esize_uri = Vocabulary::TSBDEF["concept/enterprise-size/#{urlify(esize)}"]
          o.enterprise_size = EnterpriseSize.new(esize_uri)
        end
        legal_form_code = LegalEntityForm::LEGAL_ENTITY_FORMS[row["ParticipantOrganisationType"]]
        if legal_form_code
          form = LegalEntityForm.new(Vocabulary::TSBDEF["concept/legal-entity-form/#{legal_form_code}"])
          o.legal_entity_form = form
        end



        # TODO connect company to OpenCorporates and Companies House
        # SIC code
        sic_desc = row["ParticipantSICSubclass"]
        sic_code = sic_hash[sic_desc]
        if sic_code
          sic_uri = Vocabulary::TSBDEF["concept/sic/#{sic_code}"]
          o.sic_code = sic_uri
        end

      end # of organization block

      ##### Competition #####
      comp_year = row["CompetitionYear"].to_i.to_s
      comp_call_code = row["CompCallCode"].to_s
      activity_code = row["ActivityCode"].to_i.to_s
      # fill out the activity code with leading zeroes, if it is shorter than 4 chars
      while activity_code.length < 4
        activity_code = "0" + activity_code
      end

      product = row["Product"]
      area = row["AreaBudgetHolder"]
      team = row["TeamBudgetHolder"].strip

      # use Activity Code as the unique identifier for a Competition Call

      comp_uri = Vocabulary::TSB["competition-call/#{activity_code}"]
      # have we done this competition call?
      if resources[comp_uri]
        comp = resources[comp_uri]
      else
        comp = CompetitionCall.new(comp_uri)
        resources[comp_uri] = comp

        comp.competition_code = comp_call_code
        comp.competition_year = Vocabulary::REF["year/#{comp_year}"]
        comp.activity_code = activity_code
        comp.label = "Competition Call #{activity_code}"


        # check we are not missing any codes
        puts product unless Product::PRODUCT_CODES[product]
        puts team unless Team::TEAM_CODES[team]
        puts area unless BudgetArea::BUDGET_AREA_CODES[area]

        team_code = Team::TEAM_CODES[team]
        if team_code
          t_uri = Vocabulary::TSB["team/#{team_code}"]
          comp.team_uri = t_uri
        end
        budget_area_code = BudgetArea::BUDGET_AREA_CODES[area]
        if budget_area_code
          budg_uri = Vocabulary::TSB["budget-area/#{budget_area_code}"]
          comp.budget_area_uri = budg_uri
        end
        # NB use '_uri' setter methods as linking to a URI, not a Tripod Resource
        product_code = Product::PRODUCT_CODES[product]
        if product_code
          prod_uri = Vocabulary::TSBDEF["concept/product/#{product_code}"]
          comp.product_uri = prod_uri
        end


      end

      #link project to competition call (if not already done)
      p.competition_call = comp unless p.competition_call_uri



      # Grant
      grant_uri = Vocabulary::TSB["grant/#{proj_num}/#{org_slug}"]

      g = Grant.new(grant_uri)
      resources[grant_uri] = g

      g.label = "Grant for #{org_name}, project: #{project_title}"
      g.offer_cost = row["OfferCost"].to_i
      g.offer_grant = row["OfferGrant"].to_i
      g.offer_percentage = row["OfferRateOfGrant"]
      g.payments_to_date = row["PaymentsToDate"].to_i


      ##### connections #####

      # grant - project

      # is this right?
      g.supports_project = p
      p.supported_by_uris = p.supported_by_uris.push(g.uri)

      # org - project (2 way)
      o.participates_in_projects_uris = o.participates_in_projects_uris.push(p.uri)
      p.participants_uris = p.participants_uris.push(o.uri)

      if row["IsLead"] && row["IsLead"] == "Lead"
        o.leads_projects_uris = o.leads_projects_uris.push(p.uri)
        p.leader = o
      end

      # grant - org
      g.paid_to_organization = o
      g.supports_project = p
      p.supported_by_uris = p.supported_by_uris.push(g.uri)

      return nil
    end
  end
end