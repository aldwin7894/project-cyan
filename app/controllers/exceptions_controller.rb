# frozen_string_literal: true

class ExceptionsController < ApplicationController
  respond_to :html, :xml, :json
  before_action :status
  layout "exception"

  def index
    respond_to do |format|
      format.html { render status: params[:code] }
      format.xml { render status: params[:code] }
      format.json { render status: params[:code] }
      format.any { render "index", formats: [:html], status: params[:code] }
    end
  end

  protected
    def status
      @exception  = request.env["action_dispatch.exception"]
      @status     = ActionDispatch::ExceptionWrapper.new(request.env, @exception).status_code
      @response   = ActionDispatch::ExceptionWrapper.rescue_responses[@exception.class.name].to_s.gsub("_", " ").titleize
    end

    def details
      @details ||= {}.tap do |h|
        I18n.with_options scope: [:exception, :show, @response], exception_name: @exception.class.name, exception_message: @exception.message do |i18n|
          h[:name] = i18n.t "#{@exception.class.name.underscore}.title", default: i18n.t(:title, default: @exception.class.name)
          h[:message] = i18n.t "#{@exception.class.name.underscore}.description", default: i18n.t(:description, default: @exception.message)
        end
      end
    end
    helper_method :details
end
