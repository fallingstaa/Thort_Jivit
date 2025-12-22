@echo off
REM Deploy enhanced recap Cloud Function
echo Deploying createEnhancedRecap Cloud Function...
firebase deploy --only functions:createEnhancedRecap

