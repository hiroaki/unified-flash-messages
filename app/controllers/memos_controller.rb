class MemosController < ApplicationController
  before_action :set_memo, only: %i[ show edit update destroy ]

  # GET /memos or /memos.json
  def index
    @memos = Memo.order(created_at: :desc).limit(memos_index_limit)
  end

  # GET /memos/1 or /memos/1.json
  def show
  end

  # GET /memos/new
  def new
    @memo = Memo.new
  end

  # GET /memos/1/edit
  def edit
  end

  # POST /memos or /memos.json
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

  # PATCH/PUT /memos/1 or /memos/1.json
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

  # DELETE /memos/1 or /memos/1.json
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

    # Returns the memos index limit from config, or 10 if not set
    def memos_index_limit
      Rails.configuration.respond_to?(:memos_index_limit) ? Rails.configuration.memos_index_limit : 10
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_memo
      @memo = Memo.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def memo_params
      params.expect(memo: [ :title, :description ])
    end
end
