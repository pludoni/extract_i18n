# rubocop:disable Layout/ArgumentAlignment
RSpec.describe ExtractI18n::Adapters::VueAdapter do
  specify "block content" do
    view = template(%{<div class="foo">\n  Content\n</div>})
    output = run(view, file_key: "components")
    compare output,
      <<~VIEW
        <div class="foo">
          {{ $t('components.content') }}
        </div>
      VIEW
  end

  specify 'interpolation' do
    view = template <<~HTML
      <div class="foo">
        Find me in {{ some_variable.key }}
      </div>
    HTML
    output = run(view, file_key: "components")
    compare output,
      <<~VIEW
        <div class="foo">
          {{ $t('components.find_me_in_some_variable_k', { some_variable_key: (some_variable.key) }) }}
        </div>
      VIEW
  end

  # title placeholder, foo-title, label description alt
  specify 'title' do
    view = template <<~HTML
      <div class="foo" title="Foobar Foo">
      </div>
    HTML
    output = run(view, file_key: "components")
    compare output,
      <<~VIEW
        <div class="foo" :title="$t('components.foobar_foo')">
        </div>
      VIEW
  end

  specify 'keep vue special tags' do
    view = <<~HTML
      <template>
      <div :class="foo" v-bind:foo="Foobar Foo" :fooBar="fooBar" v-if="bla" @click.prevent="foo" stacked>
        <BModal></BModal>
      </div>
      </template>

      <script setup lang="ts">
      fooBar
      </script>
    HTML
    output = run(view, file_key: "components")
    expect(output[0].gsub("\n", '')).to be == view.gsub("\n", '')
  end

  specify 'ignore dynamic' do
    view = <<~HTML
      <div>
        {{ alreadyReplaced }}
      </div>
    HTML
    output = run(template(view), file_key: "components")
    compare output, view
  end

  def template(content)
    <<~DOC
      <template>
      #{content}
      </template>
    DOC
  end

  def compare(output, tpl)
    expect(output[0].gsub("\n", '')).to be == template(tpl).gsub("\n", '')
  end
end
