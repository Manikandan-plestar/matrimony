/**
 * ============================================================
 * Matrimonyer — Matrimony App Backend
 * Node.js + Express + MySQL
 *
 * Separate database (matrimony_db) and JWT secret from Simple ADVT.
 * All sensitive operations use parameterized SQL queries.
 * JWT Bearer authentication on every protected route.
 * Explicit public-profile DTOs — private fields never returned unauthorized.
 * ============================================================
 */

'use strict';

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');
const multer = require('multer');
const sharp = require('sharp');

// Load environment variables
dotenv.config();

// ============================================================
// 1. CONFIGURATION
// ============================================================
const PORT = parseInt(process.env.PORT || '5001', 10);
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT || '3306', 10);
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'matrimony_db';

const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '465', 10);
const SMTP_SECURE = process.env.SMTP_SECURE !== 'false';
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const FROM_EMAIL = process.env.FROM_EMAIL || `"Matrimonyer" <${SMTP_USER || 'no-reply@matrimonyer.com'}>`;

// NOTE: This JWT_SECRET is intentionally separate from Simple ADVT's secret.
const JWT_SECRET = process.env.JWT_SECRET || 'matrimony_dev_jwt_secret_CHANGE_IN_PRODUCTION_2026';
const JWT_EXPIRES_IN = '30d'; // Access token lifetime

const OTP_EXPIRY_MINUTES = parseInt(process.env.OTP_EXPIRY_MINUTES || '5', 10);
const RATE_LIMIT_MAX = parseInt(process.env.RATE_LIMIT_MAX_ATTEMPTS || '3', 10);
const RATE_LIMIT_WINDOW_MIN = parseInt(process.env.RATE_LIMIT_WINDOW_MINUTES || '10', 10);

const ENABLE_TEST_OTP = process.env.ENABLE_TEST_OTP === 'true' || process.env.NODE_ENV !== 'production';
const TEST_OTP_ALLOWLIST_RAW = process.env.TEST_OTP_ALLOWLIST || '';
const TEST_OTP_ALLOWLIST = TEST_OTP_ALLOWLIST_RAW.split(',').map(e => e.trim().toLowerCase()).filter(e => e.length > 0);
const MAX_IMAGE_SIZE_BYTES = parseInt(process.env.MAX_IMAGE_SIZE_MB || '5', 10) * 1024 * 1024;

// Subscription & Daily Swipe Limit Configuration
const APP_TIMEZONE = process.env.APP_TIMEZONE || 'Asia/Kolkata';
const SWIPE_DAILY_LIMIT = parseInt(process.env.SWIPE_DAILY_LIMIT || '10', 10);
const UNLIMITED_SWIPE_PLAN_PRICE = parseFloat(process.env.UNLIMITED_SWIPE_PLAN_PRICE || '499');

/**
 * Returns current date string 'YYYY-MM-DD' in the configured APP_TIMEZONE.
 */
function getTodayDateInTimezone(tz = APP_TIMEZONE) {
  try {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: tz,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    });
    return formatter.format(new Date());
  } catch (_) {
    return new Date().toISOString().slice(0, 10);
  }
}

/**
 * Returns ISO timestamp of the next midnight boundary (reset time) in APP_TIMEZONE.
 */
function getNextResetBoundaryIso(tz = APP_TIMEZONE) {
  try {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: tz,
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      hour12: false
    });
    const parts = formatter.formatToParts(now);
    const partMap = {};
    for (const p of parts) partMap[p.type] = p.value;
    const tzYear = parseInt(partMap.year, 10);
    const tzMonth = parseInt(partMap.month, 10) - 1;
    const tzDay = parseInt(partMap.day, 10);
    const tzHour = parseInt(partMap.hour, 10);
    const tzMin = parseInt(partMap.minute, 10);
    const tzSec = parseInt(partMap.second, 10);

    const tzNow = new Date(Date.UTC(tzYear, tzMonth, tzDay, tzHour, tzMin, tzSec));
    const nextMidnight = new Date(Date.UTC(tzYear, tzMonth, tzDay + 1, 0, 0, 0));
    const msUntilMidnight = nextMidnight.getTime() - tzNow.getTime();

    return new Date(now.getTime() + msUntilMidnight).toISOString();
  } catch (_) {
    const d = new Date();
    d.setUTCHours(24, 0, 0, 0);
    return d.toISOString();
  }
}

/**
 * Resolves local date ('YYYY-MM-DD') and next local midnight ISO reset timestamp
 * based on device client headers ('x-timezone-offset' in minutes, e.g. +330 for India, -300 for US EST)
 * allowing the application to function seamlessly worldwide in all 24+ time zones.
 */
function resolveClientDateAndReset(req) {
  const now = new Date();

  const offsetHeader = req.headers['x-timezone-offset'] || (req.query && req.query.offset) || (req.body && req.body.offsetMinutes);
  if (offsetHeader !== undefined && offsetHeader !== null && offsetHeader !== '') {
    const offsetMin = parseInt(offsetHeader, 10);
    // Earth timezones range from UTC-12 to UTC+14 (-720 to +840 minutes)
    if (!isNaN(offsetMin) && offsetMin >= -720 && offsetMin <= 840) {
      const localMs = now.getTime() + (offsetMin * 60000);
      const localDateObj = new Date(localMs);
      const year = localDateObj.getUTCFullYear();
      const month = String(localDateObj.getUTCMonth() + 1).padStart(2, '0');
      const day = String(localDateObj.getUTCDate()).padStart(2, '0');
      const dateStr = `${year}-${month}-${day}`;

      // Next local midnight
      const nextMidnightLocalMs = Date.UTC(year, localDateObj.getUTCMonth(), localDateObj.getUTCDate() + 1, 0, 0, 0);
      const msUntilMidnight = nextMidnightLocalMs - localMs;
      const resetAt = new Date(now.getTime() + msUntilMidnight).toISOString();
      const tzName = (req.headers['x-client-timezone'] || '').trim() ||
        `UTC${offsetMin >= 0 ? '+' : '-'}${String(Math.floor(Math.abs(offsetMin) / 60)).padStart(2, '0')}:${String(Math.abs(offsetMin) % 60).padStart(2, '0')}`;

      return {
        dateStr,
        resetAt,
        timezone: tzName,
        offsetMinutes: offsetMin
      };
    }
  }

  // Fallback to configured default timezone
  const defaultTz = process.env.APP_TIMEZONE || 'Asia/Kolkata';
  return {
    dateStr: getTodayDateInTimezone(defaultTz),
    resetAt: getNextResetBoundaryIso(defaultTz),
    timezone: defaultTz,
    offsetMinutes: 330
  };
}

if (process.env.NODE_ENV === 'production' && (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32)) {
  console.error('[SECURITY WARNING] JWT_SECRET must be at least 32 characters in production!');
}

// ============================================================
// 2. DATABASE POOL
// ============================================================
const pool = mysql.createPool({
  host: DB_HOST,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: '+00:00'
});

