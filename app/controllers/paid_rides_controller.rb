class PaidRidesController < ApplicationController
  before_action :set_paid_ride, only: %i[ show edit update destroy ]

  # GET /paid_rides or /paid_rides.json
  def index
    @paid_rides = PaidRide.recent
    @month_paid_rides = PaidRide.this_month.recent
    @month_total_fare = @month_paid_rides.sum(:fare)
    @monthly_comment = PaidRide.monthly_comment
  end

  # GET /paid_rides/1 or /paid_rides/1.json
  def show
  end

  # GET /paid_rides/new
  def new
    @paid_ride = PaidRide.new(used_on: Date.current, line_name: "京王ライナー", fare: 410, fatigue_level: 3)
  end

  # GET /paid_rides/1/edit
  def edit
  end

  # POST /paid_rides or /paid_rides.json
  def create
    @paid_ride = PaidRide.new(paid_ride_params)

    respond_to do |format|
      if @paid_ride.save
        format.html { redirect_to paid_rides_path, notice: "有料列車ログを記録しました。" }
        format.json { render :show, status: :created, location: @paid_ride }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @paid_ride.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /paid_rides/1 or /paid_rides/1.json
  def update
    respond_to do |format|
      if @paid_ride.update(paid_ride_params)
        format.html { redirect_to paid_rides_path, notice: "有料列車ログを更新しました。", status: :see_other }
        format.json { render :show, status: :ok, location: @paid_ride }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @paid_ride.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /paid_rides/1 or /paid_rides/1.json
  def destroy
    @paid_ride.destroy!

    respond_to do |format|
      format.html { redirect_to paid_rides_path, notice: "有料列車ログを削除しました。", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_paid_ride
      @paid_ride = PaidRide.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def paid_ride_params
      params.require(:paid_ride).permit(:used_on, :line_name, :direction, :fare, :reason, :fatigue_level, :memo)
    end
end
