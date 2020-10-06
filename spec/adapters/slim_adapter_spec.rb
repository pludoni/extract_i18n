# rubocop:disable Lint/InterpolationCheck

RSpec.describe ExtractI18n::Adapters::SlimAdapter do
  specify "initial" do
    cmp!(
      "div.foobar\n  p Hello World" => [
        "div.foobar\n  p = t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World" }
      ])
  end

  specify 'pipe' do
    cmp!(
      "  |Hello World!" => [
        "  = t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" },
      ],
      "  | Hello World!" => [
        "  = t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ]
    )
  end

  specify 'whitespace control' do
    cmp!(
      "  ' Hello World!" => [
        "  => t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" },
      ],
      "  | &nbsp;Hello World!" => [
        "  =< t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ],
      "| &nbsp;Hello World!&nbsp;" => [
        "=<> t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ],
      "| Hello&nbsp;World!" => [
        "= t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ],
      "| &nbsp;Hello World!" => [
        "=< t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ]
    )
  end

  specify "nested html" do
    cmp!(
      "  aside.pointer: div Hello World!" => [
        "  aside.pointer: div = t('models.foo.hello_world')\n",
        { "models.foo.hello_world" => "Hello World!" }
      ]
    )
  end

  specify 'ignore already translated' do
    cmp!(
      "p= t '.actions'" => [
        "p= t '.actions'\n", {}
      ]
    )
  end

  context "when word contains [a-z].input" do
    specify 'ruby strings' do
      cmp!(
        '= f.input :max_characters_allowed, label: "Max. Characters", hint: "Shows an indicator how..."' => [
          "= f.input :max_characters_allowed, label: t('models.foo.max_characters'), hint: t('models.foo.shows_an_indicator_how')\n",
          { "models.foo.max_characters" => "Max. Characters", "models.foo.shows_an_indicator_how" => "Shows an indicator how..." }
        ]
      )
    end
  end

  specify 'interpolation in text' do
    cmp!(
      '| Hello #{Date.today}!' => [
        "= t('models.foo.hello_date_today', date_today: (Date.today))\n",
        { "models.foo.hello_date_today" => "Hello %{date_today}!" }
      ]
    )
  end
  specify 'interpolation in html arg' do
    cmp!(
      '= f.input label: "Foobar #{Date.today}"' => [
        "= f.input label: t('models.foo.foobar_date_today', date_today: (Date.today))\n",
        { "models.foo.foobar_date_today" => "Foobar %{date_today}" }
      ]
    )
  end

  specify 'slimkeyfy migrated examples' do
    cmp!(
      "# key_stuff = \"#\{raw(t('.key_names', href: \"#\{link_to(\"W00t\", title: t('.key_names_column'), data: {content: \"Some more Content\", html: true})}\"" => [
        "# key_stuff = \"#\{raw(t('.key_names', href: \"#\{link_to(t('models.foo.w00t'), title: t('.key_names_column'), data: {content: t('models.foo.some_more_content'), html: true})}\"\n",
        {
          "models.foo.w00t" => "W00t",
          "models.foo.some_more_content" => "Some more Content"
        }
      ]
    )
  end
end
