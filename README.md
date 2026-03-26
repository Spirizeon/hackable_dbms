# Metro PD SQLi Lab

A deliberately vulnerable backend simulating a **police investigation database**, designed for practicing **SQL Injection (SQLi)** techniques in a safe, local environment.


## Features

* Single vulnerable endpoint: `/search`
* MariaDB/MySQL backend
* Realistic relational schema:

  * officers, suspects, cases, evidence, surveillance_reports
  * internal_credentials (high-value target)
* Designed for:

  * SQLi learning
  * CTF-style challenges
  * Security training


## Prerequisites

* Go (≥ 1.20)
* MariaDB / MySQL (≥ 10.6 recommended)
* Git (optional)

## Database Setup

### 1. Start MariaDB

```bash
sudo systemctl start mariadb
```

---

### 2. Import schema

```bash
sudo mysql < metro_pd.sql
```

This will:

* Create database `metro_pd`
* Create tables and seed data
* Create users:

  * `pd_webapp`
  * `pd_analyst`
  * `pd_admin`


### 3. Fix user access (important)

Login:

```bash
sudo mysql
```
