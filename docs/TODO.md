```markdown
# Plan To-Do สำหรับระบบเรียนออนไลน์ด้วย Firebase (อัปเดตรวม Flow และ Database Schema)

## สถานะโครงการ: กำลังดำเนินการตามแผน

**หมายเหตุ:** แผนการพัฒนารายละเอียดอยู่ในไฟล์ `IMPLEMENTATION_PLAN.md` กรุณาดูไฟล์ดังกล่าวสำหรับแผนงานที่อัปเดตและสามารถติดตามความคืบหน้าได้

---

## 1. ระบบ Login และจัดการ Role
- สร้าง Collection `users` ใน Firestore (email, name, role, fcmToken, createdAt, updatedAt)
- เพิ่ม role: student, teacher, admin, driver, parent
- พัฒนาระบบ Login ด้วย Firebase Authentication (email/password)
- แยกเส้นทางและสิทธิ์เข้าถึงตาม role  

### Flow
- ผู้ใช้กรอก email/password → ระบบตรวจสอบ → ดึง role → นำทางไปหน้าหลักที่เหมาะสม

---

## 2. ระบบ QR Scan เข้าเรียน
- สร้าง Collection `subjects`, `attendance_sessions`, `attendance_records`
- ครูสร้าง session + เลือกวิชา + สร้าง QR Code
- นักเรียนสแกน QR → บันทึก attendance
- แจ้งเตือนครู-ผู้ปกครอง ผ่าน `notifications` และ Push Notification

### Flow
- ครูสร้าง session → นักเรียนสแกน → บันทึกเวลา → แจ้งครูและผู้ปกครอง

---

## 3. ระบบการบ้าน
- สร้าง Collection `homeworks`, `submissions`
- ครูมอบหมายการบ้าน เลือกวิชาและนักเรียน
- นักเรียนดูและส่งงาน
- แจ้งเตือนนักเรียน ครู และผู้ปกครอง

### Flow
- ครูสร้างการบ้าน → แจ้งนักเรียนและผู้ปกครอง → นักเรียนส่งงาน → แจ้งครู → ครูตรวจและแจ้งผล

---

## 4. ระบบแจ้งเตือนกระดิ่ง (Notifications)
- สร้าง Collection `notifications`
- API ยิง Firebase Cloud Messaging
- UI ดึงแจ้งเตือนเรียลไทม์ แสดง badge และสถานะอ่านข้อความ

### Flow
- เหตุการณ์ใดๆ → สร้างแจ้งเตือน → แสดง UI และส่ง Push Notification

---

## 5. ระบบจัดการของ Admin
- CRUD ผู้ใช้และวิชา ผ่าน UI
- สร้างแจ้งเตือนรายบุคคล/กลุ่ม
- จำกัดเฉพาะ admin

### Flow
- Admin เข้าสู่ระบบ → จัดการข้อมูลและแจ้งเตือน

---

## 6. ระบบจัดการคนขับรถและผู้โดยสาร
- สร้าง Collection `rides` หรือ `bus_trips`
- แอดมินเพิ่ม/ลบ/แก้ไขรายชื่อผู้โดยสารบนรถ
- คนขับดูรายชื่อและอัพเดตสถานะรับ-ส่ง
- แจ้งเตือนผู้เกี่ยวข้อง

### Flow
- แอดมินจัดการรายชื่อ → คนขับอัพเดตสถานะ → แจ้งเตือนผู้ปกครองและแอดมิน

---

## 7. ระบบแจ้งเตือนผู้ปกครอง
- เชื่อมผู้ปกครองกับนักเรียน (`childUserIds`)
- แจ้งเตือนสถานะเข้าเรียน การบ้าน การส่งงาน การรับส่งรถ
- UI แสดงแจ้งเตือนและรับ Push Notification

### Flow
- ผู้ปกครองรับแจ้งเตือนและติดตามสถานะเรียลไทม์

---

## 8. ระบบติดตามผู้โดยสารขึ้นรถ
- บันทึกเวลารับขึ้นและส่งถึงปลายทางใน `rides`
- คนขับอัพเดตสถานะเรียลไทม์
- ผู้ปกครองและแอดมินดูรายงานสถานะและแจ้งเตือน

### Flow
- คนขับบันทึกสถานะ → ผู้ปกครองและแอดมินรับข้อมูลทันที

---

## 9. การทดสอบและปรับปรุง
- ทดสอบทุกระบบและ role
- ทดสอบแจ้งเตือน UI และ Push Notification
- แก้ไขบั๊กและปรับ UX/UI

---

# Database Schema

### users
| Field         | Type      | Description                          |
|---------------|-----------|------------------------------------|
| email         | string    | อีเมลผู้ใช้                        |
| name          | string    | ชื่อผู้ใช้                        |
| role          | string    | บทบาท เช่น student, teacher, admin, driver, parent |
| fcmToken      | string    | Token สำหรับ Push Notification     |
| childUserIds  | array     | (สำหรับ parent) รายการ userId ลูก |
| createdAt     | timestamp | วันที่สร้าง                       |
| updatedAt     | timestamp | วันที่แก้ไข                       |

---

### subjects
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| subjectId     | string    | รหัสวิชา (Document ID)           |
| name          | string    | ชื่อวิชา                        |
| teacherId     | string    | userId ครูผู้สอน                 |
| description   | string    | รายละเอียดเพิ่มเติม (ถ้ามี)       |
| createdAt     | timestamp | วันที่สร้าง                     |
| updatedAt     | timestamp | วันที่แก้ไข                     |

---

### attendance_sessions
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| sessionId     | string    | รหัส session                    |
| subjectId     | string    | อ้างอิงวิชา                     |
| date          | timestamp | วันที่และเวลา session           |
| qrCode        | string    | ข้อมูล QR Code                  |
| createdAt     | timestamp | วันที่สร้าง                    |

---

### attendance_records
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| recordId      | string    | รหัสบันทึก                      |
| sessionId     | string    | อ้างอิง session                 |
| studentId     | string    | อ้างอิง userId นักเรียน         |
| scanTime      | timestamp | เวลาสแกน QR                    |
| status        | string    | สถานะ attendance เช่น present  |
| createdAt     | timestamp | วันที่สร้าง                    |

---

### homeworks
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| homeworkId    | string    | รหัสการบ้าน                    |
| subjectId     | string    | อ้างอิงวิชา                     |
| title         | string    | ชื่อการบ้าน                   |
| description   | string    | รายละเอียด                    |
| assignedTo    | array     | รายการ userId นักเรียนที่ได้รับมอบหมาย |
| dueDate       | timestamp | วันครบกำหนด                  |
| createdAt     | timestamp | วันที่สร้าง                   |
| updatedAt     | timestamp | วันที่แก้ไข                   |

---

### submissions
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| submissionId  | string    | รหัสส่งงาน                     |
| homeworkId    | string    | อ้างอิงการบ้าน                 |
| studentId     | string    | อ้างอิงนักเรียน                |
| imageURL      | string    | URL รูปภาพ                    |
| submitTime    | timestamp | เวลาส่งงาน                   |
| status        | string    | สถานะ เช่น submitted, checked |
| feedback      | string    | ความเห็นครู                   |

---

### notifications
| Field         | Type      | Description                        |
|---------------|-----------|----------------------------------|
| notificationId| string    | รหัสแจ้งเตือน                  |
| userId        | string    | ผู้รับแจ้งเตือน                |
| type          | string    | ประเภทแจ้งเตือน                |
| message       | string    | ข้อความแจ้งเตือน              |
| relatedId     | string    | อ้างอิง entity ที่เกี่ยวข้อง   |
| isRead        | boolean   | สถานะอ่านแล้ว                 |
| timestamp     | timestamp | เวลาสร้างแจ้งเตือน            |

---

### rides (bus_trips)
| Field            | Type      | Description                          |
|------------------|-----------|------------------------------------|
| rideId           | string    | รหัสทริป                         |
| driverId         | string    | userId คนขับรถ                     |
| date             | timestamp | วันที่และเวลา                     |
| passengerIds     | array     | รายการ userId ผู้โดยสาร           |
| passengerStatus  | map       | สถานะรายคน {userId: status}       |
| pickedUpTime     | map       | เวลารับขึ้นรถรายคน                 |
| droppedOffTime   | map       | เวลาส่งถึงปลายทางรายคน             |
| createdAt        | timestamp | วันที่สร้าง                       |
| updatedAt        | timestamp | วันที่แก้ไข                       |

# Flutter Project Folder Structure สำหรับระบบเรียนออนไลน์ด้วย Firebase
/lib
│
├── main.dart                      \# จุดเริ่มต้นแอป
├── app.dart                       \# กำหนด routing \& theme ของแอป
│
├── core                           \# ส่วนกลางที่ใช้ซ้ำทั่วแอป
│   ├── constants.dart             \# ค่าคงที่ต่าง ๆ
│   ├── enums.dart                 \# ตัว enum เช่น role, status
│   ├── utils.dart                 \# ฟังก์ชันช่วยเหลือต่าง ๆ
│   ├── widgets                   \# widget ทั่วไปใช้ซ้ำได้
│   ├── services                  \# service ต่าง ๆ (เช่น Firebase API)
│   └── providers                 \# providers สำหรับ state management
│
├── features                      \# ฟีเจอร์หลักของแอปแยกตามโดเมน
│   ├── auth                      \# ระบบ login/จัดการ user
│   │   ├── data                  \# โมเดล, Firebase CRUD
│   │   ├── presentation          \# หน้า UI เช่น login, register
│   │   └── logic                 \# ตัวจัดการ states เช่น provider, bloc
│   │
│   ├── attendance                \# ระบบเข้าเรียนผ่าน QR
│   │   ├── data
│   │   ├── presentation
│   │   └── logic
│   │
│   ├── homework                  \# ระบบการบ้าน
│   │   ├── data
│   │   ├── presentation
│   │   └── logic
│   │
│   ├── notification             \# ระบบแจ้งเตือน
│   │   ├── data
│   │   ├── presentation
│   │   └── logic
│   │
│   ├── admin                    \# ระบบจัดการของแอดมิน
│   │   ├── data
│   │   ├── presentation
│   │   └── logic
│   │
│   ├── rides                    \# ระบบจัดการคนขับรถ-ผู้โดยสาร
│   │   ├── data
│   │   ├── presentation
│   │   └── logic
│   │
│   └── parent                   \# ระบบแจ้งเตือนและติดตามของผู้ปกครอง
│       ├── data
│       ├── presentation
│       └── logic
---

## อธิบายโครงสร้าง

- `core`  
  รวมส่วนที่ใช้ซ้ำในหลายๆ ฟีเจอร์ เช่น ค่าคงที่, enums, ฟังก์ชันช่วยเหลือ, widget ทั่วไป, service สำหรับติดต่อ Firebase, และ providers สำหรับจัดการสถานะ

- `features`  
  แยกฟีเจอร์หลักตามโดเมน ทำให้การพัฒนาและการดูแลรักษาง่ายขึ้น โดยแต่ละฟีเจอร์จะแบ่งเป็น  
  - `data` สำหรับโมเดลและการติดต่อ Firebase  
  - `presentation` สำหรับ UI ที่เกี่ยวข้อง  
  - `logic` สำหรับ state management เช่น Provider หรือ Bloc

- `main.dart` กับ `app.dart`  
  เป็น entry point ของแอปและจัดการ routing และ theme ของแอป

---

โครงสร้างนี้เหมาะสำหรับการขยายแอปในอนาคต และช่วยให้ทีมงานสามารถดูแลและพัฒนาฟีเจอร์ต่าง ๆ ได้เป็นระบบและมีประสิทธิภาพ