if [[ -z $sqld1 ]]; then
  sqld1=
fi

if [[ -z $sqld2 ]]; then
  sqld2=
fi

if [[ -z $force ]]; then
  force=
fi

function posix_setter {
  if [[ -z $(set -o | grep '^posix[^a-zA-Z0-9]*on$') ]]; then
    set -o posix || exit_edx "$?" "failed to set posix"
  fi
}

posix_setter

if [[ -z $(docker ps -a | grep "${sqld1}") ]]; then
  :
else
  if [[ -z $force ]]; then
    exists='true'
  fi
  if [[ -z $(docker ps | grep "${sqld1}" ) ]]; then
    :
  else
    if [[ -z $force ]]; then
      if [[ -z $exists ]]; then
        echo "error container image cannot be in run state"
        exit 1
      fi
      running='true'
    else
      docker stop "$sqld1"
      docker stop "$sqld2"
    fi
  fi
  if [[ -z $force ]]; then
    echo "$force"
  else
    docker rm "$sqld1"
    docker rm "$sqld2"
  fi
fi

if [[ -z $force ]]; then
  if [[ -z $exists ]]; then
      docker run --name "$sqld1" \
      -e MYSQL_USER=user \
      -e MYSQL_PASSWORD=password \
      -e MYSQL_ROOT_PASSWORD=rootpassword \
      -e MYSQL_DATABASE=mdatabase \
      -d rhscl/mysql-56-rhel7

      docker run  --name "$sqld2" -t rhscl/mysql-56-rhel7 bash -c "while(true) do echo hello;sleep 300; done "&
      sqld2_run_pid="$!"
      running='true'
  else
    if [[ -z $running ]]; then
      echo "Image already exists"
      docker restart "$sqld1"
      docker rm "$sqld2"
      docker run  --name "$sqld2" -t rhscl/mysql-56-rhel7 bash -c "while(true) do echo hello;sleep 300; done "&
      sqld2_run_pid="$!"
      running='true'
    else
      echo "Image already exists and operational"
      docker stop "$sqld2"
      docker rm "$sqld2"
      docker run  --name "$sqld2" -t rhscl/mysql-56-rhel7 bash -c "while(true) do echo hello;sleep 300; done "&
      sqld2_run_pid="$!"
    fi
  fi
else
  echo "force option is enabled for remote scripts"
  docker run --name "$sqld1" \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=password \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=mdatabase \
  -d rhscl/mysql-56-rhel7

  docker run  --name "$sqld2" -t rhscl/mysql-56-rhel7 bash -c "while(true) do echo hello;sleep 300; done "&
  sqld2_run_pid="$!"
  running='true'
fi


#if [[ -z $running ]]; then
#  sqldid1=$(docker ps -aqf name="$sqld1")
#  # echo docker logs "$sqld1"
sleep 20
if [[ -e test.sh ]]; then
  rm  test.h
fi
if [[ -e test2.sh ]]; then
  rm test.sh
fi
ipaddress1=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$sqld1")
cat > test.sh <<'EOF'
if [[ -z $(set -o | grep '^posix[^a-zA-Z0-9]*on$') ]]; then
  set -o posix || exit_edx "$?" "failed to set posix"
fi
echo "Printing from inside sql container"
EOF
chmod +x test.sh
echo "ipaddress1=${ipaddress1}" > test2.sh

cat >> test2.sh <<'EOF'
if [[ -z $(set -o | grep '^posix[^a-zA-Z0-9]*on$') ]]; then
  set -o posix || exit_edx "$?" "failed to set posix"
fi
echo $ipaddress1
sql_q1="create table courses (id int not null, name varchar(255) not null,primary key (id));"
sql_q2="insert into courses (id,name) values(1,'DO081x');"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="show databases;"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="show tables;"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="drop table courses;"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="$sql_q1"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="$sql_q2"
mysql --user=user --password=password --host=${ipaddress1} -D mdatabase --execute="select * from courses;"
EOF
chmod +x test2.sh

docker cp test.sh "$sqld1":/opt/app-root/src/test.sh
exit_val="$?"
if [[ $exit_val != 0 ]]; then
  echo "@failure exit in copy test.sh"
  rm "test.sh"
  exit "$exit_val"
else
  rm "test.sh"
fi

docker cp test2.sh "$sqld2":/opt/app-root/src/test2.sh
exit_val="$?"
if [[ $exit_val != 0 ]]; then
  echo "@failure exit in copy test2.sh"
  rm "test2.sh"
  exit "$exit_val"
else
  rm "test2.sh"
fi

docker exec  "$sqld1" bash -c "./test.sh"
docker exec  "$sqld1" bash -c "rm test.sh"
docker exec "$sqld2" bash -c "./test2.sh"
docker exec "$sqld2"  bash -c "rm test2.sh"

if [[ -z $sqld2_run_pid ]]; then
  :
else
  echo $sqld2_run_pid
  docker stop "$sqld2"
  match=$(ps -e | sed  s/'\([0-9]*\).*'/\\1/ | grep $sqld2_run_pid)
  if [[ -z $match ]]; then
    echo "background process termination check...NOT OK"
  elif [[ $match -eq $sqld2_run_pid ]]; then
    kill -9  $sqld2_run_pid
  else
    echo "logic trap for practically unreachable code...NOT OK"
  fi
fi

