class Merchant < ApplicationRecord
  validates :name, presence: :true

  has_many  :items
  has_many  :invoices

  has_many  :customers,     through: :invoices
  has_many  :invoice_items, through: :invoices
  has_many  :transactions,  through: :invoices


  def total_revenue(date = nil)
    if date
      invoices
        .joins(:transactions, :invoice_items)
        .where(invoices: {created_at: "#{date}"})
        .merge(Transaction.successful)
        .sum('invoice_items.unit_price * invoice_items.quantity')
    else
      invoices
        .joins(:transactions, :invoice_items)
        .merge(Transaction.successful)
        .sum('invoice_items.unit_price * invoice_items.quantity')
    end
  end

  def total_revenue_response
    formatted_revenue = total_revenue/100.0
    {revenue: formatted_revenue}
  end

  def favorite_customer
    customers
      .joins(invoices: [:transactions])
      .merge(Transaction.successful)
      .group('customers.id')
      .order('count(invoices.*) desc')
      .first
  end

  def self.most_items_sold(limit=5)
    select("merchants.*, sum(invoice_items.quantity) as quantity")
    .joins(invoices: [:transactions, :invoice_items])
    .merge(Transaction.successful)
    .group(:id)
    .order("quantity DESC")
    .limit(limit)
  end

  def self.total_revenue(date)
    joins(invoices: [:invoice_items, :transactions])
      .merge(Transaction.successful)
      .where('invoices.created_at = ?', date)
      .sum('invoice_items.quantity * invoice_items.unit_price')
  end

  def self.most_revenue(x)
    joins(invoices: [:invoice_items, :transactions])
      .merge(Transaction.successful)
      .group('merchants.id')
      .order('sum(invoice_items.quantity * invoice_items.unit_price) DESC')
      .take(x)
  end
end