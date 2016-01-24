#!/bin/bash
#Путь к файлу логов
LOGFILE=/var/log/backup.jenkins.log
#Код с которым была завершена предыдущая команда. Если команда была выполнена удачно, то значение этой переменной будет 0, если же неудачно то не 0. 
STATUS=$?

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

log "Начало бэкапа Jenkins"
function main
{

	if [[ $STATUS != 0 ]]; then
		log "Произошла ошибка! Бэкап не удался"
		exit
	fi

	log "архивирование в папку /backup/jenkins"
	tar cfz /backup/jenkins/$(date +"%Y%m%d.%H%M%S").tar.gz /var/lib/jenkins/ | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при архивировании"
		exit
	fi	

}

main 2>&1 | tee -a $LOGFILE

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/sender_log.tmp
mv -f /tmp/sender_log.tmp $LOGFILE
