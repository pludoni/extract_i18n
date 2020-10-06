RSpec.describe ExtractI18n do
  specify 'File key' do
    expect(
      ExtractI18n.file_key("app/views/admin/index.html.slim")
    ).to be == 'admin.index'

    expect(
      ExtractI18n.file_key("app/views/admin/users/edit.html.slim")
    ).to be == 'admin.users.edit'

    expect(
      ExtractI18n.file_key("app/models/user.rb")
    ).to be == 'models.user'

    expect(
      ExtractI18n.file_key("app/javascript/recruiter/components/EditModal.vue")
    ).to be == 'recruiter.components.edit_modal'
  end
end
