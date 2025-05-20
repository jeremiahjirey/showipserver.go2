package main

import (
	"fmt"
	"html/template"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	// "strings" // strings sudah dihapus karena tidak digunakan
)

// IPData merepresentasikan data yang akan ditampilkan di template
type IPData struct {
	LocalIP string
	Port    int
}

func getLocalIP() string {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		log.Printf("Error getting local IP: %v", err)
		return "Tidak dapat menemukan IP lokal"
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String()
}

func main() {
	// Dapatkan port dari environment variable, default 8080
	portStr := os.Getenv("PORT")
	if portStr == "" {
		portStr = "8080"
	}
	port, err := strconv.Atoi(portStr)
	if err != nil {
		log.Fatalf("Invalid port specified: %v", err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		localIP := getLocalIP()
		data := IPData{
			LocalIP: localIP,
			Port:    port,
		}

		tmpl, err := template.New("index").Parse(indexHTML)
		if err != nil {
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			log.Printf("Error parsing template: %v", err)
			return
		}
		tmpl.Execute(w, data)
	})

	log.Printf("Server berjalan di http://0.0.0.0:%d", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}

const indexHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IP Lokal Server</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <style>
        /* CSS Kustom untuk Animasi Background */
        @keyframes gradient-animation {
            0% {
                background-position: 0% 50%;
            }
            50% {
                background-position: 100% 50%;
            }
            100% {
                background-position: 0% 50%;
            }
        }

        body {
            background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
            background-size: 400% 400%;
            animation: gradient-animation 15s ease infinite;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        /* Penyesuaian untuk konten di tengah agar terlihat jelas */
        .card-container {
            background-color: rgba(255, 255, 255, 0.9); /* Sedikit transparan untuk melihat background */
            backdrop-filter: blur(5px); /* Efek blur pada background di belakang card */
            padding: 2.5rem; /* p-10 */
            border-radius: 0.75rem; /* rounded-lg */
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05); /* shadow-xl */
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="card-container">
        <h1 class="text-4xl font-extrabold mb-6 text-gray-900">IP Lokal Server Anda</h1>
        <p class="text-2xl text-gray-800 mb-4">Alamat IP: <span class="font-bold text-indigo-700">{{ .LocalIP }}</span></p>
        <p class="text-2xl text-gray-800">Berjalan di Port: <span class="font-bold text-teal-600">{{ .Port }}</span></p>
    </div>
</body>
</html>
`
