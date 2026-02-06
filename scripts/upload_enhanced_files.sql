-- ============================================================
-- Upload Enhanced Static Files to APEX Application
-- ============================================================
-- Run this script in your APEX application's schema (USCIS_APP)
-- after connecting to the database.
--
-- This will upload the enhanced CSS and JS files for the modern UI.
-- ============================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Uploading enhanced static files to APEX Application 102...

DECLARE
    l_app_id NUMBER := 102;
    l_workspace_id NUMBER;
    l_file_content CLOB;
    l_file_name VARCHAR2(4000);
BEGIN
    -- Get workspace ID
    SELECT workspace_id INTO l_workspace_id
    FROM apex_applications
    WHERE application_id = l_app_id;

    -- Set APEX security context
    apex_util.set_security_group_id(l_workspace_id);

    DBMS_OUTPUT.PUT_LINE('Uploading enhanced static files...');

    -- Upload CSS file
    l_file_name := 'css/app-styles.css';

    -- Delete existing file if present (query ID first, then remove by ID)
    DECLARE
        l_file_id NUMBER;
    BEGIN
        SELECT application_file_id INTO l_file_id
        FROM apex_application_static_files
        WHERE application_id = l_app_id
        AND file_name = l_file_name;
        
        wwv_flow_imp.remove_app_static_file(
            p_id      => l_file_id,
            p_flow_id => l_app_id
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- File doesn't exist, that's OK
    END;

    -- Read CSS file content
    BEGIN
        l_file_content := q'[
/**
 * USCIS Case Tracker - Application Styles
 * Version: 2.0.0 - ENHANCED EDITION
 * Date: February 4, 2026
 *
 * Upload to: Shared Components → Static Application Files
 * Reference as: #APP_FILES#css/app-styles.css
 * Features: Gradients, Glassmorphism, Animations, Modern UI
 */

/* =============================================
   CSS VARIABLES (Enhanced Color Palette)
   ============================================= */

:root {
  /* Primary Colors - Modern Gradient Palette */
  --uscis-primary: #0f172a;
  --uscis-primary-light: #1e293b;
  --uscis-secondary: #3b82f6;
  --uscis-secondary-dark: #2563eb;
  --uscis-accent: #06b6d4;
  --uscis-accent-glow: rgba(6, 182, 212, 0.4);

  /* Neutral Colors */
  --neutral-100: #f8fafc;
  --neutral-300: #cbd5e1;
  --neutral-600: #475569;
  --neutral-900: #0f172a;

  /* Status Glow Colors */
  --status-approved-glow: rgba(16, 185, 129, 0.3);
  --status-denied-glow: rgba(239, 68, 68, 0.3);
  --status-pending-glow: rgba(245, 158, 11, 0.3);
  --status-rfe-glow: rgba(59, 130, 246, 0.3);
  --status-received-glow: rgba(139, 92, 246, 0.3);
  --status-transferred-glow: rgba(6, 182, 212, 0.3);
  --status-unknown-glow: rgba(100, 116, 139, 0.3);

  /* Gradient Definitions */
  --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --gradient-secondary: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  --gradient-success: linear-gradient(135deg, #10b981 0%, #34d399 100%);
  --gradient-danger: linear-gradient(135deg, #ef4444 0%, #f97316 100%);
  --gradient-warning: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%);
  --gradient-purple: linear-gradient(135deg, #8b5cf6 0%, #a855f7 100%);
  --gradient-dark: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  --gradient-hero: linear-gradient(135deg, #1e3a5f 0%, #0f172a 50%, #0c1929 100%);
  --gradient-glass: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%);

  /* Glassmorphism */
  --glass-bg: rgba(255, 255, 255, 0.08);
  --glass-border: rgba(255, 255, 255, 0.15);
  --glass-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);

  /* Enhanced Shadows */
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1), 0 2px 4px rgba(0, 0, 0, 0.08);
  --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.15), 0 4px 10px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 40px rgba(0, 0, 0, 0.2), 0 8px 16px rgba(0, 0, 0, 0.12);
  --shadow-glow-blue: 0 0 30px rgba(59, 130, 246, 0.3), 0 0 60px rgba(59, 130, 246, 0.1);
  --shadow-glow-cyan: 0 0 30px rgba(6, 182, 212, 0.3), 0 0 60px rgba(6, 182, 212, 0.1);
  --shadow-float: 0 20px 50px rgba(0, 0, 0, 0.25);

  /* Border Radius */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 16px;
  --radius-xl: 24px;
  --radius-full: 9999px;

  /* Transitions */
  --transition-fast: 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-normal: 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-slow: 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-bounce: 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}

/* =============================================
   GLOBAL ENHANCEMENTS & BODY
   ============================================= */

body {
  background: var(--gradient-hero) !important;
  background-attachment: fixed !important;
  min-height: 100vh;
}

/* Animated background mesh */
body::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image:
    radial-gradient(ellipse at 20% 30%, rgba(59, 130, 246, 0.15) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 70%, rgba(6, 182, 212, 0.1) 0%, transparent 50%),
    radial-gradient(ellipse at 50% 50%, rgba(139, 92, 246, 0.08) 0%, transparent 60%);
  pointer-events: none;
  z-index: -1;
}

/* Main content area styling */
.t-Body-content,
.t-Body-contentInner {
  background: transparent !important;
}

.t-Body-main {
  background: rgba(248, 250, 252, 0.95) !important;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-left: 1px solid rgba(255, 255, 255, 0.1);
}

/* =============================================
   HEADER & BRANDING - STUNNING DESIGN
   ============================================= */

.t-Header {
  background: var(--gradient-dark) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3) !important;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.t-Header-logo {
  background: transparent !important;
  position: relative;
}

.t-Header-logo::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 60%;
  height: 2px;
  background: var(--gradient-secondary);
  border-radius: var(--radius-full);
  opacity: 0;
  transition: all var(--transition-normal);
}

.t-Header-logo:hover::after {
  opacity: 1;
  width: 80%;
}

