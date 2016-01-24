#!/bin/bash
#Путь к файлу логов
LOGFILE=/var/log/backup.log
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

log "Начало бэкапа"
function main
{
if [[ $STATUS != 0 ]]; then
	log "Произошла ошибка! Бэкап не удался"
else	

	log "Остановка tomcat"
	cd $DIRROOT
	/opt/alfresco-4.2.f/alfresco.sh stop tomcat | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при остановке tomcat"
		log "Запуск tomcat"
			cd $DIRROOT
			/opt/alfresco-4.2.f/alfresco.sh start tomcat | adddate
			if [[ $? != 0 ]]; then
				log "Ошибка при запуске tomcat"
			fi		
		exit
	fi
	
	log "Копирование каталогов"
	cd /opt/alfresco-4.2.f/
	tar cfz /backup/files/$(date +"%Y%m%d.%H%M%S").tar.gz --exclude='postgresql/*' ./alf_data | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании каталогов"
		log "Запуск tomcat"
			cd $DIRROOT
			/opt/alfresco-4.2.f/alfresco.sh start tomcat | adddate
			if [[ $? != 0 ]]; then
				log "Ошибка при запуске tomcat"
			fi		
		exit
	fi
	
	log "Выгрузка базы"
	/opt/alfresco-4.2.f/postgresql/bin/pg_dump -w -U alfresco alfresco> /backup/sql/$(date +"%y-%m-%d_%H-%M-%S").sql | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании бызы"
		log "Запуск tomcat"
			cd $DIRROOT
			/opt/alfresco-4.2.f/alfresco.sh start tomcat | adddate
			if [[ $? != 0 ]]; then
				log "Ошибка при запуске tomcat"
			fi		
		exit
	fi
	
	log "Запуск tomcat"
	cd $DIRROOT
	/opt/alfresco-4.2.f/alfresco.sh start tomcat | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при запуске tomcat"
		exit
	fi	
	
	log "Копирование на удаленный сервер"
	rsync -zvr --exclude='weekly' /backup/ $BS::$BP | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании на удаленный сервер"
		exit
	fi	
	
	log "Удаляем все бэкапы кроме последнего"
	cd /backup/files/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/files/"
		exit
	fi
	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
	cd /backup/sql/
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/sql/"
		exit
	fi	
	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
	if [[ $? != 0 ]]; then
		log "Ошибка при удалении бэкапов"
		exit
	fi
fi	
log "Успешное окончание Бэкапа"
}

main 2>&1 | tee -a $LOGFILE

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/backup_log.tmp
mv -f /tmp/backup_log.tmp $LOGFILE
