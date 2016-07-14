#!/bin/bash

###
# COMANDS
# 'get uploads' = retrieve all uploads that do not already exist
# 'get plugin [plugin-name]' = retrieve and overwrite the plugin [plugin-name]
# 'get --all-plugins' = retrieve all paid plugins (REQUIRED BEFORE RUNNING ENVIRONMENT)
# 'get database' = retrieve a copy of the database from the server + rename urls
# 'get theme' = download the Divi theme from the server
# 'update plugin [plugin-name] = update a specific plugin'

# Globals
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PaidPlugins=(learndash-propanel sfwd-lms)
NATIVE=true
CONTAINER_IP=localhost

###
# PRECHECKS
#

type rsync &>/dev/null
if [[ $? == 1 ]]; then
    echo '=> Error: rsync must be installed.'
    exit 1
fi

# Check ownership of wp-content
owners=$(ls -lR $SCRIPTDIR/wp-content | awk '{print $3}')
for o in $owners; do
    if [[ $o != "$USER" ]]; then
        echo '=> Need sudo priveledges to take ownership of wp-content directory'
        sudo chown -R $USER $SCRIPTDIR/wp-content
        break
    fi
done;


# Exit if the DSA file doesn't exist
if [[ ! -f ./data/aliemu_dsa ]]; then
    echo '=> Error: You must have the file "aliemu_dsa" located within your data directory'
    exit 1
fi

# Check to see if the user is running docker through a virtual machine or natively
#  and set the CONTAINER_IP accordingly.
type docker-machine &>/dev/null
if [[ $? == 0 ]]; then
    docker-machine ip $DOCKER_MACHINE_NAME &>/dev/null
    if [[ $? == 0 ]]; then
        CONTAINER_IP=$(docker-machine ip $DOCKER_MACHINE_NAME)
        NATIVE=false
    fi
fi

# Prepare for SSH
chmod 400 $SCRIPTDIR/data/aliemu_dsa
eval "$(ssh-agent -s)" &>/dev/null
ssh-add $SCRIPTDIR/data/aliemu_dsa &>/dev/null

main() {

    if [[ $# == 0 ]]; then
        get_uploads
        get_database
        exit 0
    fi

    case "$1" in
        init)
            get_theme
            get_all_plugins
            get_uploads
            get_database;;
        get)
            case "$2" in
                uploads)
                    get_uploads;;
                --all-plugins)
                    get_all_plugins;;
                plugin)
                    get_plugin $3;;
                theme)
                    get_theme;;
                database)
                    get_database;;
                *)
                    echo "'get' subcommmand must be either 'uploads', 'plugin', '--all-plugins', 'theme', or 'database'" && exit 1
            esac;;
        update)
            case "$2" in
                plugin)
                    echo "=> Updating plugin: $3"
                    PLUGIN=$3
                    docker exec -it "$(docker ps -lq)" bash -c "wp plugin install $PLUGIN --force --activate --allow-root"
                    ;;
                *)
                    echo "'update' subcommand must be 'plugin'" && exit 1
            esac;;
        *)
            echo "The only commands available are 'get' and 'update'" && exit 1
    esac
}

get_uploads() {
    echo "=> Downloading uploads from server..."
    rsync --ignore-existing --progress -az -e "ssh -i $SCRIPTDIR/data/aliemu_dsa -p 18765" aliemu@c7563.sgvps.net:public_html/wp-content/uploads/ "$SCRIPTDIR/wp-content/uploads"
    echo "=> Uploads Synced Successfully!"
}

get_all_plugins() {
    for plugin in "${PaidPlugins[@]}"; do
        echo "=> Retrieving plugin: $plugin"
        rsync --progress -auz -e "ssh -i $SCRIPTDIR/data/aliemu_dsa -p 18765" aliemu@c7563.sgvps.net:public_html/wp-content/plugins/"$PLUGIN" "$SCRIPTDIR/wp-content"
        echo "=> Plugin $plugin Retrieved Successfully!"
    done
}

get_plugin() {
    echo "=> Retrieving plugin: $1"
    rsync --progress -auz -e "ssh -i $SCRIPTDIR/data/aliemu_dsa -p 18765" aliemu@c7563.sgvps.net:public_html/wp-content/plugins/"$1" "$SCRIPTDIR/wp-content/plugins"
    echo "=> Plugin $1 Retrieved Successfully!"
}

get_theme() {
    echo "=> Retrieving Divi Theme"
    rsync --progress -auz -e "ssh -i $SCRIPTDIR/data/aliemu_dsa -p 18765" aliemu@c7563.sgvps.net:public_html/wp-content/themes/Divi "$SCRIPTDIR/wp-content/themes"
    echo "=> Theme Retrieved Successfully!"
}

get_database() {
    # SSH into siteground and backup the database and copy to the data directory
    if [[ $NATIVE == true ]]; then
        ssh -i $SCRIPTDIR/data/aliemu_dsa aliemu@c7563.sgvps.net -p 18765 "
        cd public_html
        wp db export database.sql"
        echo '=> Downloading database to local machine...'
        scp -i $SCRIPTDIR/data/aliemu_dsa -P 18765 aliemu@c7563.sgvps.net:public_html/database.sql $SCRIPTDIR/data
        echo '=> Deleting database copy from server...'
        ssh -i $SCRIPTDIR/data/aliemu_dsa aliemu@c7563.sgvps.net -p 18765 "cd public_html && rm database.sql"
    else
        ssh -i $SCRIPTDIR/data/aliemu_dsa aliemu@c7563.sgvps.net -p 18765 -o "PubkeyAcceptedKeyTypes ssh-dss" "
        cd public_html
        wp db export database.sql"
        scp -i $SCRIPTDIR/data/aliemu_dsa -P 18765 -o "PubkeyAcceptedKeyTypes ssh-dss" aliemu@c7563.sgvps.net:public_html/database.sql $SCRIPTDIR/data
        ssh -i $SCRIPTDIR/data/aliemu_dsa aliemu@c7563.sgvps.net -p 18765 -o "PubkeyAcceptedKeyTypes ssh-dss" "cd public_html && rm database.sql"

        # Machine not running? Start it up!
        if [[ $(docker-machine status "$DOCKER_MACHINE_NAME") != 'Running' ]]; then
            cd "$SCRIPTDIR" || exit
            docker-compose up -d
        fi
    fi

    # Import the database
    if [[ ! $(docker ps -q --filter name=aliemu_wordpress_1) ]]; then
        echo "=> Dev environment not running. Skipping import."
        exit 0
    fi

    echo "=> Importing database..."
    docker exec -it aliemu_wordpress_1 bash -c "wp db import /data/database.sql --allow-root"

    # Replace live URL with dev URL
    echo "=> Replacing URLs..."
    docker exec -it aliemu_wordpress_1 bash -c "wp  --no-quiet --allow-root search-replace 'https://www.aliemu.com' 'http://${CONTAINER_IP}:8080' --skip-columns=guid"
    echo "=> Database Successfully Imported!"
}

main "$@"
