class MemosController < ApplicationController
  before_action :set_memo, only: %i[ show edit update destroy ]

  # Custom exception raised when the provided `limit` is invalid.
  InvalidLimitError = Class.new(StandardError)

  # GET /memos
  def index
    limit_value = if params[:limit].present?
      extract_limit_value!(params[:limit])
    else
      memos_default_limit
    end

    @memos = Memo.fetch_for_index(
      offset: params[:offset],
      limit: limit_value,
      sort_order: params[:sort_order]
    )

    # TODO
    @offset_out_of_range = params[:offset].present? && @memos.empty?

    respond_to do |format|
      format.html
      format.json { render :index }
    end
  rescue InvalidLimitError => e
    respond_to do |format|
      format.html { render plain: e.message, status: :bad_request }
      format.json { render json: { error: e.message }, status: :bad_request }
    end
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

    # Use callbacks to share common setup or constraints between actions.
    def set_memo
      @memo = Memo.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def memo_params
      params.require(:memo).permit(:title, :description)
    end

    # Validate and normalize limit parameter.
    def extract_limit_value!(raw_limit)
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
end
