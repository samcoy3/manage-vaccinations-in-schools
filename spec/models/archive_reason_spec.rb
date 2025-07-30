# frozen_string_literal: true

# == Schema Information
#
# Table name: archive_reasons
#
#  id                 :bigint           not null, primary key
#  other_details      :string           default(""), not null
#  type               :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  organisation_id    :bigint           not null
#  patient_id         :bigint           not null
#
# Indexes
#
#  index_archive_reasons_on_created_by_user_id              (created_by_user_id)
#  index_archive_reasons_on_organisation_id                 (organisation_id)
#  index_archive_reasons_on_organisation_id_and_patient_id  (organisation_id,patient_id) UNIQUE
#  index_archive_reasons_on_patient_id                      (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#
describe ArchiveReason do
  subject(:archive_reason) { build(:archive_reason) }

  describe "associations" do
    it { should belong_to(:organisation) }
    it { should belong_to(:patient) }
    it { should belong_to(:created_by).class_name("User").optional(true) }
  end

  describe "validations" do
    it do
      expect(archive_reason).to validate_inclusion_of(:type).in_array(
        %w[imported_in_error moved_out_of_area deceased other]
      )
    end

    context "when type is not other" do
      before { archive_reason.type = "imported_in_error" }

      it { should validate_absence_of(:other_details) }
    end

    context "when type is other" do
      before { archive_reason.type = "other" }

      it { should validate_presence_of(:other_details) }
      it { should validate_length_of(:other_details).is_at_most(300) }
    end
  end
end
