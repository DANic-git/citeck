#!/bin/bash
#Путь к файлу логов
LOGFILE=/var/log/sender.log
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

log "Начало передачи файлов"
function main
{
if [[ $STATUS != 0 ]]; then
	log "Произошла ошибка! передача не удался"
else	

	log "Копирование на удаленный сервер"
	rsync -zvr /backup/$(echo $BP) $BS::$BP | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании на удаленный сервер"
		exit
	fi	
	
	log "Удаляем все бэкапы кроме последнего"
	cd /backup/$(echo $BP)
	if [[ $? != 0 ]]; then
		log "Нет каталога /backup/$(echo $BP)"
		exit
	fi
	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
	
fi	
log "Успешное окончание передачи файлов"
}

main 2>&1 | tee -a $LOGFILE

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/sender_log.tmp
mv -f /tmp/sender_log.tmp $LOGFILE
