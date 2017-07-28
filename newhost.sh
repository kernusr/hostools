#!/bin/bash

function getHostName() {
        echo -n "Введите имя нового хоста и нажмите [ENTER]: ";
        read NEWHOSTNMAE;
	if [ ${#NEWHOSTNMAE} == 0 ]; then
		echo "Имя хоста не может быть пустой строкой!";
		getHostName;
	else
		if ! hostRegExp "$NEWHOSTNMAE"; then
			echo "Имя хоста имеет неверный формат";
			echo -n "Ввести другое имя хоста? (y/n) "

			read item
			case "$item" in
				y|Y) getHostName
					;;
				n|N) echo "Выход"
					exit 0
					;;
				*) getHostName
					;;
			esac;
		fi;
	fi;
	NEWHOSTCONFIG=${NEWHOSTNMAE}.conf;
        checkHostName;
}

hostRegExp() {
    echo -n "$1" | grep -e \
        '^[a-z0-9]{4,36}$' \
        &>/dev/null
    return $?
}

function checkHostName() {
	if [ -f /etc/apache2/sites-available/${NEWHOSTCONFIG} || -f /etc/nginx/sites-available/${NEWHOSTCONFIG} ]; then
		echo "Такое имя хоста уже занято";
		echo -n "Ввести другое имя хоста? (y/n) "

		read item
		case "$item" in
			y|Y) getHostName
    			;;
    		n|N) echo "Выход"
				exit 0
				;;
    		*) getHostName
				;;
		esac;
	else
		getHostOwner;
	fi;
}

function nameRegExp() {
    echo -n "$1" | LANG=C grep -e '^[^-][a-z0-9-]{3,16}$' &>/dev/null
    return $?
}

function getHostOwner(){
	echo -n "Введите имя владельца нового хоста и нажмите [ENTER]: ";
	read HOSTOWNER;
	if [ ${#HOSTOWNER} == 0 ]; then
		echo "Имя пользователя не может быть пустой строкой!";
		getHostOwner;
	else
		if ! nameRegExp "${HOSTOWNER}"; then
			echo "Имя пользователя имеет неверный формат";
			echo -n "Ввести другое имя пользователя? (y/n) "

			read item
			case "$item" in
				y|Y) getHostOwner
					;;
				n|N) echo "Выход"
					exit 0
					;;
				*) getHostOwner
					;;
			esac;
		fi;
	fi;
	checkHostOwner;
}

function checkHostOwner() {
	grep ${HOSTOWNER} /etc/passwd >/dev/null
	if [ $? -ne 0 ]; then
		echo -n "Пользователя с именем "$HOSTOWNER" не существует. Создать?  (y/n) ";
		read item;
                case "$item" in
                        y|Y) echo "Пользователь будет владельцем"
				;;
                        n|N) echo "Выход"
                                exit 0
                                ;;
                        *) echo "Пользователь будет владельцем"
				;;
                esac;
        else
               	echo "Пользователь с именем "$HOSTOWNER" уже существует.";
		echo -n "Назначить этого пользователя владельцем хоста "$NEWHOSTNAME"?  (y/n) (n - ввести другое имя пользователя) ";
		read item;
                case "$item" in
                        y|Y) "Пользователь будет владельцем"
				;;
                        n|N) getHostOwner
                                ;;
                        *) "Пользователь будет владельцем"
				;;
                esac;
        fi;
}


getHostName;
