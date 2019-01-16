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
sudo apt-get install elasticsearch=6.5.4 -y

# Metricbeat
sudo apt-get install metricbeat=6.5.4 -y

# Elasticsearch heap
sudo sed -i.bak 's/-Xmx1g/-Xmx256m/; s/-Xms1g/-Xms256m/' /etc/elasticsearch/jvm.options