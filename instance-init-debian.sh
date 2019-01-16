# Required environment variables
# elasticsearch : true/false/unset
# discovery_nodes: ["ad.dr.e.ss:9300"]
# cluster_name : some_cluster_name
# ca_node : true/false/unset
# CERT_PASSWORD : Elasticsearch certificate password
# ES_BOOTSTRAP_PW : Elasticsearch bootstrap password
# kibana : true/false/unset
# metricbeat : true/false/unset

sudo apt-get update && apt-get upgrade -y
sudo apt-get install software-properties-common -y

# Install Openjdk 11
sudo apt-get install openjdk-11-jdk -y

# Download ES public signing key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

# Save the repository definition to /etc/apt/sources.list.d/elastic-6.x.list
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo apt-get update

# Install specific package version
# Elasticsearch
if [ "$elasticsearch" ]; then
    sudo apt-get install elasticsearch=6.5.4 -y
  
  # Elasticsearch heap
    sudo sed -i.bak 's/-Xmx1g/-Xmx256m/; s/-Xms1g/-Xms256m/' /etc/elasticsearch/jvm.options

  # Systemd
    sudo /bin/systemctl daemon-reload
    sudo /bin/systemctl enable elasticsearch.service

    if [ "$ca_node" ]; then
        # Create CA
        sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca \
        --ca-dn "CN=Cluster Support Services" \
        --days 3650 \
        --out /etc/elasticsearch/elastic-stack-ca.p12 \
        --pass "$CERT_PASSWORD"

        sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert \
            --ca /etc/elasticsearch/elastic-stack-ca.p12 \
            --ca-pass "$CERT_PASSWORD" \
            --days 3650 \
            --out /etc/elasticsearch/elastic-stack-certificate.p12 \
            --pass "$CERT_PASSWORD"
    fi

    CERT_FILE=$(realpath ~/certs.tgz)
    sudo tar zxvf "$CERT_FILE" -C /etc/elasticsearch
    sudo chmod g+r /etc/elasticsearch/elastic-stack-ca.p12 /etc/elasticsearch/elastic-stack-certificate.p12

    echo "$ES_BOOTSTRAP_PW" | sudo /usr/share/elasticsearch/bin/elasticsearch-keystore \
        add -x "bootstrap.password"
    echo "$CERT_PASSWORD" | sudo /usr/share/elasticsearch/bin/elasticsearch-keystore \
        add -x xpack.security.transport.ssl.truststore.secure_password
    echo "$CERT_PASSWORD" | sudo /usr/share/elasticsearch/bin/elasticsearch-keystore \
        add -x xpack.security.transport.ssl.keystore.secure_password
    echo "$CERT_PASSWORD" | sudo /usr/share/elasticsearch/bin/elasticsearch-keystore \
        add -x xpack.security.http.ssl.keystore.secure_password
    echo "$CERT_PASSWORD" | sudo /usr/share/elasticsearch/bin/elasticsearch-keystore \
        add -x xpack.security.http.ssl.truststore.secure_password
    # elasticsearch.yml
    sudo mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.orig
    cat << EOF | sudo tee /etc/elasticsearch/elasticsearch.yml
#xpack.license.self_generated.type: trial
cluster.name: $cluster_name
network.host: _site_,_local_
node.master: true
node.data: false
node.ingest: true
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
discovery.zen.ping.unicast.hosts: $discovery_nodes
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate 
xpack.security.transport.ssl.keystore.path: elastic-stack-certificate.p12
xpack.security.transport.ssl.truststore.path: elastic-stack-ca.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: elastic-stack-certificate.p12
xpack.security.http.ssl.truststore.path: elastic-stack-ca.p12
EOF
fi

# Kibana
if [ "$kibana" ]; then
sudo apt-get install kibana=6.5.4
# kibana.yml
cat << EOF

EOF
fi

# Metricbeat
if [ "$metricbeat" ]; then 
  sudo apt-get install metricbeat=6.5.4 -y
fi