# Gunakan image official Go
FROM golang:1.21

# Set working directory di dalam container
WORKDIR /app

# Copy semua file ke dalam container (termasuk go.mod, go.sum, dan *.go)
COPY . .

# Build binary
RUN go build -o main

# Expose port yang digunakan aplikasi
EXPOSE 8080

# Jalankan binary saat container start
CMD ["./main"]