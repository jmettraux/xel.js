
#
# $(NAME).js Makefile


NAME != basename `pwd` '.js'
SHA != git log -1 --format="%h"
NOW != date
VERSION != awk -F"'" '/this\.VERSION =/ {print $$2}' src/$(NAME).js


name:
	@echo "$(NAME) $(VERSION)"

spec:
	bundle exec rspec

pkg_plain:
	mkdir -p pkg
	cat LICENSE.txt src/$(NAME).js > pkg/$(NAME)-$(VERSION).js
	echo "/* from commit $(SHA) on $(NOW) */" >> pkg/$(NAME)-$(VERSION).js
	cp pkg/$(NAME)-$(VERSION).js pkg/$(NAME)-$(VERSION)-$(SHA).js
pkg_mini:

pkg: pkg_plain pkg_mini


.PHONY: name spec pkg

