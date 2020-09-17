  if [[ -z $httpd1 ]]; then
    httpd1=
  fi
  if [[ -z $custom ]]; then
    custom=
  fi
  # shellcheck disable=SC2143
  if [[ -z $(docker ps -a | grep "${httpd1}*") ]]; then
    :
  else
    # shellcheck disable=SC2143
    if [[ -z $(docker ps | grep "${httpd1}" ) ]]; then
      :
    else
      docker stop "$httpd1"
    fi
    docker rm "$httpd1"
  fi

  if [[ -z $custom ]]; then
    docker run --name "$httpd1" -d rhscl/httpd-24-rhel7
    # myhttpdid1=$(docker ps -aqf name="$httpd1")
    echo "This is a test" > test.html
    docker cp test.html "$httpd1":'/opt/rh/httpd24/root/var/www/html/test.html'
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
      # shellcheck disable=SC2143
      if [[ -z $(echo "$inspected_field" | grep 'functional test page test,html') ]];then
        continue
      else
        # shellcheck disable=SC2001
      image_id=$(echo "$inspected_field" | sed 's/^[a-z0-9:]\{7\}\([a-z0-9]\{12\}\).*$/\1/')
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
  else
    echo "container using custom images"
    custom_folder=custom$$
    custom_ext_folder=custom_$$

    mkdir "${PWD}"/$custom_folder
    mkdir "${PWD}"/$custom_ext_folder
    custom_folder_abs=${PWD}/$custom_folder
    custom_ext_folder_abs=${PWD}/$custom_ext_folder
    echo "This is custom test image" > test.html
    mv test.html "${custom_ext_folder_abs}"/

    if [[ -e Dockerfile ]]; then
      mv Dockerfile   "${custom_folder_abs}"/
      docker build  --build-arg  httpd_folder="${custom_ext_folder}"  \
      -t do081x-5c/httpd  \
      "${custom_folder_abs}"
      build_result=$?
    else
      echo "Dockerfile presence check...NOT OK"
      build_result=1
    fi

    if [[ $build_result -eq 0 ]]; then
      echo "Docker build using docker file...OK"
      httpdcd="httpd_custom_doc"
      docker run --name $httpdcd -d  do081x-5c/httpd

      # myhttpdidcd=$(docker ps -aqf name=$httpdcd)
      ipaddresscd=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$httpdcd")

      sleep 20
      curl "$ipaddresscd":80
      ret_val=$?
      if [[ ret_val -ne 0 ]]; then
        docker logs "$httpdcd"
      fi
      docker diff "$httpdcd"
      docker stop "$httpdcd"
      docker rm "$httpdcd"

      if [[ -d $custom_folder_abs ]]; then
        rm -r "$custom_folder_abs"
      fi
      if [[ -d $custom_ext_folder_abs ]];then
        rm -r "$custom_ext_folder_abs"
      fi
    else
      echo "Docker build using docker file...NOT OK"
      if [[ -d $custom_folder_abs ]]; then
        rm -r "$custom_folder_abs"
      fi
      if [[ -d $custom_ext_folder_abs ]];then
        rm -r "$custom_ext_folder_abs"
      fi
      exit $build_result
    fi
  fi

