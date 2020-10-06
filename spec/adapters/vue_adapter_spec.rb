RSpec.describe ExtractI18n::Adapters::VueAdapter do
  specify "block content" do
    view = template("div.foo\n  | Content\n")
    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      <<~VIEW
        div.foo
          | {{ $t('components.content') }}
      VIEW
    )
  end

  specify "attributes" do
    view = template(%{div.foo(label="Title Here" title='Bla')\n  span\n})

    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      <<~VIEW
        div.foo(:label="$t('components.title_here')" :title="$t('components.bla')")
          span
      VIEW
    )
  end

  specify "content with interpolation" do
    view = template("div\n  | please click {{ here + 1 }}\n")

    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      <<~VIEW
        div
          | {{ $t('components.please_click_here_1', { here_1: (here + 1) }) }}
      VIEW
    )
    expect(output[1]).to be == {
      "components.please_click_here_1" => "please click {here_1}"
    }
  end

  specify 'ignore raw interpolated' do
    view = template("| {{filename}}")
    output = run(view, file_key: "components")
    expect(output[0]).to be == view
  end

  specify "with html prefix" do
    view = template("button.btn Speichern")
    output = run(view, file_key: "components")
    expect(output[0]).to be == template("button.btn {{ $t('components.speichern') }}")
  end

  specify "attribute keys whitelist" do
    view = template('button(class="btn btn-outline-secondary" type="button" title="Toggle" data-toggle)')
    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      %{button(class="btn btn-outline-secondary" type="button" :title="$t('components.toggle')" data-toggle)}
    )
  end

  specify "don't translate dynamic keys" do
    view = template('button(class="btn btn-outline-secondary" type="button" :title="toggle" data-toggle)')
    output = run(view, file_key: "components")
    expect(output[0]).to be == view
  end

  specify "arial-label" do
    view = template('a(href="#" class="btn-clear" aria-label="Löschen" role="button")')
    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      %[a(href="#" class="btn-clear" :aria-label="$t('components.loschen')" role="button")]
    )
  end

  specify "label as first attribute" do
    view = template('b-form-group(label="Sprache")')
    output = run(view, file_key: "components")
    expect(output[0]).to be == template(
      %[b-form-group(:label="$t('components.sprache')")]
    )
  end

  def template(content)
    <<~DOC
      <template lang="pug">
      #{content}
      </template>
    DOC
  end
end