.t-Header-logo-link {
  color: var(--neutral-100) !important;
  font-weight: 700;
  font-size: 1.25rem;
  letter-spacing: -0.02em;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
  transition: all var(--transition-fast);
}

.t-Header-logo-link:hover {
  color: var(--uscis-accent) !important;
  text-shadow: 0 0 20px var(--uscis-accent-glow);
}

/* Navigation - Modern Sidebar */
.t-TreeNav {
  background: var(--gradient-dark) !important;
  box-shadow: 4px 0 30px rgba(0, 0, 0, 0.2);
}

.t-TreeNav .a-TreeView-node--topLevel > .a-TreeView-content {
  color: var(--neutral-300) !important;
  transition: all var(--transition-normal);
  border-radius: var(--radius-md);
  margin: 4px 8px;
  position: relative;
  overflow: hidden;
}

.t-TreeNav .a-TreeView-node--topLevel > .a-TreeView-content::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--gradient-secondary);
  transform: scaleY(0);
  transition: transform var(--transition-normal);
}

.t-TreeNav .a-TreeView-node--topLevel.is-selected > .a-TreeView-content,
.t-TreeNav .a-TreeView-node--topLevel > .a-TreeView-content:hover {
  background: linear-gradient(90deg, rgba(59, 130, 246, 0.2) 0%, transparent 100%) !important;
  color: var(--neutral-100) !important;
}

.t-TreeNav .a-TreeView-node--topLevel.is-selected > .a-TreeView-content::before,
.t-TreeNav .a-TreeView-node--topLevel > .a-TreeView-content:hover::before {
  transform: scaleY(1);
}

/* Navigation icons glow */
.t-TreeNav .fa,
.t-TreeNav [class*="fa-"] {
  transition: all var(--transition-fast);
}

.t-TreeNav .a-TreeView-content:hover .fa,
.t-TreeNav .a-TreeView-content:hover [class*="fa-"] {
  color: var(--uscis-accent) !important;
  filter: drop-shadow(0 0 8px var(--uscis-accent-glow));
}

/* =============================================
   STATUS BADGES - GLOWING & ANIMATED
   ============================================= */

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: var(--radius-full);
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  white-space: nowrap;
  position: relative;
  overflow: hidden;
  transition: all var(--transition-normal);
  animation: badgeFadeIn 0.4s ease-out;
}

.status-badge::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
  transition: left 0.5s ease;
}

.status-badge:hover::before {
  left: 100%;
}

.status-badge:hover {
  transform: scale(1.05);
}

@keyframes badgeFadeIn {
  from {
    opacity: 0;
    transform: scale(0.8);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.status-approved {
  background: var(--gradient-success);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-approved-glow);
}

.status-denied {
  background: var(--gradient-danger);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-denied-glow);
}

.status-pending {
  background: var(--gradient-warning);
  color: var(--neutral-900);
  box-shadow: 0 4px 15px var(--status-pending-glow);
}

.status-rfe {
  background: var(--gradient-secondary);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-rfe-glow);
}

.status-received {
  background: var(--gradient-purple);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-received-glow);
}

.status-transferred {
  background: linear-gradient(135deg, #06b6d4 0%, #0ea5e9 100%);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-transferred-glow);
}

.status-unknown {
  background: linear-gradient(135deg, #64748b 0%, #94a3b8 100%);
  color: var(--neutral-100);
  box-shadow: 0 4px 15px var(--status-unknown-glow);
}

/* Status dot indicator with pulse animation */
.status-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 8px;
  position: relative;
}

.status-dot::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  transform: translate(-50%, -50%);
  animation: dotPulse 2s ease-in-out infinite;
}

@keyframes dotPulse {
  0%, 100% {
    box-shadow: 0 0 0 0 currentColor;
    opacity: 0.7;
  }
  50% {
    box-shadow: 0 0 0 8px currentColor;
    opacity: 0;
  }
}

