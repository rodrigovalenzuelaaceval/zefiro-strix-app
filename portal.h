#pragma once
// ============================================================================
// ZÉFIRO STRIX — portal.h  (V3.2.0)
// Portal web de configuración — Tetrapoda SpA
// ============================================================================

const char PORTAL_HTML[] PROGMEM = R"HTMLEOF(
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>Zéfiro Strix — Tetrapoda SpA</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --ink:       #1a1a18;
    --paper:     #f4f1ea;
    --sage:      #6b7c6e;
    --sage-lt:   #a8b8aa;
    --orange:    #e8670a;
    --orange-lt: #f5954a;
    --blue:      #2a7ab5;
    --green:     #5aaa3c;
    --mist:      #ede9e0;
    --border:    #cdc9be;
    --mono:      'Inter', sans-serif;
    --serif:     'Montserrat', sans-serif;
  }
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  html { font-size: 16px; }
  body {
    background: var(--paper);
    color: var(--ink);
    font-family: var(--mono);
    font-weight: 400;
    min-height: 100vh;
    padding-bottom: 80px;
  }

  /* ── Header ── */
  header {
    background: var(--ink);
    color: var(--paper);
    padding: 0;
    position: relative;
    overflow: hidden;
  }
  .header-inner {
    display: flex;
    align-items: stretch;
    gap: 0;
  }
  .header-logo-wrap {
    background: var(--paper);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 12px 14px;
    flex-shrink: 0;
  }
  .header-logo-wrap img {
    width: 72px;
    height: auto;
    display: block;
  }
  .header-text {
    padding: 16px 16px 14px;
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  .header-eyebrow {
    font-family: var(--mono);
    font-size: 8px;
    letter-spacing: 0.22em;
    color: var(--sage-lt);
    text-transform: uppercase;
    margin-bottom: 4px;
  }
  .header-title {
    font-size: 2rem;
    font-family: var(--serif);
    font-weight: 800;
    letter-spacing: -0.01em;
    line-height: 1;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .header-title em { font-style: italic; color: var(--orange-lt); }
  .owl-icon {
    width: 32px; height: 32px;
    color: var(--paper);
    opacity: 0.85;
    flex-shrink: 0;
  }
  .header-company {
    font-family: var(--mono);
    font-size: 9px;
    color: var(--sage-lt);
    margin-top: 6px;
    letter-spacing: 0.12em;
  }
  .header-stripe {
    height: 3px;
    background: linear-gradient(90deg, var(--blue) 50%, var(--green) 50%);
  }

  /* ── Timer (solo visible antes de conexión) ── */
  #timerWrap {
    background: rgba(255,255,255,0.06);
    padding: 7px 16px;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  #timerWrap.hidden { display: none; }
  .timer-bar {
    flex: 1;
    background: rgba(255,255,255,0.12);
    border-radius: 2px;
    height: 2px;
    overflow: hidden;
  }
  .timer-fill {
    height: 100%;
    background: var(--orange);
    width: 100%;
    transform-origin: left;
  }
  #timerLabel {
    font-family: var(--mono);
    font-size: 9px;
    color: var(--sage-lt);
    letter-spacing: 0.08em;
    white-space: nowrap;
  }

  /* ── Status bar ── */
  #statusBar {
    background: var(--sage);
    color: var(--paper);
    font-family: var(--mono);
    font-size: 11px;
    padding: 8px 20px;
    letter-spacing: 0.07em;
    display: none;
    align-items: center;
    gap: 8px;
  }
  #statusBar.visible { display: flex; }
  #statusBar.error   { background: #a03020; }
  #statusBar.ok      { background: #3a6b3e; }
  .sdot { width:6px;height:6px;border-radius:50%;background:currentColor;opacity:.7;flex-shrink:0; }

  /* ── Main ── */
  main { padding: 0 16px; max-width: 520px; margin: 0 auto; }

  /* ── Section ── */
  .section {
    margin-top: 26px;
    border-left: 2px solid var(--border);
    padding-left: 16px;
  }
  .section-header {
    display: flex;
    align-items: baseline;
    gap: 10px;
    margin-bottom: 14px;
  }
  .section-num { font-family:var(--mono);font-size:10px;color:var(--orange);letter-spacing:.1em; }
  .section-title { font-size:1.2rem;font-weight:400; }

  /* ── Field ── */
  .field { margin-bottom: 12px; }
  .field label {
    display:block;font-family:var(--mono);font-size:10px;
    letter-spacing:.14em;color:var(--sage);text-transform:uppercase;margin-bottom:4px;
  }
  .field input[type="text"],
  .field input[type="number"],
  .field input[type="time"],
  .field select {
    width:100%;background:var(--mist);border:1px solid var(--border);border-radius:3px;
    padding:9px 12px;font-family:var(--mono);font-size:13px;color:var(--ink);
    outline:none;transition:border-color .2s,box-shadow .2s;-webkit-appearance:none;
  }
  .field input:focus,.field select:focus {
    border-color:var(--blue);box-shadow:0 0 0 3px rgba(42,122,181,.13);
  }
  .hint { font-family:var(--mono);font-size:9px;color:var(--sage-lt);margin-top:4px;letter-spacing:.05em; }

  /* ── Dashboard de estado ── */
  .dashboard {
    margin: 0 16px;
    max-width: 520px;
    margin-left: auto;
    margin-right: auto;
    margin-top: 16px;
  }
  .dash-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
  }
  .dash-card {
    background: var(--mist);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 10px 12px;
  }
  .dash-card-label {
    font-family: var(--mono);
    font-size: 8px;
    letter-spacing: 0.18em;
    color: var(--sage-lt);
    text-transform: uppercase;
    margin-bottom: 4px;
  }
  .dash-card-value {
    font-family: var(--mono);
    font-size: 15px;
    color: var(--ink);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }
  .dash-card-value.loading {
    color: var(--sage-lt);
    font-size: 11px;
  }
  .dash-fw {
    grid-column: 1 / -1;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 12px;
    background: var(--ink);
    border-radius: 3px;
  }
  .dash-fw-label {
    font-family: var(--mono);
    font-size: 9px;
    color: var(--sage-lt);
    letter-spacing: 0.15em;
  }
  .dash-fw-value {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--paper);
    letter-spacing: 0.1em;
  }
  .dash-rtc {
    grid-column: 1 / -1;
  }


  /* ── Banner abrir en navegador ── */
  #browserBanner {
    background: #1a3a5c;
    color: #f4f1ea;
    padding: 16px;
    border-bottom: 3px solid var(--orange);
  }
  #browserBanner.hidden { display: none; }
  .browser-banner-title {
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    color: var(--orange-lt);
    margin-bottom: 10px;
  }
  .browser-banner-inner {
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .browser-banner-qr {
    flex-shrink: 0;
    background: white;
    padding: 6px;
    border-radius: 4px;
    width: 88px;
    height: 88px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .browser-banner-qr canvas {
    display: block;
  }
  .browser-banner-right {
    flex: 1;
  }
  .browser-banner-body {
    font-family: var(--mono);
    font-size: 1rem;
    font-weight: 400;
    line-height: 1.45;
    color: #e8e4db;
    margin-bottom: 10px;
  }
  .browser-banner-addr-wrap {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .browser-banner-addr {
    font-family: var(--mono);
    font-size: 16px;
    font-weight: 400;
    color: #fff;
    background: rgba(255,255,255,0.12);
    border-radius: 3px;
    padding: 5px 10px;
    letter-spacing: 0.05em;
    flex: 1;
    text-align: center;
  }
  .browser-banner-copy {
    background: var(--orange);
    color: var(--ink);
    border: none;
    border-radius: 3px;
    padding: 6px 12px;
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    cursor: pointer;
    white-space: nowrap;
    transition: background .2s;
  }
  .browser-banner-copy:hover { background: #c4550a; }
  .browser-banner-copy.copied { background: var(--sage); }

  /* ── Batería ── */
  .bat-bar-wrap {
    grid-column: 1 / -1;
    background: var(--mist);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 10px 12px;
  }
  .bat-bar-row {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-top: 4px;
  }
  .bat-bar-bg {
    flex: 1;
    background: rgba(0,0,0,0.07);
    border-radius: 2px;
    height: 6px;
    overflow: hidden;
  }
  .bat-bar-fill {
    height: 100%;
    border-radius: 2px;
    background: var(--green);
    transition: width .5s ease, background .5s;
    width: 0%;
  }
  .bat-bar-fill.low    { background: #e04020; }
  .bat-bar-fill.medium { background: #e8900a; }
  .bat-label-row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
  }
  .bat-label { font-family:var(--mono);font-size:8px;letter-spacing:.18em;color:var(--sage-lt);text-transform:uppercase; }
  .bat-value { font-family:var(--mono);font-size:15px;color:var(--ink);font-weight:400; }
  .bat-volt  { font-family:var(--mono);font-size:10px;color:var(--sage); }

  /* ── Ambiente (BME280) ── */
  .env-grid {
    grid-column: 1 / -1;
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 8px;
  }

  .row { display:grid;grid-template-columns:1fr 1fr;gap:10px; }

  /* ── GPS block ── */
  .gps-block {
    background:var(--mist);border:1px solid var(--border);border-radius:3px;
    padding:12px;margin-bottom:12px;
  }
  .gps-row { display:flex;align-items:center;gap:10px;margin-bottom:10px; }
  #gpsStatus {
    font-family:var(--mono);font-size:10px;color:var(--sage-lt);
    letter-spacing:.07em;flex:1;line-height:1.4;
  }
  #gpsStatus.acquired { color:#3a6b3e; }
  #gpsStatus.error    { color:#a03020; }
  .utm-fields { display:grid;grid-template-columns:60px 1fr 1fr;gap:8px; }

  /* ── Botón GPS+Hora combinado ── */
  #btnGPSHora {
    background:var(--ink);color:var(--paper);border:none;border-radius:2px;
    padding:8px 14px;font-family:var(--mono);font-size:10px;letter-spacing:.1em;
    cursor:pointer;text-transform:uppercase;transition:background .2s;white-space:nowrap;
  }
  #btnGPSHora:hover  { background:var(--blue); }
  #btnGPSHora:active { background:var(--orange); }

  /* ── Horarios / Modo SEA ── */
  .cycle-block {
    background:var(--mist);border:1px solid var(--border);border-radius:3px;
    padding:12px;margin-bottom:10px;
  }
  .cycle-label {
    font-family:var(--mono);font-size:9px;letter-spacing:.18em;
    color:var(--orange);text-transform:uppercase;margin-bottom:10px;
  }
  .mode-tabs { display:flex;gap:0;margin-bottom:14px; }
  .mode-tab {
    flex:1;padding:8px;font-family:var(--mono);font-size:10px;letter-spacing:.1em;
    text-transform:uppercase;border:1px solid var(--border);background:var(--mist);
    color:var(--sage);cursor:pointer;transition:all .2s;text-align:center;
  }
  .mode-tab:first-child { border-radius:3px 0 0 3px; }
  .mode-tab:last-child  { border-radius:0 3px 3px 0;border-left:none; }
  .mode-tab.active { background:var(--ink);color:var(--paper);border-color:var(--ink); }

  .sea-result {
    background:var(--mist);border:1px solid var(--border);border-radius:3px;
    padding:10px 12px;margin-bottom:10px;display:none;
  }
  .sea-result.visible { display:block; }
  .sea-result-label { font-family:var(--mono);font-size:9px;color:var(--sage);letter-spacing:.1em;margin-bottom:6px; }
  .sea-times { display:grid;grid-template-columns:1fr 1fr;gap:8px; }
  .sea-time-item label { display:block;font-family:var(--mono);font-size:8px;color:var(--sage-lt);letter-spacing:.1em;margin-bottom:2px; }
  .sea-time-item span  { font-family:var(--mono);font-size:14px;color:var(--ink); }

  /* ── Tracks ── */
  .track-table { width:100%;border-collapse:collapse; }
  .track-table th {
    font-family:var(--mono);font-size:9px;letter-spacing:.14em;color:var(--sage);
    text-transform:uppercase;text-align:left;padding:0 8px 8px 0;border-bottom:1px solid var(--border);
  }
  .track-table td { padding:7px 8px 7px 0;border-bottom:1px solid var(--mist);vertical-align:middle; }
  .track-num { font-family:var(--mono);font-size:11px;color:var(--orange);width:28px; }
  .track-table input[type="text"] {
    background:transparent;border:none;border-bottom:1px solid var(--border);border-radius:0;
    padding:3px 0;width:100%;font-family:var(--mono);font-size:12px;color:var(--ink);outline:none;
  }
  .track-table input[type="text"]:focus { border-color:var(--blue); }
  .track-order { width:44px; }
  .track-order input[type="number"] {
    width:36px;padding:3px 6px;font-family:var(--mono);font-size:12px;text-align:center;
    background:var(--mist);border:1px solid var(--border);border-radius:2px;color:var(--ink);outline:none;
  }
  .track-active { width:32px;text-align:center; }
  .toggle { position:relative;display:inline-block;width:28px;height:16px; }
  .toggle input { display:none; }
  .toggle-slider {
    position:absolute;inset:0;background:var(--border);border-radius:8px;
    cursor:pointer;transition:background .2s;
  }
  .toggle-slider::before {
    content:'';position:absolute;width:12px;height:12px;left:2px;top:2px;
    background:white;border-radius:50%;transition:transform .2s;
  }
  .toggle input:checked + .toggle-slider { background:var(--sage); }
  .toggle input:checked + .toggle-slider::before { transform:translateX(12px); }

  /* ── Botones secundarios ── */
  .btn-secondary {
    background:transparent;border:1px solid var(--border);border-radius:2px;
    padding:7px 14px;font-family:var(--mono);font-size:10px;letter-spacing:.1em;
    cursor:pointer;color:var(--sage);text-transform:uppercase;transition:all .2s;
  }
  .btn-secondary:hover { border-color:var(--blue);color:var(--blue); }

  /* ── Botón guardar / finalizar ── */
  .save-wrap { padding:28px 16px 0;max-width:520px;margin:0 auto; }
  #btnFinalizar {
    width:100%;background:var(--orange);color:var(--paper);border:none;border-radius:3px;
    padding:16px;font-family:var(--mono);font-size:12px;letter-spacing:.18em;
    text-transform:uppercase;cursor:pointer;transition:background .2s,transform .1s;
  }
  #btnFinalizar:hover  { background:#c4550a; }
  #btnFinalizar:active { transform:scale(.99); }
  #btnFinalizar:disabled { opacity:.5;cursor:default; }

  /* ── Footer ── */
  footer {
    margin-top:32px;padding:16px;
    border-top:1px solid var(--border);
    max-width:520px;margin-left:auto;margin-right:auto;
  }
  .footer-stripe {
    height:2px;
    background:linear-gradient(90deg, var(--blue) 50%, var(--green) 50%);
    margin-bottom:12px;
    border-radius:1px;
  }
  .footer-text {
    font-family:var(--mono);font-size:9px;color:var(--sage-lt);
    letter-spacing:.1em;text-align:center;line-height:2;
  }

  /* ── Popup modal ── */
  .modal-overlay {
    position:fixed;inset:0;background:rgba(26,26,24,.7);
    display:flex;align-items:center;justify-content:center;
    z-index:1000;opacity:0;pointer-events:none;transition:opacity .25s;
    padding:20px;
  }
  .modal-overlay.visible { opacity:1;pointer-events:auto; }
  .modal {
    background:var(--paper);border-radius:4px;padding:28px 24px;
    max-width:320px;width:100%;
    transform:translateY(10px);transition:transform .25s;
    box-shadow:0 20px 60px rgba(0,0,0,.3);
  }
  .modal-overlay.visible .modal { transform:translateY(0); }
  .modal-icon { font-size:2rem;margin-bottom:12px;text-align:center; }
  .modal-title { font-size:1.3rem;font-weight:400;text-align:center;margin-bottom:8px; }
  .modal-body { font-family:var(--mono);font-size:11px;color:var(--sage);text-align:center;line-height:1.7;margin-bottom:20px; }
  .modal-btn {
    width:100%;background:var(--ink);color:var(--paper);border:none;border-radius:2px;
    padding:11px;font-family:var(--mono);font-size:11px;letter-spacing:.15em;
    text-transform:uppercase;cursor:pointer;
  }
  .modal-btn:hover { background:var(--orange); }
  .modal-countdown { font-family:var(--mono);font-size:28px;text-align:center;color:var(--orange);margin:12px 0; }

  /* ── Spinner ── */
  .spinner {
    display:inline-block;width:10px;height:10px;border:1px solid currentColor;
    border-top-color:transparent;border-radius:50%;
    animation:spin .6s linear infinite;vertical-align:middle;margin-right:6px;
  }
  @keyframes spin { to { transform:rotate(360deg); } }
</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrious/4.0.2/qrious.min.js"></script>
</head>
<body>

<!-- ══ HEADER ══════════════════════════════════════════════════════════ -->
<header>
  <div class="header-inner">
    <div class="header-logo-wrap">
      <img src="data:image/webp;base64,UklGRqagAABXRUJQVlA4WAoAAAAgAAAAnwUAnwUASUNDUBgCAAAAAAIYAAAAAAQwAABtbnRyUkdCIFhZWiAAAAAAAAAAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAAHRyWFlaAAABZAAAABRnWFlaAAABeAAAABRiWFlaAAABjAAAABRyVFJDAAABoAAAAChnVFJDAAABoAAAAChiVFJDAAABoAAAACh3dHB0AAAByAAAABRjcHJ0AAAB3AAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAFgAAAAcAHMAUgBHAEIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFhZWiAAAAAAAABvogAAOPUAAAOQWFlaIAAAAAAAAGKZAAC3hQAAGNpYWVogAAAAAAAAJKAAAA+EAAC2z3BhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABYWVogAAAAAAAA9tYAAQAAAADTLW1sdWMAAAAAAAAAAQAAAAxlblVTAAAAIAAAABwARwBvAG8AZwBsAGUAIABJAG4AYwAuACAAMgAwADEANlZQOCBongAA8HIDnQEqoAWgBT4ZDIVCIQQ2axYEAGEtLd96Vk7WDtGkze6dcjg//94nFm29oZ1y2A+TPz2lR/dfsn4//3f9i/mG5L68O5H278t/2L/hf6/7/f7//O/ID0l+K/5v/U+6r3VPI/yz+t/2P/Gf4v+9//3/WffP9tfyq+b/9k/0n++9wL+H/x7+o/2v/Ff3P++f/v7I/+7/af6L33fuv6g/5r/Tf81/d/3m/f/7mP+p+7vvE/vf+0/8X+f/3PyEfzv+1f7r86u9C9Az+uf8D/6ezp/zf/F/tf31+mP+lf5z/t/5L/c//X6EP5d/Vvys/7H7//+78AP//7b/8A///Wr+b/s16cPJf7//g/2o/wP/k80X039z/uX+T/x/+G/5n+t+7X9X0n9nn+l6F/xz7Vfk/7F/mv9j/g/+h/x/vr/cf8P/G+R/ya/x/UI/H/5h/cv7f+yP+J/8P+35b8AX57/Y/9f/iv3F/xnyXfj/970//fv9j/3fcE/o/9j/2n98/bf9//fj8Tr1r2Bf6P/if+n/lvyd+nH+//8n+k/1v7fe8j9M/z//j/0n+p/8P7////9Df5h/Zv9p/gP8z/zv9D////Z5SP3r9nb92Q0ZmJHF/0r83lwZskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yChskXrIKGyResgobJF6yCh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" alt="Tetrapoda SpA">
    </div>
    <div class="header-text">
      <div class="header-eyebrow">Monitor acústico de aves nocturnas</div>
      <h1 class="header-title">
        <span class="owl-icon"><svg fill="currentColor" height="100%" width="100%" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
	 viewBox="0 0 512.002 512.002" xml:space="preserve">
<g>
	<g>
		<path d="M247.048,79.333c-11.377,0-20.633,9.256-20.633,20.633c-0.001,11.377,9.255,20.634,20.633,20.634
			c11.378,0,20.634-9.256,20.634-20.634C267.682,88.588,258.425,79.333,247.048,79.333z M247.048,105.399
			c-2.996,0-5.433-2.438-5.433-5.434s2.437-5.433,5.433-5.433s5.434,2.437,5.434,5.433S250.044,105.399,247.048,105.399z"/>
	</g>
</g>
<g>
	<g>
		<path d="M343.427,79.333c-11.377,0-20.633,9.256-20.633,20.633c0,11.377,9.255,20.634,20.633,20.634
			c11.378,0,20.634-9.256,20.634-20.634C364.061,88.588,354.804,79.333,343.427,79.333z M343.427,105.399
			c-2.996,0-5.433-2.438-5.433-5.434s2.437-5.433,5.433-5.433c2.996,0,5.434,2.437,5.434,5.433S346.423,105.399,343.427,105.399z"/>
	</g>
</g>
<g>
	<g>
		<path d="M504.4,430.625H376.187v-50.272h18.595c4.198,0,7.6-3.402,7.6-7.6v-57.529c1.278,0.042,2.557,0.075,3.839,0.075
			c12.758,0,25.729-2.055,38.462-6.384c3.969-1.349,6.097-5.655,4.754-9.627l-53.164-157.407c3.842-8.14,6.108-16.692,6.108-25.559
			C402.381,57.696,354.686,10,296.059,10S189.735,57.695,189.735,116.322c0,2.182,0.152,4.343,0.415,6.485
			c-0.264,0.773-0.415,1.598-0.415,2.461v126.767c0,0.006,0,0.012,0,0.019v21.976c0,51.403,36.669,94.4,85.222,104.216v52.379
			H171.781c-4.198,0-7.6,3.402-7.6,7.6s3.402,7.6,7.6,7.6h110.775h24.253h37.525h16.324c-0.967,10.834-0.578,28.94,9.885,42.644
			c15.601,20.438,46.571,21.858,47.881,21.908c0.099,0.004,0.198,0.006,0.296,0.006c3.52,0,6.597-2.427,7.4-5.88
			c0.297-1.278,7.09-31.526-8.511-51.963c-1.921-2.517-4.078-4.743-6.381-6.716h93.174c4.198,0,7.6-3.402,7.6-7.6
			S508.598,430.625,504.4,430.625z M416.977,250.68c-22.637,6.713-47.033,1.984-65.793-12.908c-3.29-2.608-8.068-2.059-10.678,1.228
			c-2.608,3.288-2.059,8.069,1.229,10.678c15.9,12.62,35.162,19.2,54.699,19.2c8.503,0,17.055-1.259,25.407-3.795l10.682,31.626
			c-12.075,3.157-24.289,4.047-36.155,2.918c-0.512-0.108-1.042-0.168-1.587-0.168c-0.01,0-0.019,0.001-0.028,0.001
			c-39.122-4.337-74.209-30.66-87.691-70.324l-3.185-9.372c14.486-7.034,57.935-29.859,82.005-61.149L416.977,250.68z
			 M296.059,25.199c16.203,0,31.429,4.257,44.628,11.702c-14.951,9.269-26.37,30.347-33.963,48.767
			c-4.078,9.894-7.722,20.768-10.665,31.477c-2.943-10.708-6.587-21.584-10.665-31.477c-7.593-18.42-19.012-39.498-33.963-48.767
			C264.629,29.456,279.855,25.199,296.059,25.199z M236.578,47.345c24.932,1.926,51.881,81.2,51.881,115.104
			c0,4.198,3.402,7.6,7.6,7.6s7.6-3.402,7.6-7.6c0-33.903,26.948-113.175,51.88-115.104c19.366,16.722,31.643,41.443,31.643,68.977
			c0,24.901-25.027,48.281-46.023,63.511c-18.768,13.615-37.804,23.291-45.101,26.814c-7.299-3.523-26.332-13.2-45.101-26.814
			c-20.996-15.229-46.024-38.61-46.024-63.511C204.935,88.788,217.212,64.068,236.578,47.345z M299.209,430.625h-9.053v-50.272
			h5.902h3.15V430.625z M336.734,430.624h-22.326v-50.272h22.326V430.624z M306.809,365.153h-10.75
			c-50.246,0-91.124-40.878-91.124-91.122v-15.887c13.064-1.424,49.815,0.263,98.933,50.053
			c13.906,14.885,34.796,41.123,40.192,56.956H306.809z M360.987,430.624h-9.054v-50.272h9.054V430.624z M368.587,365.153h-8.843
			c-5.833-25.097-40.563-62.832-44.843-67.41c-0.047-0.049-0.092-0.097-0.14-0.145c-51.139-51.874-91.809-56.095-109.826-54.669
			v-86.03c23.512,31.821,67.574,55.187,82.806,62.623l4.931,14.506c14.758,43.415,52.118,72.871,94.511,79.731v51.394H368.587z
			 M412.298,494.376c-8.256-1.415-22.093-5.198-29.673-15.13c-7.582-9.932-7.586-24.275-6.773-32.614
			c8.256,1.414,22.092,5.198,29.674,15.13C413.109,471.697,413.111,486.043,412.298,494.376z"/>
	</g>
</g>
<g>
	<g>
		<path d="M105.604,128.843c-20.49-9.682-33.729-30.566-33.729-53.206c0-22.64,13.24-43.525,33.729-53.206
			c2.658-1.255,4.353-3.932,4.353-6.871c0-2.939-1.695-5.616-4.353-6.871C95.676,3.998,85.049,1.619,74.02,1.619
			C33.206,1.619,0,34.823,0,75.638c0,40.814,33.206,74.019,74.02,74.019c11.03,0,21.656-2.379,31.584-7.071
			c2.658-1.255,4.353-3.933,4.353-6.871C109.957,132.775,108.262,130.099,105.604,128.843z M74.02,134.457
			c-32.433-0.001-58.82-26.387-58.82-58.819c0-32.432,26.387-58.819,58.82-58.819c3.583,0,7.112,0.316,10.57,0.943
			C67.25,31.64,56.675,52.937,56.675,75.638c0,22.7,10.576,43.997,27.914,57.876C81.132,134.141,77.603,134.457,74.02,134.457z"/>
	</g>
</g>
</svg></span>
        Zéfiro <em>Strix</em>
      </h1>
      <div class="header-company">Tetrapoda SpA</div>
    </div>
  </div>
  <div class="header-stripe"></div>
  <div id="timerWrap">
    <div class="timer-bar"><div class="timer-fill" id="timerFill"></div></div>
    <span id="timerLabel">Cerrando en 30 s</span>
  </div>
</header>

<!-- ══ BANNER: ABRIR EN NAVEGADOR PARA GPS ══════════════════════════════ -->
<div id="browserBanner">
  <div class="browser-banner-title">📍 Para usar el GPS, abre esta página en tu navegador</div>
  <div class="browser-banner-inner">
    <div class="browser-banner-qr">
      <canvas id="qrCanvas"></canvas>
    </div>
    <div class="browser-banner-right">
      <div class="browser-banner-body">
        Escanea el código QR con la cámara, o escribe la dirección en Safari o Chrome:
      </div>
      <div class="browser-banner-addr-wrap">
        <span class="browser-banner-addr">192.168.4.1</span>
        <button class="browser-banner-copy" id="btnCopyAddr" onclick="copiarDireccion()">
          Copiar
        </button>
      </div>
    </div>
  </div>
</div>

<div id="statusBar"><div class="sdot"></div><span id="statusMsg"></span></div>

<main>

  <!-- ── Dashboard de estado del dispositivo ── -->
  <div class="dashboard">
    <div class="dash-grid">
      <div class="dash-fw">
        <span class="dash-fw-label">Firmware</span>
        <span class="dash-fw-value" id="dashFW">—</span>
      </div>
      <div class="dash-card dash-rtc">
        <div class="dash-card-label">Hora RTC</div>
        <div class="dash-card-value loading" id="dashRTC">Cargando…</div>
      </div>
      <div class="dash-card">
        <div class="dash-card-label">SD libre</div>
        <div class="dash-card-value loading" id="dashSD">—</div>
      </div>
      <div class="dash-card">
        <div class="dash-card-label">Sesiones</div>
        <div class="dash-card-value loading" id="dashSesiones">—</div>
      </div>
      <div class="dash-card">
        <div class="dash-card-label">Grabaciones</div>
        <div class="dash-card-value loading" id="dashGrab">—</div>
      </div>
      <div class="bat-bar-wrap">
        <div class="bat-label-row">
          <span class="bat-label">Batería</span>
          <span class="bat-volt" id="dashBatV">—</span>
        </div>
        <div class="bat-bar-row">
          <div class="bat-bar-bg"><div class="bat-bar-fill" id="dashBatBar"></div></div>
          <span class="bat-value" id="dashBatPct">—</span>
        </div>
      </div>
      <div class="env-grid">
        <div class="dash-card">
          <div class="dash-card-label">Temperatura</div>
          <div class="dash-card-value loading" id="dashTemp">—</div>
        </div>
        <div class="dash-card">
          <div class="dash-card-label">Humedad</div>
          <div class="dash-card-value loading" id="dashHum">—</div>
        </div>
        <div class="dash-card">
          <div class="dash-card-label">Presión</div>
          <div class="dash-card-value loading" id="dashPres">—</div>
        </div>
      </div>
    </div>
  </div>

  <!-- ① IDENTIDAD -->
  <div class="section">
    <div class="section-header">
      <span class="section-num">01</span>
      <h2 class="section-title">Punto de muestreo</h2>
    </div>
    <div class="field">
      <label>Nombre de la estación</label>
      <input type="text" id="stationName" placeholder="Ej: Quebrada Los Robles — E1">
    </div>
    <div class="row">
      <div class="field">
        <label>Proyecto</label>
        <input type="text" id="projectName" placeholder="Nombre del proyecto">
      </div>
      <div class="field">
        <label>Investigador</label>
        <input type="text" id="researcher" placeholder="Nombre">
      </div>
    </div>
    <div class="field">
      <label>ID de unidad</label>
      <input type="text" id="unitName" placeholder="Ej: ZS-01">
      <div class="hint">Identificador único del dispositivo físico</div>
    </div>
  </div>

  <!-- ② UBICACIÓN + HORA (botón único) -->
  <div class="section">
    <div class="section-header">
      <span class="section-num">02</span>
      <h2 class="section-title">Ubicación y hora</h2>
    </div>

    <div class="gps-block">
      <div class="gps-row">
        <span id="gpsStatus">Captando GPS automáticamente…</span>
        <button id="btnGPSHora" onclick="captarGPSyHora()">↺ Recaptar</button>
      </div>
      <div class="utm-fields">
        <div class="field" style="margin:0">
          <label>Zona</label>
          <input type="text" id="utmZone" placeholder="19S" maxlength="4">
        </div>
        <div class="field" style="margin:0">
          <label>Este (m)</label>
          <input type="number" id="utmEaste" placeholder="342500">
        </div>
        <div class="field" style="margin:0">
          <label>Norte (m)</label>
          <input type="number" id="utmNorte" placeholder="5812000">
        </div>
      </div>
      <div class="hint" style="margin-top:8px">
        Coordenadas captadas desde el GPS del teléfono y convertidas a UTM.
        La hora del sistema también se sincroniza al captar la ubicación.
        Puedes editar los campos manualmente si es necesario.
      </div>
    </div>

    <div class="row">
      <div class="field">
        <label>Fecha del sistema</label>
        <input type="text" id="sysDate" placeholder="YYYY-MM-DD" maxlength="10">
      </div>
      <div class="field">
        <label>Hora del sistema</label>
        <input type="text" id="sysTime" placeholder="HH:MM:SS" maxlength="8">
      </div>
    </div>
  </div>

  <!-- ③ HORARIOS -->
  <div class="section">
    <div class="section-header">
      <span class="section-num">03</span>
      <h2 class="section-title">Horarios de ciclo</h2>
    </div>

    <div class="mode-tabs">
      <div class="mode-tab active" id="tabManual" onclick="setMode('manual')">Manual</div>
      <div class="mode-tab" id="tabSEA" onclick="setMode('sea')">Modo normativo SEA</div>
    </div>

    <!-- Manual -->
    <div id="modoManual">
      <div class="cycle-block">
        <div class="cycle-label">Ciclo mañana</div>
        <div class="row">
          <div class="field" style="margin:0"><label>Inicio</label>
            <input type="time" id="morningStart" value="06:22"></div>
          <div class="field" style="margin:0"><label>Término</label>
            <input type="time" id="morningEnd" value="07:22"></div>
        </div>
      </div>
      <div class="cycle-block">
        <div class="cycle-label">Ciclo noche</div>
        <div class="row">
          <div class="field" style="margin:0"><label>Inicio</label>
            <input type="time" id="nightStart" value="18:55"></div>
          <div class="field" style="margin:0"><label>Término</label>
            <input type="time" id="nightEnd" value="19:55"></div>
        </div>
      </div>
    </div>

    <!-- SEA -->
    <div id="modoSEA" style="display:none">
      <div class="hint" style="margin-bottom:12px">
        Calcula automáticamente los horarios según normativa SEA:
        ciclo noche = 1h después del atardecer,
        ciclo mañana = 1h antes del amanecer.
        Requiere coordenadas GPS activas.
      </div>
      <div class="sea-result" id="seaResult">
        <div class="sea-result-label">Horarios calculados para hoy</div>
        <div class="sea-times">
          <div class="sea-time-item">
            <label>Ciclo noche — inicio</label>
            <span id="seaNightStart">—</span>
          </div>
          <div class="sea-time-item">
            <label>Ciclo noche — término (+1h)</label>
            <span id="seaNightEnd">—</span>
          </div>
          <div class="sea-time-item">
            <label>Ciclo mañana — inicio</label>
            <span id="seaMornStart">—</span>
          </div>
          <div class="sea-time-item">
            <label>Ciclo mañana — término (+1h)</label>
            <span id="seaMornEnd">—</span>
          </div>
        </div>
      </div>
      <button class="btn-secondary" onclick="calcularSEA()" style="margin-bottom:10px">
        ↻ Recalcular con ubicación actual
      </button>
      <div class="hint">Los horarios calculados se aplicarán al guardar.</div>
    </div>
  </div>

  <!-- ④ GRABACIÓN -->
  <div class="section">
    <div class="section-header">
      <span class="section-num">04</span>
      <h2 class="section-title">Grabación</h2>
    </div>
    <div class="field" style="max-width:200px">
      <label>Duración de grabación (seg)</label>
      <input type="number" id="recTime" min="5" max="120" value="20">
      <div class="hint">Segundos de escucha tras cada canto</div>
    </div>
  </div>

  <!-- ⑤ ESPECIES Y ORDEN -->
  <div class="section">
    <div class="section-header">
      <span class="section-num">05</span>
      <h2 class="section-title">Especies y orden</h2>
    </div>
    <table class="track-table">
      <thead>
        <tr>
          <th>Track</th>
          <th>Especie</th>
          <th class="track-order">Orden</th>
          <th class="track-active">Activo</th>
        </tr>
      </thead>
      <tbody id="trackBody"></tbody>
    </table>
    <div class="hint" style="margin-top:8px">
      Tracks desactivados se omiten en el ciclo. El orden define la secuencia.
    </div>
  </div>

</main>

<!-- ── Botón finalizar ── -->
<div class="save-wrap">
  <button id="btnFinalizar" onclick="finalizar()">
    Finalizar configuración y armar equipo
  </button>
</div>

<!-- ── Footer ── -->
<footer>
  <div class="footer-stripe"></div>
  <div class="footer-text" id="footerInfo">
    Zéfiro Strix · Tetrapoda SpA<br>
    <span id="footerDevice"></span>
  </div>
</footer>

<!-- ══ MODALES ══════════════════════════════════════════════════════════ -->

<!-- Modal: permiso GPS -->
<div class="modal-overlay" id="modalGPS">
  <div class="modal">
    <div class="modal-icon">📍</div>
    <div class="modal-title">GPS bloqueado</div>
    <div class="modal-body">
      El GPS no está disponible en el portal del sistema.<br><br>
      Escanea el código QR con la cámara de tu teléfono, o escribe
      <strong>192.168.4.1</strong> en Safari o Chrome.
      Allí el GPS funcionará sin problemas.
    </div>
    <div style="background:white;padding:8px;border-radius:4px;display:inline-block;margin-bottom:14px">
      <canvas id="qrCanvasModal"></canvas>
    </div>
    <button class="modal-btn" onclick="cerrarModal('modalGPS')" style="background:var(--sage)">
      Ingresaré las coordenadas manualmente
    </button>
  </div>
</div>

<!-- Modal: confirmación GPS + hora -->
<div class="modal-overlay" id="modalOK">
  <div class="modal">
    <div class="modal-icon">✓</div>
    <div class="modal-title">Ubicación y hora actualizadas</div>
    <div class="modal-body" id="modalOKBody">—</div>
    <button class="modal-btn" onclick="cerrarModal('modalOK')">Continuar</button>
  </div>
</div>

<!-- Modal: finalizar con cuenta regresiva -->
<div class="modal-overlay" id="modalFinalizar">
  <div class="modal">
    <div class="modal-icon">🦉</div>
    <div class="modal-title">Configuración guardada</div>
    <div class="modal-body">
      El dispositivo cerrará la red WiFi y comenzará a operar en:
    </div>
    <div class="modal-countdown" id="cuentaRegresiva">5</div>
    <div class="modal-body">Puedes desconectarte del equipo con seguridad.</div>
  </div>
</div>

<!-- Modal: error genérico -->
<div class="modal-overlay" id="modalError">
  <div class="modal">
    <div class="modal-icon">⚠</div>
    <div class="modal-title">Atención</div>
    <div class="modal-body" id="modalErrorBody">—</div>
    <button class="modal-btn" onclick="cerrarModal('modalError')">Entendido</button>
  </div>
</div>

<script>
// ═══════════════════════════════════════════════════════════════════════════
// ESTADO
// ═══════════════════════════════════════════════════════════════════════════
let timerSec    = 30;
let timerInt    = null;
let connected   = false;
let latActual   = null;
let lonActual   = null;
let modoHorario = 'manual';

const ESPECIES_DEFAULT = [
  'Chuncho (Glaucidium nanum)',
  'Concon (Strix rufipes)',
  'Lechuza (Tyto alba)',
  'Tucuquere (Bubo magellanicus)',
  'Nuco (Asio flammeus)',
  'Especie 6',
  'Especie 7'
];

// ═══════════════════════════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════════════════════════
window.addEventListener('load', async () => {
  buildTrackTable();
  setNow();
  startTimer();
  generarQR();
  await cargarConfig();
  await cargarInfoDispositivo();
  // Intento silencioso de GPS al cargar
  intentarGPSSilencioso();
});

function generarQR() {
  try {
    new QRious({
      element: document.getElementById('qrCanvas'),
      value: 'http://192.168.4.1',
      size: 76,
      background: 'white',
      foreground: '#1a1a18',
      level: 'M'
    });
  } catch(e) {
    // Si no carga la librería, ocultar el canvas
    const c = document.getElementById('qrCanvas');
    if (c) c.style.display = 'none';
  }
}

function copiarDireccion() {
  const btn = document.getElementById('btnCopyAddr');
  if (navigator.clipboard) {
    navigator.clipboard.writeText('192.168.4.1').then(() => {
      btn.textContent = '✓ Copiado';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = 'Copiar';
        btn.classList.remove('copied');
      }, 2000);
    }).catch(() => fallbackCopy(btn));
  } else {
    fallbackCopy(btn);
  }
}

