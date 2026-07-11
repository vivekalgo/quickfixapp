const fs = require('fs');
const db = JSON.parse(fs.readFileSync('database.json', 'utf8'));
for (const shop of db.shops) {
  console.log(`Shop: ${shop.name} (${shop.id})`);
  for (const srv of shop.services) {
    console.log(` - Service: ${srv.title} (${srv.id})`);
    console.log(`   * pricingType: ${srv.pricingType}`);
    console.log(`   * price: ${srv.price}`);
    console.log(`   * gst: ${srv.gst} (type: ${typeof srv.gst})`);
    console.log(`   * extraCharges: ${srv.extraCharges} (type: ${typeof srv.extraCharges})`);
    console.log(`   * extraChargesLabel: "${srv.extraChargesLabel}"`);
  }
}
