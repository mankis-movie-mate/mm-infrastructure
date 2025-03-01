#docker compose down --rmi all
#docker compose down -v
docker compose --env-file ./.env  --env-file ./.env.db up -d