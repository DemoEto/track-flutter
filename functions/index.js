const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

// Trigger function when a new homework document is created
exports.notifyHomeworkCreated = functions.firestore
  .document('homeworks/{homeworkId}') // This listens to the homeworks collection
  .onCreate(async (snap, context) => {
    try {
      // Get the newly created homework data
      const homeworkData = snap.data();
      
      console.log('New homework created:', homeworkData);
      
      // Extract necessary information
      const { title, description, assignedTo, subjectId, id: homeworkId } = homeworkData;
      
      // Get teacher information from subject
      const subjectDoc = await admin.firestore().collection('subjects').doc(subjectId).get();
      let teacherId = null;
      if (subjectDoc.exists) {
        const subjectData = subjectDoc.data();
        teacherId = subjectData.teacherId;
      }
      
      // Create a notification message
      const message = `New homework assigned: ${title}. Due date: ${homeworkData.dueDate.toDate().toLocaleDateString()}`;
      
      // Array to hold all notification promises
      const notificationPromises = [];
      
      // Notify each assigned student
      for (const studentId of assignedTo) {
        // Create notification for the student
        const studentNotification = {
          userId: studentId,
          type: 'homework',
          message: `New homework assigned: ${title}`,
          relatedId: homeworkId,
          isRead: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        };
        
        // Add to notifications collection
        notificationPromises.push(
          admin.firestore()
            .collection('notifications')
            .add(studentNotification)
        );
        
        // Also try to send a push notification if the student has FCM token
        try {
          const userDoc = await admin.firestore().collection('users').doc(studentId).get();
          const userData = userDoc.data();
          
          if (userData && userData.fcmToken) {
            const payload = {
              notification: {
                title: 'New Homework Assigned',
                body: `You have new homework: ${title}`,
              },
              data: {
                homeworkId: homeworkId,
                type: 'homework',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              }
            };
            
            // Use the new FCM API instead of deprecated sendToDevice
            const message = {
              notification: {
                title: 'New Homework Assigned',
                body: `You have new homework: ${title}`,
              },
              data: {
                homeworkId: homeworkId,
                type: 'homework',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              },
              token: userData.fcmToken,
            };
            
            await admin.messaging().send(message);
            console.log(`Push notification sent to student ${studentId}`);
          }
        } catch (error) {
          console.error('Error sending push notification to student:', error);
        }
      }
      
      // Now find and notify parents of the assigned students
      for (const studentId of assignedTo) {
        // Find parents associated with this student
        // Parents have a childUserIds array that contains the student IDs
        const parentQuery = await admin.firestore()
          .collection('users')
          .where('role', '==', 'parent')
          .get();
          
        parentQuery.forEach(parentDoc => {
          const parentData = parentDoc.data();
          const parentId = parentDoc.id;
          
          // Check if this parent is responsible for the current student
          if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
            // Create notification for the parent
            const parentNotification = {
              userId: parentId,
              type: 'homework',
              message: `Homework assigned to your child: ${title}`,
              relatedId: homeworkId,
              isRead: false,
              timestamp: admin.firestore.FieldValue.serverTimestamp()
            };
            
            // Add to notifications collection
            notificationPromises.push(
              admin.firestore()
                .collection('notifications')
                .add(parentNotification)
            );
            
            // Try to send push notification to parent
            if (parentData && parentData.fcmToken) {
              const message = {
                notification: {
                  title: 'Homework Assigned to Your Child',
                  body: `Your child has new homework: ${title}`,
                },
                data: {
                  homeworkId: homeworkId,
                  type: 'homework',
                  click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                token: parentData.fcmToken,
              };
              
              notificationPromises.push(
                admin.messaging().send(message)
                  .then(() => console.log(`Push notification sent to parent ${parentId}`))
                  .catch(err => console.error('Error sending push notification to parent:', err))
              );
            }
          }
        });
      }
      
      // Notify the teacher who assigned the homework
      if (teacherId) {
        const teacherNotification = {
          userId: teacherId,
          type: 'homework',
          message: `You assigned homework "${title}" to ${assignedTo.length} student(s)`,
          relatedId: homeworkId,
          isRead: false,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        };
        
        // Add to notifications collection
        notificationPromises.push(
          admin.firestore()
            .collection('notifications')
            .add(teacherNotification)
        );
        
        // Try to send push notification to teacher
        try {
          const teacherDoc = await admin.firestore().collection('users').doc(teacherId).get();
          const teacherData = teacherDoc.data();
          
          if (teacherData && teacherData.fcmToken) {
            const message = {
              notification: {
                title: 'Homework Assignment Created',
                body: `You assigned homework "${title}" to ${assignedTo.length} student(s)`,
              },
              data: {
                homeworkId: homeworkId,
                type: 'homework',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              },
              token: teacherData.fcmToken,
            };
            
            await admin.messaging().send(message);
            console.log(`Push notification sent to teacher ${teacherId}`);
          }
        } catch (error) {
          console.error('Error sending push notification to teacher:', error);
        }
      }
      
      // Wait for all notification promises to complete
      await Promise.all(notificationPromises);
      
      console.log(`Notifications created for ${assignedTo.length} students, their parents, and teacher`);
      
      return null;
    } catch (error) {
      console.error('Error in notifyHomeworkCreated function:', error);
      return null;
    }
  });

