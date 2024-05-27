#!/bin/bash

PGM=`basename $0`

if [ `id -u` == 0 ]
then
    echo -e "$PGM should not be run as root.\n"
    exit 1
fi
NEW_PHP_VERSION=7.4.33

# Function to check PHP version
check_php_version() {
    if command -v php > /dev/null 2>&1; then
        PHP_VERSION=$(php -v | grep -oP '^PHP \K[\d.]+')
		echo "$PHP_VERSION found."
        if [ "$PHP_VERSION" == "$NEW_PHP_VERSION" ]; then
            echo "$NEW_PHP_VERSION is already installed."
            read -p "reinstall? (y/n) " choice
            case "$choice" in 
              y|Y ) return 1;;
              n|N ) return 0;;
              * ) echo "Invalid choice. Exiting."; exit 1;;
            esac
        else
            echo "Different PHP version $PHP_VERSION"
		fi
            read -p "Do you want to uninstall the current PHP version and install $NEW_PHP_VERSION? (y/n) " choice
            case "$choice" in 
              y|Y ) echo "Uninstalling current PHP version...";return 1;;
              n|N ) echo "keep current php $PHP_VERSION";return 0;;
              * ) echo "Invalid choice. Exiting."; exit 1;;
            esac
        fi
    else
        echo "PHP is not installed. Installing PHP $NEW_PHP_VERSION...";return 1;;
    fi
}

# Function to uninstall current PHP version
uninstall_php() {
    echo "Uninstalling current PHP version..."
    sudo apt-get purge -y php*
    sudo apt-get autoremove -y
    sudo rm -rf /etc/php /usr/local/php
	sudo systemctl stop php-fpm
	sudo rm /etc/systemd/system/php-fpm.service
    # Create symlinks for php and php-fpm
    sudo rm /usr/bin/php
    sudo rm /usr/sbin/php-fpm
}

# Function to install PHP 7.4
install_php_7_4() {
    sudo apt update
    sudo apt install -y \
        autoconf \
        bison \
        build-essential \
        curl \
        libxml2-dev \
        libsqlite3-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libjpeg-dev \
        libpng-dev \
        libonig-dev \
        libreadline-dev \
        libfreetype6-dev \
        libzip-dev \
        pkg-config \
        re2c

    # Download PHP 7.4 source
   
    curl -O https://www.php.net/distributions/php-$NEW_PHP_VERSION.tar.gz
    tar -xzvf php-$NEW_PHP_VERSION.tar.gz
    cd php-$NEW_PHP_VERSION

    # Configure and install
    ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php --enable-mbstring --with-curl --with-openssl --with-zlib --with-pdo-mysql --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --enable-mbstring --with-readline --with-zip
    make -j$(nproc)
    sudo make install

    # Set up PHP-FPM as a service
    sudo cp sapi/fpm/php-fpm.service /etc/systemd/system/
    sudo systemctl enable php-fpm
    sudo systemctl start php-fpm

    # Create symlinks for php and php-fpm
    sudo ln -s /usr/local/php/bin/php /usr/bin/php
    sudo ln -s /usr/local/php/sbin/php-fpm /usr/sbin/php-fpm
	cd ..  # on ~/user/pikrellcam  now
	rm -rf php-$NEW_PHP_VERSION.tar.gz
	rm -rf php-$NEW_PHP_VERSION

    echo "PHP $NEW_PHP_VERSION installation is complete."
}




bad_install()
	{
	echo "Cannot find $1 in $PWD"
	echo "Are you running $PGM in the install directory?"
	exit 1
	}

cd src
make -j4
cd ..

if [ ! -x $PWD/pikrellcam ]
then
	bad_install "program pikrellcam"
fi

if [ ! -d $PWD/www ]
then
	bad_install "directory www"
fi

sudo chown .www-data $PWD/www
sudo chmod 775 $PWD/www

if [ ! -d media ]
then
	mkdir media media/archive media/videos media/thumbs media/stills
	sudo chown .www-data media media/archive media/videos media/thumbs media/stills
	sudo chmod 775 media media/archive media/videos media/thumbs media/stills
