-- ============================================================
-- Upload Enhanced Static Files to APEX Application
-- Version 2.0 - Inline SQL Version
-- ============================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    l_app_id NUMBER := 102;
    l_workspace_id NUMBER;
    l_css_content CLOB;
    l_js_content CLOB;
    l_blob BLOB;
    l_dest_offset INTEGER := 1;
    l_src_offset INTEGER := 1;
    l_lang_context INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warning INTEGER;

    -- Helper function to convert CLOB to BLOB for large content
    FUNCTION clob_to_blob(p_clob IN CLOB) RETURN BLOB IS
        l_result BLOB;
        l_dest_off INTEGER := 1;
        l_src_off INTEGER := 1;
        l_ctx INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
        l_warn INTEGER;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(l_result, TRUE);
        IF p_clob IS NOT NULL AND DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
            DBMS_LOB.CONVERTTOBLOB(
                dest_lob     => l_result,
                src_clob     => p_clob,
                amount       => DBMS_LOB.LOBMAXSIZE,
                dest_offset  => l_dest_off,
                src_offset   => l_src_off,
                blob_csid    => DBMS_LOB.DEFAULT_CSID,
                lang_context => l_ctx,
                warning      => l_warn
            );
        END IF;
        RETURN l_result;
    END clob_to_blob;
BEGIN
    -- Get workspace ID
    SELECT workspace_id INTO l_workspace_id
    FROM apex_applications
    WHERE application_id = l_app_id;

    -- Set APEX security context
    apex_util.set_security_group_id(l_workspace_id);

    DBMS_OUTPUT.PUT_LINE('Uploading enhanced CSS file...');

    -- Delete existing CSS file if present (query ID first, then remove by ID)
    DECLARE
        l_file_id NUMBER;
    BEGIN
        SELECT application_file_id INTO l_file_id
        FROM apex_application_static_files
        WHERE application_id = l_app_id
        AND file_name = 'css/app-styles.css';
        
        wwv_flow_imp.remove_app_static_file(
            p_id      => l_file_id,
            p_flow_id => l_app_id
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- File doesn't exist, that's OK
    END;

    -- CSS Content (Part 1 - Basic styles)
    l_css_content := q'[
/**
 * USCIS Case Tracker - Application Styles
 * Version: 2.0.0 - ENHANCED EDITION
 * Date: February 4, 2026
 */

/* CSS Variables */
:root {
  --uscis-primary: #0f172a;
  --uscis-secondary: #3b82f6;
  --uscis-accent: #06b6d4;
  --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --gradient-secondary: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  --glass-bg: rgba(255, 255, 255, 0.08);
  --glass-border: rgba(255, 255, 255, 0.15);
  --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.15);
}

