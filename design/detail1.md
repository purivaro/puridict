<!DOCTYPE html>

<html class="light" lang="th"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Puri Dictionary - Detail View</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&amp;family=Noto+Sans+Thai:wght@400;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
    tailwind.config = {
      darkMode: "class",
      theme: {
        extend: {
          "colors": {
            "on-surface-variant": "#434655",
            "secondary": "#904d00",
            "surface-dim": "#cbdbf5",
            "tertiary-container": "#bc4800",
            "outline": "#737686",
            "on-error": "#ffffff",
            "on-primary-container": "#eeefff",
            "on-primary": "#ffffff",
            "inverse-primary": "#b4c5ff",
            "on-primary-fixed": "#00174b",
            "on-surface": "#0b1c30",
            "surface-container": "#e5eeff",
            "surface-container-highest": "#d3e4fe",
            "surface": "#f8f9ff",
            "on-secondary": "#ffffff",
            "tertiary-fixed-dim": "#ffb596",
            "surface-tint": "#0053db",
            "on-secondary-container": "#663500",
            "on-tertiary-fixed": "#360f00",
            "tertiary": "#943700",
            "inverse-surface": "#213145",
            "on-background": "#0b1c30",
            "on-secondary-fixed": "#2f1500",
            "on-primary-fixed-variant": "#003ea8",
            "outline-variant": "#c3c6d7",
            "surface-variant": "#d3e4fe",
            "primary": "#004ac6",
            "surface-container-lowest": "#ffffff",
            "error-container": "#ffdad6",
            "surface-bright": "#f8f9ff",
            "tertiary-fixed": "#ffdbcd",
            "primary-container": "#2563eb",
            "on-tertiary-fixed-variant": "#7d2d00",
            "on-tertiary": "#ffffff",
            "error": "#ba1a1a",
            "surface-container-low": "#eff4ff",
            "inverse-on-surface": "#eaf1ff",
            "on-error-container": "#93000a",
            "surface-container-high": "#dce9ff",
            "secondary-fixed-dim": "#ffb77d",
            "primary-fixed": "#dbe1ff",
            "secondary-fixed": "#ffdcc3",
            "secondary-container": "#fe932c",
            "primary-fixed-dim": "#b4c5ff",
            "on-tertiary-container": "#ffede6",
            "on-secondary-fixed-variant": "#6e3900",
            "background": "#f8f9ff"
          },
          "borderRadius": {
            "DEFAULT": "0.25rem",
            "lg": "0.5rem",
            "xl": "0.75rem",
            "full": "9999px"
          },
          "spacing": {
            "sm": "8px",
            "md": "16px",
            "edge-margin": "20px",
            "gutter": "12px",
            "xs": "4px",
            "base": "4px",
            "lg": "24px",
            "xl": "32px"
          },
          "fontFamily": {
            "body-lg": ["Inter", "Noto Sans Thai"],
            "title-sm": ["Inter", "Noto Sans Thai"],
            "caption": ["Inter", "Noto Sans Thai"],
            "display-pali": ["Inter", "Noto Sans Thai"],
            "label-caps": ["Inter", "Noto Sans Thai"],
            "headline-md": ["Inter", "Noto Sans Thai"],
            "body-md": ["Inter", "Noto Sans Thai"]
          },
          "fontSize": {
            "body-lg": ["18px", {"lineHeight": "28px", "fontWeight": "400"}],
            "title-sm": ["16px", {"lineHeight": "24px", "fontWeight": "600"}],
            "caption": ["14px", {"lineHeight": "20px", "fontWeight": "400"}],
            "display-pali": ["28px", {"lineHeight": "36px", "letterSpacing": "-0.02em", "fontWeight": "600"}],
            "label-caps": ["12px", {"lineHeight": "16px", "letterSpacing": "0.05em", "fontWeight": "700"}],
            "headline-md": ["20px", {"lineHeight": "28px", "fontWeight": "600"}],
            "body-md": ["16px", {"lineHeight": "24px", "fontWeight": "400"}]
          }
        },
      },
    }
  </script>
