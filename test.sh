#!/bin/bash

b=$(tput bold);
eb=$(tput sgr0);
errCounter=0;

function strLen(){
	return ${#1};
}

function exitWithError(){
	clear;
	echo "Я уже говорил тебе,что такое безумие,а?"; sleep 0.58;
	echo "Безумие-это точное повторение одного и того же действия."; sleep 0.75;
	echo "Раз за разом,в надежде на изменение."; sleep 0.55;
	echo "Это есть безумие."; sleep 0.36;
	echo "Куда ни глянь, все делают точно одно и то же,снова и снова и снова и снова и снова."; sleep 1.2;
	echo "И думают:Сейчас все изменится."; sleep 0.49;
	echo "Не-не-не,прошу."; sleep 0.34;
	echo "Сейчас все будет иначе."; sleep 0.42;
	echo "Прости."; sleep 0.26;
	exit 1
}

function matchHostName() {
    echo -n "$1" | grep -E '^[a-z]{1}[a-z|0-9|\-|\.]{2,23}$' &>/dev/null;
	return $?;
}

function checkHost() {
	[[ -f /etc/apache2/sites-available/"$1".conf || -f /etc/nginx/sites-available/"$1".conf ]] &>/dev/null;
	return $?;
}

function getHostName(){
	if [ $errCounter -eq 5 ]; then exitWithError; fi;
	echo -n "Введите имя хоста и нажмите [ENTER]: ";
	read STR;
	if ! strLen $STR; then
		if ! matchHostName "$STR"; then
			echo "Неверный формат имени хоста";
			echo "Имя хоста должно начинаться с буквы и может содержать только:${b}";
			echo "буквы латинского алвафита [a-z] в нижнем регистре, ";
			echo "цыфры [0-9],";
			echo "знак \"-\" ";
			echo "и точку.";
			echo "${eb}";
			errCounter=$[errCounter + 1];
			getHostName;
		else
			if ! checkHost "$STR"; then
				NEWHOST=$STR;
				errCounter=0;
				getHostOwner;
			else
				echo "Такое имя хоста уже занято";
				echo -n "Ввести другое имя хоста? (Y/n) "

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
	else
		echo "Имя хоста не может быть пустой строкой";
		errCounter=$[errCounter + 1];
		getHostName;
	fi;
}

function matchHostOwner(){
    echo -n "$1" | grep -E '^[a-z]{1}[a-z|0-9|\-]{2,23}$' &>/dev/null;
	return $?;
}
function checkOwner(){
	grep "$1" /etc/passwd &>/dev/null;
	return $?;
}

function getHostOwner(){
	if [ $errCounter -eq 5 ]; then exitWithError; fi;
	echo -n "Введите имя владельца для хоста \"${b}$NEWHOST${eb}\" и нажмите [ENTER]: ";
	read STR;
	if ! strLen $STR; then
		if ! matchHostOwner "$STR"; then
			echo "Неверный формат имени пользователя";
			echo "Имя пользователя должно начинаться с буквы и может содержать только:${b}";
			echo "буквы латинского алвафита [a-z] в нижнем регистре, ";
			echo "цыфры [0-9],";
			echo "и знак \"-\" ";
			echo "${eb}";
			errCounter=$[errCounter + 1];
			getHostOwner;
		else
			if ! checkOwner "$STR"; then
				echo -n "Пользователя с именем \"${b}$STR${eb}\" не существует. Создать?  (Y/n) ";
				read item;
                case "$item" in
					y|Y) echo "Пользователь будет владельцем";
						HOSTOWNER="$STR";
						errCounter=0;
						createHostOwner;
						;;
					n|N) echo "Выход"
						exit 0
						;;
					*) echo "Пользователь будет владельцем";
						HOSTOWNER="$STR";
						errCounter=0;
						createHostOwner "$STR";
						;;
                esac;
				# HOSTOWNER="$STR";
				# errCounter=0;
				# getHostOwnerPass;
			else
				if [ $(id "$STR" | sed 's/.*uid=\([0-9]*\).*/\1/') -le "1000" ]; then 
					echo "Пользователь с именем \"${b}$STR${eb}\" является системным пользователем.";
					echo "Нельзя назначть системных пользователей владельцем хоста";
					errCounter=$[errCounter + 1];
					getHostOwner;
				else
					echo "Пользователь с именем \"${b}$STR${eb}\" уже существует.";
					echo -n "Назначить этого пользователя владельцем хоста \"${b}$NEWHOST${eb}\"?  (Y/n) (n - ввести другое имя пользователя) ";
					read item;
					case "$item" in
						y|Y) echo "Пользователь будет владельцем";
							;;
						n|N) getHostOwner
							;;
						*) 	echo "Пользователь будет владельцем";
							;;
					esac;
				fi;				
			fi;
		fi;
	else
		echo "Имя пользователя не может быть пустой строкой";
		errCounter=$[errCounter + 1];
		getHostOwner;
	fi;
}

function matchOwnerPass() {
    echo -n "$1" | grep -E '^[^а-яА-Я](.*){6,}$' &>/dev/null;
	return $?;
}

function createHostOwner() {
	if [ $errCounter -eq 5 ]; then exitWithError; fi;
	echo -n "Укажите пароль для пользователя \"${b}$1${eb}\"";
	PASSWORD=""
	while
	read -s -n1 BUFF
	[[ -n $BUFF ]]
	do
		# 127 - backspace ascii code
		if [[ `printf "%d\n" \'$BUFF` == 127 ]]
		then
		PASSWORD="${PASSWORD%?}"
		echo -en "\b \b"
		else
		PASSWORD=$PASSWORD$BUFF
		echo -en "*"
		fi
	done
	echo;
	if ! matchOwnerPass "$PASSWORD"; then
		echo "Неверный формат пароля";
		errCounter=$[errCounter + 1];
		createHostOwner "$1";
	else
		echo $PASSWORD
	fi;
}
getHostName

exit 0