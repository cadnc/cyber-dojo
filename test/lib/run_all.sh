
# after running this check the coverage under the
# lib tab of coverage/index.html

echo '' > run_all.tmp
for TEST in *.rb ; do
    cat $TEST >> run_all.tmp
done
ruby run_all.tmp
rm run_all.tmp