.status-dot.approved { background: #10b981; color: rgba(16, 185, 129, 0.5); }
.status-dot.denied { background: #ef4444; color: rgba(239, 68, 68, 0.5); }
.status-dot.pending { background: #f59e0b; color: rgba(245, 158, 11, 0.5); }
.status-dot.rfe { background: #3b82f6; color: rgba(59, 130, 246, 0.5); }
.status-dot.received { background: #8b5cf6; color: rgba(139, 92, 246, 0.5); }
.status-dot.transferred { background: #06b6d4; color: rgba(6, 182, 212, 0.5); }
.status-dot.unknown { background: #64748b; color: rgba(100, 116, 139, 0.5); }

/* =============================================
   CARDS & CONTAINERS - GLASSMORPHISM STYLE
   ============================================= */

.t-Card {
  background: rgba(255, 255, 255, 0.95) !important;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: var(--radius-lg) !important;
  transition: all var(--transition-normal);
  overflow: hidden;
}

.t-Card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: var(--gradient-secondary);
  opacity: 0;
  transition: opacity var(--transition-normal);
}

.t-Card:hover {
  box-shadow: var(--shadow-xl);
  transform: translateY(-6px);
  border-color: rgba(59, 130, 246, 0.3) !important;
}

.t-Card:hover::before {
  opacity: 1;
}

/* Summary Cards (Dashboard) - Redesigned */
.summary-card {
  text-align: center;
  padding: 28px 20px;
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: var(--radius-xl);
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: var(--shadow-lg);
  position: relative;
  overflow: hidden;
  transition: all var(--transition-normal);
}

.summary-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 5px;
  background: var(--gradient-secondary);
}

.summary-card::after {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle, rgba(59, 130, 246, 0.08) 0%, transparent 60%);
  pointer-events: none;
}

.summary-card:hover {
  transform: translateY(-8px) scale(1.02);
  box-shadow: var(--shadow-xl), var(--shadow-glow-blue);
}

.summary-card-icon {
  font-size: 40px;
  background: var(--gradient-secondary);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 14px;
  filter: drop-shadow(0 4px 8px rgba(59, 130, 246, 0.3));
}

.summary-card-value {
  font-size: 48px;
  font-weight: 800;
  background: var(--gradient-primary);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1.1;
  margin-bottom: 8px;
}

.summary-card-label {
  font-size: 12px;
  color: var(--neutral-600);
  text-transform: uppercase;
  letter-spacing: 1.5px;
  font-weight: 600;
}

.summary-card-change {
  font-size: 13px;
  margin-top: 12px;
  padding: 4px 10px;
  border-radius: var(--radius-full);
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.summary-card-change.positive {
  color: #10b981;
  background: rgba(16, 185, 129, 0.1);
  border: 1px solid rgba(16, 185, 129, 0.2);
}

.summary-card-change.negative {
  color: #ef4444;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
}

/* =============================================
   TIMELINE (Status History) - STUNNING REDESIGN
   ============================================= */

.timeline-container {
  position: relative;
  padding-left: 40px;
  margin: 24px 0;
}

.timeline-container::before {
  content: '';
  position: absolute;
  left: 14px;
  top: 0;
  bottom: 0;
  width: 3px;
  background: linear-gradient(
    to bottom,
    var(--uscis-secondary),
    var(--uscis-accent),
    var(--neutral-300)
  );
  border-radius: var(--radius-full);
}

.timeline-item {
  position: relative;
  margin-bottom: 24px;
  padding: 18px 22px;
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border-radius: var(--radius-lg);
  border: 1px solid rgba(59, 130, 246, 0.15);
  box-shadow: var(--shadow-md);
  transition: all var(--transition-normal);
  animation: timelineSlideIn 0.5s ease-out backwards;
}

.timeline-item:nth-child(1) { animation-delay: 0s; }
.timeline-item:nth-child(2) { animation-delay: 0.1s; }
.timeline-item:nth-child(3) { animation-delay: 0.2s; }
.timeline-item:nth-child(4) { animation-delay: 0.3s; }
.timeline-item:nth-child(5) { animation-delay: 0.4s; }

@keyframes timelineSlideIn {
  from {
    opacity: 0;
    transform: translateX(-20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.timeline-item:hover {
  background: rgba(248, 250, 252, 1);
  box-shadow: var(--shadow-lg);
  transform: translateX(8px);
  border-color: rgba(59, 130, 246, 0.3);
}

.timeline-item::before {
  content: '';
  position: absolute;
  left: -30px;
  top: 22px;
  width: 16px;
  height: 16px;
  background: var(--gradient-secondary);
  border-radius: 50%;
  border: 3px solid var(--neutral-100);
  box-shadow: var(--shadow-md), 0 0 0 4px rgba(59, 130, 246, 0.2);
  z-index: 1;
  transition: all var(--transition-fast);
}

.timeline-item:hover::before {
  transform: scale(1.2);
  box-shadow: var(--shadow-lg), 0 0 0 6px rgba(59, 130, 246, 0.3);
}

.timeline-item:first-child::before {
  background: var(--gradient-primary);
  width: 20px;
  height: 20px;
  left: -32px;
  top: 20px;
  animation: pulseRing 2s ease-out infinite;
}

@keyframes pulseRing {
  0% {
    box-shadow: var(--shadow-md), 0 0 0 0 rgba(102, 126, 234, 0.5);
  }
  70% {
    box-shadow: var(--shadow-md), 0 0 0 12px rgba(102, 126, 234, 0);
  }
  100% {
    box-shadow: var(--shadow-md), 0 0 0 0 rgba(102, 126, 234, 0);
  }
}

.timeline-date {
  font-size: 12px;
  color: var(--uscis-secondary);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
}

.timeline-status {
  font-weight: 700;
  color: var(--neutral-900);
  font-size: 16px;
  margin-bottom: 6px;
}

.timeline-details {
  font-size: 14px;
  color: var(--neutral-600);
  margin-top: 8px;
  line-height: 1.6;
  padding-left: 12px;
  border-left: 3px solid rgba(59, 130, 246, 0.2);
}

/* =============================================
   BUTTONS - STUNNING MODERN DESIGN
   ============================================= */

.btn-primary,
.t-Button--hot {
  background: var(--gradient-secondary) !important;
  border: none !important;
  color: var(--neutral-100) !important;
  font-weight: 600 !important;
  padding: 12px 24px !important;
  border-radius: var(--radius-md) !important;
  box-shadow: 0 4px 15px rgba(59, 130, 246, 0.35) !important;
  transition: all var(--transition-normal) !important;
  position: relative;
  overflow: hidden;
}

.btn-primary::before,
.t-Button--hot::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: left 0.5s ease;
}

.btn-primary:hover,
.t-Button--hot:hover {
  background: var(--gradient-primary) !important;
  transform: translateY(-3px) !important;
  box-shadow: 0 8px 25px rgba(59, 130, 246, 0.45) !important;
}

.btn-primary:hover::before,
.t-Button--hot:hover::before {
  left: 100%;
}

.btn-primary:active,
.t-Button--hot:active {
  transform: translateY(-1px) !important;
}

/* Standard buttons */
.t-Button {
  border-radius: var(--radius-md) !important;
  font-weight: 600 !important;
  transition: all var(--transition-fast) !important;
  position: relative;
  overflow: hidden;
}

.t-Button:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

/* Danger button - Red gradient */
.btn-danger,
.t-Button--danger {
  background: var(--gradient-danger) !important;
  border: none !important;
  color: var(--neutral-100) !important;
  box-shadow: 0 4px 15px rgba(239, 68, 68, 0.35) !important;
}

.btn-danger:hover,
.t-Button--danger:hover {
  box-shadow: 0 8px 25px rgba(239, 68, 68, 0.45) !important;
  transform: translateY(-3px) !important;
}

/* Success button */
.t-Button--success {
  background: var(--gradient-success) !important;
  border: none !important;
  color: var(--neutral-100) !important;
  box-shadow: 0 4px 15px rgba(16, 185, 129, 0.35) !important;
}

.t-Button--success:hover {
  box-shadow: 0 8px 25px rgba(16, 185, 129, 0.45) !important;
  transform: translateY(-3px) !important;
}

/* Quick action buttons - Enhanced */
.quick-action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 24px;
  border-radius: var(--radius-lg);
  font-weight: 600;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid var(--neutral-300);
  box-shadow: var(--shadow-md);
  transition: all var(--transition-normal);
  cursor: pointer;
}

.quick-action-btn:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-xl);
  border-color: var(--uscis-secondary);
  color: var(--uscis-secondary);
}

.quick-action-btn:active {
  transform: translateY(-2px);
}

/* Icon buttons */
.t-Button--icon {
  border-radius: var(--radius-full) !important;
  width: 42px !important;
  height: 42px !important;
  padding: 0 !important;
  display: inline-flex !important;
  align-items: center;
  justify-content: center;
}

.t-Button--icon:hover {
  background: var(--gradient-secondary) !important;
  color: var(--neutral-100) !important;
  box-shadow: var(--shadow-glow-blue);
  transform: scale(1.1);
}

/* =============================================
   LOADING OVERLAY - MODERN SPINNER
   ============================================= */

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(15, 23, 42, 0.85);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.loading-spinner {
  width: 60px;
  height: 60px;
  border: 4px solid rgba(255, 255, 255, 0.1);
  border-top-color: var(--uscis-accent);
  border-right-color: var(--uscis-secondary);
  border-radius: 50%;
  animation: spinGradient 1s linear infinite;
  box-shadow: 0 0 30px rgba(6, 182, 212, 0.3);
}

.loading-text {
  margin-top: 24px;
  color: var(--neutral-100);
  font-size: 15px;
  font-weight: 500;
  letter-spacing: 0.5px;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

@keyframes spinGradient {
  to { transform: rotate(360deg); }
}

/* =============================================
   ALERTS & NOTIFICATIONS - GLASSMORPHIC
   ============================================= */

.alert-info,
.alert-success,
.alert-warning,
.alert-error {
  padding: 16px 20px;
  border-radius: var(--radius-lg);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  display: flex;
  align-items: flex-start;
  gap: 14px;
  animation: alertSlideIn 0.4s ease-out;
  position: relative;
  overflow: hidden;
}

@keyframes alertSlideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.alert-info::before,
.alert-success::before,
.alert-warning::before,
.alert-error::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
}

.alert-info {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.12) 0%, rgba(6, 182, 212, 0.08) 100%);
  border: 1px solid rgba(59, 130, 246, 0.25);
  box-shadow: 0 4px 20px rgba(59, 130, 246, 0.15);
}

.alert-info::before {
  background: var(--gradient-secondary);
}

.alert-success {
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.12) 0%, rgba(52, 211, 153, 0.08) 100%);
  border: 1px solid rgba(16, 185, 129, 0.25);
  box-shadow: 0 4px 20px rgba(16, 185, 129, 0.15);
}

