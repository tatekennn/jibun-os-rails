class HobbyItemsController < ApplicationController
  before_action :set_hobby_item, only: %i[ show edit update destroy ]

  # GET /hobby_items or /hobby_items.json
  def index
    @hobby_items = HobbyItem.recent
    @next_hobby_item = HobbyItem.events.planned.where("scheduled_on >= ?", Date.current).order(:scheduled_on).first
    @recent_memos = HobbyItem.memos.recent.limit(4)
  end

  # GET /hobby_items/1 or /hobby_items/1.json
  def show
  end

  # GET /hobby_items/new
  def new
    @hobby_item = HobbyItem.new(item_type: params[:item_type] || "memo", status: "planned", scheduled_on: Date.current)
  end

  # GET /hobby_items/1/edit
  def edit
  end

  # POST /hobby_items or /hobby_items.json
  def create
    @hobby_item = HobbyItem.new(hobby_item_params)

    respond_to do |format|
      if @hobby_item.save
        format.html { redirect_to hobby_items_path, notice: "趣味アイテムを記録しました。" }
        format.json { render :show, status: :created, location: @hobby_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @hobby_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hobby_items/1 or /hobby_items/1.json
  def update
    respond_to do |format|
      if @hobby_item.update(hobby_item_params)
        format.html { redirect_to hobby_items_path, notice: "趣味アイテムを更新しました。", status: :see_other }
        format.json { render :show, status: :ok, location: @hobby_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hobby_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hobby_items/1 or /hobby_items/1.json
  def destroy
    @hobby_item.destroy!

    respond_to do |format|
      format.html { redirect_to hobby_items_path, notice: "趣味アイテムを削除しました。", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hobby_item
      @hobby_item = HobbyItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hobby_item_params
      params.require(:hobby_item).permit(:title, :category, :item_type, :scheduled_on, :location, :cost, :url, :body, :rating, :status)
    end
end
