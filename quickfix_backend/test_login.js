const https = require('https');

const data = JSON.stringify({
  shopId: 'TEST',
  password: 'TEST'
});

const options = {
  hostname: 'quickfixapp-production.up.railway.app',
  path: '/api/provider/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  console.log('Status Code:', res.statusCode);
  
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('Response Body:', body);
  });
});

req.on('error', (error) => {
  console.error('Request Error:', error.message);
});

req.write(data);
req.end();
