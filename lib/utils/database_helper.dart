import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'healthcare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        isAdmin INTEGER DEFAULT 0
      )
    ''');

    // Create Doctors table
    await db.execute('''
      CREATE TABLE doctors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        clinic TEXT NOT NULL
      )
    ''');

    // Create Appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        doctorId INTEGER,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        paymentMethod TEXT,
        isPaid INTEGER DEFAULT 0,
        amount REAL DEFAULT 0.0,
        appointmentType TEXT DEFAULT 'Consultation',
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (doctorId) REFERENCES doctors (id)
      )
    ''');

    // Create Messages table
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderId INTEGER,
        receiverId INTEGER,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0
      )
    ''');

    // Insert admin user
    await db.insert('users', {
      'name': 'Admin',
      'email': 'admin',
      'password': '123qwe',
      'isAdmin': 1
    });

    // Insert some sample doctors
    await db.insert('doctors', {
      'name': 'Dr. John Smith',
      'specialty': 'Cardiology',
      'clinic': 'Heart Care Center'
    });

    await db.insert('doctors', {
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Dermatology',
      'clinic': 'Skin Health Clinic'
    });

    await db.insert('doctors', {
      'name': 'Dr. Michael Lee',
      'specialty': 'Neurology',
      'clinic': 'Brain & Spine Center'
    });
  }

  // User operations
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Doctor operations
  Future<int> insertDoctor(Doctor doctor) async {
    Database db = await database;
    return await db.insert('doctors', doctor.toMap());
  }

  Future<int> updateDoctor(Doctor doctor) async {
    Database db = await database;
    return await db.update(
      'doctors',
      doctor.toMap(),
      where: 'id = ?',
      whereArgs: [doctor.id],
    );
  }

  Future<int> deleteDoctor(int id) async {
    Database db = await database;
    return await db.delete(
      'doctors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Doctor>> getAllDoctors() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('doctors');
    return List.generate(maps.length, (i) => Doctor.fromMap(maps[i]));
  }

  // Appointment operations
  Future<int> insertAppointment(Appointment appointment) async {
    Database db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<int> updateAppointmentStatus(int id, String status) async {
    Database db = await database;
    return await db.update(
      'appointments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAppointmentPayment(
      int id, String paymentMethod, bool isPaid, double amount) async {
    Database db = await database;
    return await db.update(
      'appointments',
      {
        'paymentMethod': paymentMethod,
        'isPaid': isPaid ? 1 : 0,
        'amount': amount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Appointment>> getUserAppointments(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, time ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<List<Appointment>> getDoctorAppointments(int doctorId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'doctorId = ?',
      whereArgs: [doctorId],
      orderBy: 'date ASC, time ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<List<Appointment>> getAllAppointments() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      orderBy: 'date DESC, time ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<List<Appointment>> getCompletedAppointments(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'userId = ? AND status = ? AND isPaid = ?',
      whereArgs: [userId, 'completed', 1],
      orderBy: 'date DESC, time ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<int> createAppointmentForUser(Appointment appointment) async {
    Database db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  // Message operations
  Future<int> insertMessage(Message message) async {
    Database db = await database;
    return await db.insert('messages', message.toMap());
  }

  Future<int> markMessageAsRead(int messageId) async {
    Database db = await database;
    return await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Message>> getMessages(int userId, int doctorId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [userId, doctorId, doctorId, userId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<List<Message>> getUserMessages(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'senderId = ? OR receiverId = ?',
      whereArgs: [userId, userId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }
}
