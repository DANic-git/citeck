#!/bin/bash
#Путь к файлу логов
LOGFILE=/var/log/remove.log
#Код с которым была завершена предыдущая команда. Если команда была выполнена удачно, то значение этой переменной будет 0, если же неудачно то не 0. 
STATUS=$?
#Первый парамт Backup Server второй Backup Patch
BS=$1
BP=$2

#Директория скрипта
DIRROOT=$(cd $(dirname $0) && pwd)

#Вывод текущей даты и времени
log(){
   message="$(date +"%y-%m-%d %T") $@"
   #echo $message
   echo $message >>$LOGFILE
}
adddate() {
    while IFS= read -r line; do
        echo "$(date +"%y-%m-%d %T") $line"
    done
}

#>$LOGFILE

log "Начало удаления стары бэкапов"
function main
{
if [[ $STATUS != 0 ]]; then
	log "Произошла ошибка! удаление не удалось"
else	

	log "Удаляем бэкапы artifactory кроме последних трех"
	cd /backup/artifactory/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 4)printf("%s ",$9);}'`
	fi
  
	log "Удаляем бэкапы jenkins кроме последних трех"
	cd /backup/jenkins/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 4)printf("%s ",$9);}'`
	fi  
	
	log "Удаляем ежедневные бэкапы alfresco на citeck.ecos365.ru кроме последних двух"
	cd /backup/citeck.ecos365.ru/files/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/citeck.ecos365.ru/files/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'`
	fi
	cd /backup/citeck.ecos365.ru/sql/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/citeck.ecos365.ru/sql/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'`
	fi

	log "Удаляем еженедельные бэкапы alfresco на citeck.ecos365.ru кроме последних двух"
	cd /backup/citeck.ecos365.ru/weekly/files/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/citeck.ecos365.ru/weekly/files/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'`		
	fi
	cd /backup/citeck.ecos365.ru/weekly/sql/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/citeck.ecos365.ru/weekly/sql/"
		exit
	else
	rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'`	
	fi
	
fi	
log "Успешное удаление бэкапов"
}

main 2>&1 | tee -a $LOGFILE

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/sender_log.tmp
mv -f /tmp/sender_log.tmp $LOGFILE
