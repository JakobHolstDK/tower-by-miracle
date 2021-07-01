#!/usr/bin/env bash

sudo mkdir /opt/my-envs
sudo chmod 0755 /opt/my-envs
sudo chown awx:awx /opt/my-envs
curl -X PATCH 'https://admin:ixj90j2s@localhost/api/v2/settings/system/'     -d '{"CUSTOM_VENV_PATHS": ["/opt/my-envs/"]}'  -H 'Content-Type:application/json' --insecure
sudo virtualenv /opt/my-envs/awx-turnkey



tower-cli user          create         --username miracle --password "ixj90j2s" --first-name "Tower" --email jho@miracle.dk --last-name "Miracle" --is-superuser False

tower-cli team           create         --name miracle                         --description "The ansible tower team" --organization miracle
tower-cli organization   create --force-on-exists  --name miracle      --description "Miracle AS"
tower-cli project        create --force-on-exists  --name  awx-turnkey --description "AWX turnkey installer by miracle and RPM's" --organization miracle --scm-type git --scm-url "https://github.com/JakobHolstDK/awx-turnkey.git" --scm-branch "master" --scm-clean TRUE --scm-delete-on-update TRUE --scm-update-on-launch TRUE --scm-update-cache-timeout 60 --job-timeout 600 --custom-virtualenv /opt/my-envs/awx-turnkey/

tower-cli role           grant  --type member --user miracle  --organization miracle
tower-cli role           grant  --type use --user miracle  --project awx-turnkey

tower-cli inventory      create  --name awx-turnkey --organization miracle --variables @awx-turnkey.json
tower-cli host           create  --name centos8venv --description "the host for awx by miracle and virtual environments" -i awx-turnkey --enabled True 
tower-cli credential     create  --name maas        --description "access to maas servers" --credential-type Machine --organization miracle  --inputs="{\"username\":\"cloud-user\",\"ssh_key_data\":\"$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' ~/.ssh/id_rsa)\n\",\"become_method\":\"sudo\"}"

tower-cli job_template   create  --name "ansible_fact_collecter"              --description "Collect ansible facts"                   --inventory awx-turnkey --project awx-turnkey --playbook "ansiblefacts.yml"                        --credential maas
tower-cli job_template   create  --name "awx-turnkey-create-project-servers"  --description "Terraform server on maas"                --inventory awx-turnkey --project awx-turnkey --playbook "awx-turnkey-create-project-servers.yml"  --credential maas
tower-cli job_template   create  --name "awx-turnkey-on-kubernetes"           --description "autodeploy awx on kubernetes"            --inventory awx-turnkey --project awx-turnkey --playbook "awx-turnkey-on-kubernetes.yml"           --credential maas
tower-cli job_template   create  --name "awx-turnkey-on-venv"                 --description "autodeploy awx on virtual environment"   --inventory awx-turnkey --project awx-turnkey --playbook "awx-turnkey-on-venv.yml"                 --credential maas
tower-cli job_template   create  --name "awx-turnkey-on-scl"                  --description "autodeploy awx on software collections"  --inventory awx-turnkey --project awx-turnkey --playbook "awx-turnkey-on-scl.yml"                 --credential maas


tower-cli workflow       create   --name "awx-turnkey" --description "Awx turnkey workflow"  -e @awx-turnkey.json --organization miracle 


