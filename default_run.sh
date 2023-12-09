curl https://binaries.cockroachdb.com/cockroach-v23.1.11.linux-amd64.tgz | tar -xz && sudo cp -i cockroach-v23.1.11.linux-amd64/cockroach /usr/local/bin/
sudo mkdir -p /usr/local/lib/cockroach
cp -i cockroach-v23.1.11.linux-amd64/lib/libgeos.so /usr/local/lib/cockroach/
cp -i cockroach-v23.1.11.linux-amd64/lib/libgeos_c.so /usr/local/lib/cockroach/
cockroach version