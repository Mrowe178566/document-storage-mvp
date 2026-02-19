class ApplicationController < ActionController::Base
  helper BreadcrumbsHelper
  include BreadcrumbsHelper
end
