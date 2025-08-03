#!/bin/sh

#  versioning.sh
#  TaggedFileBrowser
#
#  Created by Ryan Robinson on 12/17/24.
#  

cd "$SRCROOT"

# Updates "BUILD_NUMBER" in versioning xcconfig to the current date
sed -i -e "/BUILD_NUMBER =/ s/= .*/= $(date +"%Y%m%d%H%M%S")/" versioning.xcconfig

function get_git_tag {
  echo "$(git describe --tags $(git rev-list --tags --max-count=1))"
}

# Updates "VERSION" in versioning xcconfig to the current git tag
sed -i -e "/VERSION =/ s/= .*/= $(get_git_tag)/" versioning.xcconfig

# Delete temp file
rm versioning.xcconfig-e