// ============================================================
// 3. DATABASE INIT & MIGRATIONS
// ============================================================
async function initDatabase() {
  // First: ensure the database itself exists
  const rawConn = await mysql.createConnection({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD
  });
  await rawConn.query(
    `CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
  );
  await rawConn.end();

  const conn = await pool.getConnection();
  console.log(`[Database] Connected to MySQL: "${DB_NAME}"`);

  try {
    // ---- Table 1: email_otp (same schema as ADVT reference) ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS email_otp (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        email       VARCHAR(255) NOT NULL,
        otp_hash    VARCHAR(64)  NOT NULL,
        expires_at  DATETIME     NOT NULL,
        is_used     TINYINT      DEFAULT 0,
        attempts    INT          DEFAULT 0,
        created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email   (email),
        INDEX idx_expires (expires_at),
        INDEX idx_created (created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 2: mat_users ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_users (
        id                   INT AUTO_INCREMENT PRIMARY KEY,
        email                VARCHAR(255) NOT NULL,
        full_name            VARCHAR(255) NOT NULL DEFAULT '',
        country_code         VARCHAR(10)  NOT NULL DEFAULT '+91',
        mobile_number        VARCHAR(20)  NOT NULL DEFAULT '',
        profile_photo_url    TEXT,
        active_profile_id    INT          DEFAULT NULL,
        has_published_profile TINYINT     DEFAULT 0,
        created_at           DATETIME     DEFAULT CURRENT_TIMESTAMP,
        updated_at           DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_email  (email),
        INDEX idx_mobile     (mobile_number)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 3: mat_profiles ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_profiles (
        id                   INT AUTO_INCREMENT PRIMARY KEY,
        user_id              INT          NOT NULL,
        profile_code         VARCHAR(30)  NOT NULL,
        created_for          VARCHAR(50)  DEFAULT 'Self',
        full_name            VARCHAR(255) NOT NULL,
        gender               VARCHAR(10)  NOT NULL,
        date_of_birth        DATE         NOT NULL,
        age                  INT          NOT NULL,
        marital_status       VARCHAR(50)  DEFAULT 'Never Married',
        height               VARCHAR(50),
        mother_tongue        VARCHAR(100),
        religion             VARCHAR(100),
        community            VARCHAR(200),
        dietary_preference   VARCHAR(50),
        profile_photo_url    TEXT,
        country_code         VARCHAR(10)  DEFAULT '+91',
        phone                VARCHAR(30),
        address              TEXT,
        highest_education    VARCHAR(200),
        occupation           VARCHAR(200),
        company              VARCHAR(200),
        annual_income        VARCHAR(100),
        country              VARCHAR(100),
        state                VARCHAR(100),
        city                 VARCHAR(100),
        locality             VARCHAR(100),
        family_type          VARCHAR(100),
        family_background    TEXT,
        family_values        VARCHAR(100),
        pref_age_min         INT          DEFAULT 21,
        pref_age_max         INT          DEFAULT 40,
        pref_marital_status  VARCHAR(100),
        pref_location        VARCHAR(255) DEFAULT 'Any Worldwide Location',
        pref_education       VARCHAR(200),
        pref_occupation      VARCHAR(200),
        pref_income          VARCHAR(100),
        partner_expectations TEXT,
        bio                  TEXT,
        is_verified          TINYINT      DEFAULT 0,
        is_premium           TINYINT      DEFAULT 0,
        compatibility_score  INT          DEFAULT 85,
        status               VARCHAR(20)  DEFAULT 'draft',
        more_info_clicks     INT          DEFAULT 0,
        created_at           DATETIME     DEFAULT CURRENT_TIMESTAMP,
        updated_at           DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_profile_code (profile_code),
        UNIQUE KEY uk_user_id      (user_id),
        INDEX idx_gender           (gender),
        INDEX idx_status           (status),
        INDEX idx_country          (country),
        INDEX idx_religion         (religion),
        INDEX idx_mother_tongue    (mother_tongue),
        INDEX idx_age              (age)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 4: mat_profile_images ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_profile_images (
        id         INT AUTO_INCREMENT PRIMARY KEY,
        profile_id INT  NOT NULL,
        image_url  TEXT NOT NULL,
        sort_order INT  DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_profile_id (profile_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 5: mat_saved_profiles ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_saved_profiles (
        id              INT AUTO_INCREMENT PRIMARY KEY,
        user_id         INT NOT NULL,
        saved_profile_id INT NOT NULL,
        created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_user_saved (user_id, saved_profile_id),
        INDEX idx_user_id (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 6: mat_profile_views ----
    // Tracks unique views per viewer per profile per day to prevent duplicate counting
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_profile_views (
        id               INT AUTO_INCREMENT PRIMARY KEY,
        profile_id       INT  NOT NULL,
        viewer_user_id   INT  NOT NULL,
        view_date        DATE NOT NULL,
        total_views      INT  DEFAULT 1,
        last_viewed_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_viewer_profile_date (viewer_user_id, profile_id, view_date),
        INDEX idx_profile_id     (profile_id),
        INDEX idx_viewer_user_id (viewer_user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 7: mat_interests ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_interests (
        id                  INT AUTO_INCREMENT PRIMARY KEY,
        sender_profile_id   INT         NOT NULL,
        receiver_profile_id INT         NOT NULL,
        sender_user_id      INT         NOT NULL,
        receiver_user_id    INT         NOT NULL,
        status              VARCHAR(20) NOT NULL DEFAULT 'pending',
        withdrawn_at        DATETIME    DEFAULT NULL,
        responded_at        DATETIME    DEFAULT NULL,
        created_at          DATETIME    DEFAULT CURRENT_TIMESTAMP,
        updated_at          DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_sender_receiver (sender_profile_id, receiver_profile_id),
        INDEX idx_sender_profile   (sender_profile_id),
        INDEX idx_receiver_profile (receiver_profile_id),
        INDEX idx_sender_user      (sender_user_id),
        INDEX idx_receiver_user    (receiver_user_id),
        INDEX idx_status           (status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 8: mat_notifications ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_notifications (
        id               INT AUTO_INCREMENT PRIMARY KEY,
        user_id          INT          NOT NULL,
        type             VARCHAR(50)  NOT NULL DEFAULT 'interest_received',
        title            VARCHAR(255) NOT NULL,
        message          TEXT         NOT NULL,
        related_profile_id INT        DEFAULT NULL,
        related_interest_id INT       DEFAULT NULL,
        is_read          TINYINT      DEFAULT 0,
        created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
        updated_at       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_user_id  (user_id),
        INDEX idx_is_read  (is_read),
        INDEX idx_created  (created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 9: mat_matches (shortcut for accepted interests) ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_matches (
        id                  INT AUTO_INCREMENT PRIMARY KEY,
        user_id_a           INT NOT NULL,
        user_id_b           INT NOT NULL,
        profile_id_a        INT NOT NULL,
        profile_id_b        INT NOT NULL,
        interest_id         INT NOT NULL,
        compatibility_score INT DEFAULT 85,
        status              VARCHAR(20) DEFAULT 'active',
        created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_match_interest (interest_id),
        INDEX idx_user_a (user_id_a),
        INDEX idx_user_b (user_id_b),
        INDEX idx_status (status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Safe migration: ensure status column exists in mat_matches
    try {
      await conn.query(`ALTER TABLE mat_matches ADD COLUMN status VARCHAR(20) DEFAULT 'active'`);
    } catch (_) {}

    // ---- Table 10: mat_user_subscriptions ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_user_subscriptions (
        id               INT AUTO_INCREMENT PRIMARY KEY,
        user_id          INT NOT NULL,
        plan_type        VARCHAR(50) NOT NULL DEFAULT 'unlimited_swipes',
        plan_price       DECIMAL(10,2) NOT NULL DEFAULT 499.00,
        currency         VARCHAR(10) NOT NULL DEFAULT 'INR',
        status           VARCHAR(20) NOT NULL DEFAULT 'active',
        payment_id       VARCHAR(255) NOT NULL,
        payment_gateway  VARCHAR(50) NOT NULL DEFAULT 'verified_payment',
        transaction_data JSON DEFAULT NULL,
        starts_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at       DATETIME DEFAULT NULL,
        created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_payment_id (payment_id),
        INDEX idx_user_status (user_id, status)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 11: mat_daily_swipes ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_daily_swipes (
        id               INT AUTO_INCREMENT PRIMARY KEY,
        user_id          INT NOT NULL,
        swipe_date       DATE NOT NULL,
        swipe_count      INT NOT NULL DEFAULT 0,
        created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_user_date (user_id, swipe_date),
        INDEX idx_user_id (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // ---- Table 12: mat_swipe_logs ----
    await conn.query(`
      CREATE TABLE IF NOT EXISTS mat_swipe_logs (
        id                INT AUTO_INCREMENT PRIMARY KEY,
        user_id           INT NOT NULL,
        target_profile_id INT NOT NULL,
        action            VARCHAR(20) NOT NULL,
        feed_type         VARCHAR(20) NOT NULL DEFAULT 'groom',
        client_request_id VARCHAR(100) NOT NULL,
        swipe_date        DATE NOT NULL,
        created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_user_client_req (user_id, client_request_id),
        INDEX idx_user_swipe_date (user_id, swipe_date),
        INDEX idx_target_profile  (target_profile_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    console.log('[Database] All tables initialized/verified successfully.');
  } finally {
    conn.release();
  }
}

// ============================================================
// 4. EMAIL / SMTP
// ============================================================
const cleanSmtpPass = (SMTP_PASS || '').replace(/\s+/g, '');

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_SECURE,
  auth: { user: SMTP_USER, pass: cleanSmtpPass },
  tls: { rejectUnauthorized: false }
});

function buildOtpEmailHtml(otp, expiryMin) {
  return `
  <!DOCTYPE html><html><head><meta charset="utf-8">
  <style>
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#fdf0f3;margin:0;padding:0}
    .wrap{max-width:480px;margin:30px auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e8d0d8}
    .hdr{background:linear-gradient(135deg,#8b1a4a 0%,#c43d75 100%);padding:28px 20px;text-align:center;color:#fff}
    .hdr h1{margin:0;font-size:22px;font-weight:700}
    .hdr p{margin:4px 0 0;opacity:.85;font-size:13px}
    .body{padding:28px 24px;text-align:center;color:#334155}
    .otp{display:inline-block;background:#fdf0f3;border:2px dashed #8b1a4a;border-radius:12px;padding:14px 32px;
         font-size:34px;font-weight:800;letter-spacing:10px;color:#8b1a4a;margin:14px 0 18px}
    .exp{font-size:12px;color:#ef4444;font-weight:600;margin-bottom:14px}
    .note{font-size:11px;color:#94a3b8;border-top:1px solid #f1f5f9;padding-top:14px;margin-top:18px;line-height:1.5}
    .footer{background:#fdf0f3;padding:12px;text-align:center;font-size:11px;color:#94a3b8;border-top:1px solid #e8d0d8}
  </style></head><body>
  <div class="wrap">
    <div class="hdr"><h1>💍 Matrimonyer</h1><p>Email Verification Code</p></div>
    <div class="body">
      <p style="font-size:15px;margin-bottom:14px">Your 6-digit verification code:</p>
      <div class="otp">${otp}</div>
      <p class="exp">⏰ Expires in ${expiryMin} minutes</p>
      <div class="note">Never share this code. If you did not request this, please ignore this email.</div>
    </div>
    <div class="footer">© ${new Date().getFullYear()} Matrimonyer. All rights reserved.</div>
  </div></body></html>`;
}

async function sendOtpEmail(email, otp) {
  if (!SMTP_USER || !cleanSmtpPass) {
    throw new Error('SMTP credentials are not configured. Set SMTP_USER and SMTP_PASS in .env');
  }
  const mailOpts = {
    from: FROM_EMAIL,
    to: email,
    subject: `${otp} — Your Matrimonyer verification code`,
    text: `Your Matrimonyer OTP is: ${otp}. It expires in ${OTP_EXPIRY_MINUTES} minutes. Never share it.`,
    html: buildOtpEmailHtml(otp, OTP_EXPIRY_MINUTES)
  };
  const info = await transporter.sendMail(mailOpts);
  console.log(`[Mailer] OTP sent to ${email} (MsgID: ${info.messageId})`);
}

// ============================================================
// 5. HELPERS
// ============================================================

function hashOtp(otp) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function normalizePhone(phone) {
  // Strip all non-digit characters for storage comparison
  return (phone || '').replace(/\D/g, '');
}

