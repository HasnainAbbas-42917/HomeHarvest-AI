"""
HomeHarvest AI - Backend API
Requirements: pip install flask bcrypt flask-cors stripe
Run: python app.py
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import MySQLdb
import MySQLdb.cursors
import stripe
import bcrypt
import re
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import os

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS", "")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "")

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=False)


def get_db():
    conn = MySQLdb.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        passwd=os.getenv("DB_PASSWORD", ""),
        db=os.getenv("DB_NAME", "homeharvest"),
        cursorclass=MySQLdb.cursors.DictCursor
    )
    return conn


@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET,POST,PUT,DELETE,OPTIONS'
    return response


@app.route('/check-email', methods=['OPTIONS'])
@app.route('/change-password', methods=['OPTIONS'])
@app.route('/login', methods=['OPTIONS'])
@app.route('/signup', methods=['OPTIONS'])
def handle_options():
    return jsonify({}), 200


def init_db():
    conn = MySQLdb.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        passwd=os.getenv("DB_PASSWORD", ""),
        db=os.getenv("DB_NAME", "homeharvest"),
        cursorclass=MySQLdb.cursors.DictCursor
    )
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            name       VARCHAR(100)        NOT NULL,
            email      VARCHAR(150) UNIQUE NOT NULL,
            phone      VARCHAR(20)         NOT NULL,
            password   VARCHAR(255)        NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            name       VARCHAR(150)  NOT NULL,
            price      DECIMAL(10,2) NOT NULL,
            image_url  VARCHAR(500)  NOT NULL,
            category   VARCHAR(50)   NOT NULL,
            type       VARCHAR(50)   NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id               INT AUTO_INCREMENT PRIMARY KEY,
            order_number     VARCHAR(20)    NOT NULL UNIQUE,
            customer_name    VARCHAR(100)   NOT NULL,
            customer_email   VARCHAR(150)   NOT NULL,
            customer_phone   VARCHAR(20)    NOT NULL,
            delivery_address TEXT           NOT NULL,
            subtotal         DECIMAL(10,2)  NOT NULL,
            shipping         DECIMAL(10,2)  NOT NULL DEFAULT 150.00,
            total            DECIMAL(10,2)  NOT NULL,
            payment_method   VARCHAR(50)    NOT NULL DEFAULT 'Cash on Delivery',
            status           VARCHAR(30)    NOT NULL DEFAULT 'Pending',
            created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS order_items (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            order_id    INT           NOT NULL,
            name        VARCHAR(150)  NOT NULL,
            price       DECIMAL(10,2) NOT NULL,
            quantity    INT           NOT NULL,
            image_url   VARCHAR(500),
            category    VARCHAR(50),
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_history (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            user_email VARCHAR(150) NOT NULL,
            role       VARCHAR(10)  NOT NULL,
            message    TEXT         NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            session_id INT          NOT NULL DEFAULT 1
        )
    """)
    conn.commit()
    cur.execute("SELECT COUNT(*) as cnt FROM products")
    if cur.fetchone()['cnt'] == 0:
        products = [
            ('Snake Plant',        7000.00, 'https://images.unsplash.com/photo-1632207691143-643e2a9a9361?w=400', 'Plant', 'Indoor'),
            ('Fiddle Leaf',       12500.00, 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400', 'Plant', 'Indoor'),
            ('Monstera',           8400.00, 'https://images.unsplash.com/photo-1614594895304-fe7116ac3b58?w=400', 'Plant', 'Indoor'),
            ('Peace Lily',         7800.00, 'https://images.unsplash.com/photo-1593482892540-73c6d4537b5f?w=400', 'Plant', 'Indoor'),
            ('Pothos',             5600.00, 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400', 'Plant', 'Indoor'),
            ('Rose Bush',         11700.00, 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400', 'Plant', 'Outdoor'),
            ('Jasmine',           10600.00, 'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400', 'Plant', 'Outdoor'),
            ('Hibiscus',           9200.00, 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400', 'Plant', 'Outdoor'),
            ('Poinsettia',         6100.00, 'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=400', 'Plant', 'Seasonal'),
            ('Marigold',           2200.00, 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400', 'Plant', 'Seasonal'),
            ('Lavender',           3900.00, 'https://images.unsplash.com/photo-1611909023032-2d6b3134ecba?w=400', 'Plant', 'Seasonal'),
            ('Aloe Vera',          2800.00, 'https://images.unsplash.com/photo-1509587584298-0f3b3a3a1797?w=400', 'Plant', 'Seasonal'),
            ('Organic Fertilizer', 3350.00, 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400', 'Medicine', 'Care'),
            ('Neem Oil',           5000.00, 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400', 'Medicine', 'Care'),
            ('Root Boost',         4200.00, 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400', 'Medicine', 'Care'),
            ('Pest Control',       6100.00, 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400', 'Medicine', 'Care'),
        ]
        cur.executemany(
            "INSERT INTO products (name, price, image_url, category, type) VALUES (%s,%s,%s,%s,%s)",
            products
        )
        conn.commit()
        print("Products seeded!")
    cur.close()
    conn.close()


def send_order_email(to_email, customer_name, order_number, items, total, payment_method):
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'Order Confirmed - {order_number} | HomeHarvest AI'
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = to_email
        items_html = ''.join([
            f'<tr><td style="padding:8px;border-bottom:1px solid #eee;">{i["name"]}</td>'
            f'<td style="padding:8px;border-bottom:1px solid #eee;">x{i["quantity"]}</td>'
            f'<td style="padding:8px;border-bottom:1px solid #eee;">Rs.{i["price"]}</td></tr>'
            for i in items
        ])
        html = f"""
        <html><body style="font-family:sans-serif;max-width:600px;margin:auto;padding:20px;">
            <div style="background:#2D5233;padding:20px;border-radius:12px 12px 0 0;text-align:center;">
                <h1 style="color:white;margin:0;">HomeHarvest AI</h1>
            </div>
            <div style="background:white;padding:30px;border:1px solid #e5e7eb;">
                <h2 style="color:#1A2E1A;">Hi {customer_name}!</h2>
                <p>Order ID: <b>{order_number}</b> | Payment: {payment_method}</p>
                <table style="width:100%;border-collapse:collapse;">{items_html}</table>
                <p style="text-align:right;font-size:18px;font-weight:bold;color:#2D5233;">Total: Rs.{total}</p>
            </div>
        </body></html>
        """
        msg.attach(MIMEText(html, 'html'))
        with smtplib.SMTP('smtp.gmail.com', 587, timeout=30) as smtp:
            smtp.ehlo()
            smtp.starttls()
            smtp.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            smtp.sendmail(EMAIL_ADDRESS, to_email, msg.as_string())
        print(f'Order email sent to {to_email}')
    except Exception as e:
        print(f'Email error: {e}')


@app.route('/verify-password', methods=['POST', 'OPTIONS'])
def verify_password():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data     = request.get_json()
    email    = data.get('email', '').strip().lower()
    password = data.get('password', '').strip()
    if not email or not password:
        return jsonify({'message': 'Email and password are required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT password FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close(); conn.close()
        if not user:
            return jsonify({'match': False, 'message': 'User not found.'}), 404
        if bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({'match': True}), 200
        return jsonify({'match': False, 'message': 'Current password is incorrect.'}), 401
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/update-profile', methods=['POST', 'OPTIONS'])
def update_profile():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data     = request.get_json()
    email    = data.get('email', '').strip().lower()
    name     = data.get('name', '').strip()
    phone    = data.get('phone', '').strip()
    if not email:
        return jsonify({'message': 'Email is required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if not cur.fetchone():
            cur.close(); conn.close()
            return jsonify({'message': 'User not found.'}), 404
        cur.execute("UPDATE users SET name = %s, phone = %s WHERE email = %s", (name, phone, email))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Profile updated successfully.', 'user': {'name': name, 'phone': phone, 'email': email}}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/signup', methods=['POST'])
def signup():
    data     = request.get_json()
    name     = data.get('name', '').strip()
    email    = data.get('email', '').strip().lower()
    phone    = data.get('phone', '').strip()
    password = data.get('password', '').strip()

    if not all([name, email, phone, password]):
        return jsonify({'message': 'All fields are required.'}), 400
    if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email):
        return jsonify({'message': 'Invalid email address.'}), 400
    if len(password) < 8:
        return jsonify({'message': 'Password must be at least 8 characters.'}), 400

    hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            cur.close(); conn.close()
            return jsonify({'message': 'An account already exists with this email.'}), 409
        cur.execute(
            "INSERT INTO users (name, email, phone, password) VALUES (%s,%s,%s,%s)",
            (name, email, phone, hashed_pw.decode('utf-8'))
        )
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'User registered successfully.'}), 201
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/login', methods=['POST'])
def login():
    data     = request.get_json()
    email    = data.get('email', '').strip().lower()
    password = data.get('password', '').strip()

    if not email or not password:
        return jsonify({'message': 'Email and password are required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close(); conn.close()
        if not user:
            return jsonify({'message': 'Invalid email or password.'}), 401
        if bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({
                'message': 'Login successful.',
                'user': {'id': user['id'], 'name': user['name'], 'email': user['email'], 'phone': user['phone']}
            }), 200
        return jsonify({'message': 'Invalid email or password.'}), 401
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/check-email', methods=['POST'])
def check_email():
    data  = request.get_json()
    email = data.get('email', '').strip().lower()
    if not email:
        return jsonify({'message': 'Email is required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close(); conn.close()
        if user:
            return jsonify({'exists': True, 'message': 'Email found.'}), 200
        return jsonify({'exists': False, 'message': 'No account found.'}), 404
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/change-password', methods=['POST'])
def change_password():
    data         = request.get_json()
    email        = data.get('email', '').strip().lower()
    new_password = data.get('new_password', '').strip()
    if not email or not new_password:
        return jsonify({'message': 'Email and new password are required.'}), 400
    if len(new_password) < 8:
        return jsonify({'message': 'Password must be at least 8 characters.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if not cur.fetchone():
            cur.close(); conn.close()
            return jsonify({'message': 'No account found with this email.'}), 404
        hashed_pw = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
        cur.execute("UPDATE users SET password = %s WHERE email = %s", (hashed_pw.decode('utf-8'), email))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Password updated successfully.'}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/products', methods=['GET'])
def get_products():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT * FROM products ORDER BY category, type")
        rows = cur.fetchall()
        cur.close(); conn.close()
        return jsonify({'products': [{'id': r['id'], 'name': r['name'], 'price': float(r['price']),
                     'image_url': r['image_url'], 'category': r['category'], 'type': r['type']} for r in rows]}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/products/type/<product_type>', methods=['GET'])
def get_products_by_type(product_type):
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT * FROM products WHERE type=%s ORDER BY name", (product_type,))
        rows = cur.fetchall()
        cur.close(); conn.close()
        return jsonify({'products': [{'id': r['id'], 'name': r['name'], 'price': float(r['price']),
                     'image_url': r['image_url'], 'category': r['category'], 'type': r['type']} for r in rows]}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/search', methods=['GET'])
def search_products():
    query = request.args.get('q', '').strip()
    if not query:
        return jsonify({'products': []}), 200
    try:
        conn = get_db()
        cur = conn.cursor()
        s = f'%{query}%'
        cur.execute("SELECT * FROM products WHERE name LIKE %s OR category LIKE %s OR type LIKE %s", (s, s, s))
        rows = cur.fetchall()
        cur.close(); conn.close()
        return jsonify({'products': [{'id': r['id'], 'name': r['name'], 'price': float(r['price']),
                     'image_url': r['image_url'], 'category': r['category'], 'type': r['type']} for r in rows]}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/orders', methods=['POST'])
def place_order():
    data             = request.get_json()
    customer_name    = data.get('customer_name', '').strip()
    customer_email   = data.get('customer_email', '').strip().lower()
    customer_phone   = data.get('customer_phone', '').strip()
    delivery_address = data.get('delivery_address', '').strip()
    payment_method   = data.get('payment_method', 'Cash on Delivery').strip()
    items            = data.get('items', [])
    subtotal         = float(data.get('subtotal', 0))
    shipping         = float(data.get('shipping', 150))
    total            = float(data.get('total', 0))

    if not all([customer_name, customer_email, customer_phone, delivery_address]):
        return jsonify({'message': 'All customer fields are required.'}), 400
    if not items:
        return jsonify({'message': 'Cart is empty.'}), 400

    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM orders")
        count = cur.fetchone()['cnt']
        order_number = f'HH{45289 + count}'
        cur.execute("""
            INSERT INTO orders (order_number, customer_name, customer_email, customer_phone,
                 delivery_address, subtotal, shipping, total, payment_method, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'Pending')
        """, (order_number, customer_name, customer_email, customer_phone,
              delivery_address, subtotal, shipping, total, payment_method))
        order_id = cur.lastrowid
        for item in items:
            cur.execute("""
                INSERT INTO order_items (order_id, name, price, quantity, image_url, category)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (order_id, item.get('name', ''), float(item.get('price', 0)),
                  int(item.get('quantity', 1)), item.get('imageUrl', ''), item.get('category', '')))
        conn.commit()
        cur.close(); conn.close()
        try:
            send_order_email(customer_email, customer_name, order_number,
                [{'name': i.get('name'), 'quantity': int(i.get('quantity', 1)), 'price': float(i.get('price', 0))} for i in items],
                total, payment_method)
        except Exception as email_err:
            print(f'Order email failed: {email_err}')
        return jsonify({'message': 'Order placed successfully.', 'order_number': order_number, 'order_id': order_id}), 201
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/orders', methods=['GET'])
def get_orders():
    email = request.args.get('email', '').strip().lower()
    try:
        conn = get_db()
        cur = conn.cursor()
        if email:
            cur.execute("SELECT * FROM orders WHERE customer_email=%s ORDER BY created_at DESC", (email,))
        else:
            cur.execute("SELECT * FROM orders ORDER BY created_at DESC")
        orders = cur.fetchall()
        result = []
        for order in orders:
            cur.execute("SELECT * FROM order_items WHERE order_id=%s", (order['id'],))
            items = cur.fetchall()
            result.append({
                'id': order['id'], 'order_number': order['order_number'],
                'customer_name': order['customer_name'], 'customer_email': order['customer_email'],
                'customer_phone': order['customer_phone'], 'delivery_address': order['delivery_address'],
                'subtotal': float(order['subtotal']), 'shipping': float(order['shipping']),
                'total': float(order['total']), 'payment_method': order['payment_method'],
                'status': order['status'], 'created_at': str(order['created_at']),
                'items': [{'name': i['name'], 'price': float(i['price']), 'quantity': i['quantity'],
                           'image_url': i['image_url'], 'category': i['category']} for i in items],
            })
        cur.close(); conn.close()
        return jsonify({'orders': result}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/users', methods=['GET'])
def get_users():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT id, name, email, phone, created_at FROM users ORDER BY created_at DESC")
        rows = cur.fetchall()
        cur.close(); conn.close()
        return jsonify({'users': [{'id': r['id'], 'name': r['name'], 'email': r['email'],
                  'phone': r['phone'], 'created_at': str(r['created_at'])} for r in rows], 'total': len(rows)}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/stats', methods=['GET'])
def get_stats():
    try:
        conn = get_db()
        cur = conn.cursor()
        stats = {}
        for key, query in [
            ('total_users', "SELECT COUNT(*) as cnt FROM users"),
            ('total_orders', "SELECT COUNT(*) as cnt FROM orders"),
            ('pending_orders', "SELECT COUNT(*) as cnt FROM orders WHERE status='Pending'"),
            ('completed_orders', "SELECT COUNT(*) as cnt FROM orders WHERE status='Completed'"),
            ('delivered_orders', "SELECT COUNT(*) as cnt FROM orders WHERE status='Delivered'"),
            ('cancelled_orders', "SELECT COUNT(*) as cnt FROM orders WHERE status='Cancelled'"),
            ('total_plants', "SELECT COUNT(*) as cnt FROM products WHERE category='Plant'"),
            ('total_medicines', "SELECT COUNT(*) as cnt FROM products WHERE category='Medicine'"),
        ]:
            cur.execute(query)
            stats[key] = cur.fetchone()['cnt']
        cur.close(); conn.close()
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/orders/<int:order_id>/status', methods=['PATCH', 'POST', 'OPTIONS'])
def update_order_status(order_id):
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.get_json()
    status = data.get('status', '').strip()
    if status not in ['Pending', 'Completed', 'Cancelled', 'Delivered']:
        return jsonify({'message': 'Invalid status.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("UPDATE orders SET status=%s WHERE id=%s", (status, order_id))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Order status updated.'}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/create-checkout-session', methods=['POST', 'OPTIONS'])
def create_checkout_session():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    try:
        data        = request.get_json()
        order_items = data.get('items', [])
        line_items  = [{'price_data': {'currency': 'usd', 'product_data': {'name': i.get('name', 'Product')},
                        'unit_amount': max(50, int(float(i.get('price', 0)) / 280))}, 'quantity': i.get('quantity', 1)}
                       for i in order_items]
        line_items.append({'price_data': {'currency': 'usd', 'product_data': {'name': 'Shipping'}, 'unit_amount': 54}, 'quantity': 1})
        session = stripe.checkout.Session.create(
            payment_method_types=['card'], line_items=line_items, mode='payment',
            success_url='http://localhost:5000/payment-success?session_id={CHECKOUT_SESSION_ID}',
            cancel_url='http://localhost:5000/payment-cancel',
        )
        return jsonify({'url': session.url}), 200
    except Exception as e:
        return jsonify({'message': str(e)}), 500


@app.route('/add-product', methods=['POST', 'OPTIONS'])
def add_product():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data      = request.get_json()
    name      = data.get('name', '').strip()
    price     = data.get('price', 0)
    image_url = data.get('image_url', '').strip()
    category  = data.get('category', 'Plant').strip()
    ptype     = data.get('type', 'Indoor').strip()
    if not all([name, price, image_url]):
        return jsonify({'message': 'Name, price and image URL are required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO products (name, price, image_url, category, type) VALUES (%s,%s,%s,%s,%s)",
                    (name, float(price), image_url, category, ptype))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Product added successfully.'}), 201
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/delete-product/<int:product_id>', methods=['DELETE', 'POST', 'OPTIONS'])
def delete_product(product_id):
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM products WHERE id=%s", (product_id,))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Product deleted.'}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/favicon.ico')
def favicon():
    return '', 204


@app.route('/payment-success', methods=['GET'])
def payment_success():
    return '<html><body style="font-family:sans-serif;text-align:center;padding:50px;"><h1 style="color:#2D5233;">Payment Successful!</h1></body></html>'


@app.route('/payment-cancel', methods=['GET'])
def payment_cancel():
    return '<html><body style="font-family:sans-serif;text-align:center;padding:50px;"><h1 style="color:#E74C3C;">Payment Cancelled</h1></body></html>'


# --- Plant Disease Detection Setup --------------------------------------
import numpy as np
from PIL import Image
import io
import json as _json
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from torchvision import models


def conv_block(in_channels, out_channels, pool=False):
    layers = [nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1),
              nn.BatchNorm2d(out_channels), nn.ReLU(inplace=True)]
    if pool:
        layers.append(nn.MaxPool2d(2))
    return nn.Sequential(*layers)


class ResNet9(nn.Module):
    def __init__(self, in_channels, num_classes):
        super().__init__()
        self.conv1 = conv_block(in_channels, 64)
        self.conv2 = conv_block(64, 128, pool=True)
        self.res1  = nn.Sequential(conv_block(128, 128), conv_block(128, 128))
        self.conv3 = conv_block(128, 256, pool=True)
        self.conv4 = conv_block(256, 512, pool=True)
        self.res2  = nn.Sequential(conv_block(512, 512), conv_block(512, 512))
        self.classifier = nn.Sequential(nn.MaxPool2d(4), nn.Flatten(),
                                        nn.Linear(512, num_classes))
    def forward(self, x):
        out = self.conv1(x)
        out = self.conv2(out)
        out = self.res1(out) + out
        out = self.conv3(out)
        out = self.conv4(out)
        out = self.res2(out) + out
        return self.classifier(out)

_disease_model = None
_class_indices = None

def get_disease_model():
    global _disease_model, _class_indices
    if _disease_model is not None:
        return _disease_model, _class_indices
    model_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'plant-disease-model-complete.pth')
    if not os.path.exists(model_path):
        return None, None
    _disease_model = torch.load(model_path, map_location=torch.device('cpu'), weights_only=False)
    _disease_model.eval()
    idx_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'class_indices.json')
    with open(idx_path, 'r') as f:
        _class_indices = _json.load(f)
    print('Plant disease model loaded!')
    return _disease_model, _class_indices


_transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
])


@app.route('/predict-disease', methods=['POST', 'OPTIONS'])
def predict_disease():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    try:
        if 'image' not in request.files:
            return jsonify({'message': 'No image provided.'}), 400
        model, class_indices = get_disease_model()
        if model is None:
            return jsonify({'message': 'Model not loaded. Please add plant-disease-model-complete.pth to the project folder.'}), 500
        file = request.files['image']
        img  = Image.open(io.BytesIO(file.read())).convert('RGB')
        tensor = _transform(img).unsqueeze(0)
        with torch.no_grad():
            outputs = model(tensor)
            probs   = torch.softmax(outputs, dim=1)[0]
        idx        = int(torch.argmax(probs).item())
        confidence = float(probs[idx].item()) * 100
        label      = class_indices.get(str(idx), 'Unknown')
        parts      = label.split('___')
        plant      = parts[0].replace('_', ' ') if len(parts) > 0 else 'Unknown'
        disease    = parts[1].replace('_', ' ') if len(parts) > 1 else 'Unknown'
        is_healthy = 'healthy' in disease.lower()
        return jsonify({
            'plant': plant,
            'disease': disease,
            'is_healthy': is_healthy,
            'confidence': round(confidence, 2),
            'label': label
        }), 200
    except Exception as e:
        return jsonify({'message': f'Prediction error: {str(e)}'}), 500


# --- ChromaDB RAG Setup --------------------------------------------------
import chromadb
from chromadb.utils import embedding_functions
import os
import requests as req

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

_collection = None

def get_rag_collection():
    global _collection
    if _collection is not None:
        return _collection
    client = chromadb.PersistentClient(path='./chroma_db')
    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name='all-MiniLM-L6-v2')
    _collection = client.get_or_create_collection(name='plant_knowledge', embedding_function=ef)
    if _collection.count() == 0:
        kb_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'plant_knowledge.txt')
        with open(kb_path, 'r', encoding='utf-8') as f:
            content = f.read()
        chunks = [c.strip() for c in content.split('---') if len(c.strip()) > 50]
        _collection.add(documents=chunks, ids=[f'chunk_{i}' for i in range(len(chunks))])
        print(f'RAG: Loaded {len(chunks)} chunks into ChromaDB')
    return _collection


PLANT_KEYWORDS = [
    'plant', 'flower', 'tree', 'leaf', 'leaves', 'root', 'soil', 'water', 'watering',
    'fertilizer', 'fertilize', 'pest', 'disease', 'fungus', 'mold', 'rot', 'aphid',
    'mite', 'insect', 'bug', 'spray', 'neem', 'garden', 'gardening', 'grow', 'growing',
    'seed', 'pot', 'repot', 'sunlight', 'light', 'humidity', 'prune', 'pruning',
    'monstera', 'pothos', 'jasmine', 'rose', 'hibiscus', 'lavender', 'aloe', 'marigold',
    'snake plant', 'peace lily', 'fiddle', 'poinsettia', 'tomato', 'chilli', 'mint',
    'coriander', 'spinach', 'fruit', 'vegetable', 'herb', 'homeharvest', 'seasonal',
    'indoor', 'outdoor', 'care', 'tip', 'brown', 'yellow', 'drooping', 'wilting',
    'propagate', 'propagation', 'cutting', 'compost', 'mulch', 'bloom', 'blossom'
]

CODING_KEYWORDS = [
    'code', 'coding', 'python', 'javascript', 'java', 'program', 'programming',
    'function', 'class', 'algorithm', 'script', 'html', 'css', 'build me',
    'write me', 'create a function', 'create a class', 'develop', 'flutter',
    'dart', 'c++', 'c#', 'ruby', 'php', 'swift', 'kotlin', 'react', 'angular',
    'database', 'api', 'server', 'backend', 'frontend', 'framework', 'library'
]

OFF_TOPIC_KEYWORDS = [
    'weather', 'news', 'politics', 'movie', 'music', 'sport', 'football',
    'cricket', 'cooking', 'recipe', 'food', 'travel', 'history', 'math',
    'physics', 'chemistry', 'biology', 'economics', 'finance', 'stock',
    'crypto', 'bitcoin', 'joke', 'story', 'essay', 'translate', 'language'
]

def is_plant_related(text):
    text_lower = text.lower()
    if any(kw in text_lower for kw in CODING_KEYWORDS):
        return False
    if any(kw in text_lower for kw in OFF_TOPIC_KEYWORDS):
        return False
    return any(kw in text_lower for kw in PLANT_KEYWORDS)


def query_rag(question, n_results=3):
    collection = get_rag_collection()
    results = collection.query(query_texts=[question], n_results=n_results)
    docs = results['documents'][0] if results['documents'] else []
    distances = results['distances'][0] if results['distances'] else []
    return [doc for doc, dist in zip(docs, distances) if dist < 1.2]


def _get_current_session(email):
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT MAX(session_id) as sid FROM chat_history WHERE user_email=%s", (email,))
        row = cur.fetchone()
        cur.close(); conn.close()
        return row['sid'] if row['sid'] else 1
    except:
        return 1


def _save_chat(email, role, message):
    try:
        session_id = _get_current_session(email)
        conn = get_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO chat_history (user_email, role, message, session_id) VALUES (%s, %s, %s, %s)", (email, role, message, session_id))
        conn.commit()
        cur.close(); conn.close()
    except Exception as e:
        print(f'Chat save error: {e}')


def _get_recent_history(email, limit=6):
    try:
        session_id = _get_current_session(email)
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT role, message FROM chat_history WHERE user_email=%s AND session_id=%s ORDER BY created_at DESC LIMIT %s", (email, session_id, limit))
        rows = cur.fetchall()
        cur.close(); conn.close()
        return list(reversed(rows))
    except:
        return []


@app.route('/chatbot', methods=['POST', 'OPTIONS'])
def chatbot():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    try:
        data         = request.get_json()
        user_message = data.get('message', '').strip()
        user_email   = data.get('email', '').strip().lower()
        if not user_message:
            return jsonify({'message': 'Message is required.'}), 400

        relevant_chunks = query_rag(user_message, n_results=2)

        if not is_plant_related(user_message) and not relevant_chunks:
            reply = 'Sorry, I can only answer questions related to plants, gardening, plant care, diseases, fertilizers, and the HomeHarvest app. Please ask me a plant-related question! 🌿'
            if user_email:
                _save_chat(user_email, 'user', user_message)
                _save_chat(user_email, 'bot', reply)
            return jsonify({'reply': reply}), 200

        context = '\n\n'.join(relevant_chunks)

        # Fetch medicines/products from DB
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute("SELECT name, price, image_url, category, type FROM products WHERE category='Medicine' ORDER BY name")
            medicines = cur.fetchall()
            cur.close(); conn.close()
            medicine_list = '\n'.join([f"- {m['name']} (Rs.{m['price']})" for m in medicines])
            medicines_json = [{'name': m['name'], 'price': float(m['price']), 'image_url': m['image_url'], 'category': m['category']} for m in medicines]
        except:
            medicine_list = 'No products available'
            medicines_json = []

        system_prompt = f"""You are HomeHarvest AI Assistant, a plant expert for the HomeHarvest app in Pakistan.
Use the knowledge base below to answer plant-related questions.
Keep answers helpful, friendly, and concise.

When recommending treatments, ALWAYS recommend the most relevant products from our store:

PRODUCT GUIDE (match to disease type):
- Apple scab, Black rot, Cedar rust → Copper Fungicide Spray, Mancozeb Fungicide, Systemic Fungicide
- Powdery mildew (Cherry, Squash) → Sulfur Dust Fungicide, Potassium Silicate, Bio Fungicide Trichoderma
- Bacterial spot (Peach, Pepper, Tomato) → Bactericide Copper Spray, Streptomycin Solution
- Tomato mosaic virus, Yellow leaf curl virus → Virus Shield Spray, Imidacloprid Insecticide
- Spider mites → Miticide Spray, Abamectin Acaricide, Neem Oil
- Potato/Tomato Early blight, Late blight → Chlorothalonil Spray, Metalaxyl Fungicide, Mancozeb Fungicide
- Tomato Leaf Mold, Septoria, Target Spot → Systemic Fungicide, Copper Fungicide Spray
- Grape Black rot, Leaf blight, Esca → Mancozeb Fungicide, Systemic Fungicide, Copper Fungicide Spray
- Orange Haunglongbing (Citrus greening) → Citrus Nutrient Booster, Zinc Sulfate Spray, Imidacloprid Insecticide
- Strawberry Leaf scorch → Copper Fungicide Spray, Bio Fungicide Trichoderma
- Corn Cercospora, Rust, Northern Leaf Blight → Mancozeb Fungicide, Chlorothalonil Spray
- General pest/insect → Pest Control, Neem Oil, Imidacloprid Insecticide
- Root problems, recovery → Root Boost, Organic Fertilizer
- Plant immunity boost → Potassium Silicate, Organic Fertilizer, Bio Fungicide Trichoderma

ALWAYS recommend 2-3 specific products by their EXACT name from the store list below.
Also suggest general treatments alongside store products.

HOMEHARVEST STORE MEDICINES & PRODUCTS:
{medicine_list}

KNOWLEDGE BASE:
{context}"""

        history_messages = _get_recent_history(user_email, limit=4) if user_email else []
        messages = [{'role': 'system', 'content': system_prompt}]
        for h in history_messages:
            messages.append({'role': 'user' if h['role'] == 'user' else 'assistant', 'content': h['message']})
        messages.append({'role': 'user', 'content': user_message})

        response = req.post(
            'https://api.groq.com/openai/v1/chat/completions',
            headers={'Authorization': f'Bearer {GROQ_API_KEY}', 'Content-Type': 'application/json'},
            json={'model': GROQ_MODEL, 'messages': messages, 'temperature': 0.5, 'max_tokens': 400},
            timeout=30
        )

        if response.status_code == 200:
            reply = response.json()['choices'][0]['message']['content']
            # Always return all medicines when it's a disease-related query
            mentioned_products = [m for m in medicines_json if m['name'].lower() in reply.lower()]
            # If less than 2 matched, return all medicines so user sees full store
            if len(mentioned_products) < 2:
                mentioned_products = medicines_json
            if user_email:
                _save_chat(user_email, 'user', user_message)
                _save_chat(user_email, 'bot', reply)
            return jsonify({'reply': reply, 'products': mentioned_products}), 200
        return jsonify({'message': f'Groq error: {response.text}'}), 500
    except Exception as e:
        return jsonify({'message': f'Chatbot error: {str(e)}'}), 500


@app.route('/chat-history', methods=['GET', 'OPTIONS'])
def get_chat_history():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.args.get('email', '').strip().lower()
    if not email:
        return jsonify({'history': [], 'sessions': []}), 200
    try:
        conn = get_db()
        cur = conn.cursor()
        # Get current session messages
        session_id = _get_current_session(email)
        cur.execute("SELECT role, message, created_at FROM chat_history WHERE user_email=%s AND session_id=%s ORDER BY created_at ASC", (email, session_id))
        current = cur.fetchall()
        # Get all past sessions (older sessions)
        cur.execute("SELECT DISTINCT session_id FROM chat_history WHERE user_email=%s ORDER BY session_id ASC", (email,))
        session_ids = [r['session_id'] for r in cur.fetchall()]
        sessions = []
        for sid in session_ids:
            cur.execute("SELECT message, created_at FROM chat_history WHERE user_email=%s AND session_id=%s AND role='user' ORDER BY created_at ASC LIMIT 1", (email, sid))
            first = cur.fetchone()
            if first:
                sessions.append({'session_id': sid, 'preview': first['message'][:40], 'time': str(first['created_at'])})
        cur.close(); conn.close()
        return jsonify({
            'history': [{'role': r['role'], 'message': r['message'], 'time': str(r['created_at'])} for r in current],
            'sessions': sessions,
            'current_session': session_id
        }), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/chat-session', methods=['GET', 'OPTIONS'])
def get_session_messages():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.args.get('email', '').strip().lower()
    session_id = request.args.get('session_id', '1')
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT role, message, created_at FROM chat_history WHERE user_email=%s AND session_id=%s ORDER BY created_at ASC", (email, session_id))
        rows = cur.fetchall()
        cur.close(); conn.close()
        return jsonify({'history': [{'role': r['role'], 'message': r['message'], 'time': str(r['created_at'])} for r in rows]}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/new-chat', methods=['POST', 'OPTIONS'])
def new_chat():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.get_json().get('email', '').strip().lower()
    if not email:
        return jsonify({'message': 'Email required.'}), 400
    try:
        current_session = _get_current_session(email)
        # Only create new session if current session has messages
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM chat_history WHERE user_email=%s AND session_id=%s", (email, current_session))
        count = cur.fetchone()['cnt']
        cur.close(); conn.close()
        if count == 0:
            return jsonify({'session_id': current_session}), 200
        new_session = current_session + 1
        return jsonify({'session_id': new_session}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/delete-chat-session', methods=['POST', 'OPTIONS'])
def delete_chat_session():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.get_json()
    email = data.get('email', '').strip().lower()
    session_id = data.get('session_id')
    if not email or session_id is None:
        return jsonify({'message': 'Email and session_id required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM chat_history WHERE user_email=%s AND session_id=%s", (email, session_id))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Session deleted.'}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


@app.route('/clear-chat-history', methods=['POST', 'OPTIONS'])
def clear_chat_history():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.get_json().get('email', '').strip().lower()
    if not email:
        return jsonify({'message': 'Email required.'}), 400
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM chat_history WHERE user_email=%s", (email,))
        conn.commit()
        cur.close(); conn.close()
        return jsonify({'message': 'Chat history cleared.'}), 200
    except Exception as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500


if __name__ == '__main__':
    init_db()
    get_rag_collection()
    app.run(host='0.0.0.0', port=5000, debug=True)
