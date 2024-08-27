RSpec.describe ExtractI18n::Adapters::RubyAdapter do
  specify 'normal string' do
    file = <<~DOC
      a = "Hallo Welt"
    DOC
    expect(run(file)).to be == [
      "a = I18n.t(\"models.foo.hallo_welt\")\n", { 'models.foo.hallo_welt' => 'Hallo Welt' }
    ]
  end

  specify 'Heredoc' do
    file = <<~DOC
      a = <<~FOO
        Hallo
        Welt
      FOO
    DOC
    expect(run(file)).to be == [
      "a = I18n.t(\"models.foo.hallo_welt\")\n", { 'models.foo.hallo_welt' => "Hallo\nWelt\n" }
    ]
  end

  specify 'String placeholder' do
    file = <<~DOC
      a = "What date is it: \#{Date.today}!"
    DOC
    expect(run(file)).to be == [
      "a = I18n.t(\"models.foo.what_date_is_it\", date_today: (Date.today))\n", {
        'models.foo.what_date_is_it' => "What date is it: %{date_today}!"
      }
    ]
  end

  specify 'Ignore active record stuff' do
    file = <<~DOC
      has_many :foos, class_name: "FooBar", foreign_key: "foobar"
    DOC
    expect(run(file)).to be == [
      file, {}
    ]
  end

  specify 'Ignore class and style attributes' do
    file = <<~DOC
      div(class: "foo", style: "bar") {
      }
    DOC
    expect(run(file)).to be == [
      file, {}
    ]
  end

  specify 'Ignore active record functions' do
    file = <<~DOC
      sql = User.where("some SQL Condition is true").order(Arel.sql("Foobar"))
    DOC
    expect(run(file)).to be == [
      file, {}
    ]
  end

  specify 'Ignore regex' do
    file = <<~DOC
      a = /Hallo Welt/
    DOC
    expect(run(file)).to be == [
      file, {}
    ]
  end

  specify 'Ignore active record stuff' do
    file = <<~DOC
      has_many :foos, class_name: "FooBar", foreign_key: "foobar"
    DOC
    expect(run(file)).to be == [
      file, {}
    ]
  end
end