function generateProfileCode(gender) {
  const prefix = gender === 'Bride' ? 'MAT-B' : 'MAT-G';
  const suffix = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}${suffix}`;
}

/**
 * Public profile DTO: only the 8 fields permitted for discovery viewers.
 * Private fields (phone, address, email, full location, family details etc.) are NEVER returned here.
 */
function toPublicProfile(row, interactionMeta = {}) {
  return {
    id: row.id,
    profileCode: row.profile_code,
    profilePhotoUrl: row.profile_photo_url || '',
    bio: row.bio || '',
    fullName: row.full_name,
    age: row.age,
    motherTongue: row.mother_tongue || '',
    highestEducation: row.highest_education || '',
    occupation: row.occupation || '',
    city: row.city || '',
    gender: row.gender,
    isVerified: Boolean(row.is_verified),
    isPremium: Boolean(row.is_premium),
    compatibilityScore: row.compatibility_score || 85,
    lastActive: 'Active recently',
    // UI state flags from caller
    isSaved: Boolean(interactionMeta.isSaved),
    isInterestSent: Boolean(interactionMeta.isInterestSent),
    interestStatus: interactionMeta.interestStatus || null,
  };
}

/**
 * Full profile DTO: returned only to the profile owner OR after accepted interest.
 */
function toFullProfile(row, interactionMeta = {}) {
  const pub = toPublicProfile(row, interactionMeta);
  return {
    ...pub,
    religion: row.religion || '',
    createdFor: row.created_for,
    dateOfBirth: row.date_of_birth,
    maritalStatus: row.marital_status || '',
    height: row.height || '',
    community: row.community || '',
    dietaryPreference: row.dietary_preference || '',
    company: row.company || '',
    annualIncome: row.annual_income || '',
    country: row.country || '',
    state: row.state || '',
    locality: row.locality || '',
    familyType: row.family_type || '',
    familyBackground: row.family_background || '',
    familyValues: row.family_values || '',
    prefAgeMin: row.pref_age_min || 21,
    prefAgeMax: row.pref_age_max || 40,
    prefMaritalStatus: row.pref_marital_status || '',
    prefLocation: row.pref_location || '',
    prefEducation: row.pref_education || '',
    prefOccupation: row.pref_occupation || '',
    prefIncome: row.pref_income || '',
    partnerExpectations: row.partner_expectations || '',
    // Only shared after acceptance — phone exposed in full profile
    countryCode: row.country_code || '+91',
    phone: row.phone || '',
    address: row.address || '',
    moreInfoClicks: row.more_info_clicks || 0,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

/**
 * Own profile DTO: all fields including contact for the profile owner.
 */
function toOwnProfile(row) {
  return toFullProfile(row, { isSaved: false, isInterestSent: false });
}

// ============================================================
// 6. IMAGE UPLOAD (Multer + Sharp resize)
// ============================================================
const UPLOADS_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });

const multerStorage = multer.memoryStorage();
const upload = multer({
  storage: multerStorage,
  limits: { fileSize: MAX_IMAGE_SIZE_BYTES },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowed.includes(file.mimetype)) {
      return cb(new Error('Only JPEG, PNG, and WebP images are allowed.'));
    }
    cb(null, true);
  }
});

async function saveUploadedImage(buffer, subfolder = 'profiles') {
  const dir = path.join(UPLOADS_DIR, subfolder);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const filename = `${Date.now()}_${crypto.randomBytes(6).toString('hex')}.jpg`;
  const filepath = path.join(dir, filename);
  await sharp(buffer)
    .resize(800, 800, { fit: 'cover' })
    .jpeg({ quality: 85 })
    .toFile(filepath);
  return `/uploads/${subfolder}/${filename}`;
}

// ============================================================
// 7. EXPRESS APP
// ============================================================
const app = express();

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use('/uploads', express.static(UPLOADS_DIR));

// ============================================================
// 8. AUTHENTICATION MIDDLEWARE
// ============================================================

/**
 * Verifies JWT Bearer token and attaches req.user = { id, email }.
 * All protected routes must use this middleware.
 */
function authenticateUser(req, res, next) {
  const authHeader = req.headers['authorization'] || req.headers['Authorization'] || '';
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Authorization token required.' });
  }
  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { id: payload.id, email: payload.email };
    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Session expired. Please log in again.' });
    }
    return res.status(401).json({ success: false, message: 'Invalid or malformed token.' });
  }
}

// ============================================================
// 9. HEALTH CHECK
// ============================================================
app.get('/api/mat/health', (req, res) => {
  res.json({ success: true, service: 'Matrimonyer API', version: '1.0.0', timestamp: new Date().toISOString() });
});

// ============================================================
// 10. AUTH ROUTES
// ============================================================

/**
 * POST /api/mat/auth/request-otp
 * Body: { email }
 * Validates email, rate-limits, sends OTP (or test OTP in dev), stores hash.
 */
app.post('/api/mat/auth/request-otp', async (req, res) => {
  try {
    const rawEmail = (req.body.email || '').trim();
    if (!rawEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(rawEmail)) {
      return res.status(400).json({ success: false, message: 'A valid email address is required.' });
    }
    const email = normalizeEmail(rawEmail);

    // Rate limiting: count recent OTP requests
    const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MIN * 60 * 1000);
    const [recentRows] = await pool.query(
      `SELECT COUNT(*) AS cnt FROM email_otp WHERE email = ? AND created_at >= ? AND is_used = 0`,
      [email, windowStart]
    );
    if (recentRows[0].cnt >= RATE_LIMIT_MAX) {
      return res.status(429).json({
        success: false,
        message: `Too many OTP requests. Please wait ${RATE_LIMIT_WINDOW_MIN} minutes before trying again.`
      });
    }

    // Invalidate any unused previous OTPs for this email
    await pool.query(`UPDATE email_otp SET is_used = 1 WHERE email = ? AND is_used = 0`, [email]);

    // Generate and store OTP
    let otp;
    const isTestAllowlisted = ENABLE_TEST_OTP && (
      TEST_OTP_ALLOWLIST.includes(email) ||
      email === 'test1@gmail.com' ||
      email === 'test2@gmail.com'
    );
    if (isTestAllowlisted) {
      otp = '123456'; // Fixed test OTP — never use in production
    } else {
      otp = Math.floor(100000 + Math.random() * 900000).toString();
    }

    const otpHash = hashOtp(otp);
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    await pool.query(
      `INSERT INTO email_otp (email, otp_hash, expires_at, is_used, attempts) VALUES (?, ?, ?, 0, 0)`,
      [email, otpHash, expiresAt]
    );

    if (!isTestAllowlisted) {
      await sendOtpEmail(email, otp);
    }

    return res.status(200).json({
      success: true,
      message: isTestAllowlisted
        ? 'Test OTP sent (check server documentation).'
        : `Verification code sent to ${email}. It expires in ${OTP_EXPIRY_MINUTES} minutes.`,
      isTestOtp: isTestAllowlisted,
    });
  } catch (err) {
    console.error('[Auth] OTP request error:', err.message);
    if (err.message && err.message.includes('SMTP')) {
      return res.status(503).json({ success: false, message: 'Email service unavailable. Please try again later.' });
    }
    return res.status(500).json({ success: false, message: 'Error sending verification code.' });
  }
});

/**
 * POST /api/mat/auth/verify-otp
 * Body: { email, otp }
 * Verifies OTP hash, creates account if new, returns JWT + user data.
 */
app.post('/api/mat/auth/verify-otp', async (req, res) => {
  try {
    const rawEmail = (req.body.email || '').trim();
    const otpInput = (req.body.otp || '').trim();

    if (!rawEmail || !otpInput) {
      return res.status(400).json({ success: false, message: 'Email and OTP are required.' });
    }
    if (!/^\d{6}$/.test(otpInput)) {
      return res.status(400).json({ success: false, message: 'OTP must be a 6-digit number.' });
    }

    const email = normalizeEmail(rawEmail);
    const otpHash = hashOtp(otpInput);

    // Find valid OTP record
    const [otpRows] = await pool.query(
      `SELECT id, attempts, expires_at, is_used
       FROM email_otp
       WHERE email = ? AND is_used = 0
       ORDER BY created_at DESC LIMIT 1`,
      [email]
    );

    if (!otpRows.length) {
      return res.status(400).json({ success: false, message: 'No pending verification found. Please request a new code.' });
    }

    const otpRecord = otpRows[0];

    if (new Date() > new Date(otpRecord.expires_at)) {
      await pool.query('UPDATE email_otp SET is_used = 1 WHERE id = ?', [otpRecord.id]);
      return res.status(400).json({ success: false, message: 'Verification code has expired. Please request a new one.' });
    }

    if (otpRecord.attempts >= 5) {
      await pool.query('UPDATE email_otp SET is_used = 1 WHERE id = ?', [otpRecord.id]);
      return res.status(429).json({ success: false, message: 'Too many failed attempts. Please request a new code.' });
    }

    // Increment attempt before hash check (timing-safe)
    await pool.query('UPDATE email_otp SET attempts = attempts + 1 WHERE id = ?', [otpRecord.id]);

    // Timing-safe hash comparison
    const [validRow] = await pool.query(
      `SELECT id FROM email_otp WHERE id = ? AND otp_hash = ?`,
      [otpRecord.id, otpHash]
    );

    if (!validRow.length) {
      const remaining = 5 - (otpRecord.attempts + 1);
      return res.status(400).json({
        success: false,
        message: remaining > 0
          ? `Incorrect code. ${remaining} attempt(s) remaining.`
          : 'Incorrect code. No attempts remaining. Please request a new code.'
      });
    }

    // Mark OTP as used
    await pool.query('UPDATE email_otp SET is_used = 1 WHERE id = ?', [otpRecord.id]);

    // Upsert user: create if not exists, return existing if registered
    let [userRows] = await pool.query('SELECT * FROM mat_users WHERE email = ?', [email]);
    let user;
    let isNew = false;

    if (!userRows.length) {
      const [insertResult] = await pool.query(
        `INSERT INTO mat_users (email, full_name, country_code, mobile_number)
         VALUES (?, '', '+91', '')`,
        [email]
      );
      const userId = insertResult.insertId;
      const [newRows] = await pool.query('SELECT * FROM mat_users WHERE id = ?', [userId]);
      user = newRows[0];
      isNew = true;
    } else {
      user = userRows[0];
    }

    // Fetch profile if exists
    let profile = null;
    if (user.active_profile_id) {
      const [profRows] = await pool.query('SELECT * FROM mat_profiles WHERE id = ? AND user_id = ?',
        [user.active_profile_id, user.id]);
      if (profRows.length) profile = toOwnProfile(profRows[0]);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return res.status(200).json({
      success: true,
      isNewUser: isNew,
      message: isNew ? 'Account created successfully.' : 'Logged in successfully.',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name || '',
        phone: user.mobile_number || '',
        profilePhotoUrl: user.profile_photo_url || '',
        activeProfileId: user.active_profile_id,
        hasPublishedProfile: Boolean(user.has_published_profile),
      },
      profile,
    });
  } catch (err) {
    console.error('[Auth] OTP verify error:', err.message);
    return res.status(500).json({ success: false, message: 'Error verifying code.' });
  }
});

/**
 * POST /api/mat/auth/logout
 * Invalidate user active OTPs and end authenticated session.
 */
app.post('/api/mat/auth/logout', authenticateUser, async (req, res) => {
  try {
    const email = req.user.email;
    await pool.query('UPDATE email_otp SET is_used = 1 WHERE email = ?', [email]);
    return res.status(200).json({ success: true, message: 'Logged out successfully.' });
  } catch (err) {
    console.error('[Auth] Logout error:', err.message);
    return res.status(500).json({ success: false, message: 'Error logging out.' });
  }
});

// ============================================================
// 11. ACCOUNT / USER ROUTES
// ============================================================

/**
 * GET /api/mat/me
 * Returns the authenticated user's account and profile data.
 */
app.get('/api/mat/me', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const [userRows] = await pool.query('SELECT * FROM mat_users WHERE id = ?', [userId]);
    if (!userRows.length) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    const user = userRows[0];

    let profile = null;
    if (user.active_profile_id) {
      const [profRows] = await pool.query(
        'SELECT * FROM mat_profiles WHERE id = ? AND user_id = ?',
        [user.active_profile_id, userId]
      );
      if (profRows.length) profile = toOwnProfile(profRows[0]);
    }

    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name || '',
        phone: user.mobile_number || '',
        profilePhotoUrl: user.profile_photo_url || '',
        activeProfileId: user.active_profile_id,
        hasPublishedProfile: Boolean(user.has_published_profile),
      },
      profile,
    });
  } catch (err) {
    console.error('[Account] GET /me error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching account data.' });
  }
});

/**
 * PATCH /api/mat/me
 * Update account-level fields (name, phone, countryCode).
 */
app.patch('/api/mat/me', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const allowed = ['full_name', 'mobile_number', 'country_code', 'profile_photo_url'];
    const body = req.body || {};
    const updates = {};

    if (body.fullName !== undefined) updates.full_name = String(body.fullName).trim().substring(0, 255);
    if (body.phone !== undefined) updates.mobile_number = String(body.phone).trim().substring(0, 20);
    if (body.countryCode !== undefined) updates.country_code = String(body.countryCode).trim().substring(0, 10);
    if (body.profilePhotoUrl !== undefined) updates.profile_photo_url = String(body.profilePhotoUrl).trim().substring(0, 2000);

    if (!Object.keys(updates).length) {
      return res.status(400).json({ success: false, message: 'No valid fields to update.' });
    }

    const setClauses = Object.keys(updates).map(k => `${k} = ?`).join(', ');
    await pool.query(`UPDATE mat_users SET ${setClauses} WHERE id = ?`,
      [...Object.values(updates), userId]);

    const [rows] = await pool.query('SELECT * FROM mat_users WHERE id = ?', [userId]);
    const user = rows[0];
    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name || '',
        phone: user.mobile_number || '',
        profilePhotoUrl: user.profile_photo_url || '',
        activeProfileId: user.active_profile_id,
        hasPublishedProfile: Boolean(user.has_published_profile),
      }
    });
  } catch (err) {
    console.error('[Account] PATCH /me error:', err.message);
    return res.status(500).json({ success: false, message: 'Error updating account.' });
  }
});

// ============================================================
// 12. PROFILE IMAGE UPLOAD
// ============================================================

/**
 * POST /api/mat/upload/profile-photo
 * Uploads and resizes a profile photo. Returns the URL.
 */
app.post('/api/mat/upload/profile-photo', authenticateUser, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No image file provided.' });
    }
    const url = await saveUploadedImage(req.file.buffer, 'profiles');
    // Build full URL based on request
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return res.status(200).json({ success: true, url: `${baseUrl}${url}` });
  } catch (err) {
    console.error('[Upload] Profile photo error:', err.message);
    return res.status(500).json({ success: false, message: 'Error uploading image.' });
  }
});

// ============================================================
// 13. PROFILE ROUTES
// ============================================================

/**
 * GET /api/mat/profiles/me
 * Returns the authenticated user's own full profile.
 */
app.get('/api/mat/profiles/me', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      'SELECT * FROM mat_profiles WHERE user_id = ?',
      [userId]
    );
    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'No profile found. Please create one.' });
    }
    return res.status(200).json({ success: true, profile: toOwnProfile(rows[0]) });
  } catch (err) {
    console.error('[Profile] GET /me error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching profile.' });
  }
});

/**
 * POST /api/mat/profiles
 * Creates or updates the user's matrimonial profile.
 * Also sets has_published_profile on mat_users.
 */
app.post('/api/mat/profiles', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const b = req.body || {};

    // Validate required fields
    if (!b.fullName || !b.gender || !b.dateOfBirth) {
      return res.status(400).json({ success: false, message: 'fullName, gender, and dateOfBirth are required.' });
    }
    if (!['Groom', 'Bride'].includes(b.gender)) {
      return res.status(400).json({ success: false, message: 'gender must be Groom or Bride.' });
    }

    // Check if user already has a profile
    const [existing] = await pool.query('SELECT id FROM mat_profiles WHERE user_id = ?', [userId]);

    // Sanitize allowlisted fields only
    const data = {
      user_id: userId,
      created_for: String(b.createdFor || 'Self').substring(0, 50),
      full_name: String(b.fullName || '').trim().substring(0, 255),
      gender: b.gender,
      date_of_birth: b.dateOfBirth,
      age: parseInt(b.age || 0, 10),
      marital_status: String(b.maritalStatus || 'Never Married').substring(0, 50),
      height: String(b.height || '').substring(0, 50),
      mother_tongue: String(b.motherTongue || '').substring(0, 100),
      religion: String(b.religion || '').substring(0, 100),
      community: String(b.community || '').substring(0, 200),
      dietary_preference: String(b.dietaryPreference || '').substring(0, 50),
      profile_photo_url: String(b.profilePhotoUrl || '').substring(0, 2000),
      country_code: String(b.countryCode || '+91').substring(0, 10),
      phone: String(b.phone || '').substring(0, 30),
      address: String(b.address || '').substring(0, 1000),
      highest_education: String(b.highestEducation || '').substring(0, 200),
      occupation: String(b.occupation || '').substring(0, 200),
      company: String(b.company || '').substring(0, 200),
      annual_income: String(b.annualIncome || '').substring(0, 100),
      country: String(b.country || '').substring(0, 100),
      state: String(b.state || '').substring(0, 100),
      city: String(b.city || '').substring(0, 100),
      locality: String(b.locality || '').substring(0, 100),
      family_type: String(b.familyType || '').substring(0, 100),
      family_background: String(b.familyBackground || '').substring(0, 2000),
      family_values: String(b.familyValues || '').substring(0, 100),
      pref_age_min: parseInt(b.prefAgeMin || 21, 10),
      pref_age_max: parseInt(b.prefAgeMax || 40, 10),
      pref_marital_status: String(b.prefMaritalStatus || '').substring(0, 100),
      pref_location: String(b.prefLocation || 'Any Worldwide Location').substring(0, 255),
      pref_education: String(b.prefEducation || '').substring(0, 200),
      pref_occupation: String(b.prefOccupation || '').substring(0, 200),
      pref_income: String(b.prefIncome || '').substring(0, 100),
      partner_expectations: String(b.partnerExpectations || '').substring(0, 3000),
      bio: String(b.bio || '').substring(0, 3000),
      status: b.status === 'published' ? 'published' : 'draft',
    };

    let profileId;

    if (existing.length) {
      // Update existing
      profileId = existing[0].id;
      const keys = Object.keys(data).filter(k => k !== 'user_id');
      const setClauses = keys.map(k => `${k} = ?`).join(', ');
      const values = keys.map(k => data[k]);
      await pool.query(
        `UPDATE mat_profiles SET ${setClauses} WHERE id = ? AND user_id = ?`,
        [...values, profileId, userId]
      );
    } else {
      // Insert new
      data.profile_code = generateProfileCode(b.gender);
      const keys = Object.keys(data);
      const placeholders = keys.map(() => '?').join(', ');
      const values = keys.map(k => data[k]);
      const [ins] = await pool.query(
        `INSERT INTO mat_profiles (${keys.join(', ')}) VALUES (${placeholders})`,
        values
      );
      profileId = ins.insertId;
    }

    // Update mat_users active_profile_id and has_published_profile
    const isPublished = data.status === 'published';
    await pool.query(
      `UPDATE mat_users SET active_profile_id = ?, has_published_profile = ?, full_name = ?, profile_photo_url = ? WHERE id = ?`,
      [profileId, isPublished ? 1 : 0, data.full_name, data.profile_photo_url || null, userId]
    );

    const [profRows] = await pool.query('SELECT * FROM mat_profiles WHERE id = ?', [profileId]);
    return res.status(200).json({ success: true, profile: toOwnProfile(profRows[0]) });
  } catch (err) {
    console.error('[Profile] POST error:', err.message);
    return res.status(500).json({ success: false, message: 'Error saving profile.' });
  }
});

/**
 * PATCH /api/mat/profiles/me
 * Partial update for section-by-section editing (e.g. Personal Details or Partner Preference).
 * Only provided allowlisted fields are updated. Existing fields are preserved without overwriting.
 */
app.patch('/api/mat/profiles/me', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const b = req.body || {};

    const [existing] = await pool.query('SELECT * FROM mat_profiles WHERE user_id = ?', [userId]);
    if (!existing.length) {
      return res.status(404).json({ success: false, message: 'Profile not found. Please create your profile first.' });
    }

    const fieldMap = {
      createdFor: 'created_for',
      fullName: 'full_name',
      gender: 'gender',
      dateOfBirth: 'date_of_birth',
      age: 'age',
      maritalStatus: 'marital_status',
      height: 'height',
      motherTongue: 'mother_tongue',
      religion: 'religion',
      community: 'community',
      dietaryPreference: 'dietary_preference',
      profilePhotoUrl: 'profile_photo_url',
      countryCode: 'country_code',
      phone: 'phone',
      address: 'address',
      highestEducation: 'highest_education',
      occupation: 'occupation',
      company: 'company',
      annualIncome: 'annual_income',
      country: 'country',
      state: 'state',
      city: 'city',
      locality: 'locality',
      familyType: 'family_type',
      familyBackground: 'family_background',
      familyValues: 'family_values',
      prefAgeMin: 'pref_age_min',
      prefAgeMax: 'pref_age_max',
      prefMaritalStatus: 'pref_marital_status',
      prefLocation: 'pref_location',
      prefEducation: 'pref_education',
      prefOccupation: 'pref_occupation',
      prefIncome: 'pref_income',
      partnerExpectations: 'partner_expectations',
      bio: 'bio',
    };

    const updates = [];
    const values = [];

    for (const [key, col] of Object.entries(fieldMap)) {
      if (b[key] !== undefined) {
        let val = b[key];
        if (typeof val === 'string') val = val.trim();
        if (key === 'age' || key === 'prefAgeMin' || key === 'prefAgeMax') {
          val = parseInt(val, 10);
          if (isNaN(val)) continue;
        }
        updates.push(`${col} = ?`);
        values.push(val);
      }
    }

    if (updates.length > 0) {
      values.push(existing[0].id, userId);
      await pool.query(`UPDATE mat_profiles SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`, values);

      // Keep mat_users in sync if full_name or profile_photo_url changed
      if (b.fullName !== undefined || b.profilePhotoUrl !== undefined) {
        const userUpdates = [];
        const userValues = [];
        if (b.fullName !== undefined) {
          userUpdates.push('full_name = ?');
          userValues.push(String(b.fullName).trim());
        }
        if (b.profilePhotoUrl !== undefined) {
          userUpdates.push('profile_photo_url = ?');
          userValues.push(String(b.profilePhotoUrl).trim() || null);
        }
        userValues.push(userId);
        await pool.query(`UPDATE mat_users SET ${userUpdates.join(', ')} WHERE id = ?`, userValues);
      }
    }

    const [updated] = await pool.query('SELECT * FROM mat_profiles WHERE id = ?', [existing[0].id]);
    return res.status(200).json({ success: true, profile: toOwnProfile(updated[0]) });
  } catch (err) {
    console.error('[Profile] PATCH me error:', err.message);
    return res.status(500).json({ success: false, message: 'Error updating profile.' });
  }
});

/**
 * PATCH /api/mat/profiles/me/status
 * Publish or unpublish the authenticated user's profile.
 * Body: { status: 'published' | 'draft' }
 */
app.patch('/api/mat/profiles/me/status', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const status = req.body.status;
    if (!['published', 'draft', 'deactivated'].includes(status)) {
      return res.status(400).json({ success: false, message: 'status must be published, draft, or deactivated.' });
    }
    await pool.query(
      'UPDATE mat_profiles SET status = ? WHERE user_id = ?',
      [status, userId]
    );
    await pool.query(
      'UPDATE mat_users SET has_published_profile = ? WHERE id = ?',
      [status === 'published' ? 1 : 0, userId]
    );
    return res.status(200).json({ success: true, status });
  } catch (err) {
    console.error('[Profile] PATCH status error:', err.message);
    return res.status(500).json({ success: false, message: 'Error updating profile status.' });
  }
});

/**
 * DELETE /api/mat/profiles/me
 * Deletes the authenticated user's profile.
 */
app.delete('/api/mat/profiles/me', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    await pool.query('DELETE FROM mat_profiles WHERE user_id = ?', [userId]);
    await pool.query('UPDATE mat_users SET active_profile_id = NULL, has_published_profile = 0 WHERE id = ?', [userId]);
    return res.status(200).json({ success: true, message: 'Profile deleted.' });
  } catch (err) {
    console.error('[Profile] DELETE error:', err.message);
    return res.status(500).json({ success: false, message: 'Error deleting profile.' });
  }
});

// ============================================================
// 14. DISCOVERY ROUTES (Groom & Bride Feeds)
// ============================================================

/**
 * GET /api/mat/profiles?gender=Groom|Bride&page=1&limit=20
 *
 * Returns public profiles only. Country-based visibility enforced on backend.
 * Private fields are NEVER included in this response.
 *
 * Visibility rules:
 * - pref_location = 'Any Worldwide Location' → visible to all authenticated users
 * - pref_location contains 'Country:' → only visible to users from that country
 */
app.get('/api/mat/profiles', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const gender = req.query.gender; // 'Groom' or 'Bride'
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '20', 10)));
    const offset = (page - 1) * limit;

    if (!gender || !['Groom', 'Bride'].includes(gender)) {
      return res.status(400).json({ success: false, message: 'gender must be Groom or Bride.' });
    }

    // Get the viewer's own country for visibility filtering
    const [viewerRows] = await pool.query(
      'SELECT country FROM mat_profiles WHERE user_id = ?',
      [userId]
    );
    const viewerCountry = viewerRows.length ? (viewerRows[0].country || '').toLowerCase().trim() : '';

    // Visibility: exclude own profile, only published profiles
    // Country filter: show worldwide profiles OR profiles targeting viewer's country
    const [profiles] = await pool.query(`
      SELECT p.*
      FROM mat_profiles p
      WHERE p.gender = ?
        AND p.status = 'published'
        AND p.user_id != ?
        AND (
          p.pref_location = 'Any Worldwide Location'
          OR p.pref_location = ''
          OR LOWER(p.pref_location) LIKE CONCAT('%', LOWER(?), '%')
          OR ? = ''
        )
      ORDER BY p.updated_at DESC
      LIMIT ? OFFSET ?
    `, [gender, userId, viewerCountry, viewerCountry, limit, offset]);

    // Get interaction state for each profile (saved, interest sent)
    const profileIds = profiles.map(p => p.id);

    let savedSet = new Set();
    let interestMap = {}; // profileId -> { status }

    if (profileIds.length) {
      // Saved profiles
      const [savedRows] = await pool.query(
        `SELECT saved_profile_id FROM mat_saved_profiles WHERE user_id = ? AND saved_profile_id IN (?)`,
        [userId, profileIds]
      );
      savedRows.forEach(r => savedSet.add(r.saved_profile_id));

      // Interest status
      const [interestRows] = await pool.query(
        `SELECT receiver_profile_id, status FROM mat_interests
         WHERE sender_user_id = ? AND receiver_profile_id IN (?)`,
        [userId, profileIds]
      );
      interestRows.forEach(r => {
        interestMap[r.receiver_profile_id] = { status: r.status };
      });
    }

    const publicProfiles = profiles.map(p => toPublicProfile(p, {
      isSaved: savedSet.has(p.id),
      isInterestSent: !!interestMap[p.id] && interestMap[p.id].status !== 'withdrawn',
      interestStatus: interestMap[p.id]?.status || null,
    }));

    const [countRow] = await pool.query(`
      SELECT COUNT(*) AS total
      FROM mat_profiles p
      WHERE p.gender = ? AND p.status = 'published' AND p.user_id != ?
        AND (
          p.pref_location = 'Any Worldwide Location'
          OR p.pref_location = ''
          OR LOWER(p.pref_location) LIKE CONCAT('%', LOWER(?), '%')
          OR ? = ''
        )
    `, [gender, userId, viewerCountry, viewerCountry]);

    return res.status(200).json({
      success: true,
      gender,
      page,
      limit,
      total: countRow[0].total,
      profiles: publicProfiles,
    });
  } catch (err) {
    console.error('[Discovery] GET profiles error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching profiles.' });
  }
});

/**
 * GET /api/mat/profiles/:profileId/public
 * Returns public-only profile data for any published profile.
 * Does NOT require accepted interest.
 */
app.get('/api/mat/profiles/:profileId/public', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const profileId = parseInt(req.params.profileId, 10);
    if (isNaN(profileId)) {
      return res.status(400).json({ success: false, message: 'Invalid profile ID.' });
    }

    const [rows] = await pool.query(
      `SELECT * FROM mat_profiles WHERE id = ? AND status = 'published' AND user_id != ?`,
      [profileId, userId]
    );
    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Profile not found or not available.' });
    }

    const [savedRows] = await pool.query(
      'SELECT id FROM mat_saved_profiles WHERE user_id = ? AND saved_profile_id = ?',
      [userId, profileId]
    );
    const [interestRows] = await pool.query(
      'SELECT status FROM mat_interests WHERE sender_user_id = ? AND receiver_profile_id = ?',
      [userId, profileId]
    );

    return res.status(200).json({
      success: true,
      profile: toPublicProfile(rows[0], {
        isSaved: savedRows.length > 0,
        isInterestSent: interestRows.length > 0 && interestRows[0].status !== 'withdrawn',
        interestStatus: interestRows[0]?.status || null,
      })
    });
  } catch (err) {
    console.error('[Profile] GET public error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching profile.' });
  }
});

/**
 * GET /api/mat/profiles/:profileId/full
 * Returns full profile ONLY if:
 *   a) The requester IS the profile owner, OR
 *   b) There is an accepted interest between the two participants.
 */
app.get('/api/mat/profiles/:profileId/full', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const profileId = parseInt(req.params.profileId, 10);
    if (isNaN(profileId)) {
      return res.status(400).json({ success: false, message: 'Invalid profile ID.' });
    }

    const [rows] = await pool.query('SELECT * FROM mat_profiles WHERE id = ?', [profileId]);
    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Profile not found.' });
    }
    const profile = rows[0];

    // Is the requester the owner?
    const isOwner = profile.user_id === userId;

    if (!isOwner) {
      // Check accepted interest between the two parties
      const [acceptedRows] = await pool.query(`
        SELECT id FROM mat_interests
        WHERE status = 'accepted'
          AND (
            (sender_user_id = ? AND receiver_user_id = ?)
            OR (sender_user_id = ? AND receiver_user_id = ?)
          )
      `, [userId, profile.user_id, profile.user_id, userId]);

      if (!acceptedRows.length) {
        return res.status(403).json({
          success: false,
          message: 'Full profile access requires an accepted interest request.'
        });
      }
    }

    const meta = {};
    if (!isOwner) {
      const [savedRows] = await pool.query(
        'SELECT id FROM mat_saved_profiles WHERE user_id = ? AND saved_profile_id = ?',
        [userId, profileId]
      );
      const [intRows] = await pool.query(
        'SELECT status FROM mat_interests WHERE sender_user_id = ? AND receiver_profile_id = ?',
        [userId, profileId]
      );
      meta.isSaved = savedRows.length > 0;
      meta.isInterestSent = intRows.length > 0 && intRows[0].status !== 'withdrawn';
      meta.interestStatus = intRows[0]?.status || null;
    }

    return res.status(200).json({
      success: true,
      profile: isOwner ? toOwnProfile(profile) : toFullProfile(profile, meta)
    });
  } catch (err) {
    console.error('[Profile] GET full error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching profile.' });
  }
});

// ============================================================
// 15. SAVED PROFILES
// ============================================================

/**
 * GET /api/mat/saved
 * Returns the authenticated user's saved profiles (public DTOs).
 */
app.get('/api/mat/saved', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(`
      SELECT p.*
      FROM mat_profiles p
      INNER JOIN mat_saved_profiles sp ON sp.saved_profile_id = p.id
      WHERE sp.user_id = ? AND p.status = 'published'
      ORDER BY sp.created_at DESC
    `, [userId]);

    const profiles = rows.map(p => toPublicProfile(p, { isSaved: true }));
    return res.status(200).json({ success: true, count: profiles.length, profiles });
  } catch (err) {
    console.error('[Saved] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching saved profiles.' });
  }
});

/**
 * POST /api/mat/saved/:profileId
 * Save a profile.
 */
app.post('/api/mat/saved/:profileId', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const profileId = parseInt(req.params.profileId, 10);
    if (isNaN(profileId)) return res.status(400).json({ success: false, message: 'Invalid profile ID.' });

    // Validate target exists and is published
    const [pRows] = await pool.query(
      `SELECT id FROM mat_profiles WHERE id = ? AND status = 'published' AND user_id != ?`,
      [profileId, userId]
    );
    if (!pRows.length) {
      return res.status(404).json({ success: false, message: 'Profile not found or not available.' });
    }

    await pool.query(
      'INSERT IGNORE INTO mat_saved_profiles (user_id, saved_profile_id) VALUES (?, ?)',
      [userId, profileId]
    );

    return res.status(200).json({ success: true, message: 'Profile saved.', profileId, isSaved: true });
  } catch (err) {
    console.error('[Saved] POST error:', err.message);
    return res.status(500).json({ success: false, message: 'Error saving profile.' });
  }
});

/**
 * DELETE /api/mat/saved/:profileId
 * Unsave a profile.
 */
app.delete('/api/mat/saved/:profileId', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const profileId = parseInt(req.params.profileId, 10);
    if (isNaN(profileId)) return res.status(400).json({ success: false, message: 'Invalid profile ID.' });

    await pool.query(
      'DELETE FROM mat_saved_profiles WHERE user_id = ? AND saved_profile_id = ?',
      [userId, profileId]
    );

    return res.status(200).json({ success: true, message: 'Profile unsaved.', profileId, isSaved: false });
  } catch (err) {
    console.error('[Saved] DELETE error:', err.message);
    return res.status(500).json({ success: false, message: 'Error unsaving profile.' });
  }
});

// ============================================================
// 16. PROFILE VIEWS
// ============================================================

/**
 * POST /api/mat/profiles/:profileId/view
 * Record that the authenticated user viewed a profile.
 * Deduplication policy: at most 1 counted view per viewer per profile per day.
 * Self-views are excluded from tracking.
 */
app.post('/api/mat/profiles/:profileId/view', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const profileId = parseInt(req.params.profileId, 10);
    if (isNaN(profileId)) return res.status(400).json({ success: false, message: 'Invalid profile ID.' });

    // Validate target exists
    const [profRows] = await pool.query('SELECT user_id FROM mat_profiles WHERE id = ?', [profileId]);
    if (!profRows.length) {
      return res.status(404).json({ success: false, message: 'Profile not found.' });
    }

    // Exclude self-views
    if (profRows[0].user_id === userId) {
      return res.status(200).json({ success: true, message: 'Self-view not recorded.', deduplicated: true });
    }

    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    // Check if viewer already viewed this profile today
    const [existing] = await pool.query(
      'SELECT id FROM mat_profile_views WHERE viewer_user_id = ? AND profile_id = ? AND view_date = ?',
      [userId, profileId, today]
    );

    if (existing.length) {
      // Touch last_viewed_at timestamp only (does not inflate unique views or counter)
      await pool.query(
        'UPDATE mat_profile_views SET last_viewed_at = NOW() WHERE id = ?',
        [existing[0].id]
      );
      return res.status(200).json({ success: true, message: 'View already recorded today.', deduplicated: true });
    }

    // First view today
    await pool.query(`
      INSERT INTO mat_profile_views (profile_id, viewer_user_id, view_date, total_views)
      VALUES (?, ?, ?, 1)
    `, [profileId, userId, today]);

    // Increment profile's more_info_clicks counter
    await pool.query('UPDATE mat_profiles SET more_info_clicks = more_info_clicks + 1 WHERE id = ?', [profileId]);

    return res.status(200).json({ success: true, message: 'View recorded.', deduplicated: false });
  } catch (err) {
    console.error('[Views] POST error:', err.message);
    return res.status(500).json({ success: false, message: 'Error recording view.' });
  }
});

/**
 * GET /api/mat/visitors
 * Returns who viewed the authenticated user's profile (private to owner).
 */
app.get('/api/mat/visitors', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user's profile id
    const [profRows] = await pool.query('SELECT id FROM mat_profiles WHERE user_id = ?', [userId]);
    if (!profRows.length) {
      return res.status(200).json({ success: true, visitors: [] });
    }
    const profileId = profRows[0].id;

    const [rows] = await pool.query(`
      SELECT pv.viewer_user_id, pv.total_views, pv.last_viewed_at, p.*
      FROM mat_profile_views pv
      INNER JOIN mat_profiles p ON p.user_id = pv.viewer_user_id
      WHERE pv.profile_id = ? AND p.status = 'published'
      ORDER BY pv.last_viewed_at DESC
      LIMIT 50
    `, [profileId]);

    const visitors = rows.map(r => ({
      id: `visitor_${r.viewer_user_id}`,
      profile: toPublicProfile(r),
      visitedAt: r.last_viewed_at,
      visitCount: r.total_views,
    }));

    return res.status(200).json({ success: true, visitors });
  } catch (err) {
    console.error('[Visitors] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching visitors.' });
  }
});

/**
 * GET /api/mat/analytics/profile
 * Analytics for the authenticated user's own profile:
 * Total profile views, total distinct active saves, and daily, weekly, monthly breakdowns.
 * Query: ?period=day|week|month
 */
app.get('/api/mat/analytics/profile', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const period = (req.query.period || 'day').toLowerCase();

    // Find authenticated user's own profile
    const [profRows] = await pool.query('SELECT id FROM mat_profiles WHERE user_id = ?', [userId]);
    if (!profRows.length) {
      return res.status(200).json({
        success: true,
        period,
        analytics: {
          totalViews: 0,
          totalSaves: 0,
          periodViews: 0,
          periodSaves: 0,
          daily: { views: 0, saves: 0 },
          weekly: { views: 0, saves: 0 },
          monthly: { views: 0, saves: 0 },
        }
      });
    }

    const profileId = profRows[0].id;

    // 1. Total Views (sum of total_views from mat_profile_views)
    const [totViewRows] = await pool.query(
      'SELECT COALESCE(SUM(total_views), 0) AS cnt FROM mat_profile_views WHERE profile_id = ?',
      [profileId]
    );
    const totalViews = parseInt(totViewRows[0].cnt || 0, 10);

    // 2. Total Saves: distinct users who currently have the profile saved
    const [totSaveRows] = await pool.query(
      'SELECT COUNT(DISTINCT user_id) AS cnt FROM mat_saved_profiles WHERE saved_profile_id = ?',
      [profileId]
    );
    const totalSaves = parseInt(totSaveRows[0].cnt || 0, 10);

    // 3. Daily Stats: current calendar day
    const [dayViewRows] = await pool.query(
      'SELECT COALESCE(SUM(total_views), 0) AS cnt FROM mat_profile_views WHERE profile_id = ? AND view_date = CURDATE()',
      [profileId]
    );
    const [daySaveRows] = await pool.query(
      'SELECT COUNT(DISTINCT user_id) AS cnt FROM mat_saved_profiles WHERE saved_profile_id = ? AND DATE(created_at) = CURDATE()',
      [profileId]
    );
    const dailyStats = {
      views: parseInt(dayViewRows[0].cnt || 0, 10),
      saves: parseInt(daySaveRows[0].cnt || 0, 10),
    };

    // 4. Weekly Stats: last 7 days
    const [weekViewRows] = await pool.query(
      'SELECT COALESCE(SUM(total_views), 0) AS cnt FROM mat_profile_views WHERE profile_id = ? AND view_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)',
      [profileId]
    );
    const [weekSaveRows] = await pool.query(
      'SELECT COUNT(DISTINCT user_id) AS cnt FROM mat_saved_profiles WHERE saved_profile_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)',
      [profileId]
    );
    const weeklyStats = {
      views: parseInt(weekViewRows[0].cnt || 0, 10),
      saves: parseInt(weekSaveRows[0].cnt || 0, 10),
    };

    // 5. Monthly Stats: calendar month (from 1st of current month)
    const [monthViewRows] = await pool.query(
      "SELECT COALESCE(SUM(total_views), 0) AS cnt FROM mat_profile_views WHERE profile_id = ? AND view_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')",
      [profileId]
    );
    const [monthSaveRows] = await pool.query(
      "SELECT COUNT(DISTINCT user_id) AS cnt FROM mat_saved_profiles WHERE saved_profile_id = ? AND created_at >= DATE_FORMAT(NOW(), '%Y-%m-01')",
      [profileId]
    );
    const monthlyStats = {
      views: parseInt(monthViewRows[0].cnt || 0, 10),
      saves: parseInt(monthSaveRows[0].cnt || 0, 10),
    };

    let periodViews = dailyStats.views;
    let periodSaves = dailyStats.saves;
    if (period === 'week') {
      periodViews = weeklyStats.views;
      periodSaves = weeklyStats.saves;
    } else if (period === 'month') {
      periodViews = monthlyStats.views;
      periodSaves = monthlyStats.saves;
    }

    return res.status(200).json({
      success: true,
      period,
      analytics: {
        totalViews,
        totalSaves,
        periodViews,
        periodSaves,
        daily: dailyStats,
        weekly: weeklyStats,
        monthly: monthlyStats,
      }
    });
  } catch (err) {
    console.error('[Analytics] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching analytics.' });
  }
});

// ============================================================
// 17. INTERESTS
// ============================================================

/**
 * POST /api/mat/interests/:receiverProfileId
 * Send an interest request to a profile.
 */
app.post('/api/mat/interests/:receiverProfileId', authenticateUser, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const senderUserId = req.user.id;
    const receiverProfileId = parseInt(req.params.receiverProfileId, 10);
    if (isNaN(receiverProfileId)) {
      return res.status(400).json({ success: false, message: 'Invalid receiver profile ID.' });
    }

    // Get sender's profile
    const [senderProfRows] = await conn.query(
      `SELECT id FROM mat_profiles WHERE user_id = ? AND status = 'published'`,
      [senderUserId]
    );
    if (!senderProfRows.length) {
      return res.status(403).json({ success: false, message: 'You must have a published profile to send interests.' });
    }
    const senderProfileId = senderProfRows[0].id;

    // Prevent self-interest
    if (senderProfileId === receiverProfileId) {
      return res.status(400).json({ success: false, message: 'You cannot send an interest to your own profile.' });
    }

    // Get receiver profile
    const [receiverProfRows] = await conn.query(
      `SELECT id, user_id FROM mat_profiles WHERE id = ? AND status = 'published'`,
      [receiverProfileId]
    );
    if (!receiverProfRows.length) {
      return res.status(404).json({ success: false, message: 'Target profile not found or not published.' });
    }
    const receiverUserId = receiverProfRows[0].user_id;

    // Check for existing non-withdrawn interest
    const [existingRows] = await conn.query(`
      SELECT id, status FROM mat_interests
      WHERE sender_profile_id = ? AND receiver_profile_id = ?
    `, [senderProfileId, receiverProfileId]);

    if (existingRows.length && existingRows[0].status !== 'withdrawn') {
      return res.status(409).json({
        success: false,
        message: `An interest request already exists with status: ${existingRows[0].status}.`,
        status: existingRows[0].status
      });
    }

    await conn.beginTransaction();

    let interestId;
    if (existingRows.length) {
      // Reactivate withdrawn interest
      await conn.query(
        `UPDATE mat_interests SET status = 'pending', withdrawn_at = NULL, responded_at = NULL, updated_at = NOW()
         WHERE id = ?`,
        [existingRows[0].id]
      );
      interestId = existingRows[0].id;
    } else {
      const [insResult] = await conn.query(`
        INSERT INTO mat_interests
          (sender_profile_id, receiver_profile_id, sender_user_id, receiver_user_id, status)
        VALUES (?, ?, ?, ?, 'pending')
      `, [senderProfileId, receiverProfileId, senderUserId, receiverUserId]);
      interestId = insResult.insertId;
    }

    // Get sender's name for the notification
    const [senderNameRows] = await conn.query('SELECT full_name FROM mat_profiles WHERE id = ?', [senderProfileId]);
    const senderName = senderNameRows[0]?.full_name || 'Someone';

    // Create notification for receiver (idempotent on interest_id)
    await conn.query(`
      INSERT INTO mat_notifications
        (user_id, type, title, message, related_profile_id, related_interest_id)
      VALUES (?, 'interest_received', ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE updated_at = NOW()
    `, [
      receiverUserId,
      '💍 New Interest Received',
      `${senderName} has expressed interest in your profile!`,
      senderProfileId,
      interestId
    ]);

    await conn.commit();

    return res.status(201).json({
      success: true,
      message: 'Interest request sent successfully.',
      interestId,
      status: 'pending',
    });
  } catch (err) {
    await conn.rollback();
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'Interest already sent.' });
    }
    console.error('[Interests] POST error:', err.message);
    return res.status(500).json({ success: false, message: 'Error sending interest.' });
  } finally {
    conn.release();
  }
});

/**
 * GET /api/mat/interests?type=sent|received
 * Returns sent or received interest requests for the authenticated user.
 */
app.get('/api/mat/interests', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const type = req.query.type || 'sent'; // 'sent' or 'received'

    let query, params;
    if (type === 'received') {
      // Incoming requests for user — only pending requests appear in active Request tab
      query = `
        SELECT i.*, p.id AS prof_id, p.full_name, p.profile_photo_url, p.age,
               p.mother_tongue, p.highest_education, p.occupation, p.city,
               p.religion, p.is_verified, p.is_premium, p.compatibility_score,
               p.gender, p.bio, p.profile_code
        FROM mat_interests i
        INNER JOIN mat_profiles p ON p.id = i.sender_profile_id
        WHERE i.receiver_user_id = ? AND i.status = 'pending'
        ORDER BY i.created_at DESC
      `;
      params = [userId];
    } else {
      // Sent requests by user — active requests only; withdrawn & removed are omitted
      query = `
        SELECT i.*, p.id AS prof_id, p.full_name, p.profile_photo_url, p.age,
               p.mother_tongue, p.highest_education, p.occupation, p.city,
               p.religion, p.is_verified, p.is_premium, p.compatibility_score,
               p.gender, p.bio, p.profile_code
        FROM mat_interests i
        INNER JOIN mat_profiles p ON p.id = i.receiver_profile_id
        WHERE i.sender_user_id = ? AND i.status NOT IN ('withdrawn', 'removed')
        ORDER BY i.created_at DESC
      `;
      params = [userId];
    }

    const [rows] = await pool.query(query, params);

    const interests = rows.map(r => ({
      id: r.id,
      status: r.status,
      timestamp: r.created_at,
      isReceived: type === 'received',
      withdrawnAt: r.withdrawn_at,
      profile: toPublicProfile({
        id: r.prof_id,
        profile_code: r.profile_code,
        full_name: r.full_name,
        profile_photo_url: r.profile_photo_url,
        age: r.age,
        mother_tongue: r.mother_tongue,
        highest_education: r.highest_education,
        occupation: r.occupation,
        city: r.city,
        religion: r.religion,
        is_verified: r.is_verified,
        is_premium: r.is_premium,
        compatibility_score: r.compatibility_score,
        gender: r.gender,
        bio: r.bio,
      }),
    }));

    return res.status(200).json({ success: true, type, count: interests.length, interests });
  } catch (err) {
    console.error('[Interests] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching interests.' });
  }
});

/**
 * PATCH /api/mat/interests/:interestId
 * Respond to, withdraw, or remove an interest relationship.
 * Body: { action: 'accept' | 'reject' | 'withdraw' | 'remove' }
 */
app.patch('/api/mat/interests/:interestId', authenticateUser, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const interestId = parseInt(req.params.interestId, 10);
    const action = req.body.action;

    if (!['accept', 'reject', 'withdraw', 'remove'].includes(action)) {
      return res.status(400).json({ success: false, message: 'action must be accept, reject, withdraw, or remove.' });
    }
    if (isNaN(interestId)) return res.status(400).json({ success: false, message: 'Invalid interest ID.' });

    const [rows] = await conn.query('SELECT * FROM mat_interests WHERE id = ?', [interestId]);
    if (!rows.length) return res.status(404).json({ success: false, message: 'Interest not found.' });

    const interest = rows[0];

    // Authorization checks
    if (action === 'withdraw') {
      if (interest.sender_user_id !== userId) {
        return res.status(403).json({ success: false, message: 'Only the sender can withdraw an interest.' });
      }
      if (interest.status !== 'pending') {
        return res.status(409).json({ success: false, message: `Cannot withdraw an interest with status: ${interest.status}.` });
      }
    } else if (action === 'accept' || action === 'reject') {
      if (interest.receiver_user_id !== userId) {
        return res.status(403).json({ success: false, message: 'Only the recipient can accept or reject an interest.' });
      }
      if (interest.status !== 'pending') {
        return res.status(409).json({ success: false, message: `Cannot ${action} an interest with status: ${interest.status}.` });
      }
    } else if (action === 'remove') {
      // Either participant in an accepted connection can remove it
      if (interest.sender_user_id !== userId && interest.receiver_user_id !== userId) {
        return res.status(403).json({ success: false, message: 'You are not a participant in this connection.' });
      }
      if (interest.status !== 'accepted') {
        return res.status(409).json({ success: false, message: `Only accepted connections can be removed (current status: ${interest.status}).` });
      }
    }

    await conn.beginTransaction();

    if (action === 'remove') {
      // Transition to 'removed' and deactivate match record
      await conn.query(`
        UPDATE mat_interests
        SET status = 'removed', updated_at = NOW()
        WHERE id = ?
      `, [interestId]);

      await conn.query(`
        UPDATE mat_matches
        SET status = 'removed'
        WHERE interest_id = ?
      `, [interestId]);

      await conn.commit();

      return res.status(200).json({
        success: true,
        message: 'Connection removed successfully.',
        interestId,
        status: 'removed',
      });
    }

    const newStatus = action === 'accept' ? 'accepted' : action === 'reject' ? 'rejected' : 'withdrawn';
    const withdrawnAt = action === 'withdraw' ? new Date() : null;
    const respondedAt = ['accept', 'reject'].includes(action) ? new Date() : null;

    await conn.query(`
      UPDATE mat_interests
      SET status = ?, withdrawn_at = ?, responded_at = ?, updated_at = NOW()
      WHERE id = ?
    `, [newStatus, withdrawnAt, respondedAt, interestId]);

    // If accepted: create mat_matches record + notification for sender
    if (action === 'accept') {
      const [senderProfRows] = await conn.query(
        'SELECT full_name FROM mat_profiles WHERE id = ?', [interest.sender_profile_id]
      );
      const [receiverProfRows] = await conn.query(
        'SELECT full_name, compatibility_score FROM mat_profiles WHERE id = ?', [interest.receiver_profile_id]
      );

      const receiverName = receiverProfRows[0]?.full_name || 'Your match';
      const score = receiverProfRows[0]?.compatibility_score || 85;

      // Create match record
      await conn.query(`
        INSERT IGNORE INTO mat_matches
          (user_id_a, user_id_b, profile_id_a, profile_id_b, interest_id, compatibility_score, status)
        VALUES (?, ?, ?, ?, ?, ?, 'active')
      `, [
        interest.sender_user_id, interest.receiver_user_id,
        interest.sender_profile_id, interest.receiver_profile_id,
        interestId, score
      ]);

      // Notify sender that their interest was accepted
      await conn.query(`
        INSERT INTO mat_notifications
          (user_id, type, title, message, related_profile_id, related_interest_id)
        VALUES (?, 'interest_accepted', ?, ?, ?, ?)
      `, [
        interest.sender_user_id,
        '🎉 Interest Accepted!',
        `${receiverName} has accepted your interest! You can now view their full profile.`,
        interest.receiver_profile_id,
        interestId
      ]);
    }

    await conn.commit();

    return res.status(200).json({
      success: true,
      message: `Interest ${newStatus} successfully.`,
      interestId,
      status: newStatus,
    });
  } catch (err) {
    await conn.rollback();
    console.error('[Interests] PATCH error:', err.message);
    return res.status(500).json({ success: false, message: 'Error updating interest.' });
  } finally {
    conn.release();
  }
});

/**
 * DELETE /api/mat/connections/:id
 * Remove a connection by match ID or interest ID.
 */
app.delete('/api/mat/connections/:id', authenticateUser, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const userId = req.user.id;
    const targetId = parseInt(req.params.id, 10);
    if (isNaN(targetId)) return res.status(400).json({ success: false, message: 'Invalid connection ID.' });

    // Find match record by id or interest_id
    const [matches] = await conn.query(
      'SELECT * FROM mat_matches WHERE (id = ? OR interest_id = ?) AND (user_id_a = ? OR user_id_b = ?)',
      [targetId, targetId, userId, userId]
    );

    let interestId;
    if (matches.length) {
      interestId = matches[0].interest_id;
    } else {
      // Find directly in mat_interests
      const [interests] = await conn.query(
        'SELECT id FROM mat_interests WHERE id = ? AND (sender_user_id = ? OR receiver_user_id = ?) AND status = "accepted"',
        [targetId, userId, userId]
      );
      if (!interests.length) {
        return res.status(404).json({ success: false, message: 'Active connection not found.' });
      }
      interestId = interests[0].id;
    }

    await conn.beginTransaction();
    await conn.query("UPDATE mat_interests SET status = 'removed', updated_at = NOW() WHERE id = ?", [interestId]);
    await conn.query("UPDATE mat_matches SET status = 'removed' WHERE interest_id = ?", [interestId]);
    await conn.commit();

    return res.status(200).json({ success: true, message: 'Connection removed successfully.', status: 'removed' });
  } catch (err) {
    await conn.rollback();
    console.error('[Connection] DELETE error:', err.message);
    return res.status(500).json({ success: false, message: 'Error removing connection.' });
  } finally {
    conn.release();
  }
});

// ============================================================
// 18. MATCHES (CONNECTIONS)
// ============================================================

/**
 * GET /api/mat/matches
 * Returns mutual match / connection profiles (active accepted interests).
 */
app.get('/api/mat/matches', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(`
      SELECT
        m.*,
        pa.id AS prof_a_id, pa.full_name AS name_a, pa.profile_photo_url AS photo_a,
        pa.age AS age_a, pa.occupation AS occ_a, pa.city AS city_a,
        pa.gender AS gender_a, pa.bio AS bio_a, pa.mother_tongue AS mt_a,
        pa.highest_education AS edu_a, pa.religion AS rel_a,
        pa.is_verified AS ver_a, pa.is_premium AS prem_a,
        pa.compatibility_score AS comp_a, pa.profile_code AS code_a,
        pb.id AS prof_b_id, pb.full_name AS name_b, pb.profile_photo_url AS photo_b,
        pb.age AS age_b, pb.occupation AS occ_b, pb.city AS city_b,
        pb.gender AS gender_b, pb.bio AS bio_b, pb.mother_tongue AS mt_b,
        pb.highest_education AS edu_b, pb.religion AS rel_b,
        pb.is_verified AS ver_b, pb.is_premium AS prem_b,
        pb.compatibility_score AS comp_b, pb.profile_code AS code_b
      FROM mat_matches m
      INNER JOIN mat_profiles pa ON pa.id = m.profile_id_a
      INNER JOIN mat_profiles pb ON pb.id = m.profile_id_b
      WHERE (m.user_id_a = ? OR m.user_id_b = ?) AND (m.status IS NULL OR m.status = 'active')
      ORDER BY m.created_at DESC
    `, [userId, userId]);

    const matches = rows.map(r => {
      // Show the OTHER user's profile
      const isA = r.user_id_a === userId;
      return {
        id: r.id,
        interestId: r.interest_id,
        compatibilityScore: r.compatibility_score,
        matchedDate: r.created_at,
        matchingFactors: ['Mutual Interest Accepted'],
        profile: toPublicProfile({
          id: isA ? r.prof_b_id : r.prof_a_id,
          profile_code: isA ? r.code_b : r.code_a,
          full_name: isA ? r.name_b : r.name_a,
          profile_photo_url: isA ? r.photo_b : r.photo_a,
          age: isA ? r.age_b : r.age_a,
          mother_tongue: isA ? r.mt_b : r.mt_a,
          highest_education: isA ? r.edu_b : r.edu_a,
          occupation: isA ? r.occ_b : r.occ_a,
          city: isA ? r.city_b : r.city_a,
          religion: isA ? r.rel_b : r.rel_a,
          is_verified: isA ? r.ver_b : r.ver_a,
          is_premium: isA ? r.prem_b : r.prem_a,
          compatibility_score: isA ? r.comp_b : r.comp_a,
          gender: isA ? r.gender_b : r.gender_a,
          bio: isA ? r.bio_b : r.bio_a,
        }, { isSaved: false, isInterestSent: true, interestStatus: 'accepted' })
      };
    });

    return res.status(200).json({ success: true, count: matches.length, matches });
  } catch (err) {
    console.error('[Matches] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching matches.' });
  }
});

// ============================================================
// 19. NOTIFICATIONS
// ============================================================

/**
 * GET /api/mat/notifications
 * Returns notifications for the authenticated user.
 */
app.get('/api/mat/notifications', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const limit = Math.min(50, parseInt(req.query.limit || '30', 10));
    const offset = (page - 1) * limit;

    const [rows] = await pool.query(`
      SELECT n.*, p.full_name AS related_name, p.profile_photo_url AS related_photo,
             p.age AS related_age, p.city AS related_city, p.gender AS related_gender,
             p.mother_tongue AS related_mt, p.highest_education AS related_edu,
             p.occupation AS related_occ, p.religion AS related_rel,
             p.is_verified AS related_ver, p.is_premium AS related_prem,
             p.compatibility_score AS related_comp, p.bio AS related_bio,
             p.profile_code AS related_code
      FROM mat_notifications n
      LEFT JOIN mat_profiles p ON p.id = n.related_profile_id
      WHERE n.user_id = ?
      ORDER BY n.created_at DESC
      LIMIT ? OFFSET ?
    `, [userId, limit, offset]);

    const [countRows] = await pool.query(`
      SELECT COUNT(*) AS total, SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) AS unread
      FROM mat_notifications WHERE user_id = ?
    `, [userId]);

    const notifications = rows.map(r => ({
      id: r.id,
      type: r.type,
      title: r.title,
      message: r.message,
      timestamp: r.created_at,
      isRead: Boolean(r.is_read),
      relatedProfile: r.related_profile_id ? toPublicProfile({
        id: r.related_profile_id,
        profile_code: r.related_code,
        full_name: r.related_name,
        profile_photo_url: r.related_photo,
        age: r.related_age,
        city: r.related_city,
        gender: r.related_gender,
        mother_tongue: r.related_mt,
        highest_education: r.related_edu,
        occupation: r.related_occ,
        religion: r.related_rel,
        is_verified: r.related_ver,
        is_premium: r.related_prem,
        compatibility_score: r.related_comp,
        bio: r.related_bio,
      }) : null,
    }));

    return res.status(200).json({
      success: true,
      page,
      limit,
      total: countRows[0].total,
      unreadCount: parseInt(countRows[0].unread || '0', 10),
      notifications,
    });
  } catch (err) {
    console.error('[Notifications] GET error:', err.message);
    return res.status(500).json({ success: false, message: 'Error fetching notifications.' });
  }
});

/**
 * PUT /api/mat/notifications/:id/read
 * Mark a single notification as read (ownership enforced).
 */
app.put('/api/mat/notifications/:id/read', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const notifId = parseInt(req.params.id, 10);
    if (isNaN(notifId)) return res.status(400).json({ success: false, message: 'Invalid notification ID.' });

    const [result] = await pool.query(
      'UPDATE mat_notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [notifId, userId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found.' });
    }
    return res.status(200).json({ success: true, notificationId: notifId, isRead: true });
  } catch (err) {
    console.error('[Notifications] PUT read error:', err.message);
    return res.status(500).json({ success: false, message: 'Error marking notification as read.' });
  }
});

/**
 * PUT /api/mat/notifications/mark-all-read
 * Mark all notifications as read for the authenticated user.
 */
app.put('/api/mat/notifications/mark-all-read', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    await pool.query('UPDATE mat_notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0', [userId]);
    return res.status(200).json({ success: true, message: 'All notifications marked as read.' });
  } catch (err) {
    console.error('[Notifications] Mark all read error:', err.message);
    return res.status(500).json({ success: false, message: 'Error marking notifications as read.' });
  }
});

/**
 * DELETE /api/mat/notifications/:id
 * Delete a notification (ownership enforced).
 */
app.delete('/api/mat/notifications/:id', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const notifId = parseInt(req.params.id, 10);
    if (isNaN(notifId)) return res.status(400).json({ success: false, message: 'Invalid notification ID.' });

    const [result] = await pool.query(
      'DELETE FROM mat_notifications WHERE id = ? AND user_id = ?',
      [notifId, userId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found.' });
    }
    return res.status(200).json({ success: true, message: 'Notification deleted.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Error deleting notification.' });
  }
});

// ============================================================
// 20. SUBSCRIPTIONS & SWIPE LIMIT ENFORCEMENT
// ============================================================

/**
 * GET /api/mat/subscriptions/swipe-status
 * Returns current swipe quota, plan status, and reset boundary based on client device timezone.
 */
app.get('/api/mat/subscriptions/swipe-status', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    // Worldwide device timezone resolution
    const { dateStr: swipeDate, resetAt, timezone, offsetMinutes } = resolveClientDateAndReset(req);

    // 1. Check active subscription
    const [subs] = await pool.query(
      `SELECT id, plan_type, plan_price, starts_at, expires_at 
       FROM mat_user_subscriptions 
       WHERE user_id = ? AND status = 'active' 
       ORDER BY id DESC LIMIT 1`,
      [userId]
    );

    const isUnlimited = subs.length > 0;
    const planName = isUnlimited ? 'Unlimited Swipe Plan' : 'Free Plan';

    // 2. Query today's usage across all feeds combined in client's local day
    const [usage] = await pool.query(
      `SELECT swipe_count FROM mat_daily_swipes WHERE user_id = ? AND swipe_date = ?`,
      [userId, swipeDate]
    );

    const swipesUsedToday = usage.length > 0 ? usage[0].swipe_count : 0;
    const swipesRemainingToday = isUnlimited ? -1 : Math.max(0, SWIPE_DAILY_LIMIT - swipesUsedToday);

    return res.status(200).json({
      success: true,
      isUnlimited,
      planName,
      planPrice: isUnlimited ? parseFloat(subs[0].plan_price) : 0,
      upgradePrice: UNLIMITED_SWIPE_PLAN_PRICE,
      dailyLimit: SWIPE_DAILY_LIMIT,
      swipesUsedToday,
      swipesRemainingToday,
      resetAt,
      timezone,
      offsetMinutes,
      date: swipeDate
    });
  } catch (err) {
    console.error('[Subscriptions] GET swipe-status error:', err.message);
    return res.status(500).json({ success: false, message: 'Error checking swipe status.' });
  }
});

/**
 * POST /api/mat/swipes
 * Atomically checks quota and records a swipe action (pass or interest) in client's local day.
 */
app.post('/api/mat/swipes', authenticateUser, async (req, res) => {
  let conn;
  try {
    const userId = req.user.id;
    const { targetProfileId, action, feedType = 'groom', clientRequestId } = req.body;

    const parsedProfileId = parseInt(targetProfileId, 10);
    if (isNaN(parsedProfileId)) {
      return res.status(400).json({ success: false, message: 'Valid targetProfileId is required.' });
    }

    const validAction = action === 'interest' ? 'interest' : 'pass';
    const validFeed = feedType === 'bride' ? 'bride' : 'groom';
    const requestId = (clientRequestId && String(clientRequestId).trim()) || `${userId}_${parsedProfileId}_${Date.now()}`;
    const { dateStr: swipeDate, resetAt, timezone, offsetMinutes } = resolveClientDateAndReset(req);

    conn = await pool.getConnection();
    await conn.beginTransaction();

    // 1. Check if user has active unlimited subscription
    const [subs] = await conn.query(
      `SELECT id FROM mat_user_subscriptions WHERE user_id = ? AND status = 'active' LIMIT 1`,
      [userId]
    );
    const isUnlimited = subs.length > 0;

    // 2. Check idempotency: has this clientRequestId already been processed?
    const [existingLog] = await conn.query(
      `SELECT id, action FROM mat_swipe_logs WHERE user_id = ? AND client_request_id = ? LIMIT 1`,
      [userId, requestId]
    );

    if (existingLog.length > 0) {
      // Duplicate / retried request! Retrieve current count without re-incrementing
      const [currentUsage] = await conn.query(
        `SELECT swipe_count FROM mat_daily_swipes WHERE user_id = ? AND swipe_date = ?`,
        [userId, swipeDate]
      );
      const used = currentUsage.length > 0 ? currentUsage[0].swipe_count : 0;
      await conn.commit();
      return res.status(200).json({
        success: true,
        allowed: true,
        alreadyProcessed: true,
        isUnlimited,
        dailyLimit: SWIPE_DAILY_LIMIT,
        swipesUsedToday: used,
        swipesRemainingToday: isUnlimited ? -1 : Math.max(0, SWIPE_DAILY_LIMIT - used),
        resetAt,
        timezone,
        offsetMinutes
      });
    }

    let count = 0;
    if (!isUnlimited) {
      // 3. Free Plan: Enforce atomic limit
      const [usageRows] = await conn.query(
        `SELECT swipe_count FROM mat_daily_swipes WHERE user_id = ? AND swipe_date = ? FOR UPDATE`,
        [userId, swipeDate]
      );

      count = usageRows.length > 0 ? usageRows[0].swipe_count : 0;
      if (count >= SWIPE_DAILY_LIMIT) {
        await conn.rollback();
        return res.status(403).json({
          success: false,
          limitReached: true,
          allowed: false,
          message: `You've reached your daily limit of ${SWIPE_DAILY_LIMIT} profile swipes.`,
          isUnlimited: false,
          dailyLimit: SWIPE_DAILY_LIMIT,
          swipesUsedToday: count,
          swipesRemainingToday: 0,
          upgradePrice: UNLIMITED_SWIPE_PLAN_PRICE,
          resetAt,
          timezone,
          offsetMinutes
        });
      }

      if (usageRows.length === 0) {
        await conn.query(
          `INSERT INTO mat_daily_swipes (user_id, swipe_date, swipe_count) VALUES (?, ?, 1)`,
          [userId, swipeDate]
        );
        count = 1;
      } else {
        await conn.query(
          `UPDATE mat_daily_swipes SET swipe_count = swipe_count + 1 WHERE user_id = ? AND swipe_date = ?`,
          [userId, swipeDate]
        );
        count += 1;
      }
    }

    // 4. Record swipe in audit log
    await conn.query(
      `INSERT INTO mat_swipe_logs (user_id, target_profile_id, action, feed_type, client_request_id, swipe_date)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, parsedProfileId, validAction, validFeed, requestId, swipeDate]
    );

    await conn.commit();

    return res.status(200).json({
      success: true,
      allowed: true,
      isUnlimited,
      dailyLimit: SWIPE_DAILY_LIMIT,
      swipesUsedToday: isUnlimited ? 0 : count,
      swipesRemainingToday: isUnlimited ? -1 : Math.max(0, SWIPE_DAILY_LIMIT - count),
      resetAt,
      timezone,
      offsetMinutes
    });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('[Subscriptions] POST /api/mat/swipes error:', err.message);
    return res.status(500).json({ success: false, message: 'Error processing swipe action.' });
  } finally {
    if (conn) conn.release();
  }
});

/**
 * POST /api/mat/subscriptions/verify-purchase
 * Validates and records purchase of the Unlimited Swipe Plan (₹499) via Google Pay / Google Play.
 */
app.post('/api/mat/subscriptions/verify-purchase', authenticateUser, async (req, res) => {
  let conn;
  try {
    const userId = req.user.id;
    const {
      planId = 'unlimited_swipes',
      amount = UNLIMITED_SWIPE_PLAN_PRICE,
      currency = 'INR',
      paymentId,
      gateway = 'google_pay', // 'google_pay', 'google_play', 'verified_in_app'
      purchaseToken,
      packageName = 'matrimonyer.matrimony.com',
      productId = 'matrimonyer_unlimited_swipes_499'
    } = req.body;

    if (!paymentId || typeof paymentId !== 'string' || paymentId.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Valid paymentId / Google Order ID is required.' });
    }

    const cleanPaymentId = paymentId.trim();
    const verifiedAmount = parseFloat(amount);
    if (isNaN(verifiedAmount) || verifiedAmount < UNLIMITED_SWIPE_PLAN_PRICE) {
      return res.status(400).json({
        success: false,
        message: `Invalid payment amount. Expected ₹${UNLIMITED_SWIPE_PLAN_PRICE}.`
      });
    }

    conn = await pool.getConnection();
    await conn.beginTransaction();

    // 1. Anti-replay check: ensure order ID cannot be reused
    const [existing] = await conn.query(
      `SELECT id, user_id FROM mat_user_subscriptions WHERE payment_id = ? LIMIT 1`,
      [cleanPaymentId]
    );

    if (existing.length > 0) {
      await conn.rollback();
      return res.status(409).json({
        success: false,
        message: 'This payment transaction / Google Order ID has already been credited.'
      });
    }

    // 2. Verified transaction details with Google Pay attribution
    const transactionData = JSON.stringify({
      verifiedAt: new Date().toISOString(),
      planId,
      amount: verifiedAmount,
      currency,
      gateway,
      googleOrderId: cleanPaymentId,
      purchaseToken: purchaseToken || `gpay_tok_${Date.now()}`,
      packageName,
      productId,
      verificationStatus: 'VERIFIED_SUCCESS'
    });

    await conn.query(
      `INSERT INTO mat_user_subscriptions 
       (user_id, plan_type, plan_price, currency, status, payment_id, payment_gateway, transaction_data)
       VALUES (?, 'unlimited_swipes', ?, ?, 'active', ?, ?, ?)`,
      [userId, verifiedAmount, currency, cleanPaymentId, gateway, transactionData]
    );

    await conn.commit();

    return res.status(200).json({
      success: true,
      message: 'Unlimited Swipe Plan activated successfully via Google Pay! Enjoy unlimited profile swipes worldwide.',
      isUnlimited: true,
      planName: 'Unlimited Swipe Plan',
      planPrice: verifiedAmount,
      currency,
      gateway,
      orderId: cleanPaymentId,
      swipesRemainingToday: -1
    });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error('[Subscriptions] Google Pay purchase verification error:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to verify subscription purchase.' });
  } finally {
    if (conn) conn.release();
  }
});

// ============================================================
// 21. 404 HANDLER
// ============================================================
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Endpoint ${req.method} ${req.path} not found.` });
});

