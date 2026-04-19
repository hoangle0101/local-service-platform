const fs = require('fs');
const jwt = require('jsonwebtoken');

async function testApi() {
  try {
    const token = jwt.sign({ sub: 1, email: 'test@test.com' }, process.env.JWT_SECRET || 'change-me-in-production', { expiresIn: '1h' });
    
    // Read package.json
    const fileBuffer = fs.readFileSync('package.json');
    
    // Construct simplified multipart/form-data
    const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    let body = Buffer.from('');
    body = Buffer.concat([
      body, 
      Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="package.json"\r\nContent-Type: application/json\r\n\r\n`)
    ]);
    body = Buffer.concat([body, fileBuffer]);
    body = Buffer.concat([body, Buffer.from(`\r\n--${boundary}--\r\n`)]);

    const response = await fetch('http://127.0.0.1:3000/ai/analyze-issue', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`
      },
      body: body
    });

    const text = await response.text();
    console.log('Status:', response.status);
    console.log('Body:', text);
  } catch (error) {
    console.error('Error:', error);
  }
}

testApi();
