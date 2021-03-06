#FROM ubuntu:focal

#export DEBIAN_FRONTEND=noninteractive

#sudo -i
export INSTALL_DIR=`pwd`
apt-get update && apt-get install --no-install-recommends -y software-properties-common
apt-get update && apt-get install --no-install-recommends -q -y \
    bzip2 \
    git \
    wget \
    sudo \
    nano \
    screen \
    gcc \
    nginx \
    python3 \
    libjpeg-dev \
    redis-server \
    supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


#postgress
#sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
#wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt-get update
apt-get -y install postgresql-12
apt-get -y install postgresql-client postgresql-server-dev-all

# python3
add-apt-repository ppa:deadsnakes/ppa -y
apt-get -y install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
apt-get -y install \
    python3.6 \
    python3.6-dev \
    python3-pip \
    python3-vexport

python3.6 -m pip install --upgrade pip
pip3 install virtualenv
#ffmpeg
add-apt-repository ppa:jonathonf/ffmpeg-4 -y
apt-get update
apt-get install -y ffmpeg

sed -i "s/bind .*/bind 127.0.0.1/g" /etc/redis/redis.conf

mkdir -p /opt/zou /var/log/zou /opt/zou/previews
chown zou: /opt/zou

git config --global --add advice.detachedHead false
git clone -b 0.12.63-build --single-branch --depth 1 https://github.com/cgwire/kitsu.git /opt/zou/kitsu

# setup.py will read requirements.txt in the current directory
cd /opt/zou
useradd --home /opt/zou zou 
# python3 -m vexport /opt/zou/export && \
/opt/zou/export/bin/pip install --upgrade pip setuptools wheel && \
/opt/zou/export/bin/pip install zou==0.12.68 && \
rm -rf /root/.cache/pip/

cd /opt/zou

# Create database
su postgres

service postgresql start && \
    createuser root && createdb -T template0 -E UTF8 --owner root root && \
    createdb -T template0 -E UTF8 --owner root zoudb && \
    service postgresql stop

exit
#sudo -i

# Wait for the startup or shutdown to complete
export PG_VERSION=12
cp pg_ctl.conf /etc/postgresql/${PG_VERSION}/main/pg_ctl.conf
chown postgres:postgres /etc/postgresql/${PG_VERSION}/main/pg_ctl.conf
chmod 0644 /etc/postgresql/${PG_VERSION}/main/pg_ctl.conf
cp postgresql-log.conf /etc/postgresql/${PG_VERSION}/main/conf.d/postgresql-log.conf
chown postgres:postgres /etc/postgresql/${PG_VERSION}/main/conf.d/postgresql-log.conf
chmod 0644 /etc/postgresql/${PG_VERSION}/main/conf.d/postgresql-log.conf


cp gunicorn /etc/zou/gunicorn.conf
cp gunicorn-events /etc/zou/gunicorn-events.conf

cp nginx.conf /etc/nginx/sites-available/zou
ln -s /etc/nginx/sites-available/zou /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

cp supervisord.conf /etc/supervisord.conf

export DB_USERNAME=root
cp init_zou.sh /opt/zou/
cp start_zou.sh /opt/zou/
chmod +x /opt/zou/init_zou.sh /opt/zou/start_zou.sh

echo Initialising Zou... && \
    /opt/zou/init_zou.sh

#EXPOSE 80
#VOLUME ["/var/lib/postgresql", "/opt/zou/previews"]
/opt/zou/start_zou.sh
