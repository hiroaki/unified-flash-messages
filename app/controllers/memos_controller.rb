class MemosController < ApplicationController
  before_action :set_memo, only: %i[ show edit update destroy ]

  # Custom exception raised when the provided `offset` is invalid.
  InvalidOffsetError = Class.new(StandardError)

  # Custom exception raised when the provided `limit` is invalid.
  InvalidLimitError = Class.new(StandardError)

  # Custom exception raised when the provided `sort_order` is invalid.
  InvalidSortOrderError = Class.new(StandardError)

  # GET /memos
  def index
    # Call memoized helpers directly to keep the action concise.
    @memos = Memo.fetch_for_index(
      offset: memos_offset_value,
      limit: memos_limit_value,
      sort_order: memos_sort_order_value
    )

    # Don't warn when offset is 0 — an empty result can be valid for page 0.
    if memos_offset_value.to_i != 0 && @memos.empty?
      flash.now[:warning] = "No memos found for the specified offset; it may be out of range."
      @memos_param_warning = :offset
    end
  rescue InvalidOffsetError, InvalidLimitError, InvalidSortOrderError => ex
    @memos = Memo.none
    # Expose which parameter caused the error so the view can highlight it.
    @memos_param_error =
      case ex
      when InvalidOffsetError then :offset
      when InvalidLimitError then :limit
      when InvalidSortOrderError then :sort_order
      else
        nil
      end
    flash.now[:alert] = ex.message
  end

  # GET /memos/1
  def show
  end

  # GET /memos/new
  def new
    @memo = Memo.new
  end

  # GET /memos/1/edit
  def edit
  end

  # POST /memos
  def create
    @memo = Memo.new(memo_params)

    respond_to do |format|
      if @memo.save
        format.html { redirect_to @memo, notice: "Created successfully." }
        format.json { render :show, status: :created, location: @memo }
      else
        flash.now[:alert] = "Could not create."
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @memo.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /memos/1
  def update
    respond_to do |format|
      if @memo.update(memo_params)
        format.html { redirect_to @memo, notice: "Updated successfully.", status: :see_other }
        format.json { render :show, status: :ok, location: @memo }
      else
        flash.now[:alert] = "Could not update."
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @memo.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /memos/1
  def destroy
    respond_to do |format|
      if @memo.destroy
        format.html { redirect_to memos_path, notice: "Destroyed successfully.", status: :see_other }
        format.json { head :no_content }
      else
        format.html { redirect_to memos_path, alert: "Could not destroy.", status: :see_other }
        format.json { render json: @memo.errors, status: :unprocessable_content }
      end
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_memo
      @memo = Memo.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def memo_params
      params.expect(memo: [ :title, :description ])
    end

    # Returns the configured maximum allowed `limit` for the memos index.
    # Memoized per-request so multiple calls return the same value without
    # repeatedly querying `Rails.configuration`.
    def memos_max_limit
      return @memos_max_limit if defined?(@memos_max_limit)

      @memos_max_limit = if Rails.configuration.respond_to?(:memos_max_limit)
        Rails.configuration.memos_max_limit
      else
        10
      end
    end

    # Compute and memoize effective offset/limit/sort_order values for index.
    def memos_offset_value
      @memos_offset_value ||= extract_offset_value! || memos_default_offset
    end

    def memos_limit_value
      @memos_limit_value ||= extract_limit_value! || memos_default_limit
    end

    def memos_sort_order_value
      @memos_sort_order_value ||= extract_sort_order! || memos_default_sort_order
    end

    # Default offset when the user doesn't supply one. Kept as a method so
    # defaults are centralized and easily changeable. `0` is a no-op offset
    # and is safe to pass through to ActiveRecord's `offset`.
    def memos_default_offset
      0
    end

    # Default `limit` value when the user doesn't supply one.
    # Stored separately from `memos_max_limit` which is the maximum allowed.
    def memos_default_limit
      return @memos_default_limit if defined?(@memos_default_limit)

      @memos_default_limit = if Rails.configuration.respond_to?(:memos_default_limit)
        Rails.configuration.memos_default_limit
      else
        10
      end
    end

    # Default sort order for index when the user doesn't supply one.
    def memos_default_sort_order
      Memo.default_sort_order
    end

    # Validate and normalize offset parameter from `params`.
    # Returns integer offset or raises InvalidOffsetError on invalid input.
    def extract_offset_value!
      raw_offset = params[:offset]
      # If the parameter is not present (nil or blank), return nil so callers
      # can fall back to defaults. Only validate when the param is present.
      return nil unless raw_offset.present?
      parsed = begin
        Integer(raw_offset)
      rescue ArgumentError, TypeError
        nil
      end

      if parsed.nil?
        raise InvalidOffsetError, "offset must be an integer"
      elsif parsed < 0
        raise InvalidOffsetError, "offset must be >= 0"
      end

      parsed
    end

    # Validate and normalize limit parameter.
    def extract_limit_value!
      raw_limit = params[:limit]
      return nil unless raw_limit.present?

      parsed = begin
        Integer(raw_limit)
      rescue ArgumentError, TypeError
        nil
      end

      if parsed.nil?
        raise InvalidLimitError, "limit must be an integer"
      elsif parsed <= 0
        raise InvalidLimitError, "limit must be a positive integer"
      elsif parsed > memos_max_limit
        raise InvalidLimitError, "limit must be <= #{memos_max_limit}"
      end

      parsed
    end

    # Validate and normalize sort_order parameter. Must be one of the values
    # returned by `Memo.sort_orders`.
    def extract_sort_order!
      raw_sort_order = params[:sort_order]
      return nil unless raw_sort_order.present?

      parsed = raw_sort_order.to_s.downcase

      unless Memo.valid_sort_order?(parsed)
        raise InvalidSortOrderError, "sort_order must be one of: #{Memo.sort_orders.join(', ')}"
      end

      parsed
    end
end
