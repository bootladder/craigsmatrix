#!/bin/bash
echo make release dir
mkdir release

echo cd into frontend
cd frontend
echo build frontend
./runner.sh
echo cd -
cd -
echo copy all frontend into release
cp -R frontend release

echo cd into backend
cd backend
echo build backend
go test && go build 
echo copy backend to release
cp craigsmatrix ../release
cd -

echo "create data directory (delete if exists)"
rm -rf release/data
mkdir release/data



