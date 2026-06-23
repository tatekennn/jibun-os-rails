class DiaryEntriesController < ApplicationController
  before_action :set_diary_entry, only: %i[show edit update destroy]

  def index
    @diary_entries = DiaryEntry.recent
    @today_entry = DiaryEntry.find_by(wrote_on: Date.current)
    @recent_entry = @diary_entries.first
  end

  def show
  end

  def new
    @diary_entry = DiaryEntry.new(wrote_on: params[:wrote_on].presence || Date.current, mood: "normal")
  end

  def edit
  end

  def create
    @diary_entry = DiaryEntry.new(diary_entry_params)

    respond_to do |format|
      if @diary_entry.save
        format.html { redirect_to diary_entries_path, notice: "日記を保存しました。" }
        format.json { render :show, status: :created, location: @diary_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @diary_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @diary_entry.update(diary_entry_params)
        format.html { redirect_to diary_entries_path, notice: "日記を更新しました。", status: :see_other }
        format.json { render :show, status: :ok, location: @diary_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @diary_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @diary_entry.destroy!

    respond_to do |format|
      format.html { redirect_to diary_entries_path, notice: "日記を削除しました。", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_diary_entry
    @diary_entry = DiaryEntry.find(params[:id])
  end

  def diary_entry_params
    params.require(:diary_entry).permit(:wrote_on, :title, :mood, :weather, :body, :tags)
  end
end
