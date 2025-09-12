class Memo < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }

  def self.fetch_for_index(offset: nil, limit: nil, sort_order: "desc")
    sort_order = sort_order.to_s.downcase
    sort_order = %w[asc desc].include?(sort_order) ? sort_order : "desc"
    scope = order(created_at: sort_order)

    if offset.present?
      offset_value = offset.to_i
      offset_value = 0 if offset_value.negative?
      scope = scope.offset(offset_value)
    end

    requested_limit = limit.present? ? limit.to_i : nil
    limit_value = requested_limit && requested_limit.positive? ? requested_limit : nil

    scope.limit(limit_value)
  end
end
