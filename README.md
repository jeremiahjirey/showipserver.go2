# showipserverwithgolang
Script Go Lang sederhana untuk menampilkan alamat IP server (lokal/private) beserta port yang digunakan.

## Instal di AL23
```
yum install golang -y
```

## Build apps
```
go build -o showip-app main.go
```

## Testing
```
./showip-app
```

## Running in production
Use nodejs package manager
```
yum install nodejs -y
npm install -g pm2
pm2 start showip-app
```