fi

if [ ! -h www/media ]
then
	ln -s $PWD/media www/media
fi

if [ ! -h www/archive ]
then
	ln -s $PWD/media/archive www/archive
fi

echo ""
echo "Set the port for the nginx web server."
echo "If you already have a web server configuration using the default"
echo "port 80, you should enter an alternate port for PiKrellCam."
echo "Otherwise you can use the default port 80 or an alternate as you wish."
echo "The port number will be set in: /etc/nginx.sites-available/pikrellcam."
echo -n "Enter web server port: "
read resp
if [ "$resp" == "" ]
then
	PORT=80
else
	PORT=$resp
fi

echo ""
echo "For auto starting at boot, a PiKrellCam start command must be in rc.local."
echo "If you don't start at boot, PiKrellCam can always be started and stopped"
echo "from the web page."
echo -n "Do you want PiKrellCam to be auto started at boot? (yes/no): "
read resp
if [ "$resp" == "y" ] || [ "$resp" == "yes" ]
then
	AUTOSTART=yes
else
	AUTOSTART=no
fi


HTPASSWD=www/.htpasswd
PASSWORD=""

echo ""
if [ -f $HTPASSWD ]
then
	echo "A web password is already set."
	echo -n "Do you want to change the password (yes/no)? "
	read resp
	if [ "$resp" == "y" ] || [ "$resp" == "yes" ]
	then
		SET_PASSWORD=yes
		rm -f $HTPASSWD
	else
		SET_PASSWORD=no
	fi
else
	SET_PASSWORD=yes
fi

if [ "$SET_PASSWORD" == "yes" ]
then
	echo "Enter a password for a web page login for user: $USER"
	echo "Enter a blank entry if you do not want the password login."
	echo -n "Enter password: "
	read PASSWORD
fi




echo ""
echo "Starting PiKrellCam install..."

# =============== apt install needed packages ===============
#
JESSIE=8
STRETCH=9
BUSTER=10

V=`cat /etc/debian_version`
#DEB_VERSION="${V:0:1}"
# Strip all chars after decimal point
DEB_VERSION="${V%.*}"

PACKAGE_LIST=""
if ((DEB_VERSION > BUSTER))
then
    echo "linux version not supported. Must be BUSTER or less."
	echo "install failed."
	exit 1
	AV_PACKAGES=""
	PHP_PACKAGES=""
elif ((DEB_VERSION >= BUSTER))
then
    echo "BUSTER detected."
	AV_PACKAGES="ffmpeg"
	PHP_PACKAGES=""
	if check_php_version; then
       uninstall_php
       install_php_7_4
	fi
elif ((DEB_VERSION >= STRETCH))
then
	AV_PACKAGES="libav-tools"
	PHP_PACKAGES="php7.0 php7.0-common php7.0-fpm"
else
	AV_PACKAGES="libav-tools"
	PHP_PACKAGES="php5 php5-common php5-fpm"
fi

for PACKAGE in $PHP_PACKAGES $AV_PACKAGES
do
	if ! dpkg -s $PACKAGE 2>/dev/null | grep Status | grep -q installed
	then
		PACKAGE_LIST="$PACKAGE_LIST $PACKAGE"
	fi
done

for PACKAGE in gpac nginx bc \
	sshpass mpack imagemagick apache2-utils libasound2 libasound2-dev \
	libmp3lame0 libmp3lame-dev
do
	if ! dpkg -s $PACKAGE 2>/dev/null | grep Status | grep -q installed
	then
		PACKAGE_LIST="$PACKAGE_LIST $PACKAGE"
	fi
done

if [ "$PACKAGE_LIST" != "" ]
then
	echo "Installing packages: $PACKAGE_LIST"
	echo "Running: apt-get update"
	sudo apt-get update
	sudo apt-get install -y --no-install-recommends $PACKAGE_LIST
else
	echo "No packages need to be installed."
fi


