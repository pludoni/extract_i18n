# ExtractI18n

[![Gem Version](https://badge.fury.io/rb/extract_i18n.svg)](https://badge.fury.io/rb/extract_i18n)

[Read my blog post if you'd like more about the development of ExtractI18n](https://www.stefanwienert.de/blog/2020/07/26/internationalize-medium-rails-app-with-tooling/).

CLI helper program to automatically extract bare text strings into Rails I18n interactively.

Useful when adding i18n to a medium/large Rails app.

This Gem **supports** the following source files:

- Ruby files (controllers, models etc.) via Ruby-Parser, e.g. walking all Ruby Strings
- Slim Views (via Regexp parser by [SlimKeyfy](https://github.com/phrase/slimkeyfy) (MIT License))
- Vue templates
  - will scan all texts and common string-attributes such as title, alt etc. for static strings and replace with vue-i18n's $t
  - Caveats: because of limitations of the HTML/XML parser it will slightly transform the HTML, for example, self closing tags are expanded (e.g. ``<Component />`` will become ``<Component></Component>``). Also multi-line arrangements of attributes, tags etc. might produce unexpected results, so make sure to use Git and diff the result.
- Vue Pug views
  - Pug is very similar to slim and thus relatively well extractable via Regexp.
- ERB views
  - by vendoring/extending https://github.com/ProGM/i18n-html_extractor (MIT License)

CURRENTLY THERE IS **NO SUPPORT** FOR:

- haml ( integrating https://github.com/shaiguitar/haml-i18n-extractor)

But I am open to integrating PRs for those!

I strongly recommend using a Source-Code-Management (Git) and ``i18n-tasks`` for checking the key consistency.
I've created a scanner to make that work with vue $t structures too: https://gist.github.com/zealot128/e6ec1767a40a6c3d85d7f171f4d88293

## Installation

install:

    $ gem install extract_i18n

## Usage

DO USE A SOURCE-CODE-MANAGEMENT-SYSTEM (Git). There is no guarantee that programm will not destroy your workspace :)


```
extract-i18n --help

extract-i18n --locale de --yaml config/locales/unsorted.de.yml app/views/user
```

If you prefer relative keys in slim views use ``--slim-relative``, e.g. ``t('.title')`` instead of ``t('users.index.title')``.
I prefer absolute keys, as it makes copy pasting/ moving files much safer.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zealot128/extract_i18n.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
