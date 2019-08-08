#  -  *  -  mode：makefile; 编码：utf-8  -  *  - 
# 
# 此文件是OpenMediaVault的一部分。
# 
#  @license http://www.gnu.org/licenses/gpl.html GPL版本3
#  @author Volker Theile <volker.theile@openmediavault.org>
#  @copyright版权所有（c）2009-2019 Volker Theile
# 
#  OpenMediaVault是免费软件：您可以重新分配和/或修改
# 根据发布的GNU通用公共许可证的条款
# 自由软件基金会，许可证的第3版，或
# 任何更高版本。
# 
#  OpenMediaVault分布在希望这将是有益的，
# 但没有任何保证; 甚至没有暗示的保证
# 适应性或特定用途的适用性。见
#  GNU通用公共许可证的更多细节。
# 
# 您应该已收到GNU通用公共许可证的副本
# 以及OpenMediaVault。如果没有，请参阅<http://www.gnu.org/licenses/>。

NUM_PROCESSORS := $(shell nproc)

OMV_PACKAGE := $(shell pwd | sed 's|.*/||')
OMV_POT_DIR := $(CURDIR)/usr/share/openmediavault/locale
OMV_POT_FILE := $(OMV_PACKAGE).pot
OMV_TRANSIFEX_PROJECT_SLUG := openmediavault

omv_tx_status:
	tx --root="$(CURDIR)/../" status \
	  --resource=$(OMV_TRANSIFEX_PROJECT_SLUG).$(OMV_PACKAGE)

omv_tx_pull_po:
	tx --root="$(CURDIR)/../" pull --all \
	  --resource=$(OMV_TRANSIFEX_PROJECT_SLUG).$(OMV_PACKAGE)

omv_tx_push_pot:
	tx --root="$(CURDIR)/../" push --source \
	  --resource=$(OMV_TRANSIFEX_PROJECT_SLUG).$(OMV_PACKAGE)

omv_build_pot:
	dh_testdir
	dh_clean
	echo "Building PO template file ..." >&2
	mkdir -p $(OMV_POT_DIR)
	find $(CURDIR) \( -iname *.js -o -iname *.php -o -iname *.inc \) \
	  -type f -print0 | xargs -0r xgettext --keyword=_ \
	  --output-dir=$(OMV_POT_DIR) --output=$(OMV_POT_FILE) \
	  --force-po --no-location --no-wrap --sort-output \
	  --package-name=$(OMV_PACKAGE) --from-code=UTF-8 -
	# Remove '#, c-format' comments, otherwise manuall upload of translation
	# files confuses Transifex.
	sed --in-place '/^#, c-format/d' $(OMV_POT_DIR)/$(OMV_POT_FILE)

omv_clean_scm:
	dh_testdir
	echo "Removing SCM files ..." >&2
	find $(CURDIR)/debian/$(OMV_PACKAGE) \( -name .svn -o -name .git \) \
	  -type d -print0 -prune | xargs -0r rm -rf

omv_build_doc: debian/doxygen.conf
	mkdir -p debian/doxygen
	doxygen $<

omv_beautify_py:
	black --target-version py37 --line-length 80 --skip-string-normalization .

omv_lint_py:
	find $(CURDIR) \( -iname *.py \) -type f -print0 | xargs -0r \
	  pylint --rcfile="$(CURDIR)/../.pylintrc" --jobs=$(NUM_PROCESSORS)

source: clean
	dpkg-buildpackage -S -us -uc

.PHONY: omv_tx_status omv_tx_pull_po omv_tx_push_pot
.PHONY: omv_build_pot omv_build_doc omv_clean_scm
.PHONY: omv_beautify_py omv_lint_py source
