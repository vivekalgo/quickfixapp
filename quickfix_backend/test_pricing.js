const assert = require('assert');
const { calculateCheckoutPriceInternal } = require('./pricingCalculator');
const { setUseLocalDb, Shop, Offer, Settings } = require('./models');

// Set mock database to use local JSON database, or define direct testing
setUseLocalDb(true);

async function runTests() {
  console.log('Running pricing calculation logic tests...\n');

  // Test Case A: Fixed Price service
  const mockShopA = {
    id: 'shop-test-a',
    visitingCharges: 150,
    services: [
      {
        id: 'srv-fixed-1',
        title: 'Fixed Price Service',
        price: 500,
        pricingType: 'fixed',
        visitingCharges: 150,
        isFreeInspection: false,
        gst: 18,
        extraCharges: 50,
        extraChargesLabel: 'Material Cost'
      }
    ]
  };

  // 1. Without Coupon
  const calcA1 = await calculateCheckoutPriceInternal(mockShopA, [{ id: 'srv-fixed-1', quantity: 1 }], null);
  console.log('Test A1 (Fixed Price, No Coupon) Result:');
  console.log(' - Service Price:', calcA1.servicePrice);
  console.log(' - Visiting Charge:', calcA1.visitingCharge);
  console.log(' - GST:', calcA1.gst);
  console.log(' - Extra Charges:', calcA1.extraChargesTotal);
  console.log(' - Grand Total:', calcA1.grandTotal);
  
  assert.strictEqual(calcA1.servicePrice, 500);
  assert.strictEqual(calcA1.visitingCharge, 150);
  assert.strictEqual(calcA1.gst, 90); // 500 * 18% = 90
  assert.strictEqual(calcA1.extraChargesTotal, 50);
  assert.strictEqual(calcA1.grandTotal, 790); // 500 + 150 + 90 + 50 = 790
  console.log('✔ Test A1 passed!\n');

  // 2. With Coupon (QUICK20)
  // Seed coupon offer to local database first
  const offer = new Offer({
    code: 'QUICK20',
    title: '20% off',
    description: 'Save 20%',
    isActive: true
  });
  await offer.save();

  const calcA2 = await calculateCheckoutPriceInternal(mockShopA, [{ id: 'srv-fixed-1', quantity: 1 }], 'QUICK20');
  console.log('Test A2 (Fixed Price, With Coupon QUICK20) Result:');
  console.log(' - Service Price:', calcA2.servicePrice);
  console.log(' - Visiting Charge:', calcA2.visitingCharge);
  console.log(' - GST:', calcA2.gst);
  console.log(' - Coupon Discount:', calcA2.couponDiscount);
  console.log(' - Grand Total:', calcA2.grandTotal);

  assert.strictEqual(calcA2.couponDiscount, 100); // 500 * 20% = 100
  assert.strictEqual(calcA2.grandTotal, 690); // 790 - 100 = 690
  console.log('✔ Test A2 passed!\n');

  // Test Case B: Starts From
  const mockShopB = {
    id: 'shop-test-b',
    visitingCharges: 150,
    services: [
      {
        id: 'srv-starts-1',
        title: 'Starts From Service',
        price: 299,
        pricingType: 'starting',
        visitingCharges: 150,
        isFreeInspection: false
      }
    ]
  };

  const calcB1 = await calculateCheckoutPriceInternal(mockShopB, [{ id: 'srv-starts-1', quantity: 1 }], null);
  console.log('Test B1 (Starts From, No Coupon) Result:');
  console.log(' - Visiting Charge Today:', calcB1.visitingCharge);
  console.log(' - Estimated Service Price:', calcB1.estimatedPriceText);
  console.log(' - Grand Total Today:', calcB1.grandTotal);
  console.log(' - Banner:', calcB1.redBannerText);

  assert.strictEqual(calcB1.visitingCharge, 150);
  assert.strictEqual(calcB1.grandTotal, 150);
  assert.strictEqual(calcB1.estimatedPriceText, 'Starts From ₹299');
  assert.ok(calcB1.redBannerText.includes('Final amount may increase'));
  console.log('✔ Test B1 passed!\n');

  // Test Case C: Price Range
  const mockShopC = {
    id: 'shop-test-c',
    visitingCharges: 200,
    services: [
      {
        id: 'srv-range-1',
        title: 'Range Service',
        minPrice: 500,
        maxPrice: 1200,
        pricingType: 'range',
        visitingCharges: 200,
        isFreeInspection: false
      }
    ]
  };

  const calcC1 = await calculateCheckoutPriceInternal(mockShopC, [{ id: 'srv-range-1', quantity: 1 }], null);
  console.log('Test C1 (Price Range) Result:');
  console.log(' - Visiting Charge Today:', calcC1.visitingCharge);
  console.log(' - Estimated Price Range:', calcC1.estimatedPriceText);
  console.log(' - Grand Total Today:', calcC1.grandTotal);

  assert.strictEqual(calcC1.visitingCharge, 200);
  assert.strictEqual(calcC1.grandTotal, 200);
  assert.strictEqual(calcC1.estimatedPriceText, '₹500 - ₹1200');
  console.log('✔ Test C1 passed!\n');

  // Test Case D: Quote Required
  const mockShopD = {
    id: 'shop-test-d',
    visitingCharges: 150,
    services: [
      {
        id: 'srv-quote-1',
        title: 'Quote Service',
        pricingType: 'inspection',
        visitingCharges: 150,
        isFreeInspection: false
      }
    ]
  };

  const calcD1 = await calculateCheckoutPriceInternal(mockShopD, [{ id: 'srv-quote-1', quantity: 1 }], null);
  console.log('Test D1 (Quote Required) Result:');
  console.log(' - Visiting Charge Today:', calcD1.visitingCharge);
  console.log(' - Grand Total Today:', calcD1.grandTotal);

  assert.strictEqual(calcD1.visitingCharge, 150);
  assert.strictEqual(calcD1.grandTotal, 150);
  console.log('✔ Test D1 passed!\n');

  // Test Case E: Free Inspection
  const mockShopE = {
    id: 'shop-test-e',
    visitingCharges: 150,
    services: [
      {
        id: 'srv-free-1',
        title: 'Free Inspection Service',
        pricingType: 'inspection',
        visitingCharges: 150,
        isFreeInspection: true
      }
    ]
  };

  const calcE1 = await calculateCheckoutPriceInternal(mockShopE, [{ id: 'srv-free-1', quantity: 1 }], null);
  console.log('Test E1 (Free Inspection) Result:');
  console.log(' - Visiting Charge Today:', calcE1.visitingCharge);
  console.log(' - Grand Total Today:', calcE1.grandTotal);
  console.log(' - isFreeInspection:', calcE1.isFreeInspection);

  assert.strictEqual(calcE1.visitingCharge, 0);
  assert.strictEqual(calcE1.grandTotal, 0);
  assert.strictEqual(calcE1.isFreeInspection, true);
  console.log('✔ Test E1 passed!\n');

  console.log('All backend pricing logic tests passed successfully!');
}

runTests().catch(err => {
  console.error('Test Execution Failed:', err);
  process.exit(1);
});
