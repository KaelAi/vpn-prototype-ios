unzip "*.zip"
rm *.zip

b='log'
for dir in $(ls)
    do
    a=${dir##*.}
    if test $b = $a
    then
        sed -i "" "/WARN\*\*\*\*\*-->/d" $dir
        sed -i "" "/CEdgeServer/d" $dir
        sed -i "" "/CRtcClient/d" $dir
        sed -i "" "/CPingMgr/d" $dir
        sed -i "" "/^\s*$/d" $dir
    fi
done
