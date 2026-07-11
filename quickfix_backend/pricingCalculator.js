const { Settings, Offer } = require('./models');

/**
 * Recalculates checking out prices dynamically for any given shop, items, and coupon.
 * Supports Fixed, Starts From, Price Range, and Quote Required models.
 * 
 * @param {Object} shop The shop document
 * @param {Array} items Array of { id: String, quantity: Number }
 * @param {String} couponCode Coupon code string (optional)
 * @returns {Promise<Object>} Calculated amounts and formatting info
 */
async function calculateCheckoutPriceInternal(shop, items, couponCode) {
  let bookingPricingType = 'fixed';
  let hasInspection = false;
  let hasStarting = false;
  let hasRange = false;

  const cartServices = [];
  for (const item of items) {
    const srv = shop.services.find(s => s.id === item.id);
    if (srv) {
      cartServices.push({ service: srv, quantity: item.quantity });
      if (srv.pricingType === 'inspection') hasInspection = true;
      else if (srv.pricingType === 'starting') hasStarting = true;
      else if (srv.pricingType === 'range') hasRange = true;
    }
  }

  // Determine overall pricing type based on priority: inspection > starting > range > fixed
  if (hasInspection) bookingPricingType = 'inspection';
  else if (hasStarting) bookingPricingType = 'starting';
  else if (hasRange) bookingPricingType = 'range';

  // Free inspection logic: if any service in cart is free inspection, then visiting charge today is free
  const isFreeInspection = cartServices.some(cs => cs.service.isFreeInspection === true);

  // Visiting charge logic: max of (isFreeInspection ? 0 : visitingCharges) across services
  let visitingCharge = 0;
  if (!isFreeInspection && cartServices.length > 0) {
    const effectiveVisitingCharges = cartServices.map(cs => {
      if (cs.service.isFreeInspection) return 0;
      // Use service visitingCharges if set and > 0, otherwise fallback to shop visitingCharges
      return (cs.service.visitingCharges !== undefined && cs.service.visitingCharges > 0)
        ? cs.service.visitingCharges 
        : (shop.visitingCharges !== undefined ? shop.visitingCharges : 150.0);
    });
    visitingCharge = Math.max(...effectiveVisitingCharges, 0);
  }

  let servicePrice = 0;
  let extraChargesTotal = 0;
  const extraChargesList = [];
  let gstTotal = 0;

  for (const cs of cartServices) {
    const srv = cs.service;
    const qty = cs.quantity;

    let itemTaxable = 0;
    if (srv.pricingType === 'fixed') {
      itemTaxable = srv.price * qty;
      servicePrice += itemTaxable;
    }

    if (srv.pricingType === 'fixed' && srv.gst > 0) {
      const itemGst = itemTaxable * (srv.gst / 100);
      gstTotal += itemGst;
    }

    if (srv.extraCharges > 0) {
      const extraAmt = srv.extraCharges * qty;
      extraChargesTotal += extraAmt;
      extraChargesList.push({
        label: srv.extraChargesLabel || 'Material Cost',
        amount: extraAmt
      });
    }
  }

  // Round GST correctly
  gstTotal = Math.round(gstTotal);

  // Convenience & safety fee
  let convenienceFee = 0.0;
  if (bookingPricingType === 'fixed' && servicePrice > 0) {
    const platformFeeSetting = await Settings.findOne({ key: 'platform_fee_enabled' });
    const platformFeeEnabled = platformFeeSetting ? (platformFeeSetting.value === true) : false;
    if (platformFeeEnabled) {
      let platformFeeAmt = 49.0;
      const platformFeeAmtSetting = await Settings.findOne({ key: 'platform_fee_amount' });
      if (platformFeeAmtSetting && !isNaN(platformFeeAmtSetting.value)) {
        platformFeeAmt = parseFloat(platformFeeAmtSetting.value);
      }
      convenienceFee = platformFeeAmt;
    }
  }

  // Subtotal (amount to pay today before coupon and convenience fee)
  let subtotal = 0;
  if (bookingPricingType === 'fixed') {
    subtotal = servicePrice + visitingCharge + extraChargesTotal + gstTotal;
  } else {
    subtotal = visitingCharge; // only inspection fee collected today
  }

  // Coupon discount calculation
  let couponDiscount = 0;
  let appliedCoupon = null;
  if (couponCode) {
    const offer = await Offer.findOne({ code: couponCode.toUpperCase(), isActive: true });
    if (offer) {
      appliedCoupon = offer.code;
      if (bookingPricingType === 'fixed') {
        // Coupon applies on service price subtotal
        if (offer.code === 'QUICK20') {
          couponDiscount = servicePrice * 0.20;
        } else if (offer.code === 'FIRST15') {
          couponDiscount = servicePrice * 0.15;
        } else {
          couponDiscount = 10.0;
        }
        couponDiscount = Math.min(couponDiscount, servicePrice);
      } else {
        // Coupon applies on inspection fee today
        if (offer.code === 'QUICK20') {
          couponDiscount = visitingCharge * 0.20;
        } else if (offer.code === 'FIRST15') {
          couponDiscount = visitingCharge * 0.15;
        } else {
          couponDiscount = 10.0;
        }
        couponDiscount = Math.min(couponDiscount, visitingCharge);
      }
      couponDiscount = Math.round(couponDiscount * 100) / 100;
    }
  }

  // Grand total
  let grandTotal = subtotal - couponDiscount + convenienceFee;
  if (grandTotal < 0) grandTotal = 0;
  grandTotal = Math.round(grandTotal);

  // Generate formatting structure for bill Details
  const billDetails = [];
  let redBannerText = null;
  let estimatedPriceText = null;

  if (bookingPricingType === 'fixed') {
    billDetails.push({ label: 'Service Price', value: `₹${servicePrice}` });
    billDetails.push({ label: 'Visiting Charge', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });
    for (const ec of extraChargesList) {
      billDetails.push({ label: ec.label, value: `₹${ec.amount}` });
    }
    if (gstTotal > 0) {
      billDetails.push({ label: 'GST', value: `₹${gstTotal}` });
    }
    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    if (convenienceFee > 0) {
      billDetails.push({ label: 'Platform Fee', value: `₹${convenienceFee}` });
    }
  } else if (bookingPricingType === 'starting') {
    billDetails.push({ label: 'Inspection / Advance Fee', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });
    
    // Starting prices listing
    const startPrices = cartServices
      .filter(cs => cs.service.pricingType === 'starting')
      .map(cs => `Starts From ₹${Math.round(cs.service.price)}`);
    estimatedPriceText = startPrices.join(', ') || 'Starts From ₹0';
    
    billDetails.push({ label: 'Estimated Service Price', value: estimatedPriceText });
    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 This payment includes inspection/visiting charges only. Final amount may increase based on actual work required.";
  } else if (bookingPricingType === 'range') {
    billDetails.push({ label: 'Inspection Fee', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });
    
    // Ranges listing
    const ranges = cartServices
      .filter(cs => cs.service.pricingType === 'range')
      .map(cs => `₹${Math.round(cs.service.minPrice)} - ₹${Math.round(cs.service.maxPrice)}`);
    estimatedPriceText = ranges.join(', ') || '₹0 - ₹0';
    
    billDetails.push({ label: 'Estimated Price', value: estimatedPriceText });
    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 This payment includes inspection fee only. Final repair cost will be decided after inspection.";
  } else if (bookingPricingType === 'inspection') {
    billDetails.push({ label: 'Inspection Fee', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });
    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 Service price is not fixed. Provider will inspect and send quotation before starting work.";
  }

  return {
    pricingType: bookingPricingType,
    isFreeInspection,
    servicePrice,
    visitingCharge,
    gst: gstTotal,
    couponDiscount,
    convenienceFee,
    extraCharges: extraChargesList,
    extraChargesTotal,
    subtotal,
    grandTotal,
    appliedCoupon,
    redBannerText,
    estimatedPriceText,
    billDetails
  };
}

module.exports = {
  calculateCheckoutPriceInternal
};
