module SearchesHelper

  def fetch_result(url_string)
    url = URI.parse(URI.escape(url_string))
    res = Net::HTTP.get_response(url)
    doc = XmlSimple.xml_in res.body
    json = JSON.pretty_generate(JSON.parse(doc.to_json))
    return json
  end


  def calculate_after_tax_income(income)
      bracket_bound = [12750, 48600, 125450, 203150, 398350, 425000]
      bracket_before_tax = [bracket_bound[0], 
                            bracket_bound[1]-bracket_bound[0],
                            bracket_bound[2]-bracket_bound[1],
                            bracket_bound[3]-bracket_bound[2],
                            bracket_bound[4]-bracket_bound[3],
                            bracket_bound[5]-bracket_bound[4]]
      tax_rate = [0.90, 0.85, 0.75, 0.72, 0.67, 0.65, 0.604]
      bracket_after_tax = [bracket_before_tax[0]*tax_rate[0],
                           bracket_before_tax[1]*tax_rate[1],
                           bracket_before_tax[2]*tax_rate[2],
                           bracket_before_tax[3]*tax_rate[3],
                           bracket_before_tax[4]*tax_rate[4],
                           bracket_before_tax[5]*tax_rate[5]]
      income_after_tax = 0
      case income
      when income < bracket_bound[0]
        income_after_tax = income * tax_rate[0]
      when income.between?(bracket_bound[0], bracket_bound[1])
        difference = (income - bracket_bound[0])*tax_rate[1]
        income_after_tax = difference + bracket_after_tax[0]
      when income.between?(bracket_bound[1], bracket_bound[2])
        difference = (income - bracket_bound[1])*tax_rate[1]
        income_after_tax = difference + bracket_after_tax[0] + bracket_after_tax[1]
      when income.between?(bracket_bound[2], bracket_bound[3])
        difference = (income - bracket_bound[2])*tax_rate[2]
        income_after_tax = difference + bracket_after_tax[0] + bracket_after_tax[1] + bracket_after_tax[2]
      when income.between?(bracket_bound[3], bracket_bound[4])
        difference = (income - bracket_bound[3])*tax_rate[3]
        income_after_tax = difference + bracket_after_tax[0] + bracket_after_tax[1] + bracket_after_tax[2] + bracket_after_tax[3]
      when income.between?(bracket_bound[4], bracket_bound[5])
        difference = (income - bracket_bound[4])*tax_rate[4]
        income_after_tax = difference + bracket_after_tax[0] + bracket_after_tax[1] + bracket_after_tax[2] + bracket_after_tax[3] + bracket_after_tax[4]
      else
        difference = (income - bracket_bound[5])*tax_rate[5]
        income_after_tax = difference + bracket_after_tax[0] + bracket_after_tax[1] + bracket_after_tax[2] + bracket_after_tax[3] + bracket_after_tax[4] + bracket_after_tax[5]
      end
      return (income_after_tax * 0.85)
    end

end
