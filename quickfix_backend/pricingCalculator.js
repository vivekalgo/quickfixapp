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
  console.log(`[Pricing Engine] Calculating checkout price for shop: ${shop.name} (${shop.id}), items:`, JSON.stringify(items), `coupon:`, couponCode);

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
      const svcCharges = parseFloat(cs.service.visitingCharges);
      const shopCharges = parseFloat(shop.visitingCharges);
      return (!isNaN(svcCharges) && svcCharges > 0)
        ? svcCharges 
        : (!isNaN(shopCharges) ? shopCharges : 150.0);
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

    let itemPrice = parseFloat(srv.price) || 0;
    let itemTaxable = 0;
    if (srv.pricingType === 'fixed') {
      itemTaxable = itemPrice * qty;
      servicePrice += itemTaxable;
    }

    const itemGstPct = parseFloat(srv.gst) || 0;
    if (srv.pricingType === 'fixed' && itemGstPct > 0) {
      const itemGst = itemTaxable * (itemGstPct / 100);
      gstTotal += itemGst;
    }

    const srvExtraCharges = parseFloat(srv.extraCharges) || 0;
    if (srvExtraCharges > 0) {
      const extraAmt = srvExtraCharges * qty;
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
    const startServices = cartServices.filter(cs => cs.service.pricingType === 'starting');
    let totalEstBase = 0;
    let totalEstGst = 0;
    let totalEstExtra = 0;
    const extraChargesItems = [];

    for (const cs of startServices) {
      const srv = cs.service;
      const qty = cs.quantity;
      const base = (parseFloat(srv.price) || 0) * qty;
      const gstPct = parseFloat(srv.gst) || 0;
      const gst = base * (gstPct / 100);
      const extra = (parseFloat(srv.extraCharges) || 0) * qty;

      totalEstBase += base;
      totalEstGst += gst;
      totalEstExtra += extra;

      if (extra > 0) {
        extraChargesItems.push({
          label: `Estimated ${srv.extraChargesLabel || 'Material Cost'}`,
          value: `₹${Math.round(extra)}`
        });
      }
    }

    const grandEstTotal = totalEstBase + totalEstGst + totalEstExtra;
    estimatedPriceText = `Starts From ₹${Math.round(grandEstTotal)}`;
    
    billDetails.push({ label: 'Estimated Service Price', value: `Starts From ₹${Math.round(totalEstBase)}` });
    if (totalEstGst > 0) {
      billDetails.push({ label: 'Estimated GST', value: `Starts From ₹${Math.round(totalEstGst)}` });
    }
    for (const ec of extraChargesItems) {
      billDetails.push({ label: ec.label, value: ec.value });
    }

    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 This payment includes inspection/visiting charges only. Final amount may increase based on actual work required.";
  } else if (bookingPricingType === 'range') {
    billDetails.push({ label: 'Inspection Fee', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });
    
    // Ranges listing
    const rangeServices = cartServices.filter(cs => cs.service.pricingType === 'range');
    let totalEstMinBase = 0;
    let totalEstMaxBase = 0;
    let totalEstMinGst = 0;
    let totalEstMaxGst = 0;
    let totalEstExtra = 0;
    const extraChargesItems = [];

    for (const cs of rangeServices) {
      const srv = cs.service;
      const qty = cs.quantity;
      const min = (parseFloat(srv.minPrice) || 0) * qty;
      const max = (parseFloat(srv.maxPrice) || 0) * qty;
      const gstPct = parseFloat(srv.gst) || 0;
      const minGst = min * (gstPct / 100);
      const maxGst = max * (gstPct / 100);
      const extra = (parseFloat(srv.extraCharges) || 0) * qty;

      totalEstMinBase += min;
      totalEstMaxBase += max;
      totalEstMinGst += minGst;
      totalEstMaxGst += maxGst;
      totalEstExtra += extra;

      if (extra > 0) {
        extraChargesItems.push({
          label: `Estimated ${srv.extraChargesLabel || 'Material Cost'}`,
          value: `₹${Math.round(extra)}`
        });
      }
    }

    const grandEstMinTotal = totalEstMinBase + totalEstMinGst + totalEstExtra;
    const grandEstMaxTotal = totalEstMaxBase + totalEstMaxGst + totalEstExtra;
    estimatedPriceText = `₹${Math.round(grandEstMinTotal)} - ₹${Math.round(grandEstMaxTotal)}`;
    
    billDetails.push({ label: 'Estimated Price', value: `₹${Math.round(totalEstMinBase)} - ₹${Math.round(totalEstMaxBase)}` });
    if (totalEstMinGst > 0 || totalEstMaxGst > 0) {
      billDetails.push({ label: 'Estimated GST', value: `₹${Math.round(totalEstMinGst)} - ₹${Math.round(totalEstMaxGst)}` });
    }
    for (const ec of extraChargesItems) {
      billDetails.push({ label: ec.label, value: ec.value });
    }

    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 This payment includes inspection fee only. Final repair cost will be decided after inspection.";
  } else if (bookingPricingType === 'inspection') {
    billDetails.push({ label: 'Inspection Fee', value: isFreeInspection ? 'FREE' : `₹${visitingCharge}`, isGreen: isFreeInspection });

    const inspectionServices = cartServices.filter(cs => cs.service.pricingType === 'inspection');
    let totalEstExtra = 0;
    const extraChargesItems = [];
    let hasGst = false;

    for (const cs of inspectionServices) {
      const srv = cs.service;
      const qty = cs.quantity;
      const gstPct = parseFloat(srv.gst) || 0;
      const extra = (parseFloat(srv.extraCharges) || 0) * qty;

      totalEstExtra += extra;
      if (gstPct > 0) {
        hasGst = true;
      }

      if (extra > 0) {
        extraChargesItems.push({
          label: `Estimated ${srv.extraChargesLabel || 'Material Cost'}`,
          value: `₹${Math.round(extra)}`
        });
      }
    }

    if (hasGst) {
      billDetails.push({ label: 'Estimated GST', value: 'Will be added to final quote' });
    }
    for (const ec of extraChargesItems) {
      billDetails.push({ label: ec.label, value: ec.value });
    }

    if (couponDiscount > 0) {
      billDetails.push({ label: 'Coupon Discount', value: `- ₹${couponDiscount}`, isGreen: true });
    }
    redBannerText = "🔴 Service price is not fixed. Provider will inspect and send quotation before starting work.";
  }

  const finalResult = {
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

  console.log(`[Pricing Engine] Output calculations:`, JSON.stringify(finalResult));
  return finalResult;
}

module.exports = {
  calculateCheckoutPriceInternal
};
