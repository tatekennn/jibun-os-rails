class LunchLogsController < ApplicationController
  SORT_OPTIONS = {
    "recent" => "新しい順",
    "visits" => "行った数が多い順",
    "rating" => "評価が高い順"
  }.freeze

  before_action :set_lunch_log, only: %i[ show edit update destroy ]

  # GET /lunch_logs or /lunch_logs.json
  def index
    @sort = safe_sort_param
    @sort_options = SORT_OPTIONS
    @lunch_logs = filtered_lunch_logs
    @month_lunch_logs = LunchLog.this_month
    @average_price = @month_lunch_logs.average(:price)&.round || 0
    @visit_counts = LunchLog.group(:shop_name).count
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
      logs = LunchLog.all
      logs = logs.where("price <= ?", 1000) if params[:under_1000].present?
      logs = logs.where("rating >= ?", 4) if params[:rating_4].present?
      logs = logs.where(solo_friendly: true) if params[:solo].present?
      logs = logs.where.not(crowdedness: "混んでる") if params[:not_crowded].present?
      logs = logs.where(repeat: true) if params[:repeat].present?
      sort_lunch_logs(logs)
    end

    def safe_sort_param
      SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : "recent"
    end

    def sort_lunch_logs(logs)
      case @sort
      when "visits"
        visit_counts_sql = LunchLog.select("shop_name, COUNT(*) AS lunch_visit_count").group(:shop_name).to_sql

        logs
          .joins("INNER JOIN (#{visit_counts_sql}) lunch_visit_counts ON lunch_visit_counts.shop_name = lunch_logs.shop_name")
          .order(Arel.sql("lunch_visit_counts.lunch_visit_count DESC"), rating: :desc, visited_on: :desc, created_at: :desc)
      when "rating"
        logs.order(rating: :desc, visited_on: :desc, created_at: :desc)
      else
        logs.recent
      end
    end
end
