export interface CheckoutFields {
  fullName: string;
  phone: string;
  email: string;
  address: string;
  city: string;
  state: string;
  postalCode: string;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const ZIP_RE = /^\d{5}(-\d{4})?$/;

// First-3-digit ZIP prefix ranges per state (mirrors backend addressValidation.js).
const ZIP_RANGES: Record<string, [number, number][]> = {
  AL: [[350, 369]], AK: [[995, 999]], AZ: [[850, 865]], AR: [[716, 729], [755, 755]],
  CA: [[900, 961]], CO: [[800, 816]], CT: [[60, 69]], DE: [[197, 199]],
  DC: [[200, 205], [569, 569]], FL: [[320, 349]], GA: [[300, 319], [398, 399]],
  HI: [[967, 968]], ID: [[832, 838]], IL: [[600, 629]], IN: [[460, 479]],
  IA: [[500, 528]], KS: [[660, 679]], KY: [[400, 427]], LA: [[700, 714]],
  ME: [[39, 49]], MD: [[206, 219]], MA: [[10, 27], [55, 55]], MI: [[480, 499]],
  MN: [[550, 567]], MS: [[386, 397]], MO: [[630, 658]], MT: [[590, 599]],
  NE: [[680, 693]], NV: [[889, 898]], NH: [[30, 38]], NJ: [[70, 89]],
  NM: [[870, 884]], NY: [[5, 5], [100, 149]], NC: [[270, 289]], ND: [[580, 588]],
  OH: [[430, 459]], OK: [[730, 749]], OR: [[970, 979]], PA: [[150, 196]],
  RI: [[28, 29]], SC: [[290, 299]], SD: [[570, 577]], TN: [[370, 385]],
  TX: [[750, 799], [885, 885]], UT: [[840, 847]], VT: [[50, 59]],
  VA: [[201, 201], [220, 246]], WA: [[980, 994]], WV: [[247, 268]],
  WI: [[530, 549]], WY: [[820, 831]],
};

/** "2125550100" -> "(212) 555-0100" while typing. */
export function formatUsPhone(raw: string): string {
  let d = raw.replace(/\D/g, '');
  if (d.length === 11 && d.startsWith('1')) d = d.slice(1);
  d = d.slice(0, 10);
  if (d.length < 4) return d;
  if (d.length < 7) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
  return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
}

export function validateCheckout(f: CheckoutFields): Partial<Record<keyof CheckoutFields, string>> {
  const e: Partial<Record<keyof CheckoutFields, string>> = {};

  if (f.fullName.trim().length < 2) e.fullName = 'Please enter your full name.';

  const digits = f.phone.replace(/\D/g, '');
  const ten = digits.length === 11 && digits.startsWith('1') ? digits.slice(1) : digits;
  if (!/^[2-9]\d{2}[2-9]\d{6}$/.test(ten)) {
    e.phone = 'Enter a valid US phone number (10 digits). We deliver within the United States only.';
  }

  if (!EMAIL_RE.test(f.email.trim())) e.email = 'Enter a valid email — your order confirmation is sent there.';

  const a = f.address.trim();
  if (a.length < 5 || !/\d/.test(a) || !/[A-Za-z]/.test(a)) {
    e.address = 'Enter a complete street address including the street number.';
  }

  const c = f.city.trim();
  if (c.length < 2 || !/[A-Za-z]/.test(c)) e.city = 'Enter a valid city.';

  const zip = f.postalCode.trim();
  if (!ZIP_RE.test(zip)) {
    e.postalCode = 'Enter a valid 5-digit US ZIP code.';
  } else {
    const prefix = parseInt(zip.slice(0, 3), 10);
    const ranges = ZIP_RANGES[f.state];
    if (ranges && !ranges.some(([lo, hi]) => prefix >= lo && prefix <= hi)) {
      e.postalCode = `ZIP ${zip} doesn't match the state ${f.state}. Please check your address.`;
    }
  }
  // The quote needs only ZIP + state; surface a state error via postalCode.
  return e;
}
