# frozen_string_literal: true

class Patients::ArchiveController < Patients::BaseController
  before_action :set_archive_reason

  def new
    @form = PatientArchiveForm.new
  end

  def create
    @form =
      PatientArchiveForm.new(
        archive_reason: @archive_reason,
        current_user:,
        **patient_archive_form_params
      )

    if @form.save
      redirect_to patient_path(@patient),
                  flash: {
                    success: "Child record archived"
                  }
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_archive_reason
    @archive_reason =
      ArchiveReason.find_or_create_by(organisation:, patient: @patient)
  end

  def organisation = current_user.selected_organisation

  def patient_archive_form_params
    params.expect(patient_archive_form: %i[nhs_number type other_details])
  end
end
