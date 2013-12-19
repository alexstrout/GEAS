@Echo off
hg archive --repository .\ -r . -t files -- .\SimContent
echo.
pause
