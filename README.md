# 📱 Work - Flutter CRM App 

**Work** is a Flutter-based Customer Relationship Management (CRM) app developed as an assignment for **Max Mobility**. It allows users to log in, manage customer data, capture geo-locations, and view them on Google Maps — with all information stored locally using SQLite.

---

## ✨ Features

- 🔐 **Login Page**
  - User ID and Password authentication
  - Input validation

- 📋 **Customer List**
  - Displays customer data from SQLite
  - Shows photo, name, phone, email, and address
  - 🗺️ Map icon launches Google Maps for navigation

- ➕ **Add Customer**
  - Input fields: Name, Phone, Email, Address, Latitude, Longitude
  - 📍 Auto-fetch location via GPS + Geocoding API
  - 📷 Select image from camera or gallery
  - 🗺️ View embedded Google Map of captured location

- 💾 **Local Storage**
  - Uses `SQFlite` for data persistence

- ⚙️ **State Management**
  - Powered by `GetX` (reactive + DI + routing)

---

## 🔧 Prerequisites

- ✅ Flutter SDK `>=3.7.2`
- ✅ Android Studio / VS Code with Android Emulator or real device
- ✅ Google Maps API Key (Maps SDK + Geocoding)

---

## 🚀 Getting Started

### 🔁 Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/work.git
cd work
