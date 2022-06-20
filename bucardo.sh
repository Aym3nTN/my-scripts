# nstall and configure PostgreSQL on the EC2 instance

su - postgres
psql -c "alter user postgres with password 'postgres_admin'"

psql -c "CREATE USER bucardo WITH LOGIN SUPERUSER ENCRYPTED PASSWORD 'bucardo_admin';" 
psql -c "CREATE DATABASE bucardo OWNER bucardo;"

# Install Bucardo on the EC2 instance
curl https://bucardo.org/downloads/Bucardo-5.6.0.tar.gz -o Bucardo-5.6.0.tar.gz && \
tar -xvf Bucardo-5.6.0.tar.gz && \
cd Bucardo-5.6.0 && \
perl Makefile.PL && \
apt install make && \
make && make install && \
export PATH=/usr/local/bin/bucardo:$PATH

# Perl module DBIx::Safe:
apt-get install -y libdbix-safe-perl libdbd-pg-perl


# Configure Bucardo

mkdir -p /var/log/bucardo /var/run/bucardo 

chown $USER:$USER /var/log/bucardo /var/run/bucardo

echo -e "host\tall\tbucardo\t127.0.0.1/32\ttrust\n$(cat /etc/postgresql/13/main/pg_hba.conf)" > /etc/postgresql/13/main/pg_hba.conf

cat > ~/.bucardorc <<EOL
dbhost=127.0.0.1
dbport=5432
dbuser=bucardo
dbname=bucardo
EOL

bucardo install


# Install pgdatadiff on the EC2 instance

apt-get install -y libpq-dev gcc && \
git clone https://github.com/andrikoz/pgdatadiff.git && \
cd pgdatadiff && \
python3 setup.py install

# Stuff connection info into pgpass file on Bucardo instance
echo "" > ~/.pgpass && \
cat >> ~/.pgpass <<EOF
$BUCARDO_OLD_HOSTNAME:5432:*:$BUCARDO_OLD_USERNAME:$BUCARDO_OLD_PASSWORD
$BUCARDO_NEW_HOSTNAME:5432:*:$BUCARDO_NEW_USERNAME:$BUCARDO_NEW_PASSWORD
EOF

chmod 0600 ~/.pgpass

# Create dbmigrationuser on new cluster, it might be said
su - postgres
psql -c "create user dbmigrationuser with encrypted password bD6TSsBAA4TXYG2y valid until 'infinity';"
grant rds_superuser to dbmigrationuser;
