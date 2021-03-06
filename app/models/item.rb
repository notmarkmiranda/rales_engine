class Item < ApplicationRecord
  validates :name, :description, presence: :true

  belongs_to :merchant
  has_many   :invoice_items
  has_many   :invoices, through: :invoice_items

  default_scope { order(:id) }

  def self.most_revenue(x)
    unscoped
      .joins(invoice_items: [invoice: :transactions])
      .merge(Transaction.successful)
      .group('items.id')
      .order('sum(invoice_items.quantity * invoice_items.unit_price) DESC')
      .take(x)
  end

  def self.most_items(x)
    unscoped
      .joins(invoice_items: [invoice: :transactions])
      .merge(Transaction.successful)
      .group('items.id')
      .order('sum(invoice_items.quantity) DESC')
      .limit(x)
  end

  def best_day
    invoices
    .select('invoices.*')
    .joins(:transactions)
    .merge(Transaction.successful)
    .group('invoices.id')
    .order('sum(invoice_items.quantity) DESC')
    .first.created_at
  end
end