if ((DEB_VERSION < JESSIE))
then
	if ! dpkg -s realpath 2>/dev/null | grep Status | grep -q installed
	then
		echo "Installing package: realpath"
		sudo apt-get install -y --no-install-recommends realpath
	fi
fi


if [ ! -h /usr/local/bin/pikrellcam ]
then
    echo "Making /usr/local/bin/pikrellcam link."
	sudo rm -f /usr/local/bin/pikrellcam
    sudo ln -s $PWD/pikrellcam /usr/local/bin/pikrellcam
else
    CURRENT_BIN=`realpath /usr/local/bin/pikrellcam`
    if [ "$CURRENT_BIN" != "$PWD/pikrellcam" ]
    then
    echo "Replacing /usr/local/bin/pikrellcam link"
        sudo rm /usr/local/bin/pikrellcam
        sudo ln -s $PWD/pikrellcam /usr/local/bin/pikrellcam
    fi
fi


# =============== create initial ~/.pikrellcam configs ===============
#
./pikrellcam -quit

if [ "$USER" == "pi" ]
then
	rm -f www/user.php
else
	printf "<?php
    \$e_user = "$USER";
?>
" > www/user.php
fi

# =============== set install_dir in pikrellcam.conf ===============
#
PIKRELLCAM_CONF=$HOME/.pikrellcam/pikrellcam.conf
if [ ! -f $PIKRELLCAM_CONF ]
then
	echo "Unexpected failure to create config file $HOME/.pikrellcam/pikrellcam.conf"
	exit 1
fi

if ! grep -q "install_dir $PWD" $PIKRELLCAM_CONF
then
	echo "Setting install_dir config line in $PIKRELLCAM_CONF:"
	echo "install_dir $PWD"
	sed -i  "/install_dir/c\install_dir $PWD" $PIKRELLCAM_CONF
fi


# =============== pikrellcam autostart to rc.local  ===============
#
#CMD="su $USER -c '(sleep 5; \/home\/pi\/pikrellcam\/pikrellcam)  \&'"
CMD="su $USER -c '(sleep 5; $PWD/pikrellcam) \&'"

if [ "$AUTOSTART" == "yes" ]
then
    if ! fgrep -q "$CMD" /etc/rc.local
    then
		if grep -q pikrellcam /etc/rc.local
		then
			sudo sed -i "/pikrellcam/d" /etc/rc.local
		fi
		echo "Adding a pikrellcam autostart command to /etc/rc.local:"
        sudo sed -i "s|^exit.*|$CMD\n&|" /etc/rc.local
		if ! [ -x /etc/rc.local ]
		then
			echo "Added execute permission to /etc/rc.local"
			sudo chmod a+x /etc/rc.local
		fi
		grep pikrellcam /etc/rc.local
    fi
else
	if grep -q pikrellcam /etc/rc.local
	then
		echo "Removing pikrellcam autostart line from /etc/rc.local."
		sudo sed -i "/pikrellcam/d" /etc/rc.local
	fi
fi


# ===== sudoers permission for www-data to run pikrellcam as pi ======
#
CMD=$PWD/pikrellcam
if ! grep -q "$CMD" /etc/sudoers.d/pikrellcam 2>/dev/null
then
	echo "Adding to /etc/sudoers.d: www-data permission to run pikrellcam as user $USER:"
	cp etc/pikrellcam.sudoers /tmp/pikrellcam.sudoers.tmp
	sed -i "s|pikrellcam|$CMD|" /tmp/pikrellcam.sudoers.tmp
	sed -i "s/USER/$USER/" /tmp/pikrellcam.sudoers.tmp
	sudo chown root.root /tmp/pikrellcam.sudoers.tmp
	sudo chmod 440 /tmp/pikrellcam.sudoers.tmp
	sudo mv /tmp/pikrellcam.sudoers.tmp /etc/sudoers.d/pikrellcam
#	sudo cat /etc/sudoers.d/pikrellcam
fi

