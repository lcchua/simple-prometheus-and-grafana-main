#!/bin/bash

# Update yumn package repositories
yum update -y
yum install stress-ng -y

# Download prometheus archive installation file and unarchive installation file
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.53.1/prometheus-2.53.1.linux-amd64.tar.gz
tar -xvf prometheus-2.53.1.linux-amd64.tar.gz
rm -f prometheus-2.53.1.linux-amd64.tar.gz
mv prometheus-2.53.1.linux-amd64 prometheus-files

# Create a user for Prometheus and assign Prometheus as the owner of these directories
groupadd -f prometheus
useradd -g prometheus --no-create-home --shell /bin/false prometheus

# create prometheus directories
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Copy the binaries prometheus and promtool from the prometheus-files directory to /usr/local/bin and update the ownership to the user prometheus.
cp prometheus-files/prometheus /usr/local/bin/
cp prometheus-files/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Move the directories consoles and console_libraries from the prometheus-files folder to /etc/prometheus, and adjust the ownership to the user prometheus
cp -r prometheus-files/consoles /etc/prometheus
cp -r prometheus-files/console_libraries /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries

# create prometheus config file
cat <<EOF | tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 10s
#  external_labels: 'prometheus'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "cpu_thresholds_rules.yml"
  - "storage_thresholds_rules.yml"
  - "memory_thresholds_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']

#remote_write:
#  - url: https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-0914006c-670c-4b2c-8252-d9ab5c0c05a7/api/v1/remote_write
#    queue_config:
#        max_samples_per_send: 1000
#        max_shards: 200
#        capacity: 2500
#    sigv4:
#        region: us-east-1
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Setup Prometheus Service File
cat <<EOF | tee  /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# dowload, unarchive and move node_exporter binary
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar -xvf node_exporter-1.8.2.linux-amd64.tar.gz
rm -f node_exporter-1.8.2.linux-amd64.tar.gz
mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

# create group/user for node_exporter
groupadd -f node_exporter
useradd -g node_exporter --no-create-home --shell /bin/false node_exporter

# Create Node Exporter Service
cat <<EOF | tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
ls -
[Install]
WantedBy=multi-user.target
EOF

# Download and install grafana
curl -LO https://dl.grafana.com/enterprise/release/grafana-enterprise-11.1.3-1.x86_64.rpm
yum localinstall grafana-enterprise-11.1.3-1.x86_64.rpm -y
rm -f grafana-enterprise-11.1.3-1.x86_64.rpm

# Configure Provisioning
sed -i 's|;provisioning = conf/provisioning|provisioning = /etc/grafana/provisioning|g' /etc/grafana/grafana.ini

cat <<EOF | tee /etc/grafana/provisioning/datasource.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF

# Download and unarchive alertmanager
curl -LO https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
rm -f alertmanager-0.27.0.linux-amd64.tar.gz
cd alertmanager-0.27.0.linux-amd64

# create group/user for alertmanager
groupadd -f alertmanager
useradd -g alertmanager --no-create-home --shell /bin/false alertmanager

# create directories for alertmanager
mkdir -p /etc/alertmanager/templates
mkdir /var/lib/alertmanager
chown alertmanager:alertmanager /etc/alertmanager
chown alertmanager:alertmanager /var/lib/alertmanager

# copy binaries
cp alertmanager /usr/bin/
cp amtool /usr/bin/
chown alertmanager:alertmanager /usr/bin/alertmanager
chown alertmanager:alertmanager /usr/bin/amtool

# configuration file (add your own discord webhook here)
cat <<EOF | tee /etc/alertmanager/alertmanager.yml
route:
  group_by: ['alertname', 'job']

  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h

  receiver: discord

receivers:
- name: 'discord'
  discord_configs:
  - webhook_url: https://discord.com/api/webhooks/1294560124735586334/y2YwN64HA8sFVZTqSJJ910xhHQ936_IErq0ckaowDmdR8AxJ7eQtyUyvX9eo9bIY-kLq
EOF
# under discord_configs block - if need be, add send_resolved: true -> set to false if do not want to receive resolved notifications

chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

# set up alertmanager service
cat <<EOF | tee /etc/systemd/system/alertmanager.service
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/

[Install]
WantedBy=multi-user.target
EOF

chmod 664 /etc/systemd/system/alertmanager.service

# rule to get an alert when the CPU usage goes more than 60%
cat <<EOF | tee /etc/prometheus/cpu_thresholds_rules.yml
groups:
  - name: CpuThreshold
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 60
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage on {{ $labels.instance }} is greater than 60%."
EOF

# Rule for memory usage alert
cat <<EOF | tee /etc/prometheus/memory_thresholds_rules.yml
groups:
  - name: MemoryThreshold
    rules:
      - alert: HighRAMUsage
        expr: 100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 60
        for: 15s
        labels:
          severity: critical
        annotations:
          summary: "High RAM usage on {{ $labels.instance }}"
          description: "RAM usage on {{ $labels.instance }} is greater than 60%."
EOF

# Rule for high storage usage alert
cat <<EOF | tee /etc/prometheus/storage_thresholds_rules.yml
groups:
  - name: StorageThreshold
    rules:
      - alert: HighStorageUsage
        expr: 100 * (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes{mountpoint="/"})) > 50
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High storage usage on {{ $labels.instance }}"
          description: "Storage usage on {{ $labels.instance }} is greater than 50%."
EOF

systemctl daemon-reload

systemctl start prometheus
systemctl start node_exporter
systemctl start grafana-server
systemctl start alertmanager

systemctl enable prometheus
systemctl enable node_exporter
systemctl enable grafana-server
systemctl enable alertmanager