// Optional: Function to handle homework updates if needed
exports.notifyHomeworkUpdated = functions.firestore
  .document('homeworks/{homeworkId}')
  .onUpdate(async (change, context) => {
    try {
      const homeworkData = change.after.data();
      const previousData = change.before.data();
      
      // Only trigger notification if important fields changed (e.g., due date, title, description)
      if (homeworkData.dueDate !== previousData.dueDate || 
          homeworkData.title !== previousData.title || 
          homeworkData.description !== previousData.description) {
        
        const { title, description, assignedTo, id: homeworkId } = homeworkData;
        const message = `Homework updated: ${title}. Due date: ${homeworkData.dueDate.toDate().toLocaleDateString()}`;
        
        const notificationPromises = [];
        
        // Notify each assigned student
        for (const studentId of assignedTo) {
          const studentNotification = {
            userId: studentId,
            type: 'homework',
            message: `Homework updated: ${title}`,
            relatedId: homeworkId,
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          };
          
          notificationPromises.push(
            admin.firestore()
              .collection('notifications')
              .add(studentNotification)
          );
        }
        
        // Notify parents as well
        for (const studentId of assignedTo) {
          const parentQuery = await admin.firestore()
            .collection('users')
            .where('role', '==', 'parent')
            .get();
            
          parentQuery.forEach(parentDoc => {
            const parentData = parentDoc.data();
            const parentId = parentDoc.id;
            
            // Check if this parent is responsible for the current student
            if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
              const parentNotification = {
                userId: parentId,
                type: 'homework',
                message: `Homework updated for your child: ${title}`,
                relatedId: homeworkId,
                isRead: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
              };
              
              notificationPromises.push(
                admin.firestore()
                  .collection('notifications')
                  .add(parentNotification)
              );
            }
          });
        }
        
        await Promise.all(notificationPromises);
        console.log(`Update notifications created for homework ${homeworkId}`);
      }
      
      return null;
    } catch (error) {
      console.error('Error in notifyHomeworkUpdated function:', error);
      return null;
    }
  });