# =============== Setup Password  ===============
#
OLD_SESSION_PATH=www/session
if [ -d $OLD_SESSION_PATH ]
then
	sudo rm -rf $OLD_SESSION_PATH
fi

OLD_PASSWORD=www/password.php
if [ -f $OLD_PASSWORD ]
then
	rm -f $OLD_PASSWORD
fi

if [ "$PASSWORD" != "" ]
then
	htpasswd -bc $HTPASSWD $USER $PASSWORD
	sudo chown $USER.www-data $HTPASSWD
fi


# =============== nginx install ===============
#
# Logging can eat many tens of megabytes of SD card space per day
# with the mjpeg.jpg streaming
#
if ! grep -q "access_log off" /etc/nginx/nginx.conf
then
	echo "Turning off nginx access_log."
	sudo sed -i  '/access_log/c\	access_log off;' /etc/nginx/nginx.conf
fi

if ((DEB_VERSION < JESSIE))
then
	NGINX_SITE=etc/nginx-wheezy-site-default
else
	NGINX_SITE=etc/nginx-jessie-site-default
fi

echo "Installing /etc/nginx/sites-available/pikrellcam"
echo "    nginx web server port: $PORT"
echo "    nginx web server root: $PWD/www"
sudo cp $NGINX_SITE /etc/nginx/sites-available/pikrellcam
sudo sed -i "s|PIKRELLCAM_WWW|$PWD/www|; \
			s/PORT/$PORT/" \
			/etc/nginx/sites-available/pikrellcam

if ((DEB_VERSION >= BUSTER))
then
	sudo sed -i "s/php5/php\/php7.4/" /etc/nginx/sites-available/pikrellcam
elif ((DEB_VERSION >= STRETCH))
then
	sudo sed -i "s/php5/php\/php7.0/" /etc/nginx/sites-available/pikrellcam
fi

NGINX_SITE=/etc/nginx/sites-available/pikrellcam

if [ "$PORT" == "80" ]
then
	NGINX_LINK=/etc/nginx/sites-enabled/default
	CURRENT_SITE=`realpath $NGINX_LINK`
	if [ "$CURRENT_SITE" != "$NGINX_SITE" ]
	then
		echo "Changing $NGINX_LINK link to pikrellcam"
		sudo rm -f $NGINX_LINK
		sudo ln -s $NGINX_SITE $NGINX_LINK
	fi
else
	NGINX_LINK=/etc/nginx/sites-enabled/pikrellcam
fi

if [ ! -h $NGINX_LINK 2>/dev/null ]
then
	echo "Adding $NGINX_LINK link to sites-available/pikrellcam."
	sudo ln -s $NGINX_SITE $NGINX_LINK
fi

if [ ! -f $HTPASSWD ]
then
	echo "A password for the web page is not set."
	sudo sed -i 's/auth_basic/\# auth_basic/' $NGINX_SITE
fi

sudo service nginx restart


# =============== Setup FIFO  ===============
#
fifo=$PWD/www/FIFO

if [ ! -p "$fifo" ]
then
	rm -f $fifo
	mkfifo $fifo
fi
sudo chown $USER.www-data $fifo
sudo chmod 664 $fifo



# =============== copy scripts-dist into scripts  ===============
#
if [ ! -d scripts ]
then
	mkdir scripts
fi

cd scripts-dist

for script in *
do
	if [ ! -f ../scripts/$script ] && [ "${script:0:1}" != "_" ]
	then
		cp $script ../scripts 
	fi
done

echo ""
echo "Install finished."
echo "This install script does not automatically start pikrellcam."
echo "To start pikrellcam, open a browser page to:"
if [ "$PORT" == "80" ]
then
	echo "    http://your_pi"
else
	echo "    http://your_pi:$PORT"
fi
echo "and click on the \"System\" panel and then the \"Start PiKrellCam\" button."
echo "PiKrellCam can also be run from a Pi terminal for testing purposes."
if [ "$AUTOSTART" == "yes" ]
then
	echo "Automatic pikrellcam starting at boot is enabled."
fi
echo ""
