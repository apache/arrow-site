#!/usr/bin/env python3

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Utility for checking that the local committers list used to generate
# the Governance page is up-to-date with the authoritative ASF roster.
#

from collections import namedtuple, Counter
import json
import os
import sys

import requests
import yaml


git_root = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
committers_yaml = os.path.join(git_root, "_data", "committers.yml")

# See https://home.apache.org/phonebook-about.html
# for available resources
committers_url = "https://whimsy.apache.org/public/public_ldap_projects.json"
people_url = "https://whimsy.apache.org/public/public_ldap_people.json"

Roster = namedtuple('Roster', ('committers', 'pmcs'))
Committers = namedtuple('Committers', ('apache_id', 'name'))
PMCs = namedtuple('PMCs', ('apache_id', 'name'))

def get_asf_roster():
    r = requests.get(committers_url)
    j = r.json()
    proj = j['projects']['arrow']
    pmcs = set(proj['owners'])
    committers = set(proj['members']) - pmcs
    return Roster(committers, pmcs)

def get_names(ids):
    r = requests.get(people_url)
    j = r.json()
    names = {}
    for id in ids:
        names[id] = j['people'][id]['name']
    return names

def print_names_and_ids(names):
    print("{:<15} {:<40}".format('Apache Id','NAME'))
    for key, value in names.items():
        print("{:<15} {:<40}".format(key,value))

def get_duplicates():
    with open(committers_yaml, "r") as f:
        d = yaml.safe_load(f)
    aliases = []
    duplicates = set()
    for member in d:
        aliases.append(member['alias'])
    alias_counts = Counter(aliases)
    for alias in alias_counts:
        if alias_counts[alias] > 1:
            duplicates.add(alias)
    return duplicates

def get_local_roster():
    with open(committers_yaml, "r") as f:
        d = yaml.safe_load(f)
    committers = set()
    pmcs = set()
    for member in d:
        uid = member['alias']
        role = member['role']
        if role in ('PMC', 'VP'):
            pmcs.add(uid)
        elif role == 'Committer':
            committers.add(uid)
        else:
            raise ValueError(f"Invalid role {role!r} for {uid}")
    return Roster(committers, pmcs)

if __name__ == "__main__":
    duplicate_members = get_duplicates()
    if duplicate_members:
       print("Duplicate members in local list:", sorted(duplicate_members))
       sys.exit(1)
    local_roster = get_local_roster()
    asf_roster = get_asf_roster()
    if local_roster == asf_roster:
        print("Committer list up-to-date")
        sys.exit(0)

    missing_pmcs = asf_roster.pmcs - local_roster.pmcs

    if missing_pmcs:
        missing_pmcs_names = get_names(missing_pmcs)
        print("Missing PMCs in local list")
        print_names_and_ids(missing_pmcs_names)
    missing_committers = asf_roster.committers - local_roster.committers
    if missing_committers:
        missing_committers_names = get_names(missing_committers)
        print("Missing committers in local list:")
        print_names_and_ids(missing_committers_names)
    unexpected_members = ((local_roster.pmcs | local_roster.committers) -
                          (asf_roster.pmcs | asf_roster.committers))
    if unexpected_members:
        print("Unexpected members in local list:", sorted(unexpected_members))
    sys.exit(1)
