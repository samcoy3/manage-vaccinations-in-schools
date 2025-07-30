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
FactoryBot.define do
  factory :archive_reason do
    organisation
    patient

    traits_for_enum :type

    trait :other do
      type { "other" }
      other_details { Faker::Lorem.sentence }
    end
  end
end
