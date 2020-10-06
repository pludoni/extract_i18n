# ExtractI18n

CLI helper program to automatically extract bare text strings into Rails I18n interactively.

Useful when adding i18n to a medium/large Rails app.

This Gem **supports** the following source files:

- Ruby files (controllers, models etc.) via Ruby-Parser, e.g. walking all Ruby Strings
- Slim Views (via Regexp parser by SlimKeyfy)
- Vue Pug views
  - Pug is very similar to slim and thus relatively good extractable via Regexp.

CURRENTLY THERE IS **NO SUPPORT** FOR:

- erb
- haml
- vue html templates (Check out my vue pug converting script)

But I am open to integrating PRs for those!

I strongly recommend using a Source-Code-Management (Git) and ``i18n-tasks`` for checking the key consistency.

## Installation

install:

    $ gem install extract_i18n

## Usage

DO USE A SOURCE-CODE-MANAGEMENT-SYSTEM (Git). There is no guarantee that programm will not destroy your workspace :)


```
extract-i18n --helper

extract-i18n --locale de --yaml config/locales/unsorted.de.yml app/views/user
```

If you prefer relative keys in slim views use ``--slim-relative``, e.g. ``t('.title')`` instead of ``t('users.index.title')``.
I prefer absolute keys, as it makes copy pasting/ moving files much safer.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zealot128/extract_i18n.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
