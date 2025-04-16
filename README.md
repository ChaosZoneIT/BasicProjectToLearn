ADD Description project


Configure local environment:
Domain assignment in host file (for easier use and certificate generation)
sudo nano /etc/hosts

172.0.10.3 gitlab.company.local



Run project

docker compose build
docker compose up -d (the environment is getting a little bit worse so you need to have some patience)

First up container:
change permision to directory storage (so you can browse files locally)
sudo chmod a+rw -R storage

When learning environment started looking for generated password to gitlab ([locally] in file: storage/config/initial_root_password , [in docker (1*)] /etc/gitlab/initial_root_password)

Change passwort to make it easier (this is only for learning/testing)
credentials
root: 1qaz@wsx#$




1* enter to container: docker compose exec -it gitlab_server bash
or show the file with tmp password: docker compose exec -it gitlab_server cat /etc/gitlab/initial_root_password
