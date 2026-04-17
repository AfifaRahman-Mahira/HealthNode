# HealthNode Firestore Schema

## Collections:

### 1. users
- uid: String (Unique ID)
- name: String
- email: String
- role: String (patient/admin)
- phone: String

### 2. medicines
- med_id: String
- name: String
- price: Number
- stock: Number
- expiry: Timestamp

### 3. orders
- order_id: String
- user_id: String
- total_bill: Number
- status: String (pending/delivered)