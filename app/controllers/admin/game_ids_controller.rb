# frozen_string_literal: true

module Admin
  class GameIdsController < AdminController
    before_action :set_game_id, only: %i[ show edit update destroy ]

    # GET /admin/game-ids or /admin/game-ids.json
    def index
      @game_ids = GameId.all
    end

    # GET /admin/game-ids/1 or /admin/game-ids/1.json
    def show
    end

    # GET /admin/game-ids/new
    def new
      @game_id = GameId.new
    end

    # GET /admin/game-ids/1/edit
    def edit
    end

    # POST /admin/game-ids or /admin/game-ids.json
    def create
      @game_id = GameId.new(game_id_params)

      respond_to do |format|
        if @game_id.save
          format.html { redirect_to [:admin, @game_id], notice: "Game ID was successfully created." }
          format.json { render :show, status: :created, location: @game_id }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @game_id.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/game-ids/1 or /admin/game-ids/1.json
    def update
      respond_to do |format|
        if @game_id.update(game_id_params)
          format.html { redirect_to [:admin, @game_id], notice: "Game ID was successfully updated." }
          format.json { render :show, status: :ok, location: @game_id }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @game_id.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /admin/game-ids/1 or /admin/game-ids/1.json
    def destroy
      @game_id.destroy
      redirect_to admin_social_links_url, info: "Game ID was successfully destroyed.", status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_game_id
        @game_id = GameId.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def game_id_params
        params.require(:game_id).permit(:name, :ign, :game_id, :icon_name, :icon_filename, :icon_url, :status)
      end
  end
end
