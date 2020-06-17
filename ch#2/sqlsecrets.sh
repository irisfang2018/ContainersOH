kubectl create secret generic mydbsecrets \
--from-literal=SQL_USER='xx' \
--from-literal=SQL_PASSWORD='xxx#' \
--from-literal=SQL_SERVER='xxxx.database.windows.net' \
--from-literal=SQL_DBNAME='mydrivingDB'

#--namespace api   