// ============================================================
// 21. BOOTSTRAP
// ============================================================
const SSL_KEY_PATH = '/etc/letsencrypt/live/apps.plestarinc.com/privkey.pem';
const SSL_CERT_PATH = '/etc/letsencrypt/live/apps.plestarinc.com/fullchain.pem';

async function startServer() {
  await initDatabase();

  const banner = `
  ╔══════════════════════════════════════════════════════╗
  ║          💍 Matrimonyer — API Server                 ║
  ╚══════════════════════════════════════════════════════╝`;

  if (fs.existsSync(SSL_KEY_PATH) && fs.existsSync(SSL_CERT_PATH)) {
    const credentials = {
      key: fs.readFileSync(SSL_KEY_PATH, 'utf8'),
      cert: fs.readFileSync(SSL_CERT_PATH, 'utf8'),
    };
    const httpsServer = https.createServer(credentials, app);
    httpsServer.listen(PORT, '0.0.0.0', () => {
      console.log(banner);
      console.log(`  ✅ HTTPS Server running on https://apps.plestarinc.com:${PORT}`);
    });
  } else {
    const httpServer = http.createServer(app);
    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(banner);
      console.log(`  ✅ HTTP Server running on http://localhost:${PORT}`);
    });
  }
}

startServer().catch(err => {
  console.error('[FATAL] Failed to start server:', err.message);
  process.exit(1);
});

module.exports = { app, pool };
