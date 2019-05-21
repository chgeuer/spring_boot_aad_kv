@echo off

docker build         .
docker build --quiet . > imgid
set /p imageid=<imgid
del imgid

docker run ^
    -e "AAD_TENANT_ID=%AAD_TENANT_ID%" ^
    -e "AAD_CLIENT_ID=%AAD_CLIENT_ID%" ^
    -e "AAD_CLIENT_SECRET=%AAD_CLIENT_SECRET%" ^
    -e "AAD_GROUP=%AAD_GROUP%" ^
    -p 8080:8080/tcp ^
    --interactive --tty --rm ^
    %imageid%

REM docker run -e "AAD_TENANT_ID=%AAD_TENANT_ID%" -e "AAD_CLIENT_ID=%AAD_CLIENT_ID%" -e "AAD_CLIENT_SECRET=%AAD_CLIENT_SECRET%" -e "AAD_GROUP=%AAD_GROUP%"  -p 8080:8080/tcp  --interactive --tty --rm  943f82a62463

REM docker run -e "AAD_TENANT_ID=%AAD_TENANT_ID%" -e "AAD_CLIENT_ID=%AAD_CLIENT_ID%" -e "AAD_CLIENT_SECRET=%AAD_CLIENT_SECRET%" -e "AAD_GROUP=%AAD_GROUP%"  -p 8080:8080/tcp  --interactive --tty --rm --entrypoint /bin/bash 943f82a62463
REM java -jar aaddemo.jar

REM java -Dhttp.proxyHost=192.168.0.6 -Dhttp.proxyPort=8888 -Dhttps.proxyHost=192.168.0.6 -Dhttps.proxyPort=8888 -Dcom.sun.net.ssl.checkRevocation=false -Dtrust_all_cert=true -jar aaddemo.jar