<style>
    body { font-family: 'Inter', 'Noto Sans Thai', sans-serif; }
    .material-symbols-outlined {
      font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
    }
    .custom-scrollbar::-webkit-scrollbar { width: 4px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background min-h-screen pb-24">
<!-- TopAppBar -->
<header class="sticky top-0 z-50 bg-primary dark:bg-primary-container text-on-primary dark:text-on-primary-container shadow-md flex justify-between items-center px-edge-margin py-md w-full rounded-b-xl">
<div class="flex items-center gap-sm">
<span class="material-symbols-outlined text-[24px]">menu_book</span>
<h1 class="font-headline-md text-headline-md font-bold">Puri Dictionary</h1>
</div>
<div class="flex items-center gap-md">
<button class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-primary-fixed-variant/20 transition-transform active:scale-95">
<span class="material-symbols-outlined">history</span>
</button>
<button class="w-10 h-10 flex items-center justify-center rounded-full hover:bg-primary-fixed-variant/20 transition-transform active:scale-95">
<span class="material-symbols-outlined">info</span>
</button>
</div>
</header>
<main class="px-edge-margin pt-lg space-y-lg">
<!-- Language Toggle -->
<div class="flex bg-surface-container rounded-xl p-xs gap-xs">
<button class="flex-1 flex items-center justify-center gap-sm py-sm rounded-lg bg-primary text-on-primary font-title-sm shadow-sm">
<span class="material-symbols-outlined text-[20px]">language</span>
<span>บาลี-ไทย</span>
</button>
<button class="flex-1 flex items-center justify-center gap-sm py-sm rounded-lg text-on-surface-variant font-title-sm hover:bg-surface-variant transition-colors">
<span class="material-symbols-outlined text-[20px]">swap_horiz</span>
<span>ไทย-บาลี</span>
</button>
</div>
<!-- Search Section -->
<section class="bg-surface-container-lowest border border-outline-variant/30 rounded-xl p-md shadow-sm">
<div class="flex gap-sm">
<div class="relative flex-1">
<input class="w-full bg-surface border-outline-variant focus:border-primary focus:ring-1 focus:ring-primary rounded-lg py-3 px-md text-body-lg text-on-surface" type="text" value="ทสฺสน"/>
<button class="absolute right-3 top-1/2 -translate-y-1/2 text-outline hover:text-on-surface">
<span class="material-symbols-outlined">close</span>
</button>
</div>
<button class="bg-primary-container text-on-primary-container px-lg rounded-lg font-title-sm flex items-center justify-center shadow-md active:scale-95 transition-transform">
          ค้นหา
        </button>
</div>
<div class="mt-md flex justify-between items-center text-on-surface-variant">
<div class="flex items-center gap-xs">
<span class="material-symbols-outlined text-[18px]">info</span>
<span class="text-caption">พบ 35 รายการ</span>
</div>
<div class="flex gap-xs">
<button class="px-sm py-1 border border-outline-variant rounded-md text-caption hover:bg-surface-variant">A-</button>
<button class="px-sm py-1 border border-outline-variant rounded-md text-caption hover:bg-surface-variant">A+</button>
</div>
</div>
</section>
<!-- Word Detail Card -->
<article class="bg-surface-container-lowest rounded-xl shadow-md overflow-hidden border-l-4 border-secondary relative">
<button class="absolute top-md right-md text-primary/50 hover:text-primary transition-colors">
<span class="material-symbols-outlined text-[28px]">bookmark</span>
</button>
<div class="p-lg space-y-md">
<!-- Header -->
<div>
<h2 class="text-display-pali font-display-pali text-primary mb-sm">ทสฺสน</h2>
<div class="flex flex-wrap gap-xs">
<span class="px-md py-1 bg-primary/10 text-primary rounded-full text-label-caps flex items-center gap-xs">
<span class="material-symbols-outlined text-[14px]">label</span> นามนาม
            </span>
<span class="px-md py-1 bg-secondary/10 text-secondary rounded-full text-label-caps flex items-center gap-xs">
<span class="material-symbols-outlined text-[14px]">auto_awesome</span> ยุ ปัจจัย
            </span>
<span class="px-md py-1 bg-tertiary-fixed-dim/30 text-on-tertiary-fixed-variant rounded-full text-label-caps flex items-center gap-xs">
<span class="material-symbols-outlined text-[14px]">transgender</span> นปุงสกลิงค์
            </span>
</div>
</div>
<!-- Meaning -->
<div class="pt-sm">
<p class="text-caption text-outline mb-xs">ความหมาย</p>
<p class="text-display-pali text-on-surface leading-snug">การเห็น, การเฝ้า</p>
</div>
<hr class="border-outline-variant/30"/>
<!-- Word Source -->
<div class="flex items-center gap-sm">
<span class="material-symbols-outlined text-outline">menu_book</span>
<span class="bg-surface-variant px-sm py-1 rounded text-caption text-on-surface-variant">ธมฺมปท ภาค 1-4</span>
</div>
<!-- Structure Section -->
<div class="bg-surface-container-low rounded-xl p-md border border-outline-variant/20">
<div class="flex items-center gap-xs text-primary mb-sm">
<span class="material-symbols-outlined text-[18px]">account_tree</span>
<span class="font-title-sm">โครงสร้างคำ</span>
</div>
<div class="flex gap-md">
<div class="bg-surface-container-lowest border border-primary/30 rounded-lg p-md text-center flex-1 shadow-sm">
<div class="text-display-pali text-primary">ยุ</div>
<div class="text-caption text-on-surface-variant">ปัจจัย</div>
</div>
<div class="flex-1 flex flex-col justify-center">
<p class="text-body-md text-on-surface-variant">ประกอบด้วย ทิส ธาตุ ในความเห็น + ยุ ปัจจัย</p>
</div>
</div>
</div>
<!-- Analysis Section -->
<div class="bg-tertiary-fixed/20 rounded-xl p-md border border-tertiary/10">
<div class="flex items-center gap-xs text-tertiary mb-sm">
<span class="material-symbols-outlined text-[18px]">search_check</span>
<span class="font-title-sm">บทวิเคราะห์</span>
</div>
<div class="bg-surface-container-lowest/50 rounded-lg p-md border-l-4 border-tertiary">
<p class="text-body-lg text-on-surface italic">วิ. ทสฺสนํ = ทสฺสนํ</p>
</div>
<p class="mt-sm text-body-md text-on-surface-variant">ภาวรูป ภาวสาธนะ</p>
</div>
<!-- Conjugation / Declension -->
<div class="bg-surface-container-low rounded-xl p-md border border-outline-variant/20">
<div class="flex items-center gap-xs text-on-surface-variant mb-sm">
<span class="material-symbols-outlined text-[18px]">grid_view</span>
<span class="font-title-sm">การแจกวิภัตติ</span>
</div>
<div class="space-y-sm">
<div class="flex items-center gap-sm">
<span class="material-symbols-outlined text-outline text-[20px]">sort</span>
<span class="text-body-md text-on-surface">แบบแจก: <span class="font-bold">แจกเหมือน กุล</span></span>
</div>
<div class="overflow-x-auto custom-scrollbar">
<table class="w-full text-left text-body-md border-collapse">
<thead>
<tr class="text-caption text-outline uppercase tracking-wider">
<th class="py-sm pr-md border-b border-outline-variant/30">วิภัตติ</th>
<th class="py-sm pr-md border-b border-outline-variant/30">เอกพจน์</th>
<th class="py-sm border-b border-outline-variant/30">พหูพจน์</th>
</tr>
</thead>
<tbody class="text-on-surface">
<tr>
<td class="py-sm pr-md border-b border-outline-variant/10 text-caption font-bold">ปฐมา (ที่ 1)</td>
<td class="py-sm pr-md border-b border-outline-variant/10">ทสฺสนํ</td>
<td class="py-sm border-b border-outline-variant/10">ทสฺสนานิ</td>
</tr>
<tr>
<td class="py-sm pr-md border-b border-outline-variant/10 text-caption font-bold">ทุติยา (ที่ 2)</td>
<td class="py-sm pr-md border-b border-outline-variant/10">ทสฺสนํ</td>
<td class="py-sm border-b border-outline-variant/10">ทสฺสนานิ</td>
</tr>
<tr>
<td class="py-sm pr-md border-b border-outline-variant/10 text-caption font-bold">ตติยา (ที่ 3)</td>
<td class="py-sm pr-md border-b border-outline-variant/10">ทสฺสเนน</td>
<td class="py-sm border-b border-outline-variant/10">ทสฺสเนหิ</td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
</div>
</article>
<!-- Contextual Information Image (Illustration of Study) -->
<section class="rounded-xl overflow-hidden shadow-lg h-48 relative">
<img alt="Buddhist study" class="w-full h-full object-cover" data-alt="A serene close-up photograph of weathered Pali manuscript pages resting on a dark wooden table in a quiet library environment. The scene is illuminated by warm, soft side-lighting that highlights the texture of the old parchment and the elegant curves of traditional Thai or Pali script. The overall atmosphere is scholarly, tranquil, and deeply respectful of tradition, using a sophisticated color palette of deep browns, soft creams, and golden accents." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBxUwcW2U-uDzd8nFIQyuFUrVl5cyOSDhYrbgKe97mSfcaO_OD2ZtVf-siWLlR6y9cwuHKabBHTJNnhKqG2sOAD-sSshkxrFp2w5g06NqQIcwmjmRbMMLHfqLARNXattKWLYHtu30n_wHbN6PsBURmNVl9jKvuhetXbMtuMwG5fHRL2Nqx8iewEzZraTHMgxSNK4F2A1V7UG4uSkWJezyXlHRi4ndAes3ZNBGW29SXBFzXViqODJJ8UCG6zbtWIlvNkUSMhuCnjUco"/>
<div class="absolute inset-0 bg-gradient-to-t from-on-surface/80 to-transparent flex items-end p-lg">
<p class="text-on-primary font-title-sm">ศึกษาเชิงลึกจากคัมภีร์ดั้งเดิม</p>
</div>
</section>
</main>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 w-full z-50 rounded-t-xl bg-surface dark:bg-surface-container-lowest flex justify-around items-center h-16 px-gutter border-t border-outline-variant/30 shadow-[0_-4px_12px_rgba(37,99,235,0.08)]">
<button class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors group">
<span class="material-symbols-outlined">search</span>
<span class="font-label-caps text-label-caps">Search</span>
</button>
<button class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors group">
<span class="material-symbols-outlined">bookmark</span>
<span class="font-label-caps text-label-caps">Favorites</span>
</button>
<button class="flex flex-col items-center justify-center bg-primary-container text-on-primary-container rounded-full px-4 py-1 active:scale-90 duration-150">
<span class="material-symbols-outlined">history</span>
<span class="font-label-caps text-label-caps">History</span>
</button>
<button class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors group">
<span class="material-symbols-outlined">settings</span>
<span class="font-label-caps text-label-caps">Settings</span>
</button>
</nav>
</body></html>