.alert-success::before {
  background: var(--gradient-success);
}

.alert-warning {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.15) 0%, rgba(251, 191, 36, 0.1) 100%);
  border: 1px solid rgba(245, 158, 11, 0.3);
  box-shadow: 0 4px 20px rgba(245, 158, 11, 0.15);
}

.alert-warning::before {
  background: var(--gradient-warning);
}

.alert-error {
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.12) 0%, rgba(249, 115, 22, 0.08) 100%);
  border: 1px solid rgba(239, 68, 68, 0.25);
  box-shadow: 0 4px 20px rgba(239, 68, 68, 0.15);
}

.alert-error::before {
  background: var(--gradient-danger);
}

/* =============================================
   RESPONSIVE UTILITIES
   ============================================= */

@media (max-width: 640px) {
  .hide-mobile {
    display: none !important;
  }

  .summary-card-value {
    font-size: 36px;
  }

  .timeline-container {
    padding-left: 30px;
  }

  .timeline-item::before {
    left: -22px;
    width: 12px;
    height: 12px;
  }
}

@media (min-width: 641px) {
  .hide-desktop {
    display: none !important;
  }
}

@media (max-width: 640px) {
  .stack-mobile {
    flex-direction: column !important;
  }

  .stack-mobile > * {
    width: 100% !important;
    margin-bottom: 12px;
  }
}

/* =============================================
   ACCESSIBILITY
   ============================================= */

*:focus-visible {
  outline: 3px solid var(--uscis-accent);
  outline-offset: 3px;
  box-shadow: 0 0 0 6px rgba(6, 182, 212, 0.2);
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }

  .t-Card:hover,
  .summary-card:hover,
  .stat-card:hover,
  .widget:hover,
  .quick-action-btn:hover,
  .timeline-item:hover {
    transform: none !important;
  }
}

