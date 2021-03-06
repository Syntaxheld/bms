require "sinatra"
require "yaml"
require "braintree"
require "json"

config = YAML.load_file("config.yml")[settings.environment.to_s]
Braintree::Configuration.environment = config["braintree_environment"].to_sym
Braintree::Configuration.merchant_id = config["merchant_id"]
Braintree::Configuration.public_key  = config["public_key"]
Braintree::Configuration.private_key = config["private_key"]
CSE_KEY = config['cse_key']

get "/" do
  erb :form
end

# https://www.braintreepayments.com/docs/ruby/customers/create#customer_with_credit_card
post "/card/add" do
  result = Braintree::Customer.create({
    :id => params[:email],    # Braintree returns: "Customer ID is invalid (use only letters, numbers, '-', and '_')." ;; so we need to find a better scheme (sha256?)
    "credit_card" => {
      "number" => params[:card_number],
      "cvv" => params[:cvv],
      "expiration_month" => params[:expiration_month],
      "expiration_year" => params[:expiration_year],
    },
  })

  out = {"success" => result.success?, "error" => nil}

  if !result.success?
    out["error"] = result.message
    halt(422, JSON.generate(out))
  else
    # out["payment_method_token"] = result.customer.credit_cards[0].token
    return JSON.generate(out)
  end
end

# https://www.braintreepayments.com/docs/ruby/reference/sandbox

# https://www.braintreepayments.com/docs/ruby/transactions/create#creating_from_vault
# https://www.braintreepayments.com/docs/ruby/transactions/create_from_vault
post "/transaction/pay" do
  result = Braintree::Transaction.sale(
    :amount => params[:amount],
    :customer_id => params[:email]
  )
  
  out = {"success" => result.success?, "error" => nil}
  
  if !result.success?
    out["error"] = result.message
    halt(422, JSON.generate(out))
  else
    out["currency_iso_code"] = result.transaction.currency_iso_code
    return JSON.generate(out)
  end
end

# https://www.braintreepayments.com/docs/ruby/credit_cards/search
get "/card/info" do
  out = {"success" => false, "error" => "not implemented"}
  halt(501, JSON.generate(out))
end
