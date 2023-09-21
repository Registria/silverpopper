# -*- encoding: utf-8 -*-
# stub: silverpopper 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "silverpopper".freeze
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["WHERE, Inc".freeze]
  s.date = "2011-10-12"
  s.description = "handle authentication, and wrap api calls in standard ruby code to\n                       so you don't have to think about xml when communicating with silverpop".freeze
  s.email = "whereweb@where.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.rdoc".freeze]
  s.files = [".document".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "VERSION".freeze, "doc/LICENSE_txt.html".freeze, "doc/Silverpopper.html".freeze, "doc/Silverpopper/Client.html".freeze, "doc/Silverpopper/Common.html".freeze, "doc/Silverpopper/TransactApi.html".freeze, "doc/Silverpopper/XmlApi.html".freeze, "doc/created.rid".freeze, "doc/images/brick.png".freeze, "doc/images/brick_link.png".freeze, "doc/images/bug.png".freeze, "doc/images/bullet_black.png".freeze, "doc/images/bullet_toggle_minus.png".freeze, "doc/images/bullet_toggle_plus.png".freeze, "doc/images/date.png".freeze, "doc/images/find.png".freeze, "doc/images/loadingAnimation.gif".freeze, "doc/images/macFFBgHack.png".freeze, "doc/images/package.png".freeze, "doc/images/page_green.png".freeze, "doc/images/page_white_text.png".freeze, "doc/images/page_white_width.png".freeze, "doc/images/plugin.png".freeze, "doc/images/ruby.png".freeze, "doc/images/tag_green.png".freeze, "doc/images/wrench.png".freeze, "doc/images/wrench_orange.png".freeze, "doc/images/zoom.png".freeze, "doc/index.html".freeze, "doc/js/darkfish.js".freeze, "doc/js/jquery.js".freeze, "doc/js/quicksearch.js".freeze, "doc/js/thickbox-compressed.js".freeze, "doc/lib/client_rb.html".freeze, "doc/lib/common_rb.html".freeze, "doc/lib/silverpopper_rb.html".freeze, "doc/lib/transact_api_rb.html".freeze, "doc/lib/xml_api_rb.html".freeze, "doc/rdoc.css".freeze, "lib/client.rb".freeze, "lib/common.rb".freeze, "lib/silverpopper.rb".freeze, "lib/transact_api.rb".freeze, "lib/xml_api.rb".freeze, "silverpopper.gemspec".freeze, "test/helper.rb".freeze, "test/silverpopper/client_test.rb".freeze]
  s.homepage = "http://github.com/where/silverpopper".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.10".freeze
  s.summary = "a simple interface to the Silverpop XMLAPI and Transact API".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<httparty>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<i18n>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<oauth2>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>.freeze, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<fakeweb>.freeze, [">= 0"])
    else
      s.add_dependency(%q<builder>.freeze, [">= 0"])
      s.add_dependency(%q<httparty>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<i18n>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<oauth2>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>.freeze, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<fakeweb>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<builder>.freeze, [">= 0"])
    s.add_dependency(%q<httparty>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<i18n>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<oauth2>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>.freeze, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<fakeweb>.freeze, [">= 0"])
  end
end
