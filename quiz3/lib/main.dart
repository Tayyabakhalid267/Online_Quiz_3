import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daraz Style Auth App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SignInPage(),
    );
  }
}

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  static Future<Database> initDb() async {
    String dbPath = join(await getDatabasesPath(), 'user.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE,
          firstName TEXT,
          lastName TEXT,
          username TEXT,
          password TEXT
        )
        ''');
      },
    );
  }

  static Future<int> insertUser(Map<String, dynamic> user) async {
    final dbClient = await db;
    return await dbClient.insert('users', user);
  }

  static Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final dbClient = await db;
    final result = await dbClient.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }
}

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void _signIn() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    final user = await DBHelper.getUser(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (user != null) {
      Fluttertoast.showToast(
        msg: "🎉 Congratulations ${user['firstName']}, you are successfully logged in!",
        backgroundColor: Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
      );
    } else {
      Fluttertoast.showToast(
        msg: "❌ Invalid credentials",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              Icon(Icons.lock_open, size: 80, color: Colors.deepOrange),
              SizedBox(height: 20),
              Text("Welcome Back!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              SizedBox(height: 24),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _signIn,
                icon: Icon(Icons.login),
                label: Text("Sign In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpPage()),
                ),
                child: Text("Don't have an account? Sign Up"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Icon(Icons.person_add_alt_1, size: 60, color: Colors.deepOrange),
            SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                try {
                  await DBHelper.insertUser({
                    'email': emailController.text.trim(),
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'username': usernameController.text.trim(),
                    'password': passwordController.text.trim(),
                  });
                  Fluttertoast.showToast(
                    msg: "🎉 Hello dear ${firstNameController.text.trim()}! Your account has been created.",
                    backgroundColor: Colors.blue,
                  );
                  Navigator.pop(context);
                } catch (e) {
                  Fluttertoast.showToast(msg: "⚠️ Email already exists!", backgroundColor: Colors.red);
                }
              },
              child: Text("Register"),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  HomePage({required this.user});

  final List<Map<String, String>> items = [
    {
      'image': 'https://images.unsplash.com/photo-1581579185169-751c7c05a8a0',
      'name': 'Wireless Headphones',
      'desc': 'High quality sound with long battery life.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
      'name': 'Smart Watch',
      'desc': 'Track your fitness and notifications on the go.'
    },
    {
      'image': 'https://images.unsplash.com/photo-1512499617640-c2f999097c30',
      'name': 'Fashion Shoes',
      'desc': 'Comfortable and stylish footwear for daily use.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text("Daraz Clone Home"),
        actions: [Icon(Icons.shopping_cart)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: Image.network(item['image']!, width: 60, fit: BoxFit.cover),
                    title: Text(item['name']!),
                    subtitle: Text(item['desc']!),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}