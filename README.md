# 🎓 Class Connect

### Adaptive Mastery & Engagement Platform (AMEP)

Class Connect is a **modern, data-driven ed-tech platform** built to support **Project-Based Learning (PBL)** with structured workflows, real-time engagement tracking, and personalized mastery progression. It bridges the gap between **traditional classroom teaching** and **adaptive, student-centric learning**.

---

## 🚀 Problem Statement

Modern classrooms face several challenges:

* Increasing **teacher workload**
* **Delayed and subjective assessments**
* Limited **personalized learning paths**
* Poor visibility into **student engagement & progress**
* Fragmented tools for projects, assignments, and evaluation

**Class Connect** addresses these challenges by offering a **single unified platform** for managing PBL, tracking progress, and enabling mastery-based learning at scale.

---

## 🎯 Objectives

* Enable scalable **Project-Based Learning**
* Provide **step-wise mini-project workflows**
* Track **student engagement & completion status**
* Reduce manual effort for educators
* Support **adaptive and mastery-driven education**

---

## 🧩 Key Features

### 👩‍🏫 Teacher Features

* Create and manage classes
* Design PBL collections with multiple mini-projects
* View students enrolled in each mini-project
* Track step completion and submission status
* Monitor real-time student progress

### 👨‍🎓 Student Features

* Browse available mini-projects
* Select & start a project independently
* Follow structured step-by-step tasks
* Submit project work (links/files)
* Track personal progress and completion

---

## 🛠️ Tech Stack

### Frontend

* **Flutter** (cross-platform)
* Material UI with custom dark theme

### Backend & Services

* **Firebase Authentication** – secure login & role handling
* **Cloud Firestore** – real-time NoSQL database

---

## 🔄 Application Flow

### Student Flow

1. Login to the platform
2. Join a class
3. View available PBL collections
4. Select a mini-project
5. Selection is saved with `studentId`
6. Complete project steps
7. Submit final work

### Teacher Flow

1. Create a class
2. Add PBL collections
3. Define mini-projects and steps
4. Monitor student selections
5. Track completion and submissions

---

## 🔐 Security & Data Integrity

* Firebase Authentication ensures verified users
* Firestore rules enforce:

  * Students can only modify their own selections
  * Teachers can view all enrolled students
* One mini-project per student per PBL (UID-based enforcement)

---

## 📈 Why Class Connect?

✔ Real-world PBL workflows (not just assignments)
✔ Real-time progress tracking
✔ Scalable NoSQL-friendly architecture
✔ Clean separation of UI and business logic
✔ Designed for real classroom usage

---

## 🧠 Learning Outcomes

This project demonstrates:

* Flutter application architecture
* Firestore data modeling (NoSQL)
* Authentication and role-based access
* Scalable PBL system design
* Ed-tech product thinking

---

## 🔮 Future Enhancements

* Engagement Index & analytics dashboard
* Mastery scoring system
* AI-based feedback & evaluation
* Teacher remarks and grading rubrics
* Parent access module
* Offline progress sync

---

## 🧑‍💻 Developed By  

**Class Connect Team**  
An initiative focused on **adaptive learning, mastery, and engagement**.

- **Daksh Gopani** – [LinkedIn](https://www.linkedin.com/in/daksh-gopani-a13993251/)
- **Rishi Vejani** – [LinkedIn](https://www.linkedin.com/in/rishi-vejani-56b923257/)
- **Rudra Parmar** – [LinkedIn](https://www.linkedin.com/in/rudra-parmar-089125245/)
- **Samyak Chheda** – [LinkedIn](https://www.linkedin.com/in/samyakchheda/)

---

## ⭐ Final Note

> *Class Connect is not just an app — it is a learning ecosystem built for modern classrooms and future-ready education.*
