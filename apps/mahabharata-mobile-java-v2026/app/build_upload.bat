@echo off

set nowDate=%DATE:~6,4%_%DATE:~3,2%_%DATE:~0,2%

copy dev\release\app-dev-release.apk "w:\Share\Comics\comics_%nowDate%_dev.apk"
copy live\release\app-live-release.apk "w:\Share\Comics\comics_%nowDate%_live.apk"

@pause