@media (prefers-contrast: high) {
  .status-badge {
    border: 2px solid currentColor;
  }

  .t-Card,
  .t-Region,
  .widget {
    border: 2px solid var(--neutral-900) !important;
  }

  .t-Button {
    border: 2px solid currentColor !important;
  }
}
]';

    -- Upload CSS file
    wwv_flow_imp.create_app_static_file(
        p_id           => wwv_flow_id.next_val,
        p_flow_id      => l_app_id,
        p_file_name    => l_file_name,
        p_mime_type    => 'text/css',
        p_file_charset => 'utf-8',
        p_file_content => utl_raw.cast_to_raw(l_file_content)
    );

    DBMS_OUTPUT.PUT_LINE('Successfully uploaded: ' || l_file_name);

    -- Upload JS file
    l_file_name := 'js/app-scripts.js';

    -- Delete existing file if present (query ID first, then remove by ID)
    DECLARE
        l_file_id NUMBER;
    BEGIN
        SELECT application_file_id INTO l_file_id
        FROM apex_application_static_files
        WHERE application_id = l_app_id
        AND file_name = l_file_name;
        
        wwv_flow_imp.remove_app_static_file(
            p_id      => l_file_id,
            p_flow_id => l_app_id
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL; -- File doesn't exist, that's OK
    END;

    -- Read JS file content
    l_file_content := q'[
/**
 * USCIS Case Tracker - Application JavaScript Utilities
 * Version: 2.0.0 - ENHANCED EDITION
 * Date: February 4, 2026
 *
 * Upload to: Shared Components → Static Application Files
 * Reference as: #APP_FILES#js/app-scripts.js
 * Features: Visual Effects, Animations, Modern UX
 */

/* =============================================
   RECEIPT NUMBER UTILITIES
   ============================================= */

/**
 * Format receipt number with visual grouping
 * Example: IOE1234567890 → IOE-123-4567890
 *
 * @param {string} receiptNum - Raw receipt number
 * @returns {string} Formatted receipt number
 */
function formatReceiptNumber(receiptNum) {
    if (!receiptNum) return '';

    // Normalize first
    const normalized = normalizeReceiptNumber(receiptNum);

    if (normalized.length !== 13) return receiptNum;

    return normalized.substring(0, 3) + '-' +
           normalized.substring(3, 6) + '-' +
           normalized.substring(6);
}

/**
 * Normalize receipt number (remove formatting, uppercase)
 *
 * @param {string} receiptNum - Receipt number with possible formatting
 * @returns {string} Normalized receipt number (uppercase, no dashes/spaces)
 */
function normalizeReceiptNumber(receiptNum) {
    if (!receiptNum) return '';
    return receiptNum.replace(/[-\s]/g, '').toUpperCase().trim();
}

/**
 * Validate receipt number format
 * Must be 3 letters + 10 digits (e.g., IOE1234567890)
 *
 * @param {string} receiptNum - Receipt number to validate
 * @returns {boolean} True if valid format
 */
function isValidReceiptNumber(receiptNum) {
    if (!receiptNum) return false;

    const normalized = normalizeReceiptNumber(receiptNum);

    // Must be exactly 13 characters: 3 letters + 10 digits
    if (normalized.length !== 13) return false;

    // Regex: 3 uppercase letters followed by 10 digits
    return /^[A-Z]{3}\d{10}$/.test(normalized);
}

/**
 * Mask receipt number for privacy
 * Example: IOE1234567890 → IOE-XXX-XXXX890
 *
 * @param {string} receiptNum - Receipt number to mask
 * @returns {string} Masked receipt number
 */
function maskReceiptNumber(receiptNum) {
    if (!receiptNum) return '';

    const normalized = normalizeReceiptNumber(receiptNum);

    if (normalized.length !== 13) return receiptNum;

    return normalized.substring(0, 3) + '-XXX-XXXX' + normalized.substring(10);
}

/**
 * Get the service center name from receipt prefix
 *
 * @param {string} receiptNum - Receipt number
 * @returns {string} Service center name
 */
function getServiceCenter(receiptNum) {
    if (!receiptNum) return 'Unknown';

    const prefix = normalizeReceiptNumber(receiptNum).substring(0, 3);

    const centers = {
        'EAC': 'Vermont Service Center',
        'WAC': 'California Service Center',
        'LIN': 'Nebraska Service Center',
        'SRC': 'Texas Service Center',
        'NBC': 'National Benefits Center',
        'MSC': 'Missouri Service Center',
        'IOE': 'USCIS Electronic Immigration System',
        'YSC': 'Potomac Service Center'
    };

    return centers[prefix] || 'Unknown Service Center';
}

/* =============================================
   STATUS UTILITIES
   ============================================= */

/**
 * Get CSS class for status badge based on status text
 *
 * @param {string} status - Status text from USCIS
 * @returns {string} CSS class name
 */
function getStatusClass(status) {
    if (!status) return 'status-unknown';

    const s = status.toLowerCase();

    // Check negative/denial keywords FIRST to avoid false positives
    // (e.g., "Case Was Not Approved" should not match 'approved')
    if (/\bnot approved\b/.test(s) ||
        /\bnot accepted\b/.test(s) ||
        /\bdenied\b/.test(s) ||
        /\brejected\b/.test(s) ||
        /\bterminated\b/.test(s) ||
        /\bwithdrawn\b/.test(s) ||
        /\brevoked\b/.test(s)) {
        return 'status-denied';
    }

    // Approved / Positive outcomes (checked after negatives)
    if (/\bapproved\b/.test(s) ||
        /\bcard was produced\b/.test(s) ||
        /\bcard is being produced\b/.test(s) ||
        /\bnew card\b/.test(s) ||
        /\bcard was delivered\b/.test(s) ||
        /\bcard was picked up\b/.test(s) ||
        /\bcard was mailed\b/.test(s) ||
        /\boath ceremony\b/.test(s) ||
        /\bwelcome notice\b/.test(s)) {
        return 'status-approved';
    }

    // RFE (Request for Evidence)
    if (/\brfe\b/.test(s) ||
        /\brequest for evidence\b/.test(s) ||
        /\brequest for initial evidence\b/.test(s) ||
        /\brequest for additional evidence\b/.test(s)) {
        return 'status-rfe';
    }

    // Received / Initial stage
    if (/\breceived\b/.test(s) ||
        /\baccepted\b/.test(s) ||
        /\bfee was received\b/.test(s)) {
        return 'status-received';
    }

    // Transferred
    if (/\btransferred\b/.test(s) ||
        /\brelocated\b/.test(s) ||
        /\bsent to\b/.test(s)) {
        return 'status-transferred';
    }

    // Pending / Processing (default active state)
    if (/\bpending\b/.test(s) ||
        /\bprocessing\b/.test(s) ||
        /\breview\b/.test(s) ||
        /\bbeing processed\b/.test(s) ||
        /\bfingerprint\b/.test(s) ||
        /\binterview\b/.test(s) ||
        /\bscheduled\b/.test(s)) {
        return 'status-pending';
    }

    return 'status-unknown';
}

/**
 * Get human-friendly status category
 *
 * @param {string} status - Status text
 * @returns {string} Category name
 */
function getStatusCategory(status) {
    const statusClass = getStatusClass(status);

    const categories = {
        'status-approved': 'Approved',
        'status-denied': 'Denied',
        'status-pending': 'Pending',
        'status-rfe': 'Action Required',
        'status-received': 'Received',
        'status-transferred': 'Transferred',
        'status-unknown': 'Unknown'
    };

    return categories[statusClass] || 'Unknown';
}

/**
 * Apply status styling to an element
 *
 * @param {HTMLElement} element - DOM element to style
 * @param {string} status - Status text
 */
function applyStatusStyle(element, status) {
    if (!element) return;

    const className = getStatusClass(status);

    // Remove all status classes
    element.classList.remove(
        'status-approved', 'status-denied', 'status-pending',
        'status-rfe', 'status-received', 'status-transferred', 'status-unknown'
    );

    // Add badge class and new status class
    element.classList.add('status-badge', className);
}

/* =============================================
   VISUAL EFFECTS & ANIMATIONS
   ============================================= */

/**
 * Show a beautiful toast notification
 *
 * @param {string} message - Toast message
 * @param {string} type - 'success', 'error', 'warning', 'info'
 * @param {number} duration - Duration in ms (default 4000)
 */
function showToast(message, type, duration) {
    type = type || 'info';
    duration = duration || 4000;

    // Remove existing toasts
    document.querySelectorAll('.custom-toast').forEach(function(t) { t.remove(); });

    var toast = document.createElement('div');
    toast.className = 'custom-toast custom-toast-' + type;

    // Icon based on type
    var icons = {
        success: '\u2713',
        error: '\u2715',
        warning: '\u26A0',
        info: '\u2139'
    };

    // Build toast content using DOM methods to prevent XSS
    var iconDiv = document.createElement('div');
    iconDiv.className = 'custom-toast-icon';
    iconDiv.textContent = icons[type] || icons.info;

    var contentDiv = document.createElement('div');
    contentDiv.className = 'custom-toast-content';

    var messageDiv = document.createElement('div');
    messageDiv.className = 'custom-toast-message';
    messageDiv.textContent = message; // Safe: uses textContent, not innerHTML

    contentDiv.appendChild(messageDiv);

    var closeBtn = document.createElement('button');
    closeBtn.className = 'custom-toast-close';
    closeBtn.textContent = '\u2715';
    closeBtn.addEventListener('click', function() { toast.remove(); });

    toast.appendChild(iconDiv);
    toast.appendChild(contentDiv);
    toast.appendChild(closeBtn);

    // Add styles dynamically
    var style = document.createElement('style');
    style.textContent = '.custom-toast{position:fixed;bottom:24px;right:24px;min-width:320px;max-width:450px;padding:16px 20px;border-radius:16px;display:flex;align-items:center;gap:14px;z-index:10000;animation:toastIn .4s cubic-bezier(.68,-.55,.265,1.55);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);box-shadow:0 20px 50px rgba(0,0,0,.25),0 0 40px rgba(59,130,246,.2)}' +
    '.custom-toast-success{background:linear-gradient(135deg,rgba(16,185,129,.95),rgba(52,211,153,.9));color:#fff}' +
    '.custom-toast-error{background:linear-gradient(135deg,rgba(239,68,68,.95),rgba(249,115,22,.9));color:#fff}' +
    '.custom-toast-warning{background:linear-gradient(135deg,rgba(245,158,11,.95),rgba(251,191,36,.9));color:#1a1a1a}' +
    '.custom-toast-info{background:linear-gradient(135deg,rgba(59,130,246,.95),rgba(6,182,212,.9));color:#fff}' +
    '.custom-toast-icon{width:36px;height:36px;border-radius:50%;background:rgba(255,255,255,.25);display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:700}' +
    '.custom-toast-message{font-weight:600;font-size:14px;line-height:1.4}' +
    '.custom-toast-close{background:none;border:none;color:inherit;opacity:.7;cursor:pointer;padding:4px;font-size:14px;margin-left:auto}' +
    '.custom-toast-close:hover{opacity:1}' +
    '@keyframes toastIn{0%{opacity:0;transform:translateY(30px) scale(.9)}100%{opacity:1;transform:translateY(0) scale(1)}}' +
    '@keyframes toastOut{0%{opacity:1;transform:translateY(0)}100%{opacity:0;transform:translateY(-20px)}}';

    if (!document.querySelector('#custom-toast-styles')) {
        style.id = 'custom-toast-styles';
        document.head.appendChild(style);
    }

    document.body.appendChild(toast);

    // Auto remove
    setTimeout(function() {
        toast.style.animation = 'toastOut .3s ease forwards';
        setTimeout(function() { toast.remove(); }, 300);
    }, duration);
}

/**
 * Create confetti celebration effect for approved cases
 *
 * @param {number} particleCount - Number of particles (default 100)
 */
function showConfetti(particleCount) {
    particleCount = particleCount || 100;

    var colors = ['#10b981', '#3b82f6', '#8b5cf6', '#f59e0b', '#ec4899', '#06b6d4'];
    var container = document.createElement('div');
    container.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:10001;overflow:hidden';
    document.body.appendChild(container);

    for (var i = 0; i < particleCount; i++) {
        (function(index) {
            setTimeout(function() {
                var particle = document.createElement('div');
                var size = Math.random() * 10 + 5;
                var color = colors[Math.floor(Math.random() * colors.length)];
                var startX = Math.random() * window.innerWidth;
                var endX = startX + (Math.random() - 0.5) * 400;
                var rotation = Math.random() * 720 - 360;
                var duration = Math.random() * 2000 + 2000;

                particle.style.cssText =
                    'position:absolute;top:-20px;left:' + startX + 'px;' +
                    'width:' + size + 'px;height:' + size + 'px;' +
                    'background:' + color + ';' +
                    'border-radius:' + (Math.random() > 0.5 ? '50%' : '2px') + ';' +
                    'animation:confettiFall ' + duration + 'ms ease-out forwards;' +
                    'transform:rotate(0deg);';

                var keyframes =
                    '@keyframes confettiFall{' +
                    '0%{transform:translateY(0) translateX(0) rotate(0deg);opacity:1}' +
                    '100%{transform:translateY(' + (window.innerHeight + 50) + 'px) translateX(' + (endX - startX) + 'px) rotate(' + rotation + 'deg);opacity:0}' +
                    '}';

                var style = document.createElement('style');
                style.textContent = keyframes;
                document.head.appendChild(style);

                container.appendChild(particle);

                setTimeout(function() {
                    particle.remove();
                    style.remove();
                }, duration);
            }, index * 20);
        })(i);
    }

    setTimeout(function() { container.remove(); }, 5000);
}

/**
 * Animate a number counting up
 *
 * @param {HTMLElement} element - Element to animate
 * @param {number} start - Start value
 * @param {number} end - End value
 * @param {number} duration - Duration in ms
 */
function animateNumber(element, start, end, duration) {
    if (!element) return;

    start = start || 0;
    duration = duration || 1000;

    var startTime = null;
    var diff = end - start;

    function animate(currentTime) {
        if (!startTime) startTime = currentTime;
        var progress = Math.min((currentTime - startTime) / duration, 1);

        // Easing function (ease-out)
        var easeOut = 1 - Math.pow(1 - progress, 3);
        var current = Math.floor(start + diff * easeOut);

        element.textContent = current.toLocaleString();

        if (progress < 1) {
            requestAnimationFrame(animate);
        }
    }

    requestAnimationFrame(animate);
}

/**
 * Add ripple effect to buttons
 *
 * @param {Event} event - Click event
 */
function createRipple(event) {
    var button = event.currentTarget;
    var rect = button.getBoundingClientRect();
    var ripple = document.createElement('span');
    var size = Math.max(rect.width, rect.height);
    var x = event.clientX - rect.left - size / 2;
    var y = event.clientY - rect.top - size / 2;

    ripple.style.cssText =
        'position:absolute;border-radius:50%;background:rgba(255,255,255,.4);' +
        'width:' + size + 'px;height:' + size + 'px;' +
        'left:' + x + 'px;top:' + y + 'px;' +
        'transform:scale(0);animation:rippleEffect .6s ease-out;pointer-events:none';

    if (!document.querySelector('#ripple-styles')) {
        var style = document.createElement('style');
        style.id = 'ripple-styles';
        style.textContent = '@keyframes rippleEffect{to{transform:scale(2.5);opacity:0}}';
        document.head.appendChild(style);
    }

    button.style.position = 'relative';
    button.style.overflow = 'hidden';
    button.appendChild(ripple);

    setTimeout(function() { ripple.remove(); }, 600);
}

/**
 * Initialize ripple effect on all buttons
 */
function initRippleEffect() {
    document.querySelectorAll('.t-Button, .quick-action-btn, .btn-primary').forEach(function(btn) {
        btn.removeEventListener('click', createRipple);
        btn.addEventListener('click', createRipple);
    });
}

/**
 * Show status change with celebration if approved
 *
 * @param {string} oldStatus - Previous status
 * @param {string} newStatus - New status
 */
function celebrateStatusChange(oldStatus, newStatus) {
    var newClass = getStatusClass(newStatus);

    if (newClass === 'status-approved') {
        showConfetti(150);
        showToast('🎉 Congratulations! Your case has been APPROVED!', 'success', 6000);
    } else if (newClass === 'status-denied') {
        showToast('Case status updated: ' + newStatus, 'error', 5000);
    } else if (newClass === 'status-rfe') {
        showToast('⚠️ Action Required: ' + newStatus, 'warning', 5000);
    } else {
        showToast('Status updated: ' + newStatus, 'info', 4000);
    }
}

/**
 * Add hover tilt effect to cards (idempotent - checks for existing handlers)
 */
function initCardTiltEffect() {
    document.querySelectorAll('.t-Card, .summary-card, .stat-card').forEach(function(card) {
        // Skip if already initialized to prevent duplicate handlers
        if (card.dataset.tiltInitialized) return;
        card.dataset.tiltInitialized = 'true';

        card.addEventListener('mousemove', function(e) {
            var rect = card.getBoundingClientRect();
            var x = e.clientX - rect.left;
            var y = e.clientY - rect.top;
            var centerX = rect.width / 2;
            var centerY = rect.height / 2;
            var rotateX = (y - centerY) / 20;
            var rotateY = (centerX - x) / 20;

            card.style.transform =
                'perspective(1000px) rotateX(' + rotateX + 'deg) rotateY(' + rotateY + 'deg) translateY(-6px)';
        });

        card.addEventListener('mouseleave', function() {
            card.style.transform = '';
        });
    });
}

/**
 * Initialize all visual enhancements
 */
function initVisualEnhancements() {
    initRippleEffect();
    initCardTiltEffect();

    // Animate stat numbers on page load
    document.querySelectorAll('.summary-card-value, .stat-value').forEach(function(el) {
        var value = parseInt(el.textContent, 10);
        if (!isNaN(value) && value > 0) {
            animateNumber(el, 0, value, 1500);
        }
    });

    console.log('[USCIS Tracker] Visual enhancements initialized');
}

// Note: Initialization is handled by the IIFE at the end of this file
// to avoid duplicate event handler registration

/* =============================================
   CLIPBOARD UTILITIES
   ============================================= */

/**
 * Copy text to clipboard with feedback
 *
 * @param {string} text - Text to copy
 * @param {string} successMsg - Optional success message
 */
function copyToClipboard(text, successMsg) {
    if (!text) {
        apex.message.showErrors([{
            type: 'error',
            location: 'page',
            message: 'Nothing to copy'
        }]);
        return;
    }

    navigator.clipboard.writeText(text).then(function() {
        showToast(successMsg || 'Copied to clipboard!', 'success');
    }).catch(function(err) {
        // Fallback for older browsers
        try {
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed';
            textArea.style.left = '-9999px';
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            showToast(successMsg || 'Copied to clipboard!', 'success');
        } catch (fallbackErr) {
            apex.message.showErrors([{
                type: 'error',
                location: 'page',
                message: 'Failed to copy: ' + (err.message || fallbackErr.message)
            }]);
        }
    });
}

/**
 * Copy receipt number (formatted) to clipboard
 *
 * @param {string} receiptNum - Receipt number
 */
function copyReceiptNumber(receiptNum) {
    const normalized = normalizeReceiptNumber(receiptNum);
    copyToClipboard(normalized, 'Receipt number copied!');
}

/* =============================================
   DIALOG UTILITIES
   ============================================= */

/**
 * Show confirmation dialog
 *
 * @param {string} message - Confirmation message
 * @param {function} callback - Function to call if confirmed
 */
function confirmAction(message, callback) {
    apex.message.confirm(message, function(okPressed) {
        if (okPressed && typeof callback === 'function') {
            callback();
        }
    });
}

/**
 * Show delete confirmation dialog with specific styling
 *
 * @param {string} itemName - Name of item being deleted
 * @param {function} callback - Function to call if confirmed
 */
function confirmDelete(itemName, callback) {
    const message = 'Are you sure you want to delete' + 
        (itemName ? ' "' + itemName + '"' : ' this item') + 
        '?\n\nThis action cannot be undone.';
    
    apex.message.confirm(message, function(okPressed) {
        if (okPressed && typeof callback === 'function') {
            callback();
        }
    });
}

/**
 * Show a custom alert dialog
 * Uses apex.message.showDialog for title support
 *
 * @param {string} title - Dialog title
 * @param {string} message - Dialog message
 */
function showAlert(title, message) {
    // Use APEX dialog API that supports title
    apex.message.showDialog(message, {
        title: title || 'Alert',
        style: 'warning',
        callback: function() {
            // Optional callback after alert is closed
        }
    });
}

/* =============================================
   LOADING UTILITIES
   ============================================= */

// Module-level variable to store spinner reference
let spinnerRef = null;

/**
 * Show loading spinner
 * Stores the spinner reference for proper cleanup
 *
 * @param {string} message - Optional loading message
 */
function showLoading(message) {
    // Only create a new spinner if one isn't already active
    if (spinnerRef === null) {
        spinnerRef = apex.util.showSpinner();
    }

    if (message) {
        console.log('[USCIS Tracker] Loading:', message);
    }
}

/**
 * Hide loading spinner
 * Uses stored reference to properly hide the spinner
 */
function hideLoading() {
    if (spinnerRef !== null) {
        apex.util.hideSpinner(spinnerRef);
        spinnerRef = null;
    }
}

/**
 * Execute function with loading indicator
 *
 * @param {function} asyncFn - Async function to execute
 * @param {string} message - Loading message
 */
async function withLoading(asyncFn, message) {
    showLoading(message);
    try {
        return await asyncFn();
    } finally {
        hideLoading();
    }
}

/* =============================================
   REGION UTILITIES
   ============================================= */

/**
 * Refresh an APEX region by static ID
 *
 * @param {string} regionStaticId - Static ID of the region
 */
function refreshRegion(regionStaticId) {
    try {
        apex.region(regionStaticId).refresh();
    } catch (e) {
        console.warn('[USCIS Tracker] Could not refresh region:', regionStaticId, e);
    }
}

/* =============================================
   DEBUGGING (Development Only)
   ============================================= */

/**
 * Log debug info (only in development)
 *
 * @param {string} message - Debug message
 * @param {*} data - Optional data to log
 */
function debugLog(message, data) {
    // Check if in development mode using a global JS variable or APEX application item
    // G_APP_ENV can be set via APEX application item exported to JavaScript
    // or via a Static Application File / Custom Configuration
    var isDevelopment = (typeof window.G_APP_ENV !== 'undefined' && window.G_APP_ENV === 'DEVELOPMENT') ||
                        (typeof window.USCIS_DEBUG !== 'undefined' && window.USCIS_DEBUG === true);

    if (isDevelopment) {
        console.log('[USCIS Tracker Debug]', message, data !== undefined ? data : '');
    }
}

/**
 * Test receipt number functions (for console testing)
 */
function testReceiptFunctions() {
    const testCases = [
        'IOE1234567890',
        'ioe-123-4567890',
        'IOE 123 4567890',
        'INVALID',
        '',
        null
    ];

    console.group('[USCIS Tracker] Receipt Function Tests');
    testCases.forEach(function(tc) {
        console.log('Input:', tc);
        console.log('  Normalized:', normalizeReceiptNumber(tc));
        console.log('  Valid:', isValidReceiptNumber(tc));
        console.log('  Formatted:', formatReceiptNumber(tc));
        console.log('  Masked:', maskReceiptNumber(tc));
        console.log('  Service Center:', getServiceCenter(tc));
        console.log('---');
    });
    console.groupEnd();
}

// Initialize app when DOM is ready
(function() {
    'use strict';

    var initApp = function() {
        console.log('[USCIS Tracker] Application initialized');
        initVisualEnhancements();
    };

    // Initialize when APEX is ready
    if (typeof apex !== 'undefined' && apex.jQuery) {
        apex.jQuery(document).ready(initApp);
    } else {
        // Fallback for when APEX is not available
        document.addEventListener('DOMContentLoaded', initApp);
    }
})();
]';

    -- Upload JS file
    wwv_flow_imp.create_app_static_file(
        p_id           => wwv_flow_id.next_val,
        p_flow_id      => l_app_id,
        p_file_name    => l_file_name,
        p_mime_type    => 'application/javascript',
        p_file_charset => 'utf-8',
        p_file_content => utl_raw.cast_to_raw(l_file_content)
    );

    DBMS_OUTPUT.PUT_LINE('Successfully uploaded: ' || l_file_name);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Enhanced static files upload complete!');
    DBMS_OUTPUT.PUT_LINE('Clear your browser cache and refresh the application to see the stunning new design.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

SET DEFINE ON

PROMPT Enhanced static files uploaded successfully!