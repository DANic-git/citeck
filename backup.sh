#!/bin/bash
#Путь к файлу логов
LOGFILE=/var/log/backup
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

#>$LOGFILE

log "Начало бэкапа"
function main
{
if [[ $STATUS != 0 ]]; then
	log "Произошла ошибка! Бэкап не удался"
else	

	log "Остановка tomcat"
	cd $(DIRROOT)
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
	/opt/alfresco-4.2.f/postgresql/bin/pg_dump -w -U alfresco alfresco> /backup/sql/$(date +"%y-%m-%d_%H-%M-%S").sql
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании бызы"
		exit
	fi
	
	log "Копирование на удаленный сервер"
	rsync -zvr /backup/ $BS::$BP
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании на удаленный сервер"
		exit
	fi	
	
	log "Уждаляем все бэкапы кроме последнего"
	cd /backup/files/
	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
	cd /backup/sql/
	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
	if [[ $? != 0 ]]; then
		log "Ошибка при удалении бэкапов"
		exit
	fi
	
	log "Запуск tomcat"
	cd $(DIRROOT)
	/opt/alfresco-4.2.f/alfresco.sh start tomcat
	if [[ $? != 0 ]]; then
		log "Ошибка при запуске tomcat"
		exit
	fi	
fi	
}

main 2>&1 | tee -a $LOGFILE

log "Окончание Бэкапа"

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/backup_log.tmp
mv -f /tmp/backup_log.tmp $LOGFILE