// Trigger function when attendance is marked for a student
exports.notifyAttendanceMarked = functions.firestore
  .document('attendance_records/{recordId}')
  .onCreate(async (snap, context) => {
    try {
      const attendanceData = snap.data();
      
      console.log('New attendance record created:', attendanceData);
      
      const { studentId, status, sessionId, scanTime } = attendanceData;
      
      // Get session details to determine subject
      let subjectName = 'Class';
      if (sessionId) {
        const sessionDoc = await admin.firestore().collection('attendance_sessions').doc(sessionId).get();
        if (sessionDoc.exists) {
          const sessionData = sessionDoc.data();
          // Try to get subject name if available
          if (sessionData.subjectId) {
            const subjectDoc = await admin.firestore().collection('subjects').doc(sessionData.subjectId).get();
            if (subjectDoc.exists) {
              subjectName = subjectDoc.data().name || 'Class';
            }
          }
        }
      }
      
      const statusMessage = {
        'present': 'present',
        'absent': 'absent',
        'late': 'late'
      }[status] || status;
      
      const message = `Attendance marked as ${statusMessage} for ${subjectName}`;
      
      const notificationPromises = [];
      
      // Notify the student
      const studentNotification = {
        userId: studentId,
        type: 'attendance',
        message: `Your attendance for ${subjectName} was marked as ${statusMessage}`,
        relatedId: sessionId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };
      
      notificationPromises.push(
        admin.firestore()
          .collection('notifications')
          .add(studentNotification)
      );
      
      // Try to send push notification to student
      try {
        const userDoc = await admin.firestore().collection('users').doc(studentId).get();
        const userData = userDoc.data();
        
        if (userData && userData.fcmToken) {
          const payload = {
            notification: {
              title: 'Attendance Update',
              body: `Your attendance for ${subjectName} was marked as ${statusMessage}`,
            },
            data: {
              sessionId: sessionId,
              type: 'attendance',
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
          };
          
          // Use the new FCM API instead of deprecated sendToDevice
          const message = {
            notification: {
              title: 'Attendance Update',
              body: `Your attendance for ${subjectName} was marked as ${statusMessage}`,
            },
            data: {
              sessionId: sessionId,
              type: 'attendance',
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            token: userData.fcmToken,
          };
          
          await admin.messaging().send(message);
          console.log(`Attendance push notification sent to student ${studentId}`);
        }
      } catch (error) {
        console.error('Error sending push notification to student:', error);
      }
      
      // Notify parents of the student
      const parentQuery = await admin.firestore()
        .collection('users')
        .where('role', '==', 'parent')
        .get();
        
      parentQuery.forEach(parentDoc => {
        const parentData = parentDoc.data();
        const parentId = parentDoc.id;
        
        if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
          const parentNotification = {
            userId: parentId,
            type: 'attendance',
            message: `Attendance for your child in ${subjectName} was marked as ${statusMessage}`,
            relatedId: sessionId,
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          };
          
          notificationPromises.push(
            admin.firestore()
              .collection('notifications')
              .add(parentNotification)
          );
          
          // Try to send push notification to parent
          if (parentData && parentData.fcmToken) {
            const message = {
              notification: {
                title: 'Child Attendance Update',
                body: `Attendance for your child in ${subjectName} was marked as ${statusMessage}`,
              },
              data: {
                sessionId: sessionId,
                type: 'attendance',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              },
              token: parentData.fcmToken,
            };
            
            notificationPromises.push(
              admin.messaging().send(message)
                .then(() => console.log(`Attendance push notification sent to parent ${parentId}`))
                .catch(err => console.error('Error sending push notification to parent:', err))
            );
          }
        }
      });
      
      await Promise.all(notificationPromises);
      console.log(`Attendance notifications created for student ${studentId}`);
      
      return null;
    } catch (error) {
      console.error('Error in notifyAttendanceMarked function:', error);
      return null;
    }
  });

// Trigger function for bus tracking updates
exports.notifyBusStatusChange = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const previousData = change.before.data();
      
      // Only trigger if important fields changed
      if (newData.status !== previousData.status || newData.location !== previousData.location) {
        console.log('Bus status updated:', newData);
        
        const { studentIds, driverId, status, routeName, location } = newData;
        
        // Determine the appropriate message based on status
        let message = `Bus status updated to ${status}`;
        if (status === 'started') {
          message = `Bus has started journey for ${routeName || 'route'}`;
        } else if (status === 'completed') {
          message = `Bus has completed journey for ${routeName || 'route'}`;
        } else if (status === 'in-transit') {
          message = 'Your bus is in transit';
        } else if (status === 'arriving') {
          message = 'Your bus is arriving soon';
        } else if (status === 'departed') {
          message = 'Your bus has departed';
        } else if (status === 'delayed') {
          message = 'Your bus is delayed';
        } else if (status === 'on_time') {
          message = 'Your bus is on schedule';
        } else if (status === 'pending') {
          message = 'Bus ride is pending';
        }
        
        const notificationPromises = [];
        
        // Notify each student in the ride
        if (studentIds && Array.isArray(studentIds)) {
          for (const studentId of studentIds) {
            const studentNotification = {
              userId: studentId,
              type: 'bus',
              message: message,
              relatedId: context.params.rideId,
              isRead: false,
              timestamp: admin.firestore.FieldValue.serverTimestamp()
            };
            
            notificationPromises.push(
              admin.firestore()
                .collection('notifications')
                .add(studentNotification)
            );
            
            // Try to send push notification to student
            try {
              const userDoc = await admin.firestore().collection('users').doc(studentId).get();
              const userData = userDoc.data();
              
              if (userData && userData.fcmToken) {                
                // Use the new FCM API instead of deprecated sendToDevice
                const message = {
                  notification: {
                    title: 'Bus Status Update',
                    body: message,
                  },
                  data: {
                    rideId: context.params.rideId,
                    type: 'bus',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                  },
                  token: userData.fcmToken,
                };
                
                await admin.messaging().send(message);
                console.log(`Bus push notification sent to student ${studentId}`);
              }
            } catch (error) {
              console.error('Error sending push notification to student:', error);
            }
          }
        }
        
        // Notify parents of students in the ride
        if (studentIds && Array.isArray(studentIds)) {
          for (const studentId of studentIds) {
            const parentQuery = await admin.firestore()
              .collection('users')
              .where('role', '==', 'parent')
              .get();
              
            parentQuery.forEach(parentDoc => {
              const parentData = parentDoc.data();
              const parentId = parentDoc.id;
              
              if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
                const parentNotification = {
                  userId: parentId,
                  type: 'bus',
                  message: `Bus update for your child: ${message}`,
                  relatedId: context.params.rideId,
                  isRead: false,
                  timestamp: admin.firestore.FieldValue.serverTimestamp()
                };
                
                notificationPromises.push(
                  admin.firestore()
                    .collection('notifications')
                    .add(parentNotification)
                );
                
                // Try to send push notification to parent
                if (parentData && parentData.fcmToken) {
                  const message = {
                    notification: {
                      title: 'Child Bus Update',
                      body: `Bus update for your child: ${message}`,
                    },
                    data: {
                      rideId: context.params.rideId,
                      type: 'bus',
                      click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    },
                    token: parentData.fcmToken,
                  };
                  
                  notificationPromises.push(
                    admin.messaging().send(message)
                      .then(() => console.log(`Bus push notification sent to parent ${parentId}`))
                      .catch(err => console.error('Error sending push notification to parent:', err))
                  );
                }
              }
            });
          }
        }
        
        await Promise.all(notificationPromises);
        console.log(`Bus notifications created for ride ${context.params.rideId}`);
      }
      
      return null;
    } catch (error) {
      console.error('Error in notifyBusStatusChange function:', error);
      return null;
    }
  });

