# encoding: UTF-8
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :sessions_by_track
  helper_method :sessions_by_type
  protect_from_forgery

  around_filter :set_locale
  around_filter :set_timezone
  before_filter :set_conference
  before_filter :authenticate_user!
  before_filter :authorize_action
  # TODO: Transform into before_action once rails 4 (Issue #114) is in place
  before_filter :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

    flash[:error] = t('flash.unauthorised')
    redirect_to :back rescue redirect_to root_path
  end

  def current_ability
    session = Session.find(params[:session_id]) if params[:session_id].present?
    reviewer = Reviewer.find(params[:reviewer_id]) if params[:reviewer_id].present?
    @current_ability ||= Ability.new(current_user, @conference, session, reviewer)
  end

  def default_url_options(options={})
    # Keep locale when navigating links if locale is specified
    params[:locale] ? { locale: params[:locale] } : {}
  end

  def sanitize(text)
    text.gsub(/[\s;'\"]/,'')
  end

  def sessions_by_track
    ([['Track', 'Submitted sessions']] +
      @conference.tracks.
        map{|track| [t(track.title), track.sessions.count]})
  end

  def sessions_by_type
    ([['Type', 'Submitted sessions']] +
      @conference.session_types.
        map{|type| [t(type.title), type.sessions.count]})
  end

  private
  def set_locale(&block)
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.with_locale(params[:locale] || current_user.try(:default_locale), &block)
  end

  def set_timezone(&block)
    Time.use_zone(params[:time_zone], &block)
  end

  def set_conference
    @conference ||= Conference.find_by_year(params[:year]) || Conference.current
  end

  def authorize_action
    obj = resource rescue nil
    clazz = resource_class rescue nil
    action = params[:action].to_sym
    controller = obj || clazz || controller_name
    authorize!(action, controller)
  end

  def configure_permitted_parameters
    valid_registration_parameters = [
      :first_name, :last_name, :email, :wants_to_submit, :state,
      :organization, :website_url, :twitter_username, :default_locale,
      :phone, :country, :city, :bio
    ]
    valid_registration_parameters.each do |parameter|
      devise_parameter_sanitizer.for(:sign_up) << parameter
      devise_parameter_sanitizer.for(:account_update) << parameter
    end
  end
end
