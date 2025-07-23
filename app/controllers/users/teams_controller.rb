# frozen_string_literal: true

class Users::TeamsController < ApplicationController
  skip_before_action :set_selected_team
  skip_after_action :verify_policy_scoped

  before_action :redirect_to_dashboard_if_cis2_is_enabled
  before_action :set_teams

  layout "two_thirds"

  def new
  end

  def create
    team = @teams.find(params[:team_id])

    if team.present?
      session["cis2_info"] = {
        "selected_org" => {
          "name" => team.name,
          "code" => team.organisation.ods_code
        },
        "selected_role" => {
          "code" => valid_cis2_roles.first,
          "workgroups" => ["schoolagedimmunisations"]
        }
      }

      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_to_dashboard_if_cis2_is_enabled
    redirect_to dashboard_path if Settings.cis2.enabled
  end

  def set_teams
    @teams = current_user.teams.includes(:organisation)
  end
end
