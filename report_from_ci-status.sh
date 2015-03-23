#!/bin/bash 
release="6.1"
branch="openstack-ci/fuel-6.1/2014.2"
project=''
for project in `ssh -p 29418 sotpuschennikov@review.fuel-infra.org gerrit ls-projects | grep -v infra` ; do
ci_status_data=`curl -sS http://ci-status.vm.mirantis.net/api/v1/stages?request_project=$project`
if echo $ci_status_data | grep -o -e request_url > /dev/null ; then
export project
#python report_from_ci-status_python.py
python -c '
import json
import yaml
import sys
import os
import requests
import time, datetime
from time import strftime
from datetime import datetime

project = os.getenv("project")
release = os.getenv("release")

ci_stat_data = requests.get("http://ci-status.vm.mirantis.net/api/v1/stages?request_project=" + project)

obj = json.loads(ci_stat_data.content)

max_pages = obj["total_pages"]

pages = 0
durations_before_merge = 0
durations_after = 0
finally_commits = list()

while pages < max_pages + 1:
        if pages == 0:
                ci_stat_data = requests.get("http://ci-status.vm.mirantis.net/api/v1/stages?request_project=" + project)
        else:
                ci_stat_data = requests.get("http://ci-status.vm.mirantis.net/api/v1/stages?request_project=" + project + "&page=" + str(pages))
        obj = json.loads(ci_stat_data.content)
        finally_commits += [o.get("commit_id", 0) for o in obj["objects"] if "primary" in o["name"] and "6.1" in o["request_branch"]]
        pages = pages + 1

commits = set(finally_commits)
for commit in set(finally_commits):
        pages = 0
        durations_before_merge = 0
	durations_before_merge_clear = 0
        ci_stat_data = requests.get("http://ci-status.vm.mirantis.net/api/v1/stages?request_project=" + project + "&commit_id=" + commit)
        obj = json.loads(ci_stat_data.content)
	durations_before_merge_clear = sum([o.get("duration_seconds", 0) for o in obj["objects"] if "primary" not in o["name"] and "6.1" in o["request_branch"] and "ISO" not in o["name"]])
        start_finished_time = [o.get("finished", 0) for o in obj["objects"] if "primary" not in o["name"] and "6.1" in o["request_branch"] and "ISO" not in o["name"] and "mirror" not in o["name"]]
        start_finished_time += [o.get("started", 0) for o in obj["objects"] if "primary" not in o["name"] and "6.1" in o["request_branch"] and "ISO" not in o["name"] and "mirror" not in o["name"]]
	times = [datetime.strptime(i, "%Y-%m-%dT%H:%M:%S.000000") for i in start_finished_time]
	if times:
	        durations_before_merge = (max(times) - min(times)).total_seconds()
	else:
		durations_before_merge = "NONE"
	merge_time = min([o.get("started", 0) for o in obj["objects"] if "primary" in o["name"] and "6.1" in o["request_branch"]])
        finished_iso = [o.get("started", 0) for o in obj["objects"] if "Product" in o["name"] and "6.1" in o["request_branch"]]
        url = [o.get("meta", 0) for o in obj["objects"] if "Product" in o["name"] and "6.1" in o["request_branch"]]
        if len(url) > 0:
                iso_url = url[0]["urls"][0]["link"]
        if len(url) > 0:
                ci_url_data = requests.get(iso_url + "artifact/version.yaml.txt")
                iso_build_id = yaml.load(ci_url_data.content)["VERSION"]["build_id"]
		durations_after_merge = int(datetime.strptime(iso_build_id, "%Y-%m-%d_%H-%M-%S").strftime("%s")) - int(datetime.strptime(merge_time, "%Y-%m-%dT%H:%M:%S.000000").strftime("%s"))
        else:
                iso_build_id = "NONE"
		durations_after_merge = "NONE"
        if durations_before_merge_clear > 0:
		print ("{: >40}\t {: >40}\t {: >10}\t {: >10}\t {: >10}".format(commit, project, durations_before_merge, durations_before_merge_clear, durations_after_merge))
'
#else echo "$project" "Not found in ci-status"
fi
done

