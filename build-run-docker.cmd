@echo off

set TAG=springaad

docker build --tag %TAG% .

REM docker build --quiet . > .\imgid
REM set /p imageid=<.\imgid
REM del .\imgid
REM echo "Calling image %imageid%"

docker run ^
    -e "AAD_TENANT_ID=%AAD_TENANT_ID%" ^
    -e "AAD_CLIENT_ID=%AAD_CLIENT_ID%" ^
    -e "AAD_CLIENT_SECRET=%AAD_CLIENT_SECRET%" ^
    -e "AAD_GROUP=%AAD_GROUP%" ^
    -e "KEYVAULT_URI=%KEYVAULT_URI%" ^
    -p 8080:8080/tcp ^
    --interactive --tty --rm ^
    --entrypoint /bin/bash ^
    %TAG%

REM docker run ^
REM      -e "AAD_TENANT_ID=%AAD_TENANT_ID%" ^
REM      -e "AAD_CLIENT_ID=%AAD_CLIENT_ID%" ^
REM      -e "AAD_CLIENT_SECRET=%AAD_CLIENT_SECRET%" ^
REM      -e "AAD_GROUP=%AAD_GROUP%" ^
REM      -e "KEYVAULT_URI=%KEYVAULT_URI%" ^
REM      -p 8080:8080/tcp ^
REM      --interactive --tty --rm ^
REM      --entrypoint /bin/bash ^
REM      %TAG%

REM java -jar aaddemo.jar
REM java -Dhttp.proxyHost=192.168.0.6 -Dhttp.proxyPort=8888 -Dhttps.proxyHost=192.168.0.6 -Dhttps.proxyPort=8888 -Dcom.sun.net.ssl.checkRevocation=false -Dtrust_all_cert=true -jar aaddemo.jar
