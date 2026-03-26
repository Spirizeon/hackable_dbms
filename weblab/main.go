package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

func searchHandler(w http.ResponseWriter, r *http.Request) {
	queryParam := r.URL.Query().Get("q")

	if queryParam == "" {
		fmt.Fprintln(w, "police site is under dev")
		return
	}

	// 🚨 INTENTIONALLY VULNERABLE 🚨
	// Direct string concatenation → SQL Injection
	query := fmt.Sprintf("SELECT '%s' as result", queryParam)

	rows, err := db.Query(query)
	if err != nil {
		fmt.Fprintf(w, "DB error: %v\n", err)
		return
	}
	defer rows.Close()

	var output string

	for rows.Next() {
		var result string
		err := rows.Scan(&result)
		if err == nil {
			output += result + "\n"
		}
	}

	if output == "" {
		fmt.Fprintln(w, "police site is under dev")
	} else {
		fmt.Fprint(w, output)
	}
}

func main() {
	// ⚠️ URL-encoded password (# → %23, ! → %21)
    dsn := "pd_webapp:W3bApp#2024!@tcp(localhost:3306)/metro_pd"
	var err error
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal("DB open error:", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatal("DB connection failed:", err)
	}

	http.HandleFunc("/search", searchHandler)

	fmt.Println("🚨 Vulnerable server running at http://127.0.0.1:3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}