/* Body enhancements */
body {
  background: linear-gradient(135deg, #1e3a5f 0%, #0f172a 50%, #0c1929 100%) !important;
  background-attachment: fixed !important;
}

.t-Body-content {
  background: rgba(248, 250, 252, 0.95) !important;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

/* Header styling */
.t-Header {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3) !important;
  backdrop-filter: blur(10px);
}

.t-Header-logo-link {
  color: #ffffff !important;
  font-weight: 700;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

/* Status badges */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  animation: badgeFadeIn 0.4s ease-out;
}

@keyframes badgeFadeIn {
  from { opacity: 0; transform: scale(0.8); }
  to { opacity: 1; transform: scale(1); }
}

.status-approved {
  background: linear-gradient(135deg, #10b981 0%, #34d399 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(16, 185, 129, 0.35);
}

.status-denied {
  background: linear-gradient(135deg, #ef4444 0%, #f97316 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(239, 68, 68, 0.35);
}

.status-pending {
  background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%);
  color: #1a1a1a;
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.35);
}

.status-rfe {
  background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(59, 130, 246, 0.35);
}

.status-received {
  background: linear-gradient(135deg, #8b5cf6 0%, #a855f7 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(139, 92, 246, 0.35);
}

.status-unknown {
  background: linear-gradient(135deg, #64748b 0%, #94a3b8 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(100, 116, 139, 0.3);
}

/* Cards with glassmorphism */
.t-Card {
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 16px !important;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.t-Card:hover {
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  transform: translateY(-6px);
}

/* Buttons */
.t-Button--hot {
  background: var(--gradient-secondary) !important;
  border: none !important;
  color: #ffffff !important;
  font-weight: 600 !important;
  padding: 12px 24px !important;
  border-radius: 10px !important;
  box-shadow: 0 4px 15px rgba(59, 130, 246, 0.35) !important;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.t-Button--hot:hover {
  transform: translateY(-3px) !important;
  box-shadow: 0 8px 25px rgba(59, 130, 246, 0.45) !important;
}

/* Timeline styling */
.timeline-item {
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  border: 1px solid rgba(59, 130, 246, 0.15);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.25s ease;
}

.timeline-item:hover {
  transform: translateX(8px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
}
]';

    -- Upload CSS file (using BLOB to handle content > 32K)
    l_blob := clob_to_blob(l_css_content);
    wwv_flow_imp.create_app_static_file(
        p_id           => wwv_flow_id.next_val,
        p_flow_id      => l_app_id,
        p_file_name    => 'css/app-styles.css',
        p_mime_type    => 'text/css',
        p_file_charset => 'utf-8',
        p_file_content => l_blob
    );
    DBMS_LOB.FREETEMPORARY(l_blob);

    DBMS_OUTPUT.PUT_LINE('CSS file uploaded successfully.');

    -- Upload JS file
    DBMS_OUTPUT.PUT_LINE('Uploading enhanced JavaScript file...');

    -- Delete existing JS file if present (query ID first, then remove by ID)
    DECLARE
        l_file_id NUMBER;
    BEGIN
        SELECT application_file_id INTO l_file_id
        FROM apex_application_static_files
        WHERE application_id = l_app_id
        AND file_name = 'js/app-scripts.js';
        
        wwv_flow_imp.remove_app_static_file(
            p_id      => l_file_id,
            p_flow_id => l_app_id
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- File doesn't exist, that's OK
    END;

    -- JS Content (Core functions)
    l_js_content := q'[
/**
 * USCIS Case Tracker - Application JavaScript Utilities
 * Version: 2.0.0 - ENHANCED EDITION
 */

// Receipt number utilities
function formatReceiptNumber(receiptNum) {
    if (!receiptNum) return '';
    const normalized = normalizeReceiptNumber(receiptNum);
    if (normalized.length !== 13) return receiptNum;
    return normalized.substring(0, 3) + '-' + normalized.substring(3, 6) + '-' + normalized.substring(6);
}

function normalizeReceiptNumber(receiptNum) {
    if (!receiptNum) return '';
    return receiptNum.replace(/[-\s]/g, '').toUpperCase().trim();
}

function isValidReceiptNumber(receiptNum) {
    if (!receiptNum) return false;
    const normalized = normalizeReceiptNumber(receiptNum);
    return /^[A-Z]{3}\d{10}$/.test(normalized);
}

function getStatusClass(status) {
    if (!status) return 'status-unknown';
    const s = status.toLowerCase();
    if (/\bnot approved\b/.test(s) || /\bdenied\b/.test(s)) return 'status-denied';
    if (/\bapproved\b/.test(s) || /\bcard was produced\b/.test(s) || /\bcard is being produced\b/.test(s) || /\bnew card\b/.test(s)) return 'status-approved';
    if (/\brfe\b/.test(s)) return 'status-rfe';
    if (/\breceived\b/.test(s)) return 'status-received';
    if (/\bpending\b/.test(s) || /\bprocessing\b/.test(s)) return 'status-pending';
    return 'status-unknown';
}

// Visual effects
function showToast(message, type, duration) {
    type = type || 'info';
    duration = duration || 4000;

    const toast = document.createElement('div');
    toast.className = 'custom-toast custom-toast-' + type;

    // Use DOM construction to prevent XSS
    const msgDiv = document.createElement('div');
    msgDiv.className = 'custom-toast-message';
    msgDiv.textContent = message; // Safe: uses textContent, not innerHTML
    toast.appendChild(msgDiv);

    const style = document.createElement('style');
    style.textContent = '.custom-toast{position:fixed;bottom:24px;right:24px;min-width:320px;padding:16px;border-radius:16px;z-index:10000;backdrop-filter:blur(20px);animation:toastIn .4s cubic-bezier(.68,-.55,.265,1.55)}' +
    '.custom-toast-info{background:linear-gradient(135deg,rgba(59,130,246,.95),rgba(6,182,212,.9));color:#fff}' +
    '.custom-toast-success{background:linear-gradient(135deg,rgba(16,185,129,.95),rgba(52,211,153,.9));color:#fff}' +
    '.custom-toast-error{background:linear-gradient(135deg,rgba(239,68,68,.95),rgba(249,115,22,.9));color:#fff}' +
    '.custom-toast-message{font-weight:600;font-size:14px}' +
    '@keyframes toastIn{0%{opacity:0;transform:translateY(30px) scale(.9)}100%{opacity:1;transform:translateY(0) scale(1)}}';

    if (!document.querySelector('#custom-toast-styles')) {
        style.id = 'custom-toast-styles';
        document.head.appendChild(style);
    }

    document.body.appendChild(toast);
    setTimeout(function() { toast.remove(); }, duration);
}

function showConfetti(particleCount) {
    particleCount = particleCount || 100;
    const colors = ['#10b981', '#3b82f6', '#8b5cf6', '#f59e0b'];
    const container = document.createElement('div');
    container.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:10001';

    for (let i = 0; i < particleCount; i++) {
        setTimeout(() => {
            const particle = document.createElement('div');
            const size = Math.random() * 10 + 5;
            const color = colors[Math.floor(Math.random() * colors.length)];
            const startX = Math.random() * window.innerWidth;
            const endX = startX + (Math.random() - 0.5) * 400;
            const duration = Math.random() * 2000 + 2000;

            particle.style.cssText = 'position:absolute;top:-20px;left:' + startX + 'px;width:' + size + 'px;height:' + size + 'px;background:' + color + ';border-radius:' + (Math.random() > 0.5 ? '50%' : '2px') + ';animation:confettiFall ' + duration + 'ms ease-out forwards';
            container.appendChild(particle);

            setTimeout(() => particle.remove(), duration);
        }, i * 20);
    }

    document.body.appendChild(container);
    setTimeout(() => container.remove(), 5000);
}

function animateNumber(element, start, end, duration) {
    if (!element) return;
    duration = duration || 1000;
    const diff = end - start;
    const startTime = performance.now();

    function animate(currentTime) {
        const progress = Math.min((currentTime - startTime) / duration, 1);
        const easeOut = 1 - Math.pow(1 - progress, 3);
        const current = Math.floor(start + diff * easeOut);
        element.textContent = current.toLocaleString();
        if (progress < 1) requestAnimationFrame(animate);
    }

    requestAnimationFrame(animate);
}

// Initialize visual enhancements
function initVisualEnhancements() {
    // Animate stat numbers
    document.querySelectorAll('.summary-card-value').forEach(el => {
        const value = parseInt(el.textContent, 10);
        if (!isNaN(value) && value > 0) {
            animateNumber(el, 0, value, 1500);
        }
    });

    console.log('[USCIS Tracker] Visual enhancements initialized');
}

// Auto-initialize
if (typeof apex !== 'undefined' && apex.jQuery) {
    apex.jQuery(document).on('apexreadyend', initVisualEnhancements);
}
]';

    -- Upload JS file (using BLOB to handle content > 32K)
    l_blob := clob_to_blob(l_js_content);
    wwv_flow_imp.create_app_static_file(
        p_id           => wwv_flow_id.next_val,
        p_flow_id      => l_app_id,
        p_file_name    => 'js/app-scripts.js',
        p_mime_type    => 'application/javascript',
        p_file_charset => 'utf-8',
        p_file_content => l_blob
    );
    DBMS_LOB.FREETEMPORARY(l_blob);

    DBMS_OUTPUT.PUT_LINE('JavaScript file uploaded successfully.');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('🎉 Enhanced static files uploaded successfully!');
    DBMS_OUTPUT.PUT_LINE('Clear your browser cache and refresh the APEX application.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('New stunning features:');
    DBMS_OUTPUT.PUT_LINE('  ✨ Modern glassmorphism design');
    DBMS_OUTPUT.PUT_LINE('  🌈 Beautiful gradient backgrounds');
    DBMS_OUTPUT.PUT_LINE('  🎭 Animated status badges');
    DBMS_OUTPUT.PUT_LINE('  🎊 Enhanced visual effects');
    DBMS_OUTPUT.PUT_LINE('  🚀 Improved user experience');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

SET DEFINE ON