const fs = require('fs');
const { calculateCheckoutPriceInternal } = require('./pricingCalculator');
const { setUseLocalDb, Shop } = require('./models');

setUseLocalDb(true);

async function test() {
  console.log('Testing calculate endpoint with database update...');

  // 1. Load shop-cleaning-expert
  const shop = await Shop.findOne({ id: 'shop-cleaning-expert' });
  if (!shop) {
    console.error('Shop not found!');
    return;
  }

  // 2. Mock provider updating service 'clean-1' with GST and extra charges
  const updatedServices = shop.services.map(s => {
    if (s.id === 'clean-1') {
      return {
        ...s,
        gst: 18,
        extraCharges: 50,
        extraChargesLabel: 'Material Cost'
      };
    }
    return s;
  });

  shop.services = updatedServices;
  await shop.save();
  console.log('Updated service clean-1 with GST=18% and extraCharges=50 in local DB.');

  // 3. Reload shop from DB to simulate clean calculate endpoint lookup
  const reloadedShop = await Shop.findOne({ id: 'shop-cleaning-expert' });
  const items = [{ id: 'clean-1', quantity: 1 }];

  // 4. Calculate checkout price
  const result = await calculateCheckoutPriceInternal(reloadedShop, items, null);
  console.log('\nCalculation Result:');
  console.log(' - pricingType:', result.pricingType);
  console.log(' - subtotal:', result.subtotal);
  console.log(' - gst:', result.gst);
  console.log(' - extraChargesTotal:', result.extraChargesTotal);
  console.log(' - grandTotal:', result.grandTotal);
  console.log(' - billDetails:', JSON.stringify(result.billDetails, null, 2));

  // Reset database back to clean state
  const cleanServices = shop.services.map(s => {
    if (s.id === 'clean-1') {
      const cleanSrv = { ...s };
      delete cleanSrv.gst;
      delete cleanSrv.extraCharges;
      delete cleanSrv.extraChargesLabel;
      return cleanSrv;
    }
    return s;
  });
  shop.services = cleanServices;
  await shop.save();
}

test().catch(console.error);
