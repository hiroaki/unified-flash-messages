class Memo < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }

  # Default sort order for index queries. Kept as a model constant so the
  # canonical value belongs to the model rather than duplicated in callers.
  # Use `Memo.default_sort_order` to obtain the canonical default.
  ASC = "asc"
  DESC = "desc"

  # Whitelisted sort orders and canonical default.
  SORT_ORDERS = [ ASC, DESC ].freeze
  DEFAULT_SORT_ORDER = DESC

  def self.default_sort_order
    DEFAULT_SORT_ORDER
  end

  # Public accessor for allowed sort orders.
  def self.sort_orders
    SORT_ORDERS
  end

  # Returns true if the provided value is a recognized sort order.
  def self.valid_sort_order?(value)
    sort_orders.include?(value.to_s.downcase)
  end

  def self.fetch_for_index(offset: nil, limit: nil, sort_order: nil)
    # Use the model's canonical default when none is supplied.
    sort_order = (sort_order || default_sort_order).to_s.downcase
    sort_order = sort_orders.include?(sort_order) ? sort_order : DEFAULT_SORT_ORDER
    scope = order(created_at: sort_order)

    # Apply offset when it is explicitly provided. Use nil-check so `0` is
    # treated as a valid (no-op) offset rather than being ignored by
    # `present?` (which returns false for 0 in Rails).
    unless offset.nil?
      offset_value = offset.to_i
      offset_value = 0 if offset_value.negative?
      scope = scope.offset(offset_value)
    end

    requested_limit = limit.present? ? limit.to_i : nil
    limit_value = requested_limit && requested_limit.positive? ? requested_limit : nil

    scope.limit(limit_value)
  end
end
