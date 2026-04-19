const apiKey = "AIzaSyDmm3fcvr25LOEkvOSWX7gWIkJTFmRI6Uw";

async function testKey(model) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: "Hello" }] }]
    })
  });
  const data = await response.json();
  console.log(`Status ${model}:`, response.status);
  if (response.status !== 200) {
    if (data.error) console.log(data.error.message);
    else console.log(data);
  }
}

async function run() {
  await testKey('gemini-2.5-flash');
  await testKey('gemini-2.0-flash');
  await testKey('gemini-2.0-flash-lite');
  await testKey('gemini-1.5-flash');
}
run();
