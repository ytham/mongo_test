module Calculations

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
    case
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
    gross_income = (income_after_tax * 0.85) / 12
  end

  def calculate_mortgage_payment(home_price)
    p = home_price * 0.8
    i = 0.035 / 12
    n = 360
    monthly_payment = p*((i*(1+i)**n)/((1+i)**n-1))
  end

  def calculate_score(income, home_price)
    Rails.logger.debug ">>>>> CALCULATE SCORE: ( #{income} - #{home_price} )"
    if income.blank? || home_price.blank?
      return nil
    end
    score = (100 * (calculate_after_tax_income(income.to_f) - calculate_mortgage_payment(home_price.to_f)) / 2159).to_i
  end

end