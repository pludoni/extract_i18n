# frozen_string_literal: true

# rubocop:disable Lint/InterpolationCheck
RSpec.describe ExtractI18n::FileProcessor do
  around(:each) do |ex|
    pwd = Dir.pwd
    Dir.mktmpdir do |dir|
      @dir = dir
      Dir.chdir(@dir)
      ex.run
    end
  ensure
    Dir.chdir(pwd)
  end

  let(:yml) { 'locales.en.yml' }
  before(:each) do
    allow_any_instance_of(TTY::Prompt).to receive(:yes?).and_return(true)
    allow_any_instance_of(TTY::Prompt).to receive(:no?).and_return(false)
    allow_any_instance_of(ExtractI18n::FileProcessor).to receive(:puts)
  end

  specify 'integration test' do
    create_file_with_layout(
      'app/models/foobar.rb' => 'a = "Hello #{Date.today}!"' + "\n"
    )
    processor = ExtractI18n::FileProcessor.new(file_path: 'app/models/foobar.rb', write_to: yml, locale: 'en')
    processor.run

    expect(
      File.read(yml)
    ).to be == <<~DOC
      ---
      en:
        models:
          foobar:
            hello: Hello %{date_today}!
    DOC

    expect(
      File.read('app/models/foobar.rb')
    ).to be == <<~DOC
      a = I18n.t(\"models.foobar.hello\", date_today: (Date.today))
    DOC
  end

  specify 'Relative' do
    view = 'app/views/users/index.html.slim'
    create_file_with_layout(
      view => 'div Hello World' + "\n"
    )
    processor = ExtractI18n::FileProcessor.new(file_path: view, write_to: yml, locale: 'en', options: { relative: true })
    processor.run

    expect(
      File.read(yml)
    ).to be == <<~DOC
      ---
      en:
        users:
          index:
            hello_world: Hello World
    DOC

    expect(
      File.read(view)
    ).to be == <<~DOC
      div = t('.hello_world')
    DOC
  end

  specify 'Partial' do
    view = 'app/views/users/_foo.html.slim'
    create_file_with_layout(
      view => 'div Hello World' + "\n"
    )
    processor = ExtractI18n::FileProcessor.new(file_path: view, write_to: yml, locale: 'en', options: { relative: true })
    processor.run

    expect(
      File.read(yml)
    ).to be == <<~DOC
      ---
      en:
        users:
          foo:
            hello_world: Hello World
    DOC

    expect(
      File.read(view)
    ).to be == <<~DOC
      div = t('.hello_world')
    DOC
  end

  specify 'vue with namespace' do
    view = 'app/javascript/user/components/EditModal.vue'
    create_file_with_layout(
      view => <<~VIEW
        <template lang="pug">
          b-modal(title="Some Title")
            | Content here
            | and more here
        </template>
      VIEW
    )
    processor = ExtractI18n::FileProcessor.new(file_path: view, write_to: yml, locale: 'en', options: { namespace: 'js' })
    processor.run

    expect(
      File.read(view)
    ).to be == <<~DOC
      <template lang="pug">
        b-modal(:title="$t('js.user.components.edit_modal.some_title')")
          | {{ $t('js.user.components.edit_modal.content_here_and_more_here') }}
      </template>
    DOC

    expect(
      File.read(yml)
    ).to be == <<~DOC
      ---
      en:
        js:
          user:
            components:
              edit_modal:
                some_title: Some Title
                content_here_and_more_here: Content here and more here
    DOC
  end

  specify 'endless loop' do
    # Nutzer sagt nein
    allow_any_instance_of(TTY::Prompt).to receive(:no?).and_return(true)

    view = 'app/javascript/user/components/EditModal.vue'
    create_file_with_layout(
      view => <<~VIEW
        <template lang="pug">
          b-modal(title="Some Title")
            | Content here
            | and more here
        </template>
      VIEW
    )
    processor = ExtractI18n::FileProcessor.new(file_path: view, write_to: yml, locale: 'en', options: { namespace: 'js' })
    processor.run

    expect(File.read(yml)).to be == "--- {}\n"
  end

  specify 'key clash' do
    view = 'app/views/users/index.html.slim'
    create_file_with_layout(
      view => "div Hello World is a very long string that bla\n" +
              "div Hello World is a very long string that also bla\n"
    )
    processor = ExtractI18n::FileProcessor.new(file_path: view, write_to: yml, locale: 'en', options: { relative: true })
    processor.run

    expect(
      YAML.load_file(yml).dig('en', 'users', 'index').length
    ).to be == 2
  end

  def create_file_with_layout(hash)
    hash.each do |k, v|
      FileUtils.mkdir_p File.dirname(k)
      File.write(k, v)
    end
  end
end