function fallbackCopy(btn) {
  // Seleccionar el texto visualmente para copiar manual
  const addr = document.querySelector('.browser-banner-addr');
  const range = document.createRange();
  range.selectNode(addr);
  window.getSelection().removeAllRanges();
  window.getSelection().addRange(range);
  btn.textContent = '← Seleccionado';
  btn.classList.add('copied');
  setTimeout(() => {
    window.getSelection().removeAllRanges();
    btn.textContent = 'Copiar';
    btn.classList.remove('copied');
  }, 3000);
}

// ═══════════════════════════════════════════════════════════════════════════
// TIMER — solo corre hasta que alguien se conecta
// ═══════════════════════════════════════════════════════════════════════════
function startTimer() {
  // Notificar al servidor que hay un cliente conectado
  fetch('/ping').catch(() => {});
  connected = true;
  // Ocultar la barra del timer porque ya hay conexión
  document.getElementById('timerWrap').classList.add('hidden');
}

// ═══════════════════════════════════════════════════════════════════════════
// TRACKS
// ═══════════════════════════════════════════════════════════════════════════
function buildTrackTable() {
  const tbody = document.getElementById('trackBody');
  tbody.innerHTML = '';
  for (let i = 1; i <= 7; i++) {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="track-num">T${i}</td>
      <td><input type="text" id="sp${i}" value="${ESPECIES_DEFAULT[i-1]}"></td>
      <td class="track-order"><input type="number" id="ord${i}" value="${i}" min="1" max="7"></td>
      <td class="track-active">
        <label class="toggle">
          <input type="checkbox" id="act${i}" checked>
          <span class="toggle-slider"></span>
        </label>
      </td>`;
    tbody.appendChild(tr);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HORA ACTUAL DEL TELÉFONO
// ═══════════════════════════════════════════════════════════════════════════
function setNow() {
  const d = new Date();
  document.getElementById('sysDate').value =
    d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate());
  document.getElementById('sysTime').value =
    pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
}
function pad(n) { return String(n).padStart(2,'0'); }

// ═══════════════════════════════════════════════════════════════════════════
// GPS: INTENTO SILENCIOSO AL CARGAR
// ═══════════════════════════════════════════════════════════════════════════
function intentarGPSSilencioso() {
  if (!navigator.geolocation) {
    setGPSStatus('GPS no disponible en este navegador.', 'error');
    return;
  }
  setGPSStatus('Captando GPS automáticamente…');

  navigator.geolocation.getCurrentPosition(
    (pos) => onGPSSuccess(pos, true),
    (err) => {
      if (err.code === 1) {
        // Permiso denegado — probablemente en webview del sistema
        setGPSStatus('GPS bloqueado. Abre el portal en Safari o Chrome.', 'error');
        abrirModal('modalGPS');
      } else {
        setGPSStatus('GPS no disponible. Intenta al aire libre o ingresa manualmente.', 'error');
      }
    },
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
  );
}

function pedirPermisoGPS() {
  cerrarModal('modalGPS');
  setGPSStatus('Esperando permiso de ubicación…');
  navigator.geolocation.getCurrentPosition(
    (pos) => onGPSSuccess(pos, true),
    (err) => {
      setGPSStatus('Permiso denegado. Ingresa las coordenadas manualmente.', 'error');
    },
    { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 }
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTÓN ÚNICO: CAPTAR GPS + ACTUALIZAR HORA
// ═══════════════════════════════════════════════════════════════════════════
function captarGPSyHora() {
  setNow();
  setGPSStatus('Captando GPS…');
  document.getElementById('btnGPSHora').disabled = true;

  navigator.geolocation.getCurrentPosition(
    (pos) => onGPSSuccess(pos, false),
    (err) => {
      document.getElementById('btnGPSHora').disabled = false;
      if (err.code === 1) {
        abrirModal('modalGPS');
      } else {
        setGPSStatus('No se pudo obtener GPS. Intenta al aire libre.', 'error');
      }
    },
    { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 }
  );
}

function onGPSSuccess(pos, silencioso) {
  document.getElementById('btnGPSHora').disabled = false;
  const { latitude: lat, longitude: lon, accuracy } = pos.coords;
  latActual = lat; lonActual = lon;

  const utm = latLonToUTM(lat, lon);
  document.getElementById('utmZone').value  = utm.zone;
  document.getElementById('utmEaste').value = Math.round(utm.easting);
  document.getElementById('utmNorte').value = Math.round(utm.northing);

  setNow(); // Actualizar hora del teléfono en los campos

  setGPSStatus(
    `GPS adquirido ±${Math.round(accuracy)} m · ${lat.toFixed(5)}, ${lon.toFixed(5)}`,
    'acquired'
  );

  // Si modo SEA activo, recalcular
  if (modoHorario === 'sea') calcularSEA();

  // Mostrar popup de confirmación
  const d = new Date();
  document.getElementById('modalOKBody').innerHTML =
    `<strong>Coordenadas:</strong> ${utm.zone} ${Math.round(utm.easting)} E, ${Math.round(utm.northing)} N<br>` +
    `<strong>Precisión:</strong> ±${Math.round(accuracy)} m<br>` +
    `<strong>Hora sincronizada:</strong> ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  abrirModal('modalOK');
}

// ═══════════════════════════════════════════════════════════════════════════
// MODO HORARIO
// ═══════════════════════════════════════════════════════════════════════════
function setMode(modo) {
  modoHorario = modo;
  document.getElementById('tabManual').classList.toggle('active', modo === 'manual');
  document.getElementById('tabSEA').classList.toggle('active', modo === 'sea');
  document.getElementById('modoManual').style.display = modo === 'manual' ? '' : 'none';
  document.getElementById('modoSEA').style.display    = modo === 'sea'    ? '' : 'none';
  if (modo === 'sea') calcularSEA();
}

// ═══════════════════════════════════════════════════════════════════════════
// CÁLCULO NORMATIVO SEA (NOAA solar)
// ═══════════════════════════════════════════════════════════════════════════
function calcularSEA() {
  const lat = latActual;
  const lon = lonActual;

  if (lat === null || lon === null) {
    showStatus('Se necesitan coordenadas GPS para el modo SEA. Capta la ubicación primero.', 'error');
    return;
  }

  const hoy = new Date();
  const sunrise = calcSunEvent(hoy, lat, lon, true);   // amanecer
  const sunset  = calcSunEvent(hoy, lat, lon, false);  // atardecer

  if (!sunrise || !sunset) {
    showStatus('No se pudo calcular amanecer/atardecer para esta ubicación y fecha.', 'error');
    return;
  }

  // Ciclo noche: 1h después del atardecer, durante 1h
  const nightStart = new Date(sunset.getTime()  + 60*60*1000);
  const nightEnd   = new Date(nightStart.getTime() + 60*60*1000);
  // Ciclo mañana: 1h antes del amanecer, durante 1h
  const mornEnd    = new Date(sunrise.getTime() - 60*60*1000);
  const mornStart  = new Date(mornEnd.getTime()  - 60*60*1000);

  const fmt = d => pad(d.getHours()) + ':' + pad(d.getMinutes());

  document.getElementById('seaNightStart').textContent = fmt(nightStart);
  document.getElementById('seaNightEnd').textContent   = fmt(nightEnd);
  document.getElementById('seaMornStart').textContent  = fmt(mornStart);
  document.getElementById('seaMornEnd').textContent    = fmt(mornEnd);
  document.getElementById('seaResult').classList.add('visible');

  // Copiar a los campos reales para que se guarden
  document.getElementById('morningStart').value = fmt(mornStart);
  document.getElementById('morningEnd').value   = fmt(mornEnd);
  document.getElementById('nightStart').value   = fmt(nightStart);
  document.getElementById('nightEnd').value     = fmt(nightEnd);
}

// Algoritmo NOAA para amanecer/atardecer
function calcSunEvent(date, lat, lon, isSunrise) {
  const rad = Math.PI / 180;
  const JD  = date.getTime() / 86400000 + 2440587.5;
  const n   = JD - 2451545.0;
  const L   = (280.46 + 0.9856474 * n) % 360;
  const g   = (357.528 + 0.9856003 * n) % 360;
  const lam = L + 1.915 * Math.sin(g * rad) + 0.02 * Math.sin(2 * g * rad);
  const eps = 23.439 - 0.0000004 * n;
  const RA  = Math.atan2(Math.cos(eps * rad) * Math.sin(lam * rad), Math.cos(lam * rad)) / rad;
  const dec = Math.asin(Math.sin(eps * rad) * Math.sin(lam * rad)) / rad;
  const ha  = Math.acos(
    (Math.sin(-0.8333 * rad) - Math.sin(lat * rad) * Math.sin(dec * rad)) /
    (Math.cos(lat * rad) * Math.cos(dec * rad))
  ) / rad;
  if (isNaN(ha)) return null;
  const noon   = 12 - (lon / 15) - ((RA - (L % 360)) / 15);
  const evtUTC = isSunrise ? noon - ha / 15 : noon + ha / 15;
  const offset = date.getTimezoneOffset() / -60;
  const evtLoc = evtUTC + offset;
  const h = Math.floor(evtLoc) % 24;
  const m = Math.round((evtLoc % 1) * 60);
  const d = new Date(date);
  d.setHours(h < 0 ? h + 24 : h, m, 0, 0);
  return d;
}

// ═══════════════════════════════════════════════════════════════════════════
// CARGAR CONFIG DESDE ESP32
// ═══════════════════════════════════════════════════════════════════════════
async function cargarConfig() {
  try {
    const r = await fetch('/config.json');
    if (!r.ok) return;
    const cfg = await r.json();
    if (cfg.stationName)  document.getElementById('stationName').value  = cfg.stationName;
    if (cfg.projectName)  document.getElementById('projectName').value  = cfg.projectName;
    if (cfg.researcher)   document.getElementById('researcher').value   = cfg.researcher;
    if (cfg.unitName)     document.getElementById('unitName').value     = cfg.unitName;
    if (cfg.utmZone)      document.getElementById('utmZone').value      = cfg.utmZone;
    if (cfg.utmEaste)     document.getElementById('utmEaste').value     = cfg.utmEaste;
    if (cfg.utmNorte)     document.getElementById('utmNorte').value     = cfg.utmNorte;
    if (cfg.morningStart) document.getElementById('morningStart').value = cfg.morningStart;
    if (cfg.morningEnd)   document.getElementById('morningEnd').value   = cfg.morningEnd;
    if (cfg.nightStart)   document.getElementById('nightStart').value   = cfg.nightStart;
    if (cfg.nightEnd)     document.getElementById('nightEnd').value     = cfg.nightEnd;
    if (cfg.recTime)      document.getElementById('recTime').value      = cfg.recTime;
    if (cfg.tracks) {
      cfg.tracks.forEach((t, i) => {
        const n = i + 1;
        if (document.getElementById(`sp${n}`))  document.getElementById(`sp${n}`).value    = t.species || '';
        if (document.getElementById(`ord${n}`)) document.getElementById(`ord${n}`).value   = t.order || n;
        if (document.getElementById(`act${n}`)) document.getElementById(`act${n}`).checked = t.active !== false;
      });
    }
  } catch(e) {}
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DEL DISPOSITIVO
// ═══════════════════════════════════════════════════════════════════════════
async function cargarInfoDispositivo() {
  try {
    const r = await fetch('/status');
    if (!r.ok) return;
    const s = await r.json();
    // Dashboard cards
    document.getElementById('dashFW').textContent       = `v${s.version}`;
    document.getElementById('dashRTC').textContent      = s.rtcTime || '—';
    document.getElementById('dashRTC').classList.remove('loading');
    document.getElementById('dashSD').textContent       = `${s.sdFreeMB} MB`;
    document.getElementById('dashSD').classList.remove('loading');
    document.getElementById('dashSesiones').textContent = s.sessions;
    document.getElementById('dashSesiones').classList.remove('loading');
    document.getElementById('dashGrab').textContent     = s.recordings;
    document.getElementById('dashGrab').classList.remove('loading');
    // Batería
    const batPct = s.batPct != null ? s.batPct : 0;
    const batV   = s.batV   != null ? s.batV   : '—';
    document.getElementById('dashBatV').textContent   = batV !== '—' ? batV + ' V' : '—';
    document.getElementById('dashBatPct').textContent = batPct + '%';
    const fill = document.getElementById('dashBatBar');
    fill.style.width = batPct + '%';
    fill.className = 'bat-bar-fill' +
      (batPct <= 15 ? ' low' : batPct <= 30 ? ' medium' : '');
    // Ambiente BME280
    if (s.bmeOk) {
      document.getElementById('dashTemp').textContent = s.tempC  + ' °C';
      document.getElementById('dashHum').textContent  = s.humPct + ' %';
      document.getElementById('dashPres').textContent = s.presHpa + ' hPa';
      document.getElementById('dashTemp').classList.remove('loading');
      document.getElementById('dashHum').classList.remove('loading');
      document.getElementById('dashPres').classList.remove('loading');
    } else {
      document.getElementById('dashTemp').textContent = 'N/D';
      document.getElementById('dashHum').textContent  = 'N/D';
      document.getElementById('dashPres').textContent = 'N/D';
      document.getElementById('dashTemp').classList.remove('loading');
      document.getElementById('dashHum').classList.remove('loading');
      document.getElementById('dashPres').classList.remove('loading');
    }
    // Footer
    document.getElementById('footerDevice').textContent =
      `Unidad: ${s.unitName || '—'} · FW v${s.version}`;
  } catch(e) {
    document.getElementById('dashRTC').textContent = 'Sin datos';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FINALIZAR CONFIGURACIÓN
// ═══════════════════════════════════════════════════════════════════════════
async function finalizar() {
  const btn = document.getElementById('btnFinalizar');
  btn.disabled  = true;
  btn.innerHTML = '<span class="spinner"></span>Guardando…';

  const tracks = [];
  for (let i = 1; i <= 7; i++) {
    tracks.push({
      order:   parseInt(document.getElementById(`ord${i}`).value) || i,
      species: document.getElementById(`sp${i}`).value.trim(),
      active:  document.getElementById(`act${i}`).checked
    });
  }

  const payload = {
    stationName:  document.getElementById('stationName').value.trim(),
    projectName:  document.getElementById('projectName').value.trim(),
    researcher:   document.getElementById('researcher').value.trim(),
    unitName:     document.getElementById('unitName').value.trim(),
    utmZone:      document.getElementById('utmZone').value.trim(),
    utmEaste:     parseInt(document.getElementById('utmEaste').value) || 0,
    utmNorte:     parseInt(document.getElementById('utmNorte').value) || 0,
    morningStart: document.getElementById('morningStart').value,
    morningEnd:   document.getElementById('morningEnd').value,
    nightStart:   document.getElementById('nightStart').value,
    nightEnd:     document.getElementById('nightEnd').value,
    recTime:      parseInt(document.getElementById('recTime').value) || 20,
    sysDate:      document.getElementById('sysDate').value,
    sysTime:      document.getElementById('sysTime').value,
    tracks,
    shutdown: true   // señal al ESP32 para cerrar el AP tras guardar
  };

  try {
    const r = await fetch('/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    const res = await r.json();
    if (!res.ok) throw new Error(res.error || 'Error al guardar');

    // Mostrar modal con cuenta regresiva
    abrirModal('modalFinalizar');
    let seg = 5;
    const intervalo = setInterval(() => {
      seg--;
      document.getElementById('cuentaRegresiva').textContent = seg;
      if (seg <= 0) clearInterval(intervalo);
    }, 1000);

  } catch(e) {
    btn.disabled  = false;
    btn.innerHTML = 'Finalizar configuración y armar equipo';
    mostrarError('No se pudo guardar la configuración: ' + e.message);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODALES
// ═══════════════════════════════════════════════════════════════════════════
function abrirModal(id) {
  document.getElementById(id).classList.add('visible');
  // Generar QR en modal GPS si aplica
  if (id === 'modalGPS') {
    try {
      new QRious({
        element: document.getElementById('qrCanvasModal'),
        value: 'http://192.168.4.1',
        size: 120,
        background: 'white',
        foreground: '#1a1a18',
        level: 'M'
      });
    } catch(e) {}
  }
}
function cerrarModal(id) {
  document.getElementById(id).classList.remove('visible');
}
function mostrarError(msg) {
  document.getElementById('modalErrorBody').textContent = msg;
  abrirModal('modalError');
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════
function setGPSStatus(msg, cls = '') {
  const el = document.getElementById('gpsStatus');
  el.textContent = msg;
  el.className   = cls;
}
function showStatus(msg, type = '') {
  const bar = document.getElementById('statusBar');
  document.getElementById('statusMsg').textContent = msg;
  bar.className = 'visible' + (type ? ' ' + type : '');
}

// ── Lat/Lon WGS84 → UTM ───────────────────────────────────────────────────
function latLonToUTM(lat, lon) {
  const a  = 6378137.0, f = 1/298.257223563;
  const b  = a*(1-f), e2 = 1-(b*b)/(a*a), k0 = 0.9996;
  const zn = Math.floor((lon+180)/6)+1;
  const zl = 'CDEFGHJKLMNPQRSTUVWXX'[Math.floor((lat+80)/8)];
  const lr = lon*Math.PI/180, la = lat*Math.PI/180;
  const l0 = ((zn-1)*6-180+3)*Math.PI/180;
  const N  = a/Math.sqrt(1-e2*Math.sin(la)**2);
  const T  = Math.tan(la)**2, C = (e2/(1-e2))*Math.cos(la)**2;
  const A  = Math.cos(la)*(lr-l0);
  const e4 = e2*e2, e6 = e4*e2;
  const M  = a*((1-e2/4-3*e4/64-5*e6/256)*la-(3*e2/8+3*e4/32+45*e6/1024)*Math.sin(2*la)
               +(15*e4/256+45*e6/1024)*Math.sin(4*la)-(35*e6/3072)*Math.sin(6*la));
  let E = k0*N*(A+(1-T+C)*A**3/6+(5-18*T+T**2+72*C-58*(e2/(1-e2)))*A**5/120)+500000;
  let No = k0*(M+N*Math.tan(la)*(A**2/2+(5-T+9*C+4*C**2)*A**4/24+(61-58*T+T**2+600*C-330*(e2/(1-e2)))*A**6/720));
  if (lat<0) No+=10000000;
  return { zone:`${zn}${zl}`, easting:E, northing:No };
}
</script>
</body>
</html>
)HTMLEOF";
