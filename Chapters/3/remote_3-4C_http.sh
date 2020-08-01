
  if [[ -z $(docker ps -a | grep "${httpd1}*") ]]; then
    :
  else
    if [[ -z $(docker ps | grep "${httpd1}" ) ]]; then
      :
    else
      docker stop "$httpd1"
    fi
    docker rm "$httpd1"
  fi

  docker run --name "$httpd1" -d rhscl/httpd-24-rhel7
  myhttpdid1=$(docker ps -aqf name="$httpd1")
  echo "This is a test" > test.html
  docker cp test.html "$httpd1":"/opt/rh/httpd24/root/var/www/html/test.html"
  rm test.html
  ipaddress1=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$httpd1")
  sleep 20
  curl "$ipaddress1":8080/test.html
  docker diff "$httpd1"
  docker stop "$httpd1"
  docker commit -a 'chap4_author' -m 'functional test page test,html' "$httpd1"
  image_ids=$(docker images --format "{{.ID}}" -f "dangling=true")
  for image_id in $image_ids
  do
    inspected_field=$(docker inspect  -f "{{.ID}}\t{{.Comment}}\t{{.Author}}" "$image_id")
    if [[ -z $(echo "$inspected_field" | grep 'functional test page test,html') ]];then
      continue
    else
      image_id=$(echo "$inspected_field" | sed 's/^[a-z0-9:]\{7\}\([a-z0-9]\{12\}\).*$/\1/')
      # sed s/^[a-z0-9:]\{,17\}/\1/p
      # sed s/'^[a-z0-9:]\{7,7}([a-z0-9],10}'/\\1/)
      found=true
      echo "$image_id"
      break
    fi
  done
  if [[ -z $found ]];then
    echo "container image with search parameters not found"
    exit 1
  else
    if [[ $found == true ]];then
      echo "$image_id"
      docker tag "$image_id"  do081x-4c/httpd
      docker images | grep "$image_id"
      docker run -d --name myhttpd-custom do081x-4c/httpd
      sleep 20
      ipaddress2=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' myhttpd-custom)
      curl "$ipaddress2":8080/test.html
      docker stop myhttpd-custom
    fi
  fi
  docker rm "$httpd1"
  docker rm myhttpd-custom

