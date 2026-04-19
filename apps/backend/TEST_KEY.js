const apiKey = "AIzaSyDmm3fcvr25LOEkvOSWX7gWIkJTFmRI6Uw";
const url15 = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
const url25 = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

async function testKey(url, name) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: "Hello" }] }]
    })
  });
  const data = await response.json();
  console.log(`Status ${name}:`, response.status);
  if (response.status !== 200) console.log(data);
}

testKey(url15, '1.5-flash').then(() => testKey(url25, '2.5-flash'));
