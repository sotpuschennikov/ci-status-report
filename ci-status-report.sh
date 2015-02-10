#!/bin/bash -ex

case $1 in
	"start")
curl -X POST \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-d "{\"name\": \"$JOB_NAME\", \"started\": \"`date -u +"%Y-%m-%dT%H:%M:%S"`\", \"commit_id\": \"$GERRIT_PATCHSET_REVISION\", \"request_type\": \"CI Status Test Report\", \"request_url\": \"$GERRIT_CHANGE_URL\", \"request_branch\": \"$GERRIT_BRANCH\", \"request_project\": \"$GERRIT_PROJECT\", \"request_owner_name\": \"$GERRIT_CHANGE_OWNER_NAME\", \"request_owner_email\": \"$GERRIT_CHANGE_OWNER_EMAIL\", \"request_subject\": \"$GERRIT_CHANGE_SUBJECT\", \"commit_id\": \"$GERRIT_PATCHSET_REVISION\", \"meta\": {\"urls\": [{\"name\": \"Jenkins Job URL\", \"link\": \"$BUILD_URL\"}]}}" \
http://ci-status.vm.mirantis.net/api/v1/stages
ssh -p 29418 openstack-ci-jenkins@review.fuel-infra.org gerrit review $GERRIT_PATCHSET_REVISION --message "http://ci-status.vm.mirantis.net/commit/$GERRIT_PATCHSET_REVISION"
		;;
	"stop")
	curl -X POST \
	-H "Content-Type: application/json" \
	-H "Accept: application/json" \
	-d "{\"name\": \"$JOB_NAME\", \"finished\": \"`date -u +"%Y-%m-%dT%H:%M:%S"`\", \"commit_id\": \"$GERRIT_PATCHSET_REVISION\", \"request_type\": \"CI Status Test Report\", \"meta\": {\"urls\": [{\"name\": \"Jenkins Job URL\", \"link\": \"$BUILD_URL\"}]}}" \
http://ci-status.vm.mirantis.net/api/v1/stages
               ;;
	*)
		echo "Usage: $0 start|stop"
		;;
esac
