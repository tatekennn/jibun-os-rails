class LunchLogsController < ApplicationController
  before_action :set_lunch_log, only: %i[ show edit update destroy ]

  # GET /lunch_logs or /lunch_logs.json
  def index
    @lunch_logs = filtered_lunch_logs
    @month_lunch_logs = LunchLog.this_month
    @average_price = @month_lunch_logs.average(:price)&.round || 0
    @recommendations = LunchLog.recommended.limit(3)
  end

  # GET /lunch_logs/1 or /lunch_logs/1.json
  def show
  end

  # GET /lunch_logs/new
  def new
    @lunch_log = LunchLog.new(visited_on: Date.current, area: "渋谷", rating: 4, crowdedness: "普通")
  end

  # GET /lunch_logs/1/edit
  def edit
  end

  # POST /lunch_logs or /lunch_logs.json
  def create
    @lunch_log = LunchLog.new(lunch_log_params)

    respond_to do |format|
      if @lunch_log.save
        format.html { redirect_to lunch_logs_path, notice: "ランチを記録しました。" }
        format.json { render :show, status: :created, location: @lunch_log }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @lunch_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lunch_logs/1 or /lunch_logs/1.json
  def update
    respond_to do |format|
      if @lunch_log.update(lunch_log_params)
        format.html { redirect_to lunch_logs_path, notice: "ランチログを更新しました。", status: :see_other }
        format.json { render :show, status: :ok, location: @lunch_log }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @lunch_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lunch_logs/1 or /lunch_logs/1.json
  def destroy
    @lunch_log.destroy!

    respond_to do |format|
      format.html { redirect_to lunch_logs_path, notice: "ランチログを削除しました。", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lunch_log
      @lunch_log = LunchLog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def lunch_log_params
      params.require(:lunch_log).permit(:visited_on, :shop_name, :area, :price, :rating, :crowdedness, :solo_friendly, :repeat, :memo)
    end

    def filtered_lunch_logs
      logs = LunchLog.recent
      logs = logs.where("price <= ?", 1000) if params[:under_1000].present?
      logs = logs.where("rating >= ?", 4) if params[:rating_4].present?
      logs = logs.where(solo_friendly: true) if params[:solo].present?
      logs = logs.where.not(crowdedness: "混んでる") if params[:not_crowded].present?
      logs = logs.where(repeat: true) if params[:repeat].present?
      logs
    end
end
