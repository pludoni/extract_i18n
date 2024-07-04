RSpec.describe ExtractI18n::Adapters::JsAdapter do
  specify 'normal string' do
    file = <<~JAVASCRIPT
      const a = "Hallo Welt"

      const b = 'Wo auch immer?'
    JAVASCRIPT

    expect(run(file)).to be == [
      "const a = t('models.foo.hallo_welt')\n\n" +
      "const b = t('models.foo.wo_auch_immer')\n",

      { 'models.foo.hallo_welt' => 'Hallo Welt', 'models.foo.wo_auch_immer' => 'Wo auch immer?' }
    ]
  end

  specify 'ignore import require etc' do
    file = <<~JAVASCRIPT
      import { a } from 'thatsapackage'
      const b = require('thatspacake')
      // const c = import('thatsapackage')
    JAVASCRIPT
    expect(run(file)).to be == [
      file, {}
    ]
  end

  specify 'keys ignored' do
    file = <<~JAVASCRIPT
      const fields = [
        {
          label: "Gehalt",
          key: "salary",
        },
      ]
    JAVASCRIPT

    expect(run(file)).to be == [
      <<~JAVASCRIPT,
        const fields = [
          {
            label: t('models.foo.gehalt'),
            key: "salary",
          },
        ]
      JAVASCRIPT

      {
        'models.foo.gehalt' => 'Gehalt',
      }
    ]
  end

  xspecify 'template literals' do
    file = <<~JAVASCRIPT
      const stringWithInterpolation = `My name is ${person.title}`
    JAVASCRIPT
  end

end
