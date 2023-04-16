#!/bin/sh

git clone -b tool --depth 1 https://github.com/kewlbear/FFmpeg-iOS tool
cd tool

swift run

TAG=v0.0.6-`date +b%Y%m%d-%H%M%S`

cp ../Package.swift .

for f in Frameworks/*.xcframework
do
	f=`basename $f .xcframework`
	echo $f...
	rm Package.swift.in
	mv Package.swift Package.swift.in
	sed "s#/download/[^/]*/$f\.zip[^)]*#/download/$TAG/$f.zip\", checksum: \"`swift package compute-checksum Frameworks/$f.zip`\"#" Package.swift.in > Package.swift
done

rm ../Package.swift
mv Package.swift ..

echo "::set-output name=tag::$TAG"
