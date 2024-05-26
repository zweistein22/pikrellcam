wget https://www.php.net/distributions/php-7.4.33.tar.gz
tar -xf php-7.4.33.tar.gz
cd php-7.4.33
sudo apt-get install -y libxml2-dev libsqlite3-dev
./configure
./make -j4
sudo make install

