require 'spec_helper'
require 'rails_helper'

RSpec.describe CheckoutController, type: :controller do
  render_views

  let!(:random) { Random.new }

  describe "GET #index" do
    it "retrieves the Braintree client token and adds it to the page" do
      get :index
      client_token = assigns(:client_token)
      expect(client_token).to_not be_nil
      expect(response.body).to match /#{client_token}/
    end
  end

  describe "GET #show" do
    it "retrieves the Braintree transaction and displays its attributes" do
      # Using a random amount to prevent duplicate checking errors
      amount = "#{random.rand(100)}.#{random.rand(100)}"
      result = Braintree::Transaction.sale(
        :amount => amount,
        :payment_method_nonce => "fake-valid-nonce",
      )

      expect(result).to be_success
      transaction = result.transaction

      get :show, id: transaction.id

      expect(response).to have_http_status(:success)
      expect(response.body).to match Regexp.new(transaction.id)
      expect(response.body).to match Regexp.new(transaction.type)
      expect(response.body).to match Regexp.new(transaction.amount.to_s)
      expect(response.body).to match Regexp.new(transaction.status)
      expect(response.body).to match Regexp.new(transaction.credit_card_details.bin)
      expect(response.body).to match Regexp.new(transaction.credit_card_details.last_4)
      expect(response.body).to match Regexp.new(transaction.credit_card_details.card_type)
      expect(response.body).to match Regexp.new(transaction.credit_card_details.expiration_date)
      expect(response.body).to match Regexp.new(transaction.credit_card_details.customer_location)
    end
  end

  describe "POST #create" do
    it "creates a transaction and redirects to checkout#show" do
      amount = "#{random.rand(100)}.#{random.rand(100)}"
      post :create, payment_method_nonce: "fake-valid-nonce", amount: amount

      expect(response).to redirect_to(/\/checkout\/\w+/)
    end

    context "when transaction is not succesful" do
      it "redirects to the checkout_path" do
        amount = "#{random.rand(100)}.#{random.rand(100)}"
        post :create, payment_method_nonce: "fake-consumed-nonce", amount: amount

        expect(response).to redirect_to(checkout_path)
      end
    end
  end
end