// Trigger function when a student is added to a bus ride
exports.notifyStudentAddedToBusRide = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const previousData = change.before.data();
      
      // Check if studentIds array has changed (student added to ride)
      const newStudentIds = newData.studentIds || [];
      const oldStudentIds = previousData.studentIds || [];
      
      // Find newly added students
      const addedStudents = newStudentIds.filter(id => !oldStudentIds.includes(id));
      
      if (addedStudents.length > 0) {
        console.log(`Students added to ride ${context.params.rideId}:`, addedStudents);
        
        const routeName = newData.routeName || 'route';
        const message = `You have been added to bus ride for ${routeName}`;
        
        const notificationPromises = [];
        
        for (const studentId of addedStudents) {
          // Notify the student
          const studentNotification = {
            userId: studentId,
            type: 'bus',
            message: `You have been added to bus ride for ${routeName}`,
            relatedId: context.params.rideId,
            isRead: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          };
          
          notificationPromises.push(
            admin.firestore()
              .collection('notifications')
              .add(studentNotification)
          );
          
          // Notify the student's parents
          const parentQuery = await admin.firestore()
            .collection('users')
            .where('role', '==', 'parent')
            .get();
            
          parentQuery.forEach(parentDoc => {
            const parentData = parentDoc.data();
            const parentId = parentDoc.id;
            
            if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
              const parentNotification = {
                userId: parentId,
                type: 'bus',
                message: `${newData.driverName || 'A driver'} added ${newData.driverName || 'your child'} to bus ride for ${routeName}`,
                relatedId: context.params.rideId,
                isRead: false,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
              };
              
              notificationPromises.push(
                admin.firestore()
                  .collection('notifications')
                  .add(parentNotification)
              );
            }
          });
        }
        
        await Promise.all(notificationPromises);
        console.log(`Notifications created for added students to ride ${context.params.rideId}`);
      }
      
      return null;
    } catch (error) {
      console.error('Error in notifyStudentAddedToBusRide function:', error);
      return null;
    }
  });

