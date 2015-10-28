#!/bin/bash
LOGFILE=/var/log/backup
STATUS=$?


log(){
   message="$(date +"%y-%m-%d %T") $@"
   #echo $message
   echo $message >>$LOGFILE
}

>$LOGFILE

log "Начало копирования файлов"
function main
{
if [[ $STATUS != 0 ]]; then
	log "Произошла ошибка! Бэкап не удался"
else	
	log "Остановка tomcat"
	/opt/alfresco-4.2.f/alfresco.sh stop tomcat
	if [[ $? != 0 ]]; then
		log "Ошибка при остановке tomcat"
		exit
	fi
	cd /opt/alfresco-4.2.f/
	tar cfz /backup/files/$(date +"%y-%m-%d_%T").tar.gz ./alf_data
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании каталогов"
		exit
	fi
	log "Запуск tomcat"
	/opt/alfresco-4.2.f/alfresco.sh start tomcat
	if [[ $? != 0 ]]; then
		log "Ошибка при запуске tomcat"
		exit
	fi	
fi	
}

main 2>&1 | tee -a $LOGFILE

log "Окончание копирования файлов"