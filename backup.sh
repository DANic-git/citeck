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
	
	log "Копирование каталогов"
	cd /opt/alfresco-4.2.f/
	tar cfz /backup/files/$(date +"%y-%m-%d_%H-%M-%S").tar.gz --exclude='postgresql/*' ./alf_data
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании каталогов"
		exit
	fi
	
	log "Выгрузка базы"
	/opt/alfresco-4.2.f/postgresql/bin/pg_dump -w alfresco> /backup/sql/$(date +"%y-%m-%d_%H-%M-%S").sql
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании бызы"
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