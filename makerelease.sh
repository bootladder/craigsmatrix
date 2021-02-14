#!/bin/bash
echo "make release dir (delete if exists)"
rm -rf release
mkdir release

echo cd into frontend
cd frontend-elm
echo build frontend
./runner.sh
echo copy main.js to release
cp main.js ../release
echo cd -
cd -

echo copy frontend-static into release
cp frontend-static/* release

echo cd into backend
cd backend
echo build backend
go test && go build 
echo copy backend to release
cp craigsmatrix ../release
cd -

echo "create data directory"
mkdir release/data

echo "tag the release" # nothing for now
rm -rf craigsmatrix
mv release craigsmatrix

echo "zip the release"
rm -f craigslistmatrix.zip
zip -r craigsmatrix.zip craigsmatrix

