# 📱 Max Mobility - Flutter CRM Assignment

A mobile CRM tool built with Flutter for Max Mobility. This app allows users to manage customers locally, capturing their information, location, and viewing them via embedded Google Maps.

---

## ✨ Features

- 🔐 **Login Page**
  - User ID & Password authentication
  - Input validation

- 📋 **Customer List**
  - Fetches customers from local SQLite DB
  - Shows image, name, mobile, email & address
  - 🗺️ Map icon for directions via Google Maps

- ➕ **Add Customer**
  - Form to input name, mobile, email, address, coordinates
  - Auto-capture location with GPS & Google Geocoding API
  - 📷 Pick image from camera/gallery
  - 📌 Show embedded Google Map
  - Validates and saves data locally

- 💾 **Local Storage**
  - All data persisted using `SQFlite`

- ⚙️ **State Management**
  - Built using **GetX** for routing, DI, and reactive state

---

## 🔑 Login Credentials

```plaintext
User ID:    user@maxmobility.in  
Password:   Abc@#123
