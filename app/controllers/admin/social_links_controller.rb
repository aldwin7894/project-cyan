# frozen_string_literal: true

module Admin
  class SocialLinksController < AdminController
    before_action :set_social_link, only: %i[ show edit update destroy ]

    # GET /admin/social-links or /admin/social-links.json
    def index
      @social_links = SocialLink.all
    end

    # GET /admin/social-links/1 or /admin/social-links/1.json
    def show
      # show
    end

    # GET /admin/social-links/new
    def new
      @social_link = SocialLink.new
    end

    # GET /admin/social-links/1/edit
    def edit
      # edit
    end

    # POST /admin/social-links or /admin/social-links.json
    def create
      @social_link = SocialLink.new(social_link_params)

      respond_to do |format|
        if @social_link.save
          format.html { redirect_to [:admin, @social_link], notice: "Social Link was successfully created." }
          format.json { render :show, status: :created, location: @social_link }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @social_link.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/social-links/1 or /admin/social-links/1.json
    def update
      respond_to do |format|
        if @social_link.update(social_link_params)
          format.html { redirect_to [:admin, @social_link], notice: "Social Link was successfully updated." }
          format.json { render :show, status: :ok, location: @social_link }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @social_link.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /admin/social-links/1 or /admin/social-links/1.json
    def destroy
      @social_link.destroy
      redirect_to admin_social_links_url, info: "Social Link was successfully destroyed.", status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_social_link
        @social_link = SocialLink.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def social_link_params
        params.require(:social_link).permit(:name, :url, :icon_url)
      end
  end
end