// Trigger function when a new homework submission is created
exports.notifyHomeworkSubmitted = functions.firestore
  .document('submissions/{submissionId}') // This listens to the submissions collection
  .onCreate(async (snap, context) => {
    try {
      // Get the newly created submission data
      const submissionData = snap.data();
      
      console.log('New homework submission created:', submissionData);
      
      // Extract necessary information
      const { homeworkId, studentId } = submissionData;
      
      // Get homework information to find the subject
      const homeworkDoc = await admin.firestore().collection('homeworks').doc(homeworkId).get();
      if (!homeworkDoc.exists) {
        console.log(`Homework ${homeworkId} not found`);
        return null;
      }
      
      const homeworkData = homeworkDoc.data();
      const subjectId = homeworkData.subjectId;
      const homeworkTitle = homeworkData.title;
      
      // Get subject information to find the teacher
      const subjectDoc = await admin.firestore().collection('subjects').doc(subjectId).get();
      if (!subjectDoc.exists) {
        console.log(`Subject ${subjectId} not found`);
        return null;
      }
      
      const subjectData = subjectDoc.data();
      const teacherId = subjectData.teacherId;
      
      // Get student information for notification message
      const studentDoc = await admin.firestore().collection('users').doc(studentId).get();
      let studentName = 'a student';
      if (studentDoc.exists) {
        const studentData = studentDoc.data();
        studentName = studentData.name || studentData.email || studentId;
      }
      
      // Create a notification for the teacher
      const teacherNotification = {
        userId: teacherId,
        type: 'homework_submission',
        message: `${studentName} has submitted homework: ${homeworkTitle}`,
        relatedId: homeworkId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Add to notifications collection
      await admin.firestore()
        .collection('notifications')
        .add(teacherNotification);
      
      // Try to send push notification to teacher
      try {
        const teacherDoc = await admin.firestore().collection('users').doc(teacherId).get();
        const teacherData = teacherDoc.data();
        
        if (teacherData && teacherData.fcmToken) {
          const message = {
            notification: {
              title: 'New Homework Submission',
              body: `${studentName} has submitted homework: ${homeworkTitle}`,
            },
            data: {
              homeworkId: homeworkId,
              studentId: studentId,
              type: 'homework_submission',
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            token: teacherData.fcmToken,
          };
          
          await admin.messaging().send(message);
          console.log(`Push notification sent to teacher ${teacherId} about homework submission`);
        }
      } catch (error) {
        console.error('Error sending push notification to teacher about submission:', error);
      }
      
      console.log(`Notification created for teacher ${teacherId} about homework submission from student ${studentId}`);
      
      return null;
    } catch (error) {
      console.error('Error in notifyHomeworkSubmitted function:', error);
      return null;
    }
  });

// Trigger function when student ride status changes (pickup/dropoff)
exports.notifyStudentRideStatusChange = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const previousData = change.before.data();
      
      // Check if studentStatuses object has changed
      const newStudentStatuses = newData.studentStatuses || {};
      const oldStudentStatuses = previousData.studentStatuses || {};
      
      // Find students whose status has changed
      const allStudents = [...new Set([...Object.keys(newStudentStatuses), ...Object.keys(oldStudentStatuses)])];
      
      for (const studentId of allStudents) {
        const oldStatus = oldStudentStatuses[studentId];
        const newStatus = newStudentStatuses[studentId];
        
        if (oldStatus !== newStatus) {
          console.log(`Student ${studentId} status changed from ${oldStatus} to ${newStatus} in ride ${context.params.rideId}`);
          
          let message = '';
          const routeName = newData.routeName || 'route';
          
          if (newStatus === 'picked-up') {
            message = `Student has been picked up for ${routeName}`;
          } else if (newStatus === 'dropped-off') {
            message = `Student has been dropped off for ${routeName}`;
          } else if (newStatus === 'pending') {
            message = `Student status is pending for ${routeName}`;
          }
          
          if (message) {
            const notificationPromises = [];
            
            // Notify the student
            const studentNotification = {
              userId: studentId,
              type: 'bus',
              message: `Your status changed to ${newStatus.replace('-', ' ')} for ${routeName}`,
              relatedId: context.params.rideId,
              isRead: false,
              timestamp: admin.firestore.FieldValue.serverTimestamp()
            };
            
            notificationPromises.push(
              admin.firestore()
                .collection('notifications')
                .add(studentNotification)
            );
            
            // Try to send push notification to student
            try {
              const userDoc = await admin.firestore().collection('users').doc(studentId).get();
              const userData = userDoc.data();
              
              if (userData && userData.fcmToken) {
                const payload = {
                  notification: {
                    title: 'Bus Status Update',
                    body: `Your status changed to ${newStatus.replace('-', ' ')} for ${routeName}`,
                  },
                  data: {
                    rideId: context.params.rideId,
                    type: 'bus',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                  }
                };
                
                // Use the new FCM API instead of deprecated sendToDevice
                const message = {
                  notification: {
                    title: 'Bus Status Update',
                    body: `Your status changed to ${newStatus.replace('-', ' ')} for ${routeName}`,
                  },
                  data: {
                    rideId: context.params.rideId,
                    type: 'bus',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                  },
                  token: userData.fcmToken,
                };
                
                await admin.messaging().send(message);
                console.log(`Bus status push notification sent to student ${studentId}`);
              }
            } catch (error) {
              console.error('Error sending push notification to student:', error);
            }
            
            // Notify the student's parents
            const parentQuery = await admin.firestore()
              .collection('users')
              .where('role', '==', 'parent')
              .get();
              
            parentQuery.forEach(parentDoc => {
              const parentData = parentDoc.data();
              const parentId = parentDoc.id;
              
              if (parentData.childUserIds && parentData.childUserIds.includes(studentId)) {
                const parentNotification = {
                  userId: parentId,
                  type: 'bus',
                  message: `Status for your child changed to ${newStatus.replace('-', ' ')} for ${routeName}`,
                  relatedId: context.params.rideId,
                  isRead: false,
                  timestamp: admin.firestore.FieldValue.serverTimestamp()
                };
                
                notificationPromises.push(
                  admin.firestore()
                    .collection('notifications')
                    .add(parentNotification)
                );
                
                // Try to send push notification to parent
                if (parentData && parentData.fcmToken) {
                  const message = {
                    notification: {
                      title: 'Child Bus Status Update',
                      body: `Status for your child changed to ${newStatus.replace('-', ' ')} for ${routeName}`,
                    },
                    data: {
                      rideId: context.params.rideId,
                      type: 'bus',
                      click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    },
                    token: parentData.fcmToken,
                  };
                  
                  notificationPromises.push(
                    admin.messaging().send(message)
                      .then(() => console.log(`Bus status push notification sent to parent ${parentId}`))
                      .catch(err => console.error('Error sending push notification to parent:', err))
                  );
                }
              }
            });
            
            await Promise.all(notificationPromises);
            console.log(`Status change notifications created for student ${studentId} in ride ${context.params.rideId}`);
          }
        }
      }
      
      return null;
    } catch (error) {
      console.error('Error in notifyStudentRideStatusChange function:', error);
      return null;
    }